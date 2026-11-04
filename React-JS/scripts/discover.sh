#!/usr/bin/env bash
# Read-only project discovery for React projects.
# Usage: discover.sh [project-dir]   (defaults to the current directory)
# Prints facts about the project so decisions are based on what is really there.
# It never modifies files, installs packages, or touches Git state.

set -u
DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
  echo "ERROR: directory not found: $DIR" >&2
  exit 1
fi
cd "$DIR" || exit 1

echo "== Project: $(pwd)"

# ---- Instruction files -------------------------------------------------
echo
echo "== Instruction files (read these first)"
found=0
for f in AGENTS.md CLAUDE.md README.md README .github/copilot-instructions.md CONTRIBUTING.md .cursorrules; do
  if [ -f "$f" ]; then echo "  $f"; found=1; fi
done
for d in .github/instructions .github/skills .claude/skills .claude/agents .cursor/rules; do
  if [ -d "$d" ]; then echo "  $d/"; found=1; fi
done
[ "$found" -eq 0 ] && echo "  (none found)"

# ---- package.json ------------------------------------------------------
echo
if [ ! -f package.json ]; then
  echo "== package.json: NOT FOUND in this directory"
  echo "   If this is a monorepo, run again with the app's folder, e.g. apps/web"
else
  echo "== package.json"
  if command -v node >/dev/null 2>&1; then
    node -e '
      const fs = require("fs");
      let p;
      try { p = JSON.parse(fs.readFileSync("package.json", "utf8")); }
      catch (e) { console.log("  could not parse package.json: " + e.message); process.exit(0); }
      const deps = Object.assign({}, p.dependencies, p.devDependencies, p.peerDependencies);
      const has = (n) => Object.prototype.hasOwnProperty.call(deps, n);
      const ver = (n) => has(n) ? n + "@" + deps[n] : null;
      const list = (title, names) => {
        const found = names.map(ver).filter(Boolean);
        console.log("  " + title + ": " + (found.length ? found.join(", ") : "none detected"));
      };
      console.log("  name: " + (p.name || "(unnamed)"));
      console.log("  react: " + (ver("react") || "NOT a dependency"));
      console.log("  react-dom: " + (ver("react-dom") || "none"));
      list("framework/build", ["next","vite","react-scripts","@remix-run/react","react-router","react-router-dom","gatsby","expo","react-native","webpack","parcel","@vitejs/plugin-react","@vitejs/plugin-react-swc"]);
      list("typescript", ["typescript"]);
      list("styling", ["tailwindcss","styled-components","@emotion/react","sass","@mui/material","antd","@chakra-ui/react","@radix-ui/react-dialog"]);
      list("server-state/api", ["@tanstack/react-query","swr","@reduxjs/toolkit","axios","graphql","@apollo/client","urql"]);
      list("client-state", ["redux","zustand","jotai","recoil","mobx","valtio"]);
      list("forms/validation", ["react-hook-form","formik","zod","yup","valibot","@hookform/resolvers"]);
      list("testing", ["jest","vitest","@testing-library/react","@testing-library/user-event","@playwright/test","cypress","msw","jest-axe","axe-core","vitest-axe"]);
      list("lint/format", ["eslint","prettier","eslint-plugin-jsx-a11y","eslint-plugin-react-hooks","@biomejs/biome"]);
      list("monitoring", ["@sentry/react","@sentry/browser","web-vitals","@datadog/browser-rum"]);
      list("sanitizing", ["dompurify","sanitize-html"]);
      list("routing", ["react-router","react-router-dom","@tanstack/react-router","@remix-run/react","wouter"]);
      list("i18n", ["react-i18next","i18next","react-intl","next-intl","@lingui/core","@formatjs/intl"]);
      list("ui kit/headless", ["@radix-ui/react-dialog","@headlessui/react","react-aria-components","@ariakit/react","@mui/material","antd","@chakra-ui/react"]);
      list("storybook", ["storybook","@storybook/react","@storybook/react-vite"]);
      list("e2e", ["@playwright/test","cypress"]);
      list("tables/virtual", ["@tanstack/react-table","@tanstack/react-virtual","react-window","react-virtuoso"]);
      list("server components/compiler", ["react-server-dom-webpack","react-server-dom-turbopack","react-server-dom-parcel","server-only","babel-plugin-react-compiler"]);
      // --- version-aware hints ---
      const major = (n) => has(n) ? parseInt(String(deps[n]).replace(/[^0-9.]/g, "").split(".")[0], 10) : 0;
      const reactMajor = major("react");
      if (reactMajor && reactMajor < 19) console.log("  HINT: React " + reactMajor + " detected. Do not use React 19-only APIs (use, useActionState, ref-as-prop) here. See references/migration-upgrades.md to upgrade.");
      if (has("react-scripts")) console.log("  HINT: Create React App is deprecated. See references/migration-upgrades.md (CRA to Vite) before adding features that need a modern toolchain.");
      if (has("react-native") || has("expo")) console.log("  SCOPE: React Native/Expo detected. This skill targets React for the web; native-specific guidance is not covered.");
      if (has("tailwindcss")) console.log("  HINT: tailwindcss major " + major("tailwindcss") + " (v4 = CSS-first @theme, v3 = tailwind.config.js). Match the installed major.");
      if (has("next")) console.log("  HINT: Next.js major " + major("next") + ". Read references/nextjs-app-router.md (version differences: async params in 15, proxy.ts and Cache Components in 16).");
      if (has("react-router-dom") && !has("react-router")) console.log("  HINT: react-router-dom only (v6-style). v7 consolidates into react-router; see references/migration-upgrades.md.");
      if (has("react") && !has("typescript")) console.log("  NOTE: JavaScript project. Do not add TypeScript as a side effect of an unrelated task.");
      if (has("moment")) console.log("  NOTE: moment is in maintenance mode and heavy; do not use it in new code.");
      const nextMajor = has("next") ? parseInt(String(deps["next"]).replace(/[^0-9.]/g, "").split(".")[0], 10) : 0;
      const usesRsc = has("react-server-dom-webpack") || has("react-server-dom-turbopack") || has("react-server-dom-parcel") || nextMajor >= 13;
      if (usesRsc) {
        console.log("  SECURITY CHECK: this project may run React Server Components or Server Functions.");
        console.log("    Confirm react, react-dom, react-server-dom-* and next are on patched versions");
        console.log("    (see references/security-privacy.md > Known critical advisories) and run the audit.");
      }
      const s = p.scripts || {};
      const names = Object.keys(s);
      console.log("  scripts:");
      if (!names.length) console.log("    (none)");
      names.forEach((k) => console.log("    " + k + ": " + s[k]));
      if (p.engines) console.log("  engines: " + JSON.stringify(p.engines));
      if (p.browserslist) console.log("  browserslist: configured");
      if (p.workspaces) console.log("  workspaces: yes (monorepo) - confirm you are in the right package");
    '
  else
    echo "  (node not available; showing raw grep fallback)"
    grep -E '"(react|react-dom|next|vite|react-scripts|typescript|jest|vitest)"' package.json | sed 's/^/  /'
    echo "  scripts block:"
    sed -n '/"scripts"/,/}/p' package.json | sed 's/^/    /'
  fi
