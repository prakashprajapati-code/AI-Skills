# React Patterns for Next.js (React 19)

Read when writing or reviewing Client Components, hooks, state, forms or re-render problems. Hooks only run in Client Components (`"use client"`). Server Components cannot use state, effects, refs or context consumers.

`[MUST]` = correctness. `[SHOULD]` = strong default. Confirm against the installed React version.

## 1. Hooks cheat sheet
| Hook | Use for | Avoid |
|---|---|---|
| `useState` | Local UI state that changes on interaction | Storing values you can compute from props/state; mirroring props |
| `useReducer` | Many related fields or transitions (wizard, cart, form with rules); pure `(state, action) => state` | Simple booleans/strings |
| `useRef` | Mutable value that must not trigger render (timer id, previous value), DOM node access | Reading/writing `ref.current` during render |
| `useEffect` | Sync with an external system (subscription, timer, non-React widget, analytics) | Deriving state, handling clicks, fetching data a server component could fetch |
| `useLayoutEffect` | Measure DOM before paint (tooltip position). Client-only; warns in SSR if it runs on the server path | Anything that is not layout measurement |
| `useMemo` / `useCallback` | Expensive pure computation; stable identity for a `memo` child or an effect dependency | Wrapping everything "just in case" |
| `useContext` | Read shared low-churn values (theme, session user, locale) | High-frequency state (typing, mouse position) |
| `useTransition` | Mark a state update or async Action as non-urgent; `isPending` for UI | Controlled text input value (keep that urgent) |
| `useDeferredValue` | Let an expensive child lag behind a fast input (search results list) | Replacing debounce for network calls |
| `use(promiseOrContext)` | Read a promise (created in a Server Component and passed down) inside `Suspense`; read context conditionally | Creating the promise in render of the same client component (new promise every render) |
| `useSyncExternalStore` | Subscribe to an external store (`matchMedia`, online status, custom store); gives SSR-safe snapshots | Local component state |
| `useId` | Stable ids for `htmlFor`/`aria-describedby`, same on server and client | List keys; CSS selectors |
| `useImperativeHandle` | Expose a tiny imperative API (`focus()`, `reset()`) from a component | Default; prefer props |
| `useEffectEvent` | Effect callback that reads latest props/state without being a dependency (check React version availability) | Hiding real dependencies |
| `useActionState` / `useFormStatus` / `useOptimistic` | Server-action forms: pending, returned errors, optimistic UI | Hand-rolled `loading` flags |

## 2. Effects: "You might not need an effect"
1. **[MUST]** Do not use an effect to compute something from props/state. Compute it during render (`const total = items.reduce(...)`).
2. **[MUST]** Do not use an effect to respond to a user event. Put the logic in the event handler (or the server action).
3. **[MUST]** Do not reset state with an effect when a prop changes. Give the component a `key` (`<Profile key={userId} />`) so it remounts.
4. **[MUST]** Every effect that subscribes, sets a timer or opens a connection returns a cleanup function.
5. **[MUST]** Dependency array lists every reactive value used. Never silence `react-hooks/exhaustive-deps`; restructure instead (move the function inside, use a ref, or `useEffectEvent`).
6. **[MUST]** Effects that fetch handle races: abort with `AbortController` or ignore stale results. Better: fetch in a Server Component, or use TanStack Query/SWR on the client.
7. **[SHOULD]** One effect = one purpose; split unrelated work.
8. **[SHOULD]** Strict Mode (on by default in dev) runs mount -> unmount -> mount to expose missing cleanup. If an effect breaks under it, the effect is wrong, not Strict Mode. Do not remove `reactStrictMode`.
9. **[SHOULD]** Browser-only values (`window`, `localStorage`, `matchMedia`): read them in an effect or via `useSyncExternalStore` with a server snapshot, never in render (hydration mismatch).

