#!/usr/bin/env bash
# Read-only quick scan for common React production red flags (heuristic grep, NOT a replacement for review).
# Usage: audit-quick.sh [project-dir]     Never modifies files, installs, or touches Git.
# Output: each finding as  [LEVEL] rule  file:line  — verify manually; false positives are possible.
set -u
DIR="${1:-.}"
[ -d "$DIR" ] || { echo "ERROR: directory not found: $DIR" >&2; exit 1; }
cd "$DIR" || exit 1

EXCL=(--exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.next --exclude-dir=coverage --exclude-dir=.git --exclude-dir=.turbo --exclude-dir=storybook-static)
SRC=(--include=*.js --include=*.jsx --include=*.ts --include=*.tsx)
TESTS='\.(test|spec|stories)\.[jt]sx?:|/__tests__/|/e2e/|/test/'
total=0

scan() { # level, rule, regex, [keep-tests=0], [drop-regex: ignore matching lines]
  local level="$1" rule="$2" re="$3" keep="${4:-0}" drop="${5:-}" out
  out=$(grep -rnE "${EXCL[@]}" "${SRC[@]}" -- "$re" . 2>/dev/null)
  [ "$keep" = "0" ] && out=$(printf '%s\n' "$out" | grep -Ev "$TESTS")
  [ -n "$drop" ] && out=$(printf '%s\n' "$out" | grep -Ev "$drop")
  out=$(printf '%s\n' "$out" | sed '/^$/d')
  if [ -n "$out" ]; then
    local n; n=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
    total=$((total + n))
    echo "[$level] $rule  ($n)"
    printf '%s\n' "$out" | head -8 | sed 's/^/    /' | cut -c1-170
    [ "$n" -gt 8 ] && echo "    ... $((n - 8)) more"
    echo
  fi
}

echo "== Quick audit: $(pwd)"; echo

# --- Security ---
scan HIGH  "dangerouslySetInnerHTML (sanitize or remove)"              'dangerouslySetInnerHTML'
scan HIGH  "eval / new Function"                                       '\beval\(|new Function\('
scan HIGH  "innerHTML / document.write assignment"                     '\.innerHTML[[:space:]]*=|document\.write\('
scan HIGH  "tokens/secrets kept in web storage"                        '(localStorage|sessionStorage)\.(setItem|getItem)\([^)]*(token|jwt|secret|password|auth)'
scan HIGH  "secret-looking value exposed via public env prefix"        '(VITE_|NEXT_PUBLIC_|REACT_APP_)[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|API_KEY|TOKEN)'
scan HIGH  "hard-coded credential-like string"                         "(api[_-]?key|secret|passwd|password|token)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][A-Za-z0-9_\\-]{16,}[\"']"
scan MED   "target=_blank without rel=noopener"                        'target=["'"'"']_blank' 0 'rel=' 
scan MED   "javascript: URL"                                           'javascript:'
scan MED   "window.location assigned from variable (open redirect?)"   'window\.location(\.href)?[[:space:]]*=[[:space:]]*[a-zA-Z_]'

# --- React correctness ---
scan MED   "array index used as key"                                   'key=\{(i|idx|index)\}|key=\{`[^`]*\$\{(i|idx|index)\}'
scan MED   "fetch inside useEffect (use the data layer / query lib)"   'useEffect\(.*fetch\(' 
scan MED   "setState in effect without deps guard (check render loops)" 'useEffect\(\(\)[[:space:]]*=>[[:space:]]*\{[[:space:]]*set[A-Z][A-Za-z]*\('
scan LOW   "class components (leave unless touching file)"             'extends (React\.)?(Pure)?Component'
scan LOW   "deprecated/removed in 19: propTypes / defaultProps / findDOMNode / ReactDOM.render" 'propTypes[[:space:]]*=|\.defaultProps[[:space:]]*=|findDOMNode|ReactDOM\.render\(|unmountComponentAtNode'
scan LOW   "forwardRef (unnecessary on React 19+)"                     'forwardRef\('
scan LOW   "eslint-disable of hooks rules"                             'eslint-disable.*react-hooks'

