# Database and transactions

## Client singleton (dev hot-reload safe)
```ts
// lib/server/db.ts
import "server-only";
import { PrismaClient } from "@prisma/client"; // or your Drizzle/pg client

const globalForDb = globalThis as unknown as { prisma?: PrismaClient };
export const db = globalForDb.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForDb.prisma = db;
```
Serverless platforms: use a pooled connection string (PgBouncer/Accelerate/Neon pooler) or an HTTP driver; every function instance otherwise opens its own connections.

## Transactions
```ts
// Prisma: interactive transaction. Keep it short; no network calls inside.
const order = await db.$transaction(async (tx) => {
  const item = await tx.stock.update({ where: { sku }, data: { qty: { decrement: qty } } });
  if (item.qty < 0) throw new AppError("Out of stock", "CONFLICT"); // throwing rolls back
  return tx.order.create({ data: { userId, sku, qty } });
});

// Drizzle
await db.transaction(async (tx) => {
  await tx.update(stock).set({ qty: sql`${stock.qty} - ${qty}` }).where(eq(stock.sku, sku));
  await tx.insert(orders).values({ userId, sku, qty });
});
```
Rules of thumb:
- A transaction = one business invariant (debit + credit, stock + order). If two writes can be independently valid, they do not need one.
- Send emails and webhooks *after* commit (use `after()` or an outbox table). Otherwise a rollback leaves a sent email for a non-existent order.
- Guard against lost updates: atomic `decrement/increment` updates, optimistic version column (`WHERE version = ?`), or `SELECT ... FOR UPDATE` for hot rows.
- Enforce invariants in the database too (unique, foreign key, check constraints). App-level checks race.
- Default isolation (read committed in Postgres) is enough for most cases; reach for `serializable` with retry only for tricky invariants.

## Idempotency
- Payments/orders: accept an `Idempotency-Key`; store key + result with a unique constraint; return the stored result on replay.
- Webhooks: store processed `event.id` with a unique constraint; ignore duplicates.

## Pagination
```ts
// cursor pagination
const rows = await db.item.findMany({ take: limit + 1, ...(cursor && { cursor: { id: cursor }, skip: 1 }), orderBy: { id: "asc" } });
const nextCursor = rows.length > limit ? rows.pop()!.id : null;
```
Cap `limit` (for example max 100) on the server; index the sort column.

## Migrations
- Schema changes go through migration files committed to git (`prisma migrate`, `drizzle-kit`), run in CI/deploy, never edited by hand in production.
- Backwards-compatible steps (expand -> migrate data -> contract) so old and new app versions can run together during deploy and rollback is safe.

## DTO mapping
```ts
const toUserDto = (u: User) => ({ id: u.id, name: u.name, email: u.email }); // never spread the row
```