```tsx
// Wrong: derived state synced by an effect
const [filtered, setFiltered] = useState<Item[]>([]);
useEffect(() => setFiltered(items.filter(match)), [items, match]);

// Right: derive in render (add useMemo only if profiling shows it is slow)
const filtered = items.filter(match);
```

```tsx
// Effect with cleanup and race protection
useEffect(() => {
  const controller = new AbortController();
  fetch(`/api/search?q=${encodeURIComponent(q)}`, { signal: controller.signal })
    .then((r) => r.json())
    .then(setResults)
    .catch((e) => { if (e.name !== "AbortError") setError(e); });
  return () => controller.abort();
}, [q]);
```

## 3. Memoization and the React Compiler
1. **[SHOULD]** Measure first (React DevTools Profiler, "Highlight updates"). Do not memoize by default.
2. **[SHOULD]** If the React Compiler is enabled (`reactCompiler: true` in `next.config`, plus `babel-plugin-react-compiler`), it auto-memoizes pure components: remove hand-written `useMemo`/`useCallback`/`memo` added only for speed, and keep them only where identity matters (effect dependencies, third-party libs). Check the installed Next/React docs: support level has changed across versions.
3. **[MUST]** Without the compiler, memoization is only effective if props are stable. A `memo` child receiving a new inline object/array/function each render re-renders anyway.
4. **[SHOULD]** Prefer structural fixes before memo: move state down into the component that uses it; pass `children` so the parent's re-render does not re-render them; split a context.
5. **[MUST]** Never mutate state or props. Create new objects/arrays (`[...items, x]`, `{ ...obj, a: 1 }`). Mutation breaks memo, effects and the compiler.
6. **[SHOULD]** Long lists (hundreds of rows): virtualize (`@tanstack/react-virtual`) instead of memoizing rows.
7. **[SHOULD]** Defer non-urgent updates with `useTransition` / `useDeferredValue` before reaching for memo.

## 4. Lists and keys
1. **[MUST]** Every element in a mapped list has a `key` that is stable and unique among siblings: a database id or slug.
2. **[MUST]** Never use `Math.random()` or `crypto.randomUUID()` in render as a key (remounts every time). Never use the array index when items can be reordered, inserted or deleted (state attaches to the wrong row).
3. **[SHOULD]** Index keys are acceptable only for static lists that never change.
4. Changing `key` deliberately resets a component's state (see effects rule 3).

## 5. Forms: controlled vs uncontrolled
1. **[SHOULD]** Default to **uncontrolled** forms with a `<form action={serverAction}>` and `name` attributes; read values with `FormData`. Less state, fewer re-renders, works before hydration.
2. **[SHOULD]** Use **controlled** inputs (`value` + `onChange`) only when the UI reacts to every keystroke (live validation, formatting, dependent fields, character counters).
3. **[MUST]** Never switch an input between controlled and uncontrolled (`value={undefined}` then a string): give it an initial `""`.
4. **[SHOULD]** For complex client forms use React Hook Form + Zod resolver; the same Zod schema validates again on the server (never trust client validation).
5. **[SHOULD]** Pair `useId` with `<label htmlFor>` and `aria-describedby` for errors (see `nextjs-ui-accessibility`).
6. Server-action form pattern: `useActionState(action, initialState)` returns `[state, formAction, isPending]`; render `state.errors` next to fields; disable the submit button while `isPending`; use `useOptimistic` for instant list updates.

## 5b. Client Actions and transitions (React 19)
- Wrap async mutations in `startTransition(async () => { await save(); })` so `isPending` is tracked and the UI stays responsive; errors thrown inside surface to the nearest error boundary.
- `useOptimistic` shows the expected result immediately and reverts automatically if the action fails.
- Do not call `setState` for pending flags manually when `useTransition`/`useActionState` gives them to you.

