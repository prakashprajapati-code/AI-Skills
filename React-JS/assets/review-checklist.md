# React production review checklist (158 points)

How to use: this is the full checklist for full reviews, "use all", or large changes. Skip it for small fixes.
Mark every point as one of: [x] done, [n/a] not applicable (write a one-line reason), [ ] open (explain in the report).
Do not tick a box you did not actually verify. Some points are about the project, not your change; if you did not touch that area, mark n/a.

1. Project discovery and instructions
[ ] Read AGENTS.md, README, .github instructions, and existing AI skills.
[ ] Inspect package.json, lockfile, scripts, framework, dependencies, and React version.
[ ] Check Git branch, working tree, and existing user changes.
[ ] Map routes, components, hooks, state, API clients, services, tests, and configuration.
[ ] Trace the actual code flow before editing.
[ ] Search for existing implementations before creating new ones.

2. Architecture and project structure
[ ] Respect the existing architecture; do not force a folder structure.
[ ] Prefer feature-based organization when appropriate.
[ ] Separate presentation, business logic, data access, and shared utilities where useful.
[ ] Keep dependencies flowing in clear directions; avoid circular dependencies.
[ ] Reuse existing components, hooks, utilities, and design systems.
[ ] Avoid unnecessary layers, abstractions, and duplicate implementations.

3. React component standards
[ ] Use function components and supported React APIs.
[ ] Follow the Rules of Hooks.
[ ] Keep components focused and props explicit.
[ ] Keep state close to its consumers.
[ ] Use stable keys for rendered lists.
[ ] Derive values instead of duplicating them in state.
[ ] Use effects for external synchronization, not routine derived calculations.
[ ] Clean up subscriptions, listeners, and external resources.
[ ] Avoid render loops, stale closures, and unnecessary memoization.

4. State management
[ ] Use local state for local UI concerns.
[ ] Use Context for suitable cross-tree dependencies.
[ ] Use an existing state library when shared client state warrants it.
[ ] Separate server state from client/UI state.
[ ] Avoid duplicated sources of truth.
[ ] Handle loading, success, empty, error, and stale-data states.
[ ] Manage cache invalidation, optimistic updates, and rollback correctly when applicable.

5. API and asynchronous operations
[ ] Reuse the existing API client and service conventions.
[ ] Centralize common request configuration and error handling.
[ ] Respect backend contracts and authorization rules.
[ ] Handle HTTP errors, network failures, timeouts, and retries appropriately.
[ ] Prevent stale requests from overwriting newer results.
[ ] Use cancellation and cleanup where appropriate.
[ ] Validate untrusted data at suitable boundaries.
[ ] Never expose private credentials in browser bundles.

6. Forms and user interactions
[ ] Use semantic HTML and appropriate input types.
[ ] Keep client validation consistent with backend rules.
[ ] Use established form/schema libraries when complexity justifies them.
[ ] Prevent duplicate submissions.
[ ] Preserve input after recoverable errors.
[ ] Provide clear field-level errors and submission feedback.
[ ] Handle pending, disabled, success, and failure states.
[ ] Support keyboard interaction and accessible focus management.

7. Security and privacy
[ ] Treat user input, URLs, and API responses as untrusted.
[ ] Prevent XSS and avoid unsafe HTML rendering.
[ ] Sanitize user-controlled HTML if rendering it is required.
[ ] Validate untrusted navigation URLs and schemes.
[ ] Never rely on client-side checks for authorization.
[ ] Follow secure authentication and session patterns.
[ ] Avoid leaking tokens or sensitive data in logs, URLs, and analytics.
[ ] Check dependencies, CSP requirements, and supply-chain risks.

8. Accessibility and responsive design
[ ] Use semantic elements and accessible names.
[ ] Support keyboard navigation and visible focus.
[ ] Maintain readable contrast and logical focus order.
[ ] Provide meaningful alternative text for informative images.
[ ] Support mobile layouts, zoom, and text scaling.
[ ] Respect reduced-motion preferences.
[ ] Make dialogs, menus, and validation feedback accessible.
[ ] Do not communicate important status through color alone.

9. Performance and rendering
[ ] Measure before optimizing.
[ ] Use profiling and browser performance tools to find bottlenecks.
[ ] Avoid unnecessary renders, expensive calculations, and repeated requests.
[ ] Use memoization only when justified.
[ ] Split code and lazy-load suitable routes or features.
[ ] Optimize images, fonts, assets, and bundle size.
[ ] Use virtualization for genuinely large lists.
[ ] Respect framework-specific rendering, hydration, and caching behavior.

10. Testing and regression prevention
[ ] Use the repository's established testing tools.
[ ] Unit-test pure logic and business rules.
[ ] Test component behavior and user interactions.
[ ] Add integration tests for important connected flows.
[ ] Cover loading, empty, success, error, and validation states.
[ ] Add regression tests for bug fixes.
[ ] Test critical user journeys end to end where appropriate.
[ ] Test accessibility and asynchronous edge cases when relevant.

11. Type safety and maintainability
[ ] Follow existing naming, formatting, and import conventions.
[ ] Use TypeScript where supported by the project.
[ ] Avoid any, unsafe casts, and unjustified non-null assertions.
[ ] Keep functions readable and focused.
[ ] Avoid magic values, swallowed errors, and dead code.
[ ] Comment on intent and non-obvious constraints.
[ ] Minimize dependencies and justify new packages.
[ ] Document meaningful configuration and environment requirements.

