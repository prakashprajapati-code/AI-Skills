# Next.js Skills (10 + router, generic)

## Install (flat layout is required)
Agents discover skills only as direct children of the skills directory:
```
cp -r skills/* ~/.claude/skills/        # personal
cp -r skills/* <repo>/.claude/skills/   # per project
```
Result: `.claude/skills/nextjs-security/SKILL.md` etc. Do not nest them inside another folder. `AGENTS.md` (repo root) points other agents (Cursor, Codex, ...) at the same folders.

## Standard layout per skill
```
<skill-name>/        # folder name == `name` in frontmatter
  SKILL.md           # required: frontmatter (name, description) + instructions (< 500 lines)
  references/        # long docs, read on demand
  assets/            # templates and files used in output
  scripts/           # optional runnable helpers
```


Ten independent skills plus one router skill (`nextjs-skills-router`) that picks the right skills per task and lets you override the choice ("only security, seo", "skip testing", "all", "ask me first"). The ten skills cover Next.js App Router projects, one per engineering area. Each folder works alone; install one or all, ideally with the router (copy into your skills directory, e.g. `~/.claude/skills/`).

| # | Skill | Covers |
|---|---|---|
| 01 | `nextjs-architecture` | folder structure, feature modules, layer/dependency rules, server vs client code placement |
| 02 | `nextjs-typescript-conventions` | strict typing, naming, Zod-inferred types, env module, reusable code, error handling |
| 03 | `nextjs-rendering-react` | Server/Client Components, SSR/SSG/ISR, streaming, caching and revalidation, hydration, React hooks/effects/state/keys/memoization/refs/error boundaries (`references/react-patterns.md`) |
| 04 | `nextjs-data-backend` | server actions vs route handlers, validation, DB access, transactions, idempotency, uploads |
| 05 | `nextjs-security` | authN/authZ, IDOR, input validation, XSS/CSRF/SSRF, secrets, headers/CSP, rate limits |
| 06 | `nextjs-performance` | Core Web Vitals, images, fonts, bundles, streaming, caching, diagnosis workflow |
| 07 | `nextjs-ui-accessibility` | design tokens, theming, semantic HTML, WCAG 2.2 AA, keyboard, responsive layouts |
| 08 | `nextjs-seo` | Metadata API, canonicals, sitemap, robots, JSON-LD, redirects, i18n |
| 09 | `nextjs-testing-quality` | unit/integration/E2E tests, ESLint, TS checks, PR review, troubleshooting, upgrades |
| 10 | `nextjs-devops-operations` | env config, CI/CD, Docker, logging, monitoring, health checks, rollback, runbooks |

## Router
`nextjs-skills-router` is the single entry point: it announces which skills it will use, obeys your include/exclude instructions, and reads optional defaults from `nextjs-skills.md` in your repo.

## Conventions
`[MUST]` = required for correctness or safety. `[SHOULD]` = strong default; deviate with a reason.
Defaults assume Next 15+, React 19, TypeScript strict. Version-specific notes (Next 14/15/16) are called out where APIs differ; always confirm against the installed version's docs.
Templates use `<placeholders>`; replace them.