## 6. State placement (decision order)
1. Derive it (compute during render). 2. URL (filters, pagination, tabs; shareable, server-rendered). 3. Local `useState`/`useReducer` in the lowest component that needs it. 4. Lift to the nearest common parent. 5. Context for low-churn app-wide values. 6. A store library for genuinely shared client state. 7. Server cache library for server data on the client.

| Need | Choose |
|---|---|
| Server data on the client (polling, mutations, infinite scroll, cache invalidation) | TanStack Query or SWR; do not copy results into `useState` |
| Small shared client state (sidebar open, cart UI, wizard) | Zustand or Jotai; Redux Toolkit when the team already uses it or needs devtools/middleware discipline |
| Theme, locale, current user | Context, provided from a small client `Providers` component |
| Form state | Uncontrolled + `FormData`, or React Hook Form |

**[MUST]** Server data fetched in a Server Component is passed as props; do not duplicate it into a client store. **[MUST]** In Next.js, a module-level store is shared across requests on the server: create stores per request/provider (inside the Provider with `useRef`/`useState` initializer), never as a mutable global used during SSR.

## 7. Context
1. **[SHOULD]** One context per concern (`ThemeContext`, `SessionContext`); do not build one giant "AppContext" that re-renders every consumer on any change.
2. **[SHOULD]** Memoize the provider `value` (or use the compiler) and split state from dispatch contexts for frequently changing state.
3. **[SHOULD]** Avoid prop drilling beyond ~3 levels: first try composition (`children`, slots such as `header={<Header />}`), then context.
4. **[SHOULD]** Export a custom hook (`useSession()`) that throws a clear error if used outside its provider.
5. React 19: `<ThemeContext value={...}>` can be used directly as the provider (no `.Provider`); `.Provider` still works.

## 8. Custom hooks
1. **[MUST]** Name starts with `use`; call hooks only at the top level of components/hooks (not in conditions, loops, nested functions, or after an early return).
2. **[SHOULD]** Extract a hook when stateful logic is reused or a component mixes several concerns; keep it focused (`useDebounce`, `useMediaQuery`, `useDisclosure`).
3. **[SHOULD]** Return a stable, typed shape: tuple for 1-2 values (`[value, setValue]`), object for 3+.
4. **[SHOULD]** A hook does not hide fetching/mutation that belongs on the server; if it only wraps `fetch` in an effect, use TanStack Query or a server component instead.
5. **[SHOULD]** Test hooks with `renderHook` (see `nextjs-testing-quality`).
6. Do not export hooks from server-only files; hooks files that use state need `"use client"` at the importing component boundary, not necessarily in the hook file itself.

## 9. Refs
1. **[SHOULD]** Use refs for DOM access (focus, scroll, measure) and for mutable values that must not cause re-render.
2. **[MUST]** Do not read or write `ref.current` during render (except lazy initialization). Do it in effects or handlers.
3. React 19: `ref` is a normal prop for function components; `forwardRef` is no longer needed (still works, deprecated direction). Ref callbacks may return a cleanup function.
4. **[SHOULD]** Expose a minimal imperative API with `useImperativeHandle` rather than the whole DOM node when building reusable components.
5. **[SHOULD]** Accessibility: after opening a dialog, move focus into it; on close, return focus to the trigger (store it in a ref). Prefer the native `<dialog>` or a proven library (Radix, React Aria).

```tsx
// React 19: ref as a prop
function TextField({ ref, ...props }: React.ComponentProps<"input">) {
  return <input ref={ref} {...props} />;
}
```

