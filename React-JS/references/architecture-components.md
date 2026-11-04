# Architecture, components, and maintainability

Contents: Respect the existing architecture · Component standards · Type safety and maintainability · Modern component structure (React 19+) · Feature-first layout · Server/client boundaries · React 19 APIs · React Compiler. Folder trees, naming and boundary enforcement live in `project-structure.md`.

Read when writing or restructuring components, hooks, folders, or types.

## Respect the existing architecture
The project's structure is a decision someone already made. Matching it keeps the codebase predictable; imposing a "better" layout creates two conventions.

- Follow the existing folder structure. Do not force a new one.
- Prefer feature-based organization (a feature's components, hooks, tests and types together) when the project has no strong convention or you are adding a new area.
- Separate presentation, business logic, data access and shared utilities where it genuinely helps: components render, hooks hold behavior, services talk to APIs, utilities are pure.
- Keep dependencies flowing one way (UI → hooks → services → utils). Avoid circular imports; they cause confusing load-order bugs.
- Reuse existing components, hooks, utilities and the design system before building new ones.
- Do not add layers, wrappers or abstractions "for the future". Three similar lines are better than a premature abstraction. Remove duplicate implementations you find in your path only if it is in scope.

## Component standards
- Use function components and currently supported React APIs. Do not introduce class components or deprecated lifecycle patterns.
- Follow the Rules of Hooks: only call hooks at the top level of components or custom hooks, never conditionally or in loops.
- Keep components focused and props explicit. If a component needs ten props or does three jobs, split it.
- Keep state as close as possible to the components that use it. Lifting state higher than necessary causes wide re-renders and tangled data flow.
- Use stable keys for lists (an ID from the data). Index keys break state when items reorder, insert or delete.
- Derive values instead of storing them in state. If `fullName` can be computed from `first` and `last`, computing it during render removes a whole class of out-of-sync bugs.
- Use effects only to synchronize with something outside React (network, subscriptions, DOM APIs, timers). Calculations, event responses and resetting state on prop change usually do not need an effect.
- Clean up subscriptions, listeners, timers and external resources in the effect's return function.
- Avoid render loops (setting state during render or in an effect with a changing dependency), stale closures (state captured by an old callback; use functional updates or correct dependencies), and unnecessary memoization (see `performance.md`).

## Type safety and maintainability
- Follow existing naming, formatting and import conventions. Run the project's formatter and linter rather than formatting by hand.
- Use TypeScript where the project does. Do not add it to a JavaScript project as a side effect of an unrelated task.
- Avoid `any`, unsafe casts (`as unknown as X`) and non-null assertions (`!`) unless you can justify them in a comment. They switch off the compiler exactly where it would have caught a bug.
- Keep functions short and readable, with one job each.
- Replace magic values with named constants. Do not swallow errors with empty `catch` blocks; handle or surface them. Delete dead code you create or find in scope.
- Comment on intent and non-obvious constraints ("API returns null for deleted users"), not on what the code plainly does.
- Minimize dependencies. Before adding a package, check whether the platform or an existing dependency already covers it, and say why the new one is worth its size and maintenance cost. See `security-privacy.md` for supply-chain checks.
- Document meaningful configuration and environment requirements (new env vars, required services) in the README or the project's usual place.

---

# Modern component structure (React 19+)

These patterns apply when the project is on React 19 or newer. On older versions, match what the project uses. Existing conventions always win over this section.

## Feature-first layout with a public surface
A feature owns everything it needs, and other features import only what it exports. This keeps changes local and makes dependencies visible.

```
features/checkout/
  index.ts            # the public API: only what other features may import
  components/         # presentational pieces (render props in, JSX out)
  hooks/              # useCheckout, useCouponForm (behavior and data access)
  api/                # service functions + query keys for this feature
  schemas.ts          # runtime schemas and inferred types
  CheckoutPage.tsx    # composition root for the feature
  checkout.test.tsx
```

- Shared, feature-agnostic code goes in `shared/` (ui primitives, utils, http client). Features may import `shared/`; `shared/` never imports a feature.
- Import a feature only through its `index.ts`. Deep imports into another feature's internals break encapsulation.
- Be careful with large barrel files: re-exporting everything can pull unused code into bundles and slow tooling. Keep barrels small and specific.

## Split by responsibility
- Components render; hooks hold behavior and data access; services talk to the network; schemas describe data. A component that fetches, validates, formats and renders is four jobs.
- Prefer composition over configuration. Many boolean props (`isLarge`, `isPrimary`, `withIcon`) signal that children, slots or a compound component (`<Tabs><Tabs.List/>…`) fit better.
- Model variants with discriminated unions, not loose optional props, so impossible combinations do not type-check.
- Put an error boundary and a Suspense boundary around each independently loading section, so one failing widget does not blank the page.

## Server and client boundaries (Server Components frameworks)
Applies when the project uses React Server Components (Next.js App Router, React Router framework mode, and similar).

- Components are server components by default. Add `'use client'` only where you need state, effects, event handlers or browser APIs, and push that boundary down to the smallest leaf rather than marking whole pages.
- Props crossing from server to client components must be serializable (no functions, class instances). Pass plain data.
- Mark server-only modules (database clients, secrets, internal SDKs) with the `server-only` package so an accidental client import fails at build time instead of shipping to the browser.
- Send the client only the fields it needs (a view model), never a whole database row or user object. See `security-privacy.md`.

## React 19 APIs to prefer in new code
- `ref` is a regular prop on function components. New code does not need `forwardRef`.
- `use(promise)` and `use(context)` read async values and context, and can be called conditionally. A promise passed to `use` must be stable (created in a server component, a cache, or a data library), never created fresh during render, or it re-suspends forever.
- Render context directly as a provider (`<ThemeContext value={...}>`) instead of `<ThemeContext.Provider>`.
- Forms: `<form action={fn}>`, `useActionState`, `useFormStatus` and `useOptimistic`. See `state-data-forms.md`.
- React 19.2: `<Activity mode="hidden">` keeps a hidden screen's state alive without keeping its effects running (tabs, wizards, back navigation). `useEffectEvent` extracts non-reactive logic from an effect (read the latest `theme` inside a connection effect without reconnecting). Do not use `useEffectEvent` merely to silence the exhaustive-deps lint, and do not put an effect event in a dependency array.

## React Compiler
React Compiler v1.0 is stable and auto-memoizes components and hooks at build time.

- Check whether the project enables it (`babel-plugin-react-compiler`, framework config) before hand-writing memoization. For new code, rely on it and add `useMemo`/`useCallback` only where precise control is needed, typically a value that is an effect dependency.
- Leave existing `useMemo`/`useCallback` in place. Removing them can change compiler output and effect timing; remove only with test coverage.
- Keep components pure and follow the Rules of React, since the compiler depends on them. Enable the compiler lint rules in `eslint-plugin-react-hooks` (`recommended` preset) and fix what they flag.
- Pin the compiler to an exact version, and upgrade it deliberately with tests, since memoization changes can alter effect firing.

See also: `project-structure.md` (folder trees for Vite, Next.js and monorepos, naming table, boundary enforcement, AGENTS.md) and `assets/templates/error-boundary.tsx`.
