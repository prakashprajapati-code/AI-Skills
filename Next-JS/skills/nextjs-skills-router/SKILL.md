---
name: nextjs-skills-router
description: Master entry point for any Next.js task. Picks which of the 10 Next.js skills (architecture, typescript-conventions, rendering-react, data-backend, security, performance, ui-accessibility, seo, testing-quality, devops-operations) to load for the task at hand, tells the user which it chose, and lets the user control the selection ("only security and seo", "skip testing", "use all", "auto"). Use this skill whenever the user asks for any build, review, debug, refactor, audit or setup task in a Next.js project, asks "which skills should you use", wants to choose or limit the skills, writes or reviews React hooks/effects/state logic, or gives a broad request like "review my Next.js app", "build this feature", "make this production ready" - even if they never name a skill.
---

# Next.js Skills Router

One front door for the 10 Next.js skills. It decides which skills a task needs, shows that choice, and obeys the user's override. This avoids two failure modes: loading everything for a one-line fix (slow, noisy), and missing the skill that matters (a form change that skips security).

## The skills

| Key | Skill | Load when the task involves |
|---|---|---|
| `architecture` | `nextjs-architecture` | new project/feature, where a file goes, folders, imports, module boundaries |
| `typescript` | `nextjs-typescript-conventions` | types, naming, Zod types, env parsing, error handling patterns |
| `rendering` | `nextjs-rendering-react` | server vs client components, SSR/SSG/ISR, caching, revalidation, hydration, streaming; React hooks, effects, state, keys, memoization, refs, error boundaries |
| `data` | `nextjs-data-backend` | route handlers, server actions, database, transactions, validation, external APIs |
| `security` | `nextjs-security` | auth, permissions, user input, files, secrets, headers, rate limits |
| `performance` | `nextjs-performance` | slow pages, Web Vitals, images, fonts, bundle size, loading states |
| `ui` | `nextjs-ui-accessibility` | components, styling, themes, forms UI, accessibility, responsive layout |
| `seo` | `nextjs-seo` | metadata, canonical, OG, sitemap, robots, structured data, redirects |
| `testing` | `nextjs-testing-quality` | tests, lint, TS checks, PR review, debugging failures, upgrades |
| `devops` | `nextjs-devops-operations` | env/config, CI/CD, Docker, deploy, logging, monitoring, rollback |

## Step 1: Read the user's control instruction (it always wins)
Look in the request, then in a repo config file if present (`nextjs-skills.md` or `.claude/nextjs-skills.md`, see "Standing preferences"), for any of:

| User says | Meaning |
|---|---|
| `only security, seo` / `use just testing` | Load exactly those skills; do not add others |
| `skip testing` / `without devops` / `no seo` | Auto-select, then remove those |
| `also security` / `include performance` | Auto-select, then add those |
| `all skills` / `use everything` | Load all 10 (say this is heavy; fine for audits) |
| `auto` / nothing said | Auto-select (Step 2) |
| `ask me first` / `let me choose` | Show the proposed set and wait for confirmation before loading |
| `no skills` | Do the task without loading any skill |

Skill keys, full names, or plain words all count ("a11y" = `ui`, "ci" = `devops`, "caching" = `rendering`). If an instruction is ambiguous, pick the narrower reading and say so in one line.

A user's exclusion is respected even when the task touches that area. If a skipped area carries real risk (for example skipping `security` while adding a public endpoint), do the work as asked and add one short line naming the risk. Do not load the skipped skill.

## Step 2: Auto-select (when the user did not choose)
1. Classify the task: **build** (new code), **change** (modify existing), **review/audit**, **debug**, **setup/ops**, **upgrade**.
2. Pick the **primary** skill: the one that owns the main decision of the task (from the table above).
3. Add **supporting** skills from the signals below. Keep the set small: typically 1 primary + up to 2-3 supporting. Choose more only for audits or "production ready" requests.

Signals that pull in a supporting skill:
- Touches a form, endpoint, action, upload, cookie or login -> `security` (+ `data` if it writes data)
- Adds or edits a page or route -> `rendering` (static/dynamic choice) and `seo` if the page is public
- Adds UI -> `ui`; adds a heavy library or large images -> `performance`
- Adds a new feature or folder -> `architecture`
- Writes non-trivial TypeScript or schemas -> `typescript`
- Any change that should be verified or reviewed -> `testing` (lightweight: just the verification checklist)
- Anything about deploy, env vars, secrets in CI, monitoring -> `devops`