## 10. Portals, composition, and component design
1. **[SHOULD]** Render modals, tooltips, popovers and toasts with `createPortal(node, document.body)` (client-only; render after mount) or a library that does it, so they escape `overflow: hidden` and z-index stacking. React events still bubble through the React tree.
2. **[SHOULD]** Prefer composition over configuration: `<Card><Card.Header/>...</Card>` (compound components) beats a component with 15 boolean props.
3. **[SHOULD]** Props: required first, sensible defaults, no boolean explosion; use a `variant` union instead (`"primary" | "ghost"`). Spread rest props onto the root element for `className`, `aria-*`, handlers.
4. **[MUST]** Components are pure: same props/state -> same output, no side effects during render, no mutation of outside variables.
5. **[SHOULD]** One component per file, defined at module level; never define a component inside another component (it remounts on every render and loses state).
6. **[SHOULD]** Keep components small; split when a file mixes data fetching, layout and interaction.

## 11. Error and loading boundaries
1. Server/route level: `error.tsx` (must be a Client Component, receives `error` and `reset`), `global-error.tsx`, `not-found.tsx`, `loading.tsx`.
2. **[SHOULD]** For an isolated client widget that can crash (chart, third-party embed), wrap it in an error boundary (`react-error-boundary`'s `ErrorBoundary` with `fallbackRender` and `resetKeys`) so the page survives.
3. Error boundaries do not catch errors in event handlers, async code or effects: catch those and set state (or `throw` inside `startTransition`) to surface them.
4. Never show raw error messages or stack traces to users; log them (see `nextjs-devops-operations`).
5. **[SHOULD]** Use `<Suspense fallback>` around each independently loading region, not one boundary for the whole page.

## 12. Code splitting on the client
- `next/dynamic(() => import("./Chart"), { loading: () => <Skeleton /> })` for heavy client-only components (charts, editors, maps); `ssr: false` only inside a Client Component.
- `React.lazy` + `<Suspense>` works in Client Components, but `next/dynamic` is the Next.js idiom.
- Load below-the-fold or interaction-gated components on demand (on open, on scroll). Measure with the bundle analyzer (`nextjs-performance`).

## 13. React 19 additions worth using
1. `<form action={fn}>` and `formAction` on buttons, with `useActionState`.
2. `use()` to unwrap a promise passed from a Server Component (stream with `Suspense`).
3. Document metadata tags (`<title>`, `<meta>`, `<link>`) render into `<head>` from components. In Next.js App Router, still prefer the Metadata API (`nextjs-seo`).
4. `ref` as a prop and ref-callback cleanup (section 9).
5. Resource hints: `preload`, `preinit`, `preconnect` from `react-dom` for critical resources; in Next.js prefer `next/font` and `next/image priority` first.
6. Context as provider (`<Ctx value>`), `useDeferredValue` initial value, better hydration error messages (read the diff in the message).
7. Actions: async functions passed to transitions get pending/error/optimistic handling built in.

## 14. Lint and tooling
- Enable `eslint-plugin-react-hooks` (`rules-of-hooks`: error, `exhaustive-deps`: error). `eslint-config-next` includes it; keep it at error level, and if you enable the React Compiler also enable its lint rules (`eslint-plugin-react-compiler` / the compiler rules in recent `react-hooks` versions).
- Add `react/jsx-key` (error) and `react/no-array-index-key` (warn).
- Use `@axe-core/react` or `eslint-plugin-jsx-a11y` (included by `eslint-config-next`) for a11y feedback.
- React DevTools Profiler: record an interaction, look for components that re-render with unchanged props; fix state placement before adding memo.

## 15. Review checklist for React code
- [ ] No effect that derives state, handles an event, or fetches what a server component could
- [ ] Each effect has correct dependencies and a cleanup; race conditions handled
- [ ] Keys stable and unique; no index keys on dynamic lists; no components defined inside components
- [ ] State at the lowest sensible level; server data not copied into client state
- [ ] No state mutation; no `ref.current` access in render; hooks at top level only
- [ ] Memoization justified by measurement (or handled by the compiler)
- [ ] Inputs consistently controlled or uncontrolled; labels, `useId`, error linkage present
- [ ] Error boundary and Suspense boundary around risky or slow client regions
- [ ] Browser-only values read after mount or via `useSyncExternalStore`; no hydration warnings
