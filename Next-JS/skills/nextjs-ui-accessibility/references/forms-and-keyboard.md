# Forms, theming and keyboard patterns

## Accessible field (React 19 + server action state)
```tsx
"use client";
import { useId } from "react";

type FieldProps = { label: string; name: string; type?: string; error?: string; hint?: string; required?: boolean; autoComplete?: string };

export function FormField({ label, name, type = "text", error, hint, required, autoComplete }: FieldProps) {
  const id = useId();
  const hintId = hint ? `${id}-hint` : undefined;
  const errorId = error ? `${id}-error` : undefined;
  return (
    <div className="space-y-1">
      <label htmlFor={id} className="block text-sm font-medium">
        {label}{required && <span aria-hidden="true"> *</span>}
      </label>
      <input
        id={id} name={name} type={type} required={required} autoComplete={autoComplete}
        aria-invalid={error ? true : undefined}
        aria-describedby={[hintId, errorId].filter(Boolean).join(" ") || undefined}
        className="w-full rounded-md border border-border bg-background px-3 py-2 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary aria-[invalid=true]:border-danger"
      />
      {hint && <p id={hintId} className="text-sm text-muted-foreground">{hint}</p>}
      {error && <p id={errorId} role="alert" className="text-sm text-danger">{error}</p>}
    </div>
  );
}
```

## Form behaviors checklist
- Submit button shows pending state (`useFormStatus`) and is not the only feedback; prevent double submit.
- On failed validation: focus first invalid field; summary at top for long forms with links to fields.
- Success: announce with a polite live region (`role="status"`), do not rely on a toast that vanishes.
- Do not clear user input on error.
- `autocomplete` tokens (`email`, `given-name`, `tel`, `street-address`, `one-time-code`), `inputMode="numeric"` for digits, `type="email"/"tel"/"url"`.
- Group related controls in `<fieldset><legend>`.

## Theme without flash
```tsx
// app/layout.tsx (server component)
const themeScript = `(function(){try{var t=localStorage.getItem("theme");var d=window.matchMedia("(prefers-color-scheme: dark)").matches;document.documentElement.dataset.theme=t||(d?"dark":"light");}catch(e){}})();`;
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head><script dangerouslySetInnerHTML={{ __html: themeScript }} /></head>
      <body>{children}</body>
    </html>
  );
}
```
Or use `next-themes` (`attribute="data-theme"`, `defaultTheme="system"`). With a strict CSP, give the inline script a nonce.

## Tokens (Tailwind v4)
```css
@import "tailwindcss";
:root { --background: #fff; --foreground: #111827; --primary: #2563eb; --border: #e5e7eb; --danger: #dc2626; }
[data-theme="dark"] { --background: #0b1220; --foreground: #e5e7eb; --primary: #60a5fa; --border: #1f2937; --danger: #f87171; }
@theme inline { --color-background: var(--background); --color-foreground: var(--foreground); --color-primary: var(--primary); --color-border: var(--border); --color-danger: var(--danger); }
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { animation-duration: .01ms !important; transition-duration: .01ms !important; } }
```
Check contrast for every foreground/background pair in both themes.

## Keyboard map for common widgets
| Widget | Keys |
|---|---|
| Button | Enter, Space |
| Link | Enter |
| Dialog | Esc closes, Tab cycles inside, focus returns to trigger |
| Menu / listbox | Arrow keys move, Home/End, Enter selects, Esc closes, type-ahead |
| Tabs | Arrow keys switch tabs, Tab moves into panel |
| Disclosure/accordion | Enter/Space toggles, `aria-expanded` |
| Combobox | Arrow keys, Enter selects, Esc closes, `aria-activedescendant` |
Use a headless library to get these right instead of rebuilding them.

## Skip link
```tsx
<a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded focus:bg-background focus:px-3 focus:py-2">Skip to content</a>
<main id="main" tabIndex={-1}>...</main>
```
