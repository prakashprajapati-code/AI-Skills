# Agent instructions: Next.js skills

This repo/pack provides Agent Skills for Next.js (App Router, React 19, TypeScript).
Skills live in `skills/<name>/SKILL.md` (install flat into `.claude/skills/` or `~/.claude/skills/`).

- Start with `nextjs-skills-router`: it selects which skills to load and obeys user overrides ("only security", "skip testing", "all").
- Load a skill only when the task matches its `description` in the SKILL.md frontmatter.
- Read a skill's `references/*.md` only when the task needs it; `assets/` holds copy-ready templates with `<placeholders>`.
- Skills: nextjs-architecture, nextjs-typescript-conventions, nextjs-rendering-react (includes React patterns), nextjs-data-backend, nextjs-security, nextjs-performance, nextjs-ui-accessibility, nextjs-seo, nextjs-testing-quality, nextjs-devops-operations.
- `[MUST]` rules are required; `[SHOULD]` are defaults. Confirm version-specific APIs (Next 14/15/16, React 18/19) against the installed version.
