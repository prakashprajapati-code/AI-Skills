# Testing and regression prevention

Read for any bug fix, new feature, or request that mentions tests.

Contents: 1. Principles · 2. Test types and tools · 3. Setup · 4. Component tests · 5. Hooks and pure logic · 6. Network mocking with MSW · 7. Async, timers, races · 8. Accessibility tests · 9. Router, query, i18n providers · 10. E2E with Playwright · 11. Server Components and Server Functions · 12. Coverage, flakiness, CI · 13. Bug-fix workflow

Tests are what let the next person change this code safely. Test behavior users depend on, not implementation details that change with every refactor.

## 1. Principles
- Use the repository's established tools (Jest or Vitest, React Testing Library, Playwright or Cypress, MSW). Do not introduce a second framework. Follow how nearby tests are named, located and structured.
- Test pyramid: many fast **unit** tests, a solid layer of **component/integration** tests, few **E2E** tests for critical journeys.
- Test through the public surface: what the user sees and does. Avoid asserting on internal state, class names, hook internals, or snapshots of large trees.
- A test must be able to fail. Watch it fail for the right reason before trusting it.
- Deterministic and isolated: no real network, real time, real randomness, or shared state between tests.

## 2. Test types and tools
| Type | Tool (typical) | What it covers |
|---|---|---|
| Unit | Vitest / Jest | Pure functions, reducers, validators, formatters |
| Component | Testing Library + user-event | Rendering, interaction, states |
| Integration | Testing Library + MSW | Form → API → UI result, with real providers |
| E2E | Playwright (or Cypress) | Real browser, critical journeys, cross-page flows |
| Visual | Storybook + Chromatic/Playwright screenshots | Layout regressions |
| Accessibility | `jest-axe`/`vitest-axe`, `@axe-core/playwright`, `eslint-plugin-jsx-a11y` | Automatable WCAG issues |
| Types | `tsc --noEmit` | Contracts between modules |

## 3. Setup (Vitest + RTL)
```ts
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { cleanup } from '@testing-library/react';
import { server } from './msw/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));  // unmocked calls fail the test
afterEach(() => { cleanup(); server.resetHandlers(); });
afterAll(() => server.close());
```
Shared helper: `assets/templates/render-with-providers.tsx` (QueryClient with `retry: false`, router, i18n, theme). Use it everywhere instead of re-wiring providers per test.

## 4. Component tests
```tsx
import { render, screen } from '@/test/render-with-providers';
import userEvent from '@testing-library/user-event';

it('submits the form and shows success', async () => {
  const user = userEvent.setup();
  render(<SignupForm />);

  await user.type(screen.getByLabelText(/email/i), 'ada@example.com');
  await user.click(screen.getByRole('button', { name: /create account/i }));

  expect(await screen.findByRole('status')).toHaveTextContent(/check your inbox/i);
});
```
- **Query priority:** `getByRole` (with `name`) → `getByLabelText` → `getByPlaceholderText` → `getByText` → `getByDisplayValue` → `getByAltText` → `getByTitle` → `getByTestId` (last resort). If a role query is hard, the component's accessibility is probably wrong: fix the component.
- `findBy*` for things that appear asynchronously; `queryBy*` to assert **absence**; `getBy*` for presence. Use `waitFor` only for assertions, never put side effects in it.
- Use `userEvent.setup()` (real event sequences), not `fireEvent`, for user actions.
- Avoid `act()` warnings by awaiting user events and `findBy`; do not wrap everything in `act` manually.
- Test **states**: loading (skeleton), empty, success, error, validation failure, disabled/pending.
- Test keyboard: Tab order, Enter/Space on buttons, Escape closes dialogs, focus returns to the trigger.

## 5. Hooks and pure logic
```tsx
import { renderHook, act } from '@testing-library/react';
it('toggles', () => {
  const { result } = renderHook(() => useToggle(false));
  act(() => result.current.toggle());
  expect(result.current.value).toBe(true);
});
```
- Prefer testing a hook through a component that uses it unless the hook is a reusable public utility.
- Pure functions: table-driven tests (`it.each`) with edge cases: empty, null/undefined, boundaries, unicode, large input, timezone/locale where relevant.