12. Git and change management
[ ] Inspect Git status before editing.
[ ] Preserve unrelated user changes.
[ ] Make the smallest coherent change that solves the task.
[ ] Avoid unrelated formatting and refactoring.
[ ] Preserve public component props, exports, and API contracts unless change is required.
[ ] Do not reset, clean, commit, push, or deploy without authorization.
[ ] Review the complete diff before finishing.

13. Production readiness and deployment
[ ] Use reproducible lockfiles and documented build commands.
[ ] Verify environment variables and build-time configuration.
[ ] Check routing, asset paths, and deployment base paths.
[ ] Follow production logging and source-map security policies.
[ ] Check browser compatibility and dependency vulnerabilities.
[ ] Use appropriate error and performance monitoring.
[ ] Consider caching, CDN behavior, and rollback requirements.
[ ] Verify the production build and critical user journeys.

14. AI workflow and delivery discipline
[ ] Understand requirements before implementation.
[ ] Ask focused questions when missing information affects the solution.
[ ] Create a proportionate plan for non-trivial changes.
[ ] Identify affected files, contracts, dependencies, and risks.
[ ] Reuse existing patterns before adding new ones.
[ ] Implement in small, reviewable steps.
[ ] Run applicable tests, lint, type checks, and builds.
[ ] Report actual results, failures, assumptions, and remaining risks honestly.

15. Routing and navigation
[ ] Use the project's router; one central route table.
[ ] Lazy-load route components with Suspense and a route-level error UI.
[ ] Provide a 404 route; hard refresh on nested routes works.
[ ] Use real links (<a href>/Link) for navigation, not click-handler buttons.
[ ] Guard routes in the router and enforce access on the server; validate returnTo (same-origin only).
[ ] Keep shareable state (filters, page, tab, search) in the URL and validate parsed params.
[ ] Update the page title and manage focus/scroll on route change.

16. Next.js specifics (when next is installed)
[ ] Match patterns to the installed Next.js major version (async params in 15+, proxy.ts and Cache Components in 16).
[ ] Choose a rendering strategy per route; keep dynamic APIs low in the tree inside Suspense.
[ ] Cache deliberately; never cache user-specific data in a shared cache; invalidate after mutations.
[ ] Keep 'use client' at the leaves; pass only serializable props; guard server-only modules.
[ ] Treat Server Functions and route handlers as public endpoints (authenticate, authorize, validate).
[ ] Provide metadata, sitemap, robots, error.tsx, not-found.tsx and loading states.
[ ] Use next/image, next/font and next/script correctly; only NEXT_PUBLIC_ vars reach the browser.

17. Styling, theming and design system
[ ] Follow the existing styling approach; do not mix systems in a component.
[ ] Use design tokens, not hard-coded colors, spacing and z-indexes.
[ ] Support dark mode without a flash of wrong theme; check contrast in both themes.
[ ] Keep focus styles, reduced-motion support and 200% zoom working.
[ ] Reuse shared primitives; prefer accessible headless building blocks for complex widgets.
[ ] Reserve space for async content and images to avoid layout shift.

18. Internationalization, SEO and analytics
[ ] No hard-coded user-facing strings where i18n exists; no sentence concatenation; ICU plurals.
[ ] Format dates, numbers and currency with Intl; store UTC.
[ ] Set html lang and dir; use logical CSS properties for RTL.
[ ] Render indexable pages on the server or at build time; unique title, description, canonical, one h1.
[ ] Provide Open Graph/Twitter tags in the initial HTML, sitemap and robots; noindex non-public pages.
[ ] Send no PII to analytics; respect consent; wrap analytics in one module that cannot break the app.

19. Error handling and observability
[ ] Error boundaries at app, route and widget level, each with a reset action.
[ ] Handle async and event-handler errors explicitly (boundaries do not catch them).
[ ] Show clear, blame-free, actionable messages; keep user input after failures; announce errors accessibly.
[ ] Remove debug console output; use a redacting logger.
[ ] Monitoring initialized with release, environment, source maps and PII scrubbing; alerts reach a person.
[ ] Report Web Vitals; use feature flags with safe defaults and a kill switch for risky rollouts.

20. Migration and upgrades
[ ] Get a green baseline before upgrading.
[ ] Read the official upgrade guide; upgrade one major at a time.
[ ] Run official codemods rather than hand-editing.
[ ] Check third-party peer dependencies for compatibility with the target version.
[ ] Keep upgrades separate from refactors and new features.
[ ] Verify a production build and critical journeys after the upgrade.

21. Tooling, quality gates and CI
[ ] Typecheck, lint, tests and build pass locally and in CI.
[ ] TypeScript strict mode (or a documented plan); ESLint with react-hooks and jsx-a11y rules.
[ ] One formatter, one package manager, one React version in the dependency tree.
[ ] CI installs from the lockfile, caches dependencies, pins actions, uses least-privilege permissions.
[ ] Bundle size analyzed on a production build with a budget or regression check.
[ ] Git hooks are fast; no bypassing with --no-verify.
[ ] README, .env.example and AGENTS.md document setup, scripts and conventions.

22. Advanced features (when present)
[ ] Real-time: single connection, cleanup, backoff reconnect, validated messages, status indicator.
[ ] Uploads: client and server validation, progress, cancel, accessible input, safe serving of user files.
[ ] Search/autocomplete: debounce, cancellation, accessible combobox, URL state where shareable.
[ ] Large data: server-side pagination or virtualization, semantic tables, accessible fallbacks.
[ ] Payments: hosted fields, server-side confirmation, idempotency keys, no card data in app state.
[ ] Offline/PWA: only when required, versioned service worker with an update path.
