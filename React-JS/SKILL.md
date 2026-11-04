---
name: react-production
description: Production-grade engineering standards for React.js web work — building, fixing, reviewing, refactoring, upgrading or shipping React code (Vite, CRA, Next.js, React Router/Remix, any React app). Automatically picks the relevant areas (architecture and folder structure, state/API/forms, security, accessibility, performance, testing, release, routing, Next.js, styling/theming, i18n/SEO, error handling/monitoring, migration/upgrades, tooling/CI, advanced features like real-time/uploads/tables) and lets the user choose or limit them ("only security and testing", "skip performance", "use all"). Make sure to use this skill whenever the user works on a React project — components, hooks, state, routing, API calls, forms, styling, bugs, code review, upgrades, "make it production ready", bundle size, tests, deployment — even if they never mention a skill or standards. Not for React Native, or non-React frameworks.
---

# React production standards

React bugs that reach production usually come from a few repeating causes: changing code before understanding it, duplicating state, ignoring async edge cases, skipping accessibility and security, upgrading without a baseline, and claiming "done" without running anything. This skill is a workflow plus focused reference files that guard against those causes, while respecting the project's existing conventions.

The right amount of process scales with the task. A one-line fix needs discovery and a verified result, not a full audit.

Scope: React for the **web** (React 17 to 19.2, Vite/CRA/Next.js/React Router). React Native/Expo is out of scope; say so if you detect it.

## Step 0 — Choose the areas (automatic, user can override)

Pick areas from the task using the routing table, and tell the user in one line which ones you chose, e.g. "Applying: state-data, accessibility, testing." Then read only those reference files (plus the cross-references they point to when needed).

The user can steer this at any time, in plain words. Their choice always wins over your guess:

| User says | You do |
|---|---|
| "auto" or nothing | Choose from the routing table |
| "only security and testing" | Use exactly those areas |
| "skip performance" | Auto-select, minus performance |
| "use all" / "full review" | Read every reference that applies to the project's stack (skip `nextjs` if there is no Next.js, skip `migration` if no upgrade is involved) and use the checklist asset |
| "add accessibility" | Keep current areas, add that one |

Area names: `architecture`, `state-data`, `security`, `accessibility`, `performance`, `testing`, `release`, `routing`, `nextjs`, `styling`, `i18n-seo`, `errors`, `migration`, `tooling`, `features`.

If the user's limit conflicts with the task (for example "skip testing" on a bug fix), follow the instruction and mention in the final report that no regression test was added.

The workflow and change-discipline sections below always apply. They protect the user's repo and are cheap.

## Routing table

| Task looks like | Area | Read |
|---|---|---|
| New component, hook, refactor, TypeScript cleanup, "where should this file go", naming, new project layout, AGENTS.md | architecture | `references/architecture-components.md`, `references/project-structure.md` |
| Fetching data, caching, loading/error states, global state, forms | state-data | `references/state-data-forms.md` |
| Auth, rendering user HTML, URLs/redirects, tokens, uploads, new dependency | security | `references/security-privacy.md` |
| UI, forms, dialogs, menus, responsive layout, animation | accessibility | `references/accessibility-responsive.md` |
| Slow screen, re-renders, big lists, bundle size, images, Web Vitals | performance | `references/performance.md` |
| Any bug fix, new feature, or when tests are mentioned | testing | `references/testing.md` |
| Deploy, build config, env vars, "production ready", rollback | release | `references/release-readiness.md` |
| Routes, navigation, guards, loaders, deep links, search params | routing | `references/routing-navigation.md` |
| `next` in package.json: App Router, caching, Server Actions, metadata, proxy/middleware | nextjs | `references/nextjs-app-router.md` |
| CSS, Tailwind, CSS-in-JS, dark mode, tokens, animation, design system, Storybook | styling | `references/styling-theming.md` |
| Translations, locales, RTL, dates/currency, meta tags, sitemap, analytics, consent | i18n-seo | `references/i18n-seo-analytics.md` |
| Error boundaries, failure UX, logging, Sentry, Web Vitals, feature flags, incidents | errors | `references/error-handling-observability.md` |
| Upgrade React/Next/Router/Tailwind, CRA to Vite, class to hooks, dependency bumps | migration | `references/migration-upgrades.md` |
| ESLint, Prettier, tsconfig, Vite config, hooks, CI, bundle analysis, monorepo | tooling | `references/tooling-ci.md` |
| WebSocket/SSE, file upload, autocomplete, tables, charts, rich text, payments, PWA, workers, auth screens | features | `references/advanced-features.md` |