## Task-to-skills recipes (starting points; adjust to the request)
| Task | Primary | Supporting |
|---|---|---|
| New project bootstrap | `architecture` | `typescript`, `testing`, `devops` |
| New feature / page | `architecture` | `rendering`, `ui`, `data` (if backend), `seo` (if public) |
| Form + backend submit | `data` | `security`, `ui`, `typescript` |
| Login, roles, protecting routes | `security` | `data`, `architecture` |
| "Page is slow" / Lighthouse | `performance` | `rendering`, `ui` (layout shift) |
| Stale or unexpectedly dynamic data | `rendering` | `data` |
| Hydration error / "use client" question | `rendering` | `ui` |
| React hooks, effects, state, re-render bug, custom hook, keys | `rendering` (see `../nextjs-rendering-react/references/react-patterns.md`) | `typescript`, `testing`, `performance` (if slow) |
| Client form (controlled, React Hook Form, server action) | `data` | `rendering`, `ui`, `security`, `typescript` |
| Search visibility / social previews | `seo` | `rendering`, `performance` |
| Style / theme / accessibility fix | `ui` | `performance` (only if layout shift) |
| Review a PR / diff | `testing` | the skills matching the files changed (e.g. `security` for endpoints) |
| Failing build, lint or test | `testing` | `typescript`, `rendering` |
| Upgrade Next/React | `testing` | `rendering`, `devops` |
| CI/CD, Docker, deploy, monitoring | `devops` | `security`, `testing` |
| Full audit / "production ready" | `all` (or let user pick) | - |
| Refactor / restructure | `architecture` | `typescript`, `testing` |

## Step 3: Announce the choice, then work
Before doing the task, state the selection in two lines so the user can redirect:

> **Skills for this task:** `data` (primary), `security`, `ui`. Not using: the other 7. Say "also seo" or "skip ui" to change.

If the user said `ask me first`, stop after this line and wait. Otherwise continue straight away: the user can interrupt.

## Step 4: Load and apply
1. Load each selected skill with the Skill tool (`nextjs-<name>`). Load only the selected ones, primary first.
2. Read their reference files only when the task needs them (each skill says when).
3. Where two skills disagree, the primary skill wins on its own domain; `security` wins over convenience everywhere, unless the user excluded it.
4. If a skill is not installed, say which one is missing, continue with general best practice, and note the gap.
5. Finish by running the verification checklist of each loaded skill that applies, and report results in a few lines (what was checked, what was not).

## Standing preferences (optional repo file)
Teams can set defaults in `nextjs-skills.md` at the repo root (or `.claude/nextjs-skills.md`):
```md
# Next.js skills preferences
mode: auto            # auto | ask | all
always: security      # always load, comma separated
never: devops         # never load unless the user asks in the request
notes: we deploy on Vercel; use Drizzle; Tailwind v4
```
Precedence: the request itself > the preferences file > auto-selection. `notes` are context for every skill (stack choices), not skill selection.

Plain React projects (Vite, CRA, Remix without Next.js): load only `rendering` for its React patterns reference and `typescript`/`ui`/`testing` as needed; ignore Next-specific rules (caching, route handlers, metadata) and say so.

## Pitfalls
- Loading all 10 skills for a small change: wastes context and buries the relevant rules.
- Silent selection: always show the chosen set so the user can steer.
- Treating a user exclusion as a suggestion. It is an instruction.
- Choosing by keywords only: choose by what the change can break (a "style" tweak that adds a script tag needs `security` and `performance`).
- Forgetting `testing` verification at the end; it is cheap and catches the regressions.

## Examples
**1.** "Add a contact form that emails us" -> `data` (primary), `security`, `ui`, `typescript`. Announce, then build with the pipeline order from `data`, abuse protections from `security`, accessible fields from `ui`.
**2.** "Review this PR, only security and testing" -> exactly `security` and `testing`; no others even though the diff changes UI.
**3.** "Make the product page faster, skip seo" -> `performance` (primary), `rendering`, `ui`; `seo` excluded.
**4.** "Is this app production ready? let me choose" -> propose `security`, `performance`, `devops`, `testing`, `seo`; wait for confirmation.