fi

# ---- Package manager and lockfile --------------------------------------
echo
echo "== Package manager / lockfile"
pm_found=0
[ -f package-lock.json ] && { echo "  npm (package-lock.json)  -> install with: npm ci"; pm_found=1; }
[ -f pnpm-lock.yaml ]    && { echo "  pnpm (pnpm-lock.yaml)    -> install with: pnpm install --frozen-lockfile"; pm_found=1; }
[ -f yarn.lock ]         && { echo "  yarn (yarn.lock)         -> install with: yarn install --immutable (or --frozen-lockfile on v1)"; pm_found=1; }
[ -f bun.lockb ] || [ -f bun.lock ] && { echo "  bun (bun.lock/bun.lockb)"; pm_found=1; }
[ "$pm_found" -eq 0 ] && echo "  NO LOCKFILE found - builds are not reproducible"
[ -d node_modules ] && echo "  node_modules: present" || echo "  node_modules: missing (dependencies not installed)"

# ---- Config files ------------------------------------------------------
echo
echo "== Config files present"
cfg=0
for f in tsconfig.json jsconfig.json vite.config.ts vite.config.js next.config.js next.config.mjs next.config.ts \
         webpack.config.js craco.config.js .eslintrc .eslintrc.js .eslintrc.json .eslintrc.cjs eslint.config.js eslint.config.mjs \
         .prettierrc .prettierrc.json prettier.config.js biome.json jest.config.js jest.config.ts vitest.config.ts \
         playwright.config.ts cypress.config.ts tailwind.config.js tailwind.config.ts postcss.config.js react-router.config.ts turbo.json nx.json pnpm-workspace.yaml .storybook/main.ts .env.example .env.local .env .nvmrc .browserslistrc Dockerfile vercel.json netlify.toml; do
  if [ -f "$f" ]; then echo "  $f"; cfg=1; fi
done
[ "$cfg" -eq 0 ] && echo "  (none of the common config files found)"
if [ -f .env ] || [ -f .env.local ]; then
  echo "  NOTE: real .env file exists; check it is gitignored and never print its values"
fi

# ---- Source layout -----------------------------------------------------
echo
echo "== Source layout (top two levels of src/app/pages if present)"
shown=0
for d in src app pages components; do
  if [ -d "$d" ]; then
    echo "  $d/"
    find "$d" -mindepth 1 -maxdepth 2 -type d -not -path '*/node_modules/*' 2>/dev/null | sort | head -40 | sed 's/^/    /'
    shown=1
  fi
done
[ "$shown" -eq 0 ] && echo "  (no src/app/pages directory found)"

echo
echo "== Rough size"
for ext in tsx jsx ts js; do
  n=$(find . -type f -name "*.$ext" -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.next/*' 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" != "0" ] && echo "  .$ext files: $n"
done
tests=$(find . -type f \( -name '*.test.*' -o -name '*.spec.*' \) -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
echo "  test files: $tests"

# ---- Git ---------------------------------------------------------------
echo
echo "== Git"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "  branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  changes=$(git status --porcelain 2>/dev/null)
  if [ -z "$changes" ]; then
    echo "  working tree: clean"
  else
    echo "  working tree: HAS UNCOMMITTED CHANGES (these belong to the user - do not overwrite or revert):"
    echo "$changes" | head -30 | sed 's/^/    /'
    total=$(echo "$changes" | wc -l | tr -d ' ')
    [ "$total" -gt 30 ] && echo "    ... and $((total - 30)) more"
  fi
  echo "  recent commits:"
  git log --oneline -5 2>/dev/null | sed 's/^/    /'
else
  echo "  not a Git repository (no safety net: avoid destructive edits, keep changes small)"
fi

echo
echo "== Done. Next: read the instruction files above, then trace the code path for the task."
echo "   Optional heuristic red-flag scan (read-only): scripts/audit-quick.sh <project-dir>"
