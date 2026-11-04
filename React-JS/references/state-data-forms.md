# State, data fetching, and forms

Contents: State management · API and async · Forms · Production API flow (HTTP client, services, query library) · React 19 forms and actions · Suspense and `use()`. Failure UX and monitoring live in `error-handling-observability.md`; templates in `assets/templates/http-client.ts`.

Read when handling shared state, API calls, async flows, or forms.

## State management
Most state bugs come from two copies of the same fact disagreeing.

- Use local state for local UI concerns (open/closed, input text, selected tab).
- Use Context for values many distant components need and that change rarely (theme, current user, locale). Frequently changing values in Context re-render every consumer.
- When shared client state is genuinely needed, use the state library the project already uses. Do not add a second one.
- Separate server state (data that lives on the backend: lists, profiles) from client/UI state. Server state needs caching, refetching and invalidation; if the project uses React Query, SWR, RTK Query or similar, use it rather than copying fetched data into a store by hand.
- Keep one source of truth. If data can be derived or read from the cache, do not store a duplicate.
- Handle every state a user can see: loading, success, empty, error, and stale data (cached data shown while refetching).
- When mutating, invalidate or update the right cache entries. For optimistic updates, always implement rollback on failure and show the user the error.

## API and asynchronous operations
- Reuse the existing API client and service conventions (base URL, interceptors, typed endpoints). Do not scatter raw `fetch` calls beside an existing client.
- Centralize common request configuration (auth headers, base URL) and error handling so every call fails the same predictable way.
- Respect the backend contract and authorization rules. Do not guess response shapes; read the types, docs or a real response.
- Handle HTTP errors (4xx and 5xx), network failures and timeouts, and retry only operations that are safe to repeat (idempotent reads), with backoff. Never blindly retry a payment or other non-idempotent write.
- Prevent stale requests from overwriting newer results (typing in a search box, fast route changes). Cancel with `AbortController`, ignore outdated responses, or rely on the data library's keyed queries.
- Cancel or ignore in-flight work on unmount so you do not set state on a component that is gone.
- Validate untrusted data at boundaries: API responses, URL params, storage and `postMessage`. TypeScript types do not exist at runtime; use a schema validator (the project's, such as Zod) where bad data would cause harm.
- Never put private credentials (secret API keys, signing secrets) in browser code, `VITE_*`/`REACT_APP_*`/`NEXT_PUBLIC_*` variables, or the bundle. Anything shipped to the browser is public. See `security-privacy.md`.

## Forms and user interactions
- Use semantic HTML: `<form>`, `<label>`, `<button type="submit">`, and appropriate input types (`email`, `tel`, `number`, `date`) with `autocomplete` attributes. This gives mobile keyboards, autofill and browser validation for free.
- Keep client validation consistent with backend rules, and treat the backend as the final authority. Show server-side validation errors next to the right fields.
- Use the project's form and schema libraries (React Hook Form, Formik, Zod, Yup) when the form is complex enough to justify one. A two-field form does not need a library.
- Prevent duplicate submissions: disable or guard the submit while pending, and ideally make the server tolerate repeats.
- Preserve what the user typed after a recoverable error. Never clear a form because the network failed.
- Give clear, specific field-level errors and visible submission feedback (success message, error summary).
- Handle all states: pending (spinner or label change), disabled, success, failure.
- Support keyboard use (Enter to submit, logical tab order) and move focus sensibly after errors or success. See `accessibility-responsive.md` for error announcement.

---

# Production API flow (end to end)

Use this shape for any new data flow. Each concern lives in exactly one layer, so a change to the backend or to the UI touches one place.

```
Component
  └─ hook: useOrders() / useCreateOrder()      ← query/mutation, loading + error state
       └─ service: ordersApi.list / create     ← typed functions, no React
            └─ http client                     ← base URL, auth, timeout, error normalizing
                 └─ network
            └─ schema.parse(response)          ← runtime validation, DTO → view model
```

## The HTTP client (one per app)
- Set the base URL, credentials mode and headers in one wrapper. Add a timeout (`AbortSignal.timeout(ms)`) combined with the caller's cancellation signal, since `fetch` waits forever by default.
- Normalize errors into one type (for example `ApiError { status, code, message, requestId, fieldErrors }`) so components never parse raw responses. Keep user-facing text separate from technical detail, and log the request ID.
- Handle `401` in one place: attempt a single token refresh (single-flight, so ten parallel calls trigger one refresh), retry the request once, then send the user to sign in. Never loop.
- Retry only idempotent requests (GET, and PUT/DELETE when safe), with exponential backoff and jitter, and not on `4xx` other than `408`/`429`. For non-idempotent writes (create order, payment), send an idempotency key so a retry or double click cannot create two.

## Services and validation
- Services are plain typed functions per resource (`ordersApi.get(id)`). They return validated, app-shaped data.
- Validate responses at the boundary with a schema library (Zod, Valibot, or the project's), and map transport DTOs to view models there. When the server changes shape, the failure appears in one place with a clear message instead of as `undefined is not a function` deep in a component.
- Tolerate additive backend changes (ignore unknown fields) but fail loudly on missing required ones.

## Server state with a query library
- Use TanStack Query, SWR, RTK Query or the project's equivalent rather than `useEffect` plus `useState`. You get caching, deduplication, retries, background refetch and cancellation by default.
- Centralize query keys in a factory (`orderKeys.detail(id)`) so invalidation is exact and typo-proof.
- Set `staleTime` deliberately per resource. The default of zero refetches aggressively; data that rarely changes can be cached for minutes.
- After a mutation, invalidate or update the specific keys it affects. For optimistic updates: snapshot previous data, apply the change, roll back on error, and refetch on settle.
- Handle pagination and infinite lists with the library's primitives, and keep previous data visible while the next page loads.
- Surface errors with an error boundary or inline error component that offers a retry which resets the query.

## React 19 forms and actions
- `<form action={asyncFn}>` with `useActionState` gives pending state, the last result and progressive behavior without hand-written `onSubmit`/`preventDefault` boilerplate. Return field errors and the submitted values in the action state so the form re-renders with them.
- `useFormStatus` lets a nested submit button read pending state without prop drilling. `useOptimistic` shows an immediate result while the action runs and reverts automatically if it fails.
- Actions complement a query library; they do not replace it. Run mutations through the action, then invalidate the affected queries.
- In a Server Components framework, a Server Function used as an action is a public endpoint: authenticate, authorize and validate its input on the server every time. See `security-privacy.md`.
- Still validate on the server and show server errors per field, regardless of client validation.

## Suspense and `use()`
- Suspense-based data reading works when the library or framework supports it (cached promises). Never create a new promise during render. Wrap the section in both `<Suspense fallback>` and an error boundary.
- Show skeletons that match the final layout to prevent layout shift.