# --- Types / quality ---
scan MED   "explicit any"                                              ':[[:space:]]*any\b|as any\b|<any>'
scan MED   "ts-ignore / ts-nocheck (prefer ts-expect-error + reason)"  '@ts-ignore|@ts-nocheck'
scan LOW   "non-null assertion (!.)"                                   '[A-Za-z_\)\]]![.\[]'
scan LOW   "console.log left in source"                                'console\.(log|debug)\('
scan LOW   "empty catch block"                                         'catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}'
scan LOW   "TODO / FIXME / HACK"                                       'TODO|FIXME|HACK|XXX'

# --- Accessibility ---
scan MED   "clickable non-interactive element (div/span onClick)"      '<(div|span|li|td|p)[^>]*onClick='
scan MED   "img without alt"                                           '<img[[:space:]]' 0 'alt=' 
scan MED   "outline removed (check replacement focus style)"           'outline:[[:space:]]*(none|0)[^;]*;'
scan LOW   "positive tabIndex"                                         'tabIndex=\{?["'"'"']?[1-9]'
scan LOW   "autoFocus (check usability)"                               'autoFocus'
scan LOW   "user-scalable=no / maximum-scale (blocks zoom)"            'user-scalable=no|maximum-scale=1'

# --- Performance ---
scan LOW   "whole-library imports (lodash/moment/icons)"               "from ['\"](lodash|moment|@mui/icons-material)['\"]"
scan LOW   "inline object/array/function in useEffect deps"            'useEffect\([^)]*\[[^]]*(\{|\[|=>)'
scan LOW   "index.html/boot: sync third-party script tags (check async/defer)" '<script[^>]+src=[^>]*>' 

# --- Tests (file-level facts) ---
tests=$(find . -type f \( -name '*.test.*' -o -name '*.spec.*' \) -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
comps=$(find . -type f \( -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/.next/*' -not -name '*.test.*' -not -name '*.spec.*' -not -name '*.stories.*' 2>/dev/null | wc -l | tr -d ' ')
echo "[INFO] component files: $comps, test files: $tests"
[ "$comps" -gt 5 ] && [ "$tests" -eq 0 ] && { echo "[HIGH] no tests found for a non-trivial UI codebase"; total=$((total+1)); }

# --- Project hygiene ---
echo
echo "== Project hygiene"
[ -f .gitignore ] && grep -qE '^\.env' .gitignore 2>/dev/null || echo "[HIGH] .gitignore missing or does not ignore .env files"
for f in .env .env.local .env.production; do
  [ -f "$f" ] && command -v git >/dev/null 2>&1 && git ls-files --error-unmatch "$f" >/dev/null 2>&1 && echo "[HIGH] $f is tracked by Git (possible committed secrets)"
done
[ -f package-lock.json ] || [ -f pnpm-lock.yaml ] || [ -f yarn.lock ] || [ -f bun.lockb ] || [ -f bun.lock ] || echo "[MED] no lockfile"
lockcount=0; for l in package-lock.json pnpm-lock.yaml yarn.lock bun.lockb bun.lock; do [ -f "$l" ] && lockcount=$((lockcount+1)); done
[ "$lockcount" -gt 1 ] && echo "[MED] multiple lockfiles: pick one package manager"
[ -f .env.example ] || echo "[LOW] no .env.example documenting required variables"
[ -f AGENTS.md ] || [ -f CLAUDE.md ] || echo "[LOW] no AGENTS.md/CLAUDE.md for AI agents"
[ -f index.html ] && ! grep -q 'name="viewport"' index.html 2>/dev/null && echo "[MED] index.html has no viewport meta"
[ -f index.html ] && ! grep -qE '<html[^>]*lang=' index.html 2>/dev/null && echo "[MED] index.html <html> has no lang attribute"

echo
echo "== Findings total (heuristic): $total"
echo "Verify each hit by reading the code. Do not 'fix' false positives, and do not treat a clean scan as proof of safety."
echo "Also run the project's own: typecheck, lint, tests, build, dependency audit."
