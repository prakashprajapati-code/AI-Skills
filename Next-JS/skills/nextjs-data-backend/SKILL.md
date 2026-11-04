---
name: nextjs-data-backend
description: Data and backend integration in Next.js App Router - Route Handlers (app/api), Server Actions, request validation with Zod, database access (Prisma/Drizzle/SQL), transactions, pagination, idempotency, external API clients, error envelopes and status codes, file uploads, background work with after(). Use this skill whenever the user creates an API route or server action, wires a form to the backend, queries or mutates a database, needs a transaction, validates input, calls a third-party API, designs response/error shapes, or asks "server action or route handler?".
---

# Next.js: Data and Backend Integration

Every mutation crosses a trust boundary. Treat Server Actions and Route Handlers as public HTTP endpoints: anyone can call them with any payload, whether or not your UI exists.

## Principles (and why)
1. **Server Action for your own UI's mutations; Route Handler for everything else.** Actions integrate with forms, revalidation and progressive enhancement. Route Handlers are for webhooks, third-party consumers, mobile apps, streaming, and non-POST needs.
2. **One pipeline for every entry point:** parse -> authenticate -> authorize -> validate -> execute -> revalidate -> respond. A fixed order means no step is forgotten.
3. **Thin entry, real logic in a service.** The action/handler is ~20 lines and calls a service function; the service is testable without HTTP.
4. **Validation is authoritative on the server.** Client checks are UX only.
5. **Transactions wrap multi-step writes.** Partial writes leave data inconsistent.
6. **Consistent envelope.** Callers (and ops) learn one response shape and one status map.

## Server Action vs Route Handler
| Need | Use |
|---|---|
| Form or button in your Next UI mutates data | Server Action |
| Webhook (Stripe, GitHub), third-party/mobile client, cron | Route Handler |
| Streaming, SSE, file download, custom headers/status | Route Handler |
| Read data for rendering | Neither: call the query in a Server Component |
| Client-side fetch of read data after load (infinite scroll, search-as-you-type) | Route Handler (GET) or a server action used sparingly |

## Rules
1. **[MUST]** Re-check authentication and authorization *inside* every action and handler. Never assume the UI hid the button. See `nextjs-security`.
2. **[MUST]** Validate every input with Zod: `safeParse` the body/`FormData`, route params and query. On failure return field errors, do not throw.
3. **[MUST]** Server Actions are files/functions with `"use server"`; they must be `async`, accept serializable arguments, and return serializable results. Keep database and secrets code in `import "server-only"` modules.
4. **[MUST]** Use one response envelope: `{ ok: true, data } | { ok: false, error: { code, message, fieldErrors? } }`. Handlers also set the status: 200/201 success, 400 validation, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 429 throttled, 5xx server fault. Clients get generic messages; real errors go to server logs.
5. **[MUST]** Wrap related writes in a transaction (`prisma.$transaction`, Drizzle `db.transaction`, SQL `BEGIN/COMMIT`). Keep transactions short: no network calls, emails, or slow work inside.
6. **[MUST]** Select only the fields you need; never return a whole ORM row (it may include password hashes, internal flags). Map to a DTO.
7. **[MUST]** After a successful mutation, revalidate (`revalidateTag`/`revalidatePath`) or redirect. See `nextjs-rendering-react`.
8. **[MUST]** Route Handlers that need Node APIs (DB drivers, nodemailer, fs) declare `export const runtime = "nodejs"`. Check the edge runtime's limits before choosing it.
9. **[SHOULD]** Make unsafe retries safe: idempotency keys for payments/orders, unique constraints for natural keys, upserts where appropriate. Webhooks: verify signature, dedupe by event ID.
10. **[SHOULD]** Paginate every list (cursor-based for large/changing data, offset for small admin tables); cap `limit` server-side.
11. **[SHOULD]** Prevent N+1 queries: batch with `include`/joins or `IN` queries; dedupe per request with `React.cache`.
12. **[SHOULD]** Singleton DB client in dev to avoid exhausting connections on hot reload (`globalThis` pattern); use a pooler/serverless driver on serverless platforms.
13. **[SHOULD]** Defer non-critical work (analytics, emails) with `after()` (Next 15.1+) or a queue so the response is fast; make it fail-safe.
14. **[SHOULD]** External API calls: timeout (`AbortSignal.timeout`), bounded retry with backoff for idempotent calls, typed response parsed with a schema, secrets from env.

## Action template
Copy `assets/server-action.ts` and `assets/route-handler.ts`, then replace `<placeholders>`. Shape:
```ts
"use server";
export async function createInvoiceAction(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const session = await requireUser();                              // authenticate
  const parsed = createInvoiceSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return invalid(parsed.error);                // validate
  if (!can(session.user, "invoice:create")) return forbidden();     // authorize
  const invoice = await createInvoice(session.user.id, parsed.data);// service (transaction inside)
  revalidateTag("invoices");                                        // revalidate
  return { ok: true, data: { id: invoice.id } };
}
```
Client side use `useActionState(createInvoiceAction, initialState)` and render `fieldErrors` next to inputs.

## Database and transactions
Guidance for Prisma/Drizzle/SQL, connection handling, migrations, isolation and locking: `references/database-and-transactions.md`.

## File uploads
Validate type by content/extension allow-list and size server-side, generate your own filename, store outside the web root or in object storage (signed URLs), and never trust `file.type` alone. Stream large files; do not buffer them in memory.

## Pitfalls
- Action arguments are user input. `deleteItem(id)` without an ownership check is an IDOR vulnerability.
- Returning `error.message` from Prisma or SMTP libraries leaks internals.
- Doing `redirect()` inside `try/catch`: it works by throwing; call it after the try block.
- Calling your own Route Handler from a Server Component with `fetch("/api/...")`: call the service function directly.
- Long transactions holding row locks while awaiting an HTTP call.
- Forgetting body size limits: Server Actions default to 1 MB (`serverActions.bodySizeLimit`); raise deliberately.
- Using GET for mutations; use POST/PUT/PATCH/DELETE.

## Verification checklist
- [ ] Every action/handler: auth + authorization + Zod validation + generic errors
- [ ] Multi-write operations are in one short transaction; list queries paginated
- [ ] DTO mapping: no sensitive columns returned
- [ ] Mutations revalidate affected data; status codes follow the map
- [ ] Probe with bad JSON, missing fields, wrong user, oversize payload, duplicate submit

## Related skills
`nextjs-security` (auth, rate limits), `nextjs-typescript-conventions` (Result/Zod types), `nextjs-rendering-react` (revalidation).