## 6. Network mocking with MSW
```ts
// src/test/msw/handlers.ts
import { http, HttpResponse } from 'msw';
export const handlers = [
  http.get('/api/orders', () => HttpResponse.json([{ id: '1', total: 4200 }])),
];

// in a test: override for one scenario
server.use(http.get('/api/orders', () => HttpResponse.json({ message: 'boom' }, { status: 500 })));
```
- Mock at the **network** layer (MSW), not by mocking `fetch`/axios/the service module, so the real client, parsing, and error handling are exercised.
- Cover per endpoint: success, empty, 4xx (validation field errors, 401/403/404), 5xx, network error (`HttpResponse.error()`), slow response (`delay`), and malformed body (schema validation).
- Keep handlers in one place and reuse them for Storybook and E2E where possible. Assert on request payloads when the contract matters (capture inside the handler).

## 7. Async, timers, races
- Fake timers (`vi.useFakeTimers()` / `jest.useFakeTimers()`) for debounce, polling and countdowns; always restore real timers. With `user-event`, pass `advanceTimers: vi.advanceTimersByTime`.
- Race conditions to test: type fast in a search (stale response must not win), double-click submit (only one request), unmount during request (no state update/warning), retry after failure, navigating away mid-flight.
- Freeze time and locale for date output tests (`vi.setSystemTime`), and set the time zone in the test environment config (`TZ=UTC`).
- Never use arbitrary `sleep`/`setTimeout` waits to "fix" flakiness.

## 8. Accessibility tests
```tsx
import { axe } from 'vitest-axe';           // or jest-axe
it('has no obvious a11y violations', async () => {
  const { container } = render(<SignupForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```
- Automated tools find roughly a third of issues. They do **not** replace keyboard and screen-reader checks. Test focus management and announcements explicitly (`toHaveFocus`, `role="alert"` content).
- Run axe in Playwright on key pages and in each Storybook story if configured.

## 9. Router, query, i18n providers
- Router: `MemoryRouter` / `createMemoryRouter` with `initialEntries`; assert redirects and rendered route content (see `routing-navigation.md`).
- TanStack Query: create a **fresh QueryClient per test** with `retry: false`, `gcTime: Infinity` (or 0) to avoid cross-test leakage.
- i18n: initialize with the default locale resources in tests; assert visible strings, add a test for plural and RTL when relevant.
- Mock only what is **outside** your control: browser APIs missing in jsdom (`matchMedia`, `IntersectionObserver`, `ResizeObserver`, `scrollTo`), time, randomness. Do it in `setup.ts`.

## 10. E2E with Playwright
- Cover the few journeys whose failure would hurt most: sign-in, core create/edit flow, checkout. Keep the suite small and stable.
- Use **role/label locators** (`page.getByRole('button', { name: 'Save' })`), web-first assertions (`await expect(locator).toBeVisible()`) that auto-retry, and no fixed waits.
- Isolate tests: each creates its own data (API seeding or `storageState` login fixtures), no order dependence; run in parallel.
- Stub third parties (payments, maps, analytics) with `page.route`. Test against a **production build** (`vite preview`/`next start`) in CI.
- Capture trace/screenshot/video on first retry (`trace: 'on-first-retry'`); upload the report as a CI artifact. Test at least Chromium plus one mobile viewport; add Firefox/WebKit if the audience requires it.
- Check a11y with `@axe-core/playwright`, and visual snapshots only for stable components.

## 11. Server Components and Server Functions
- Async Server Components cannot be rendered by most unit-test setups. Test the **logic** (data functions, view-model mappers, Server Function bodies as plain async functions with mocked auth/db), and cover the rendered page in E2E.
- For Server Functions: test authentication failure, authorization failure, invalid input (schema rejection), success, and that the returned data contains only the intended fields. See `security-privacy.md`.
- Client Components inside an RSC app are tested normally.

## 12. Coverage, flakiness, CI
- Coverage is a **signal, not a goal**. Aim for high coverage on business logic and error paths; do not chase 100% by testing trivial code or implementation details. A reasonable gate is "no drop on changed files".
- A flaky test is a bug: find the real race (missing `await`, shared state, time, network), fix it, do not just add retries or skip. Quarantine with a tracked ticket if it blocks.
- Keep the unit/component suite under a couple of minutes locally; split slow tests.
- Snapshot tests only for small, stable, serializable outputs (an error message, a config). Review snapshot diffs in PRs; never blind-update (`-u`).
- Don't test third-party library behavior or the framework.

## 13. Bug-fix workflow
1. Reproduce the bug (manually or with a failing test).
2. Write a regression test at the lowest level that can show it; watch it fail for the right reason.
3. Fix the code minimally.
4. Watch the test pass; run the suite for the area touched, then lint, types, build.
5. Report the real output. If tests cannot run in this environment, say so and list the exact commands to run.
