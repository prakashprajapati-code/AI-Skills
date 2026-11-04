---
name: nextjs-ui-accessibility
description: UI, design system, accessibility (WCAG 2.2 AA) and responsive layout for Next.js - design tokens, Tailwind or CSS variables theming, dark mode without flash, reusable components, semantic HTML, forms with labels and error states, keyboard navigation, focus management, dialogs and menus, color contrast, reduced motion, mobile-first responsive design. Use this skill whenever the user builds or styles a component, page, form, navigation, modal or table in a Next.js project, adds dark mode or a theme, asks about accessibility, ARIA, keyboard support, contrast or screen readers, or fixes layout on mobile.
---

# Next.js: UI, Accessibility and Responsiveness

Build components that look consistent because they share tokens, work for everyone because they start from semantic HTML, and adapt because they start from the smallest screen.

## Principles (and why)
1. **Semantic HTML first, ARIA last.** A `<button>` gives focus, Enter/Space, and role for free; a clickable `<div>` needs all of that rebuilt (and usually isn't).
2. **Tokens, not literals.** Colors, spacing, radii, type sizes come from named tokens, so a re-theme or dark mode touches one file, not every component.
3. **Components are small, composable, and domain-free.** `Button`, `Input`, `Dialog` know nothing about invoices.
4. **Every state is designed:** default, hover, focus-visible, active, disabled, loading, empty, error, success.
5. **Mobile-first, content-driven breakpoints.** Start with the small layout, add complexity upward.
6. **Accessibility is a behavior, not an audit.** Keyboard, focus and announcements are tested as part of the component.

## Design system rules
1. **[MUST]** Define tokens once (CSS variables, or Tailwind v4 `@theme`): color roles (`background`, `foreground`, `primary`, `muted`, `border`, `danger`), spacing scale, radius, typography scale, shadows. Components use role names (`bg-primary`), never raw hex.
2. **[MUST]** Theme via a class or `data-theme` attribute on `<html>` with CSS variable overrides. Dark mode: use `next-themes` or a tiny inline script before paint, and `suppressHydrationWarning` on `<html>` only, to avoid theme flash and hydration warning. Respect `prefers-color-scheme` by default.
3. **[MUST]** One `cn()` helper (`clsx` + `tailwind-merge`) for conditional classes; variants via `class-variance-authority` or a typed variant map. Token and theme snippets are in `references/forms-and-keyboard.md`.
4. **[SHOULD]** Build primitives on an accessible headless library (Radix UI, React Aria, Headless UI, Ark) for dialogs, menus, tabs, popovers, comboboxes rather than hand-rolling focus traps and ARIA.
5. **[SHOULD]** Document components in one place (Storybook or a simple `/design` route) with all states; prefer a small API (few props, `className` passthrough, `asChild`/slots) over prop explosions.
6. **[SHOULD]** Use `next/image`, `next/font` and SVG icon components (single icon library) for consistent assets; icon-only buttons need an accessible name.

## Accessibility rules (WCAG 2.2 AA)
1. **[MUST]** Landmarks and headings: one `<h1>` per page, ordered heading levels, `<header> <nav> <main> <footer>`, a "Skip to content" link as the first focusable element.
2. **[MUST]** Every interactive element reachable and operable by keyboard; visible `:focus-visible` outline (never `outline: none` without replacement); logical tab order; no keyboard traps.
3. **[MUST]** Forms: every input has a `<label htmlFor>`; help text and errors linked with `aria-describedby`; invalid fields get `aria-invalid="true"`; errors are announced (`role="alert"` or live region) and the first invalid field gets focus on submit; do not rely on placeholder as label; correct `type`, `autocomplete`, `inputMode`. Details: `references/forms-and-keyboard.md`.
4. **[MUST]** Color contrast: text 4.5:1 (3:1 for large text and UI boundaries); never use color alone to convey meaning (add icon/text).
5. **[MUST]** Images: meaningful `alt`; decorative `alt=""`. Media: captions for video; no autoplay with sound.
6. **[MUST]** Dialogs/menus: focus moves in on open, is trapped while modal, returns to the trigger on close; `Escape` closes; background inert; use `<dialog>` or a headless library.
7. **[MUST]** Respect `prefers-reduced-motion` (disable parallax/large transitions); no flashing > 3 times/second.
8. **[MUST]** Targets at least 24x24 CSS px (aim 44x44 on touch); text can scale to 200% and reflow at 320 px width without horizontal scroll.
9. **[SHOULD]** Announce route changes and async results for screen readers (Next.js route announcer handles titles: ensure each page has a unique `<title>`); use `aria-live="polite"` for toasts/status; `aria-busy` for loading regions.
10. **[SHOULD]** Use `lang` on `<html>` (and on foreign-language snippets); links have descriptive text ("Read the pricing guide", not "click here"); links navigate, buttons act.
11. **[SHOULD]** Tables: `<th scope>` and `<caption>`; make responsive via horizontal scroll container with focusable region, or card layout on small screens.

## React accessibility patterns
1. **[MUST]** Use `htmlFor` (not `for`), `className`, and camelCase ARIA/event props in JSX; give each field a label via `useId` + `<label htmlFor={id}>`, and link errors with `aria-describedby` and `aria-invalid`.
2. **[MUST]** Manage focus with refs: move focus into a dialog/menu on open, return it to the trigger on close, focus the first invalid field or error summary after a failed submit.
3. **[SHOULD]** Prefer native `<dialog>`, `<button>`, `<details>`, or a headless library (Radix, React Aria) over custom `div` widgets.
4. **[SHOULD]** Announce async results with a polite live region (`role="status"`); keep it mounted and change its text.
5. **[SHOULD]** Render modals/tooltips with a portal so stacking and `overflow` do not clip them; keep keyboard order sensible.
6. Never put interactive handlers on non-interactive elements without role, tabIndex and key handling; use a `<button>`.
Details: `../nextjs-rendering-react/references/react-patterns.md` sections 5, 9, 10.

## Responsive rules
1. **[MUST]** `<meta viewport>` is on by default in Next.js; never disable zoom.
2. **[MUST]** Mobile-first utilities (`base`, then `sm:`, `md:`, `lg:`); test at 320, 375, 768, 1024, 1440 px; no horizontal scrolling of the page.
3. **[SHOULD]** Fluid type and spacing (`clamp()`), container queries for components that live in varying widths, CSS grid/flex over fixed widths, `min-h-dvh` instead of `100vh` for mobile browsers.
4. **[SHOULD]** Reserve space for images/embeds (aspect-ratio) to avoid layout shift (`nextjs-performance`).
5. **[SHOULD]** Touch vs hover: do not hide essential actions behind hover; use `@media (hover: hover)` for hover-only polish.

## Workflow: new component
1. Pick the semantic element and the headless primitive (if any).
2. List states and variants; write the token-based styles.
3. Keyboard path: Tab, Shift+Tab, Enter/Space, Escape, arrows where relevant.
4. Add accessible name/description; test with a screen reader quick pass (VoiceOver/NVDA).
5. Check at 320 px and 200% zoom; check dark theme and contrast.
6. Add a test: role/label queries with Testing Library (`getByRole`), and `jest-axe`/`axe-core` or Playwright + `@axe-core/playwright` for automated checks.

## Pitfalls
- `div onClick` instead of `button`; `a` without `href`; `button` that navigates.
- Removing the focus ring because "it looks ugly".
- Placeholder-only inputs; error text that is only red.
- Theme flash: reading the theme in `useEffect` instead of before paint.
- Modal implemented with `position: fixed` but background still tabbable.
- z-index wars: define a z-index scale in tokens.
- Automated tools (axe, Lighthouse) catch ~30-40% of issues: keyboard and screen-reader passes are still required.

## Verification checklist
- [ ] Only tokens used for color/spacing; light and dark themes both checked; no theme flash
- [ ] Keyboard-only pass: everything reachable, visible focus, dialogs trap and restore focus
- [ ] Forms labelled, errors announced and linked, correct input types/autocomplete
- [ ] Contrast >= 4.5:1; meaning not by color alone; reduced motion honored
- [ ] 320 px, 768 px, 1440 px layouts work; 200% zoom reflows
- [ ] axe/Lighthouse accessibility run clean on touched pages

## Related skills
`nextjs-performance` (CLS, images, fonts), `nextjs-seo` (semantic structure also helps crawlers), `nextjs-testing-quality` (component and a11y tests).