Most real tasks hit two or three rows. A signup form, for example, is state-data + accessibility + security + testing.

Combinations that always route together:
- **New feature or component** → architecture + state-data + security + testing.
- **New page or route** → routing + architecture + accessibility (title, focus, 404) + errors (boundary).
- **Any code that runs on a server** (Server Components, Server Functions, route handlers, loaders) → architecture (client/server boundary) + security (treat each as a public endpoint, check advisories) + nextjs when applicable.
- **A data call or mutation** → state-data + errors + testing.
- **Any upgrade** → migration + tooling + testing (baseline first) + security (advisories).
- **"Make it production ready"** → release + security + performance + errors + tooling + testing + accessibility.
- **Public marketing/content page** → i18n-seo + performance + accessibility (+ nextjs/rendering strategy).

The modern-pattern sections (React 19 / 19.2, React Compiler v1.0, Next.js 16, Server Function security, advisories list) were checked in 2026-10 / 2026-11. Advisories and versions move quickly, so check the project's installed versions and the current vendor security pages instead of assuming the lists are complete.

## Workflow

### 1. Discover before editing
Wrong assumptions about the project cost more than the time to check.

- Run `scripts/discover.sh <project-dir>`. It prints the React version, framework, router, package manager, scripts, test/state/styling/i18n tooling, version-specific hints, instruction files and Git state, and changes nothing.
- Read instruction files it lists: `AGENTS.md`, `CLAUDE.md`, `README`, `.github` instructions, existing AI skills. They override the defaults in this skill.
- Map the relevant routes, components, hooks, state, API clients, services, tests and config. Trace the real code flow of the feature or bug before touching it.
- Search for an existing implementation (component, hook, util, API helper) before writing a new one. Duplicates are the most common source of drift.
- For review or "production ready" tasks, also run `scripts/audit-quick.sh <project-dir>`: a read-only heuristic scan for red flags (XSS sinks, tokens in storage, secrets in public env vars, index keys, `any`, missing alt, clickable divs, missing tests). Verify each hit by reading the code; it has false positives and is not proof of safety.

### 2. Understand and plan
- Confirm what is being asked. If missing information would change the solution, ask one focused question. Otherwise choose the sensible default and state it.
- For anything non-trivial, write a short plan: affected files, public contracts (props, exports, API shapes), dependencies and risks. Keep it proportionate; a small fix gets two lines.
- For upgrades, get a green baseline (install, lint, types, tests, build) before changing versions.

### 3. Implement in small steps
- Reuse existing patterns before introducing new ones. A new library or abstraction needs a reason you can state.
- Keep each step reviewable. Prefer the smallest coherent change that solves the task.
- Apply the guidance in the chosen reference files as you go, not as an afterthought.
- Starting from scratch? Use `assets/templates/` (error boundary, HTTP client, validated env, test render helper, AGENTS.md template) as starting points and adapt them to the project's stack. If the project already has an equivalent, use that instead.

### 4. Verify with real commands
Run what the project actually has: tests, lint, type check, build (`discover.sh` lists the scripts). For UI changes, check the behavior, not just that it compiles. If a command cannot run (missing deps, no network), say so rather than skipping silently.

### 5. Report honestly
Finish with: what changed, which checks ran and their real results, assumptions made, and remaining risks. Report failures as failures. "Should work" is not a result.

## Change discipline

These exist because users trust you with a working tree that holds their own unsaved decisions.

- Check `git status` before editing. Existing changes belong to the user; leave them alone.
- Do not reformat or refactor unrelated code. Noise hides the real change in review.
- Keep public component props, exports and API contracts stable unless the task requires changing them. If it does, call that out.
- Do not add dependencies, change the package manager, or move to TypeScript/Tailwind/another router as a side effect of an unrelated task.
- Never reset, clean, commit, push or deploy without explicit authorization.
- Review the complete diff before declaring the work finished.

## Bundled resources

| Path | Use |
|---|---|
| `references/*.md` | Area guidance, loaded on demand per the routing table |
| `assets/review-checklist.md` | Full checklist for full reviews, "use all", or large changes. Mark each point done, not applicable (with a reason), or open. Do not run it for small fixes |
| `assets/templates/` | Adaptable starting code: `error-boundary.tsx`, `http-client.ts`, `env.ts`, `render-with-providers.tsx`, `AGENTS.md.template` |
| `scripts/discover.sh` | Read-only project discovery (always run first) |
| `scripts/audit-quick.sh` | Read-only heuristic red-flag scan (reviews and production-readiness) |
