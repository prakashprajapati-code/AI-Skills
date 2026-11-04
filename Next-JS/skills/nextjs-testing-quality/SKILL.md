---
name: nextjs-testing-quality
description: Testing and code quality for Next.js - unit tests (Vitest/Jest), component tests (Testing Library), integration tests for route handlers and server actions, end-to-end tests (Playwright), accessibility tests, ESLint flat config, Prettier, TypeScript type checking, Husky/lint-staged, CI quality gates, PR review checklists, and upgrade/debug workflows. Use this skill whenever the user writes or fixes tests, sets up Vitest/Jest/Playwright/ESLint/Prettier, asks what to test, reviews a pull request or diff, asks "is this ready to merge", debugs a failing build/lint/test, or upgrades Next.js, React or ESLint versions.
---

# Next.js: Testing and Code Quality

Tests exist to let you change code without fear. Aim for fast feedback on the things that break most and cost most: business logic, data boundaries, critical user flows.

## Principles (and why)
1. **Test pyramid, not ice-cream cone.** Many fast unit tests, fewer integration tests, a handful of end-to-end tests on money/auth paths. Slow tests get skipped.
2. **Test behavior, not implementation.** Query by role/text (what users see), assert outcomes. Tests that mirror internals break on every refactor.
3. **Automate the boring review.** Types, lint, format and tests run in the editor, pre-commit and CI; humans review design and risk.
4. **Small, verified, reversible changes.** Each PR is reviewable in minutes, green in CI, and can be reverted alone.
5. **Server Components are tested where they can be:** extract logic to plain functions (unit), and cover rendering through E2E, because async Server Components are not supported by most unit renderers.

## What to test where
| Layer | Tool | Examples |
|---|---|---|
| Pure logic (`lib/`, services, validators, formatters) | Vitest/Jest | Zod schemas accept/reject, price calc, slug, permission `can()` |
| Client components | Vitest + Testing Library + `user-event` | form shows errors, button disabled while pending, dialog focus |
| Route handlers and server actions | Vitest calling the function with a `Request`/`FormData`; real or containerized test DB | 400 on bad body, 403 for wrong user, transaction rollback |
| Whole flows incl. Server Components | Playwright | sign in -> create item -> see it listed; checkout; contact form |
| Accessibility | `@axe-core/playwright` / `jest-axe` | no critical violations on key pages |
| Visual (optional) | Playwright screenshots / Storybook | design-system regressions |

## Rules
1. **[MUST]** CI runs, in order: install (`npm ci`), `tsc --noEmit`, lint, unit/integration tests, build. Main branch protected; PRs require green CI.
2. **[MUST]** Cover every authorization rule and validation schema with tests (accept and reject cases). Security regressions are the most expensive ones.
3. **[MUST]** New bug -> failing test first -> fix. The test pins the regression.
4. **[MUST]** Tests are deterministic: fake timers/clock, seeded data, no network (mock with MSW or inject clients), no order dependence, clean DB state per test (transaction rollback or truncate).
5. **[MUST]** ESLint with `eslint-config-next` (core-web-vitals + typescript) in flat config; no-`any`, consistent type imports, no unused vars. Fix warnings; do not disable rules file-wide. Template: `assets/eslint.config.mjs`.
6. **[SHOULD]** Prettier (or Biome) owns formatting; no style debates in review. `lint-staged` + Husky pre-commit run `eslint --fix`, `prettier --write`, and `tsc --noEmit` is in CI (templates in `assets/`).
7. **[SHOULD]** Query by accessibility role/label (`getByRole("button", { name: /save/i })`), not by test id unless nothing else works; this keeps tests aligned with a11y.
8. **[SHOULD]** E2E: stable selectors by role/label, `data-testid` as last resort; run against a production build (`next build && next start`) in CI; keep to 5-15 critical journeys; use per-test isolated users/data; record trace on failure.
9. **[SHOULD]** Coverage as a guide for untested risk (aim ~80% on `lib/` and services), never as the goal; do not test framework code or trivial getters.
10. **[SHOULD]** Mock at the boundary only (network, clock, email). Do not mock your own modules deeply; prefer real objects and in-memory/test DB.
11. **[SHOULD]** Add `knip` or `ts-prune` to find dead exports, `madge --circular` for cycles, `npm audit` for deps, in CI or a weekly job.

