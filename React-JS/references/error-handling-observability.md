# Error handling and observability

Read when adding error boundaries, handling failures, logging, monitoring, or investigating production issues.

Contents: 1. Principles · 2. Where errors come from · 3. Error boundaries · 4. Async and event errors · 5. User-facing messages · 6. Logging · 7. Monitoring (Sentry etc.) · 8. Web Vitals · 9. Feature flags and safe rollout · 10. Incident basics

## 1. Principles
- Fail **visibly for users, loudly for developers**. Users get a clear message and a way forward; developers get stack, context and a request ID.
- Contain failures: one broken widget should not blank the whole page.
- Never swallow errors (`catch {}`) and never show raw error text or stack traces to users.
- Errors are data: normalize them into one shape (`ApiError { status, code, message, requestId, fieldErrors }`, see `state-data-forms.md`).

## 2. Where errors come from
| Source | Caught by |
|---|---|
| Exceptions while rendering, in lifecycle/effects of children | **Error boundary** |
| Event handlers, timers, promises, async code | `try/catch` or the data library (boundaries do **not** catch these) |
| Failed network/data | Query/mutation `error` state, `throwOnError` + boundary, route `errorElement` |
| Lazy chunk failed to load (deploy happened, offline) | Boundary around `Suspense` with a "reload" action |
| Uncaught anywhere | `window.onerror`, `unhandledrejection` (reported by the monitoring SDK), React 19 `onUncaughtError` / `onCaughtError` / `onRecoverableError` root options |

## 3. Error boundaries
- Place them at three levels: **app root** (last resort, full-page message), **route/page** (keeps navigation/layout alive), **widget** (independent sections such as a chart or recommendations list).
- Boundaries must be class components (or use `react-error-boundary`, the common library; use the project's choice). A function-only API does not exist for catching render errors.
- Provide **reset**: a "Try again" button that clears the error state and re-renders (and resets the query when relevant: `QueryErrorResetBoundary`).
- Use `resetKeys` (navigation/ids) so changing route clears the error automatically.
- Report from `componentDidCatch` / `onError` to monitoring with `componentStack`.
- Pair with `<Suspense>`: `ErrorBoundary > Suspense > Component`.
- Framework equivalents: Next `error.tsx` (client component) and `global-error.tsx`; React Router `errorElement` / `ErrorBoundary` export.
- Template: `assets/templates/error-boundary.tsx`.

## 4. Async and event errors
- In event handlers use `try/catch` around `await` and set state; or use mutation `onError`.
- `Promise.allSettled` when partial failure is acceptable.
- To send an async error to the nearest boundary: `setState(() => { throw err })` inside the catch, or use the query library's `throwOnError`.
- Always handle promise rejections; unhandled rejections are bugs.
- Make mutations safe: disable the submit while pending; use idempotency keys for non-idempotent writes.

## 5. User-facing messages
- Say what happened, what the user can do, and keep it blame-free: "We couldn't save your changes. Check your connection and try again." Not "Error 500" or "Something went wrong" alone.
- Distinguish: offline, timeout, validation (show per field), unauthorized (go to sign-in), forbidden, not found, server error.
- Keep user input after a failure. Offer retry. Provide a support reference (request ID) for server errors.
- Announce errors accessibly: `role="alert"` or a polite live region; move focus to the error summary on form submit failure.
- Detect offline (`navigator.onLine` + failed requests) and show a banner instead of a stack of errors.

## 6. Logging
- No `console.log` left in production paths. Use a small `logger` wrapper (levels: debug, info, warn, error) that is silent or sampled in production and forwards `error` to monitoring.
- Redact tokens, passwords, emails, payment data, and free-text input from logs and breadcrumbs.
- Include correlation: request ID from the API, release version, route, user ID (opaque ID, not email), feature flags in effect.
- Log events, not noise: avoid logging inside render and tight loops.

## 7. Monitoring (Sentry or the project's tool)
- Initialize once, as early as possible, with `release` (git SHA), `environment`, sampling rates and `beforeSend` to scrub PII.
- Upload **source maps** to the monitoring service in CI and do not serve them publicly unless the project decides to. Match the `release` to the build.
- Tag errors with route, feature and user segment. Add breadcrumbs for navigation, network calls (no bodies) and key user actions.
- Ignore known noise (browser extensions, `ResizeObserver loop`, aborted requests) with `ignoreErrors` rather than muting everything.
- Set alerts on **new issues**, **regressions** and **error-rate spikes**, routed to a place somebody reads. Errors nobody sees are not monitored.
- Session replay (if used): mask all inputs and sensitive text by default and get consent where required.

## 8. Web Vitals
- Report LCP, INP, CLS (and TTFB/FCP) with the `web-vitals` library to analytics or monitoring, tagged by route and release.
- Compare release over release; investigate regressions with the Performance panel and React Profiler (see `performance.md`).

## 9. Feature flags and safe rollout
- Wrap flags in one hook (`useFlag('newCheckout')`) backed by the project's provider (LaunchDarkly, Unleash, GrowthBook, PostHog, env/config). No scattered `if (process.env...)`.
- Default to the **safe/off** value when the flag service fails.
- Ship risky changes dark, enable for a small percentage, watch errors and vitals, keep a kill switch. Remove flags and dead code after rollout.
- Flag state must be consistent between server and client render (avoid hydration mismatches): evaluate once on the server and pass down.

## 10. Incident basics
- Reproduce with the release's source map and the request ID before changing code.
- Prefer rollback to hotfix when the cause is unclear (see `release-readiness.md`).
- After a fix: add a regression test, add a monitor/alert if none caught it, and note the cause in the PR.
