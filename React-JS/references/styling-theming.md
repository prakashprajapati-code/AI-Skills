# Styling, theming and design systems

Read when writing CSS, choosing a styling approach, adding dark mode, tokens, animation, or building shared UI primitives.

Contents: 1. Follow the project · 2. Approach comparison · 3. Tailwind · 4. CSS Modules / plain CSS · 5. CSS-in-JS · 6. Tokens and theming · 7. Dark mode · 8. Responsive · 9. Animation · 10. Design system and Storybook · 11. Pitfalls

## 1. Follow the project
Check `discover.sh` output (styling line) and the nearest component. Use the existing approach. Do not mix a second system into the same component. Adding a styling library is a decision to state and justify, not a side effect.

## 2. Approach comparison (for new projects only)
| Approach | Good for | Watch out for |
|---|---|---|
| Tailwind CSS | Fast UI work, consistent spacing/color scale, small CSS output | Long class lists; extract components, not `@apply` piles |
| CSS Modules | Scoped styles, zero runtime, works everywhere | Needs discipline for shared tokens |
| Plain CSS + custom properties | Simple sites, design tokens | Global scope collisions without naming rules |
| Runtime CSS-in-JS (styled-components, Emotion) | Existing codebases | Runtime cost, awkward with Server Components; avoid for new RSC projects |
| Zero-runtime CSS-in-JS (vanilla-extract, Panda, StyleX) | Typed tokens, RSC-friendly | Build setup |
| Component libraries (MUI, Chakra, Ant, Radix + shadcn/ui) | Speed, accessibility built in | Bundle size, theming lock-in; check RSC support |

## 3. Tailwind
- Tailwind v4 is CSS-first: `@import "tailwindcss";` in the main CSS, tokens in `@theme { --color-brand: ...; }`, the Vite plugin `@tailwindcss/vite`, and automatic content detection. v3 used `tailwind.config.js` and `@tailwind` directives. Check `package.json` and match the installed major version; do not mix their syntax.
- Compose, do not repeat: extract a React component (or a variants helper such as `cva` / `tailwind-variants`) when the same class set appears 3+ times. Use `clsx` / `tailwind-merge` to merge conditional and overriding classes safely.
- Never build class names dynamically (`` `text-${color}-500` ``): the scanner cannot see them. Map values to full static class strings.
- Use design tokens (theme colors, spacing scale) instead of arbitrary values (`w-[137px]`) unless truly one-off.
- Order and format classes with the official Prettier plugin if the project has it.
- Use `focus-visible:` styles for keyboard focus, `motion-reduce:` for reduced motion, `dark:` for dark mode.

## 4. CSS Modules / plain CSS
- One `.module.css` per component, class names in camelCase or kebab-case consistently. Access through `styles.card`.
- Put colors, spacing, radii, font sizes, z-indexes in CSS custom properties (`:root { --space-2: 0.5rem; }`) and reference them everywhere.
- Prefer logical properties (`margin-inline`, `padding-block`, `inset-inline-start`) so RTL languages work.
- Use `clamp()` for fluid type and spacing, `min()`/`max()`, grid and flexbox with `gap`. Avoid fixed heights on text containers.
- Keep specificity low: single classes, no `!important`, no deep descendant chains. Use `@layer` to order resets, base, components, utilities.
- Use container queries (`@container`) for components that live in different width contexts.

## 5. CSS-in-JS
- Match the existing library. Do not create styled components inside render (new component identity every render; state is lost, performance suffers).
- Runtime libraries need extra setup for SSR and Server Components (style registry). If a project is moving to RSC, prefer migrating to CSS Modules, Tailwind or zero-runtime.
- Avoid passing rapidly changing props (mouse position) into styled interpolations; use CSS variables or inline `style` for those.

## 6. Tokens and theming
- Define tokens once: color (semantic names: `--color-bg`, `--color-text`, `--color-primary`, `--color-danger`), spacing scale, type scale, radius, shadow, z-index layers, breakpoints, motion durations.
- Use **semantic** tokens in components (`--color-danger`) and **primitive** tokens (`--red-600`) only in the token layer. Re-theming then means changing one mapping.
- Never hard-code hex values inside components.

## 7. Dark mode
- Use `prefers-color-scheme` as the default, with a user override stored in a cookie or `localStorage` (value `light | dark | system`).
- Avoid the flash of wrong theme: set the theme attribute on `<html>` with a tiny inline script before first paint (or via a cookie read on the server). Add `suppressHydrationWarning` on `<html>` only for that attribute.
- Switch themes by changing CSS variables under `[data-theme="dark"]` (or the Tailwind `dark` variant configured to the same attribute) rather than re-rendering the tree.
- Set `color-scheme: light dark` so native controls and scrollbars follow the theme.
- Check contrast (4.5:1) in **both** themes. Do not invert images blindly.

## 8. Responsive
- Mobile first: base styles for small screens, enhance with `min-width` queries.
- Use standard breakpoints from the token set; avoid one-off pixel breakpoints.
- Test at 320px width, at 200% zoom and with large text. Touch targets at least 44x44 CSS px (24x24 minimum under WCAG 2.2 AA).
- Use `dvh`/`svh` instead of `100vh` for full-height mobile layouts.
- `<meta name="viewport" content="width=device-width, initial-scale=1">`, and never disable zoom.

## 9. Animation
- Animate `transform` and `opacity` (compositor-friendly). Avoid animating `width/height/top/left`.
- Wrap non-essential motion in `@media (prefers-reduced-motion: reduce)` (or `motion-reduce:`), and keep essential feedback non-motion.
- Prefer CSS transitions for simple states; use a library (Motion/Framer Motion, React Spring) for gestures, layout animation or orchestration. Check bundle cost; lazy-load heavy animation.
- No auto-playing motion longer than 5 seconds without a pause control. Nothing flashes more than 3 times per second.
- View Transitions (React 19.2 / browser API) can animate route changes; feature-detect and keep the fallback.

## 10. Design system and Storybook
- Shared primitives (`Button`, `Input`, `Modal`, `Tooltip`, `Select`) live in `shared/ui` with a small, consistent props API: `variant`, `size`, `disabled`, `...rest` forwarded to the root element, `ref` as a prop (React 19) and `className` merging.
- Prefer headless accessible building blocks (Radix UI, React Aria, Headless UI, Ark) for dialogs, menus, comboboxes, tabs, tooltips. Hand-rolled versions usually miss keyboard and focus requirements (see `accessibility-responsive.md`).
- Storybook (if present): one story per state (default, loading, error, empty, disabled, long text, RTL). Use `@storybook/addon-a11y`. Stories double as visual regression targets.
- Do not duplicate a primitive that exists; extend it with a variant.

## 11. Pitfalls
- Z-index wars: define layers as tokens (`--z-dropdown`, `--z-modal`, `--z-toast`).
- Layout shift: reserve space for images, fonts, async content (skeletons with fixed dimensions).
- `outline: none` without a replacement focus style.
- Styles relying on color alone for meaning.
- Global CSS resets leaking into third-party widgets.
- Unused CSS: remove dead classes when deleting components.