## Setup quick reference
- Unit/integration: `npm i -D vitest @vitejs/plugin-react @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom`; start from `assets/vitest.config.ts` (use `environment: "jsdom"` for component tests, `node` for server code, or per-file `// @vitest-environment`).
- E2E: `npm i -D @playwright/test && npx playwright install --with-deps`; config with `webServer: { command: "npm run build && npm run start", url: "http://localhost:3000" }`.
- Route handler test: `const res = await POST(new Request("http://x/api/y", { method: "POST", body: JSON.stringify(payload) })); expect(res.status).toBe(400);`
- Server action test: call it with a `FormData` and a mocked session helper; assert returned state and DB effects.
- Mock `next/navigation`, `next/headers`, `next/cache` where actions use them (`vi.mock`).

## React component and hook testing
- Render with Testing Library, interact with `userEvent.setup()` (not `fireEvent`), assert on roles/text; use `await screen.findBy...` / `waitFor` for async UI.
- Hooks: `renderHook(() => useThing())` from `@testing-library/react`; wrap state updates in `act()` (Testing Library handles most cases; an "not wrapped in act(...)" warning means an update happened after the test ended: await it).
- Wrap components in the same providers as the app (theme, query client with `retry: false`, session) through a custom `render` helper.
- Components using `useRouter`/`usePathname`/`useSearchParams`: `vi.mock("next/navigation", ...)` with stubbed return values.
- Test effects by outcome (cleanup called on unmount, abort on prop change), not by spying on `useEffect`. Under Strict Mode an effect runs twice in dev: tests should not depend on a single run.
- Test error boundaries by rendering a child that throws and asserting the fallback (silence the expected console error).
- Keep `eslint-plugin-react-hooks` at `error`; it catches most hook bugs before tests do.

## Workflow: PR review
Use `assets/pr-template.md` for authors. Reviewers walk this order:
1. **Intent**: does the description explain why? Is the change one concern? Reasonable size (< ~400 changed lines)?
2. **Correctness and risk**: edge cases, error paths, auth/validation on every new endpoint, transactions, migrations backward compatible.
3. **React**: effects only for external sync with cleanup, stable keys, no mutation, hooks rules, memoization justified (`nextjs-rendering-react/references/react-patterns.md` section 15).
   **Boundaries**: server/client placement, no server code in client bundle, layer rules (`nextjs-architecture`).
4. **Quality**: types strict, no `any`, names clear, no dead code, tests for new behavior and bug fixes.
5. **UX/SEO/perf/a11y** for UI changes: states, keyboard, metadata, bundle/LCP impact.
6. **Operations**: env vars documented, logging safe, rollback plan.
Comment on code, not people; label comments blocking vs. nit; approve when risk is understood, not when it is zero.

## Workflow: debug a failing build or runtime
Ask: does it fail in dev, build, or only production? Then check, in order: Node/Next versions and lockfile; clean `.next` and reinstall; type errors vs lint vs runtime; static/dynamic mismatch (`cookies()` in a static route); hydration mismatch; env var missing at build vs runtime; client/server import boundary. Reproduce minimally, add a regression test.
Common symptoms and fixes: `references/troubleshooting.md`.

## Workflow: version upgrade
Upgrade one major at a time using the official codemod (`npx @next/codemod@latest <transform>` or `npx @next/codemod upgrade latest`), read the release notes, then: update React/types together, run `tsc`, lint, tests, build, and an E2E smoke on a preview deploy. Common breaking areas: async request APIs (`params`, `cookies`, `headers`), fetch/caching defaults, ESLint flat config, `middleware` -> `proxy` rename (Next 16), Tailwind v4 config, Node minimum version. Ship the upgrade alone, not mixed with features.

## Pitfalls
- Snapshot tests of big trees: noisy and rubber-stamped.
- Testing mocks instead of behavior; asserting call counts of internals.
- Flaky E2E from fixed `waitForTimeout`; use web-first assertions (`expect(locator).toBeVisible()`).
- Tests that depend on today's date or random IDs.
- Lint disabled with a blanket `/* eslint-disable */`.
- `next lint` removed in Next 16: run `eslint` directly.

## Verification checklist
- [ ] `tsc --noEmit`, `eslint`, tests, and `next build` pass locally and in CI
- [ ] New behavior and each fixed bug has a test; auth and validation cases covered
- [ ] Tests deterministic, isolated, and fast; E2E covers the critical journeys only
- [ ] PR is small, described, and has a rollback note

## Related skills
`nextjs-typescript-conventions` (rules the linter enforces), `nextjs-security` (probe matrix), `nextjs-devops-operations` (CI pipeline).
