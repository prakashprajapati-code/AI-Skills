# Accessibility and responsive design

Read when building or changing UI: forms, buttons, dialogs, menus, layout, animation.

Accessibility problems are usually built in by choosing the wrong element at the start. Getting the markup right first removes most of the work.

- Use semantic elements: `button` for actions, `a` for navigation, `nav`, `main`, `header`, headings in order, lists for lists. A clickable `div` has no keyboard support, role or focus; do not use it.
- Give every control an accessible name: a visible `<label>`, text content, or `aria-label` when there is no visible text (icon-only buttons). Prefer native semantics over ARIA; use ARIA only to fill gaps.
- Support full keyboard navigation and keep a visible focus indicator. Never remove the outline without a clear replacement.
- Keep focus order logical (matches visual order). Avoid positive `tabindex`. Use `tabindex="-1"` only for programmatic focus targets.
- Maintain readable contrast (WCAG AA: 4.5:1 for normal text, 3:1 for large text and UI components).
- Provide meaningful `alt` text for informative images; use `alt=""` for decorative ones so screen readers skip them.
- Support mobile layouts, browser zoom to 200% and text scaling. Use relative units (`rem`, `%`, `clamp`), avoid fixed heights on text containers, and test narrow widths. Never disable pinch-zoom.
- Respect reduced motion: wrap non-essential animation in `@media (prefers-reduced-motion: reduce)` or check the preference in JS.
- Make dialogs, menus and validation feedback accessible:
  - Dialogs: `role="dialog"` (or native `<dialog>`), labelled, focus moved in on open, trapped while open, Escape closes, focus returns to the trigger.
  - Menus and popovers: keyboard operable, announce expanded state with `aria-expanded`.
  - Validation: associate errors with fields (`aria-describedby`, `aria-invalid`), and announce submission results with a live region or by moving focus to an error summary.
- Do not communicate important status through color alone. Pair color with text, an icon or a pattern (error text, not just a red border).

Verify when you can: tab through the UI yourself, and run the project's a11y tooling (`eslint-plugin-jsx-a11y`, `axe`, Testing Library role queries) if present.

See also: `styling-theming.md` (focus styles, reduced motion, dark-mode contrast, responsive units), `routing-navigation.md` (focus and title on route change), `testing.md` (axe and keyboard tests), `i18n-seo-analytics.md` (lang, RTL).
