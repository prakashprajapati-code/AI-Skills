# Production readiness and deployment

Read for deploy tasks, build configuration, environment variables, or "is this production ready?" reviews.

Many production failures are not logic bugs. They are configuration: a missing environment variable, a wrong base path, a source map that leaks code. Check these deliberately.

- Reproducible builds: commit the lockfile, install with the frozen command (`npm ci`, `pnpm install --frozen-lockfile`, `yarn --immutable`), and make sure the build command is documented and works from a clean checkout.
- Verify environment variables and build-time configuration. List which are needed, which are inlined into the bundle at build time (and are therefore public), and confirm none hold secrets. Check that production values are set in the deployment environment, not only locally.
- Check routing, asset paths and deployment base paths. Single-page apps need a fallback to `index.html` for deep links; apps served from a sub-path need the correct `base` / `homepage` / `basePath`. Test a hard refresh on a nested route.
- Follow production logging and source-map policy. Remove debug `console.log` noise, never log secrets or personal data, and upload source maps to the error tracker rather than serving them publicly unless the project decides otherwise.
- Check browser compatibility against the project's browserslist or supported-browser policy, and check dependency vulnerabilities with the audit tool. Report what is fixable and what is not.
- Use appropriate error and performance monitoring (Sentry or the project's tool, error boundaries around risky UI, web-vitals reporting). Make sure errors reach a place someone looks.
- Consider caching, CDN behavior and rollback. Hashed asset filenames with long cache headers, `index.html` not cached long, and a known way to roll back to the previous build.
- Verify the production build itself, not just the dev server: run the build, serve the output (`vite preview` or equivalent), and walk the critical user journeys.

State clearly what you verified and what you could not (for example, no access to the deployed environment).

See also: `tooling-ci.md` (CI pipeline, quality gates), `error-handling-observability.md` (monitoring, source maps, feature flags, rollback), `migration-upgrades.md` (planned version upgrades), `nextjs-app-router.md` (env vars, caching, proxy.ts).
