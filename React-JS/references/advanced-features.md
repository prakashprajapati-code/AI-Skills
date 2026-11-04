# Advanced feature patterns

Read when building real-time features, file uploads, search/autocomplete, tables, charts, rich text, payments, PWA/offline, or Web Workers.

Contents: 1. Real-time (WebSocket/SSE) · 2. File upload and download · 3. Search and autocomplete · 4. Tables, large data, infinite scroll · 5. Charts and maps · 6. Rich text and Markdown · 7. Payments and third-party widgets · 8. PWA and offline · 9. Web Workers and heavy work · 10. Auth UI flows · 11. Clipboard, dates, misc

## 1. Real-time (WebSocket / SSE / polling)
- Choose the simplest transport: **polling** (query `refetchInterval`) for slow-changing data; **SSE** for one-way server push; **WebSocket** for two-way low-latency (chat, collaboration). Use the project's existing channel/client.
- Wrap the connection in a **custom hook** with cleanup in the effect return; one connection per app/feature, not per component. Use `useEffectEvent` (19.2) or a ref for the latest message handler so the socket is not recreated.
- Reconnect with exponential backoff and jitter; resume from the last event ID if the protocol supports it; show a connection status indicator; pause when the tab is hidden if appropriate.
- Treat incoming messages as **untrusted input**: validate with a schema before updating state; never `dangerouslySetInnerHTML` them.
- Merge pushes into the query cache (`queryClient.setQueryData`) instead of keeping a second store. Throttle/batch high-frequency updates (`requestAnimationFrame`, `startTransition`).
- Authenticate the connection (cookie or short-lived ticket), not a long-lived token in the URL.
- Test with a fake socket/`mock-socket`; cover reconnect, duplicate and out-of-order messages.

## 2. File upload and download
- Validate on the client for UX (type, size, count, dimensions) **and on the server** for security. Never trust extension or `Content-Type`.
- Prefer **direct-to-storage uploads** with pre-signed URLs (S3/GCS/Azure) for big files; use multipart/resumable (tus, S3 multipart) beyond ~100 MB. Send progress with `XMLHttpRequest.upload.onprogress` or a library (axios `onUploadProgress`); `fetch` has no upload progress yet.
- UI: drag-and-drop **plus** a real `<input type="file">` (keyboard and screen-reader accessible), `accept` attribute, progress, cancel (`AbortController`), retry, per-file errors, and preview via `URL.createObjectURL` (revoke it on cleanup).
- Compress/resize images client-side before upload when sensible. Strip EXIF location for privacy where relevant.
- Downloads: `<a href download>` for static URLs; for generated blobs create an object URL and revoke it. Sanitize filenames. Large exports should be server-generated jobs, not a freezing client loop.
- Never render uploaded SVG/HTML inline from untrusted users; serve from a separate origin or with safe headers.

## 3. Search and autocomplete
- Debounce input (250 to 400 ms) and cancel stale requests (`AbortController` or keyed queries). Ignore out-of-order responses. Show loading, empty, and error states.
- Keep the query in the URL when results are shareable (see `routing-navigation.md`).
- Accessible combobox: use a headless library (Downshift, React Aria, Radix/Ariakit); otherwise follow the ARIA combobox pattern (`role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant`, Arrow/Enter/Escape keys, live region announcing result counts).
- Highlight matches with elements, not injected HTML. Escape regex special characters if building a `RegExp` from user text.
- `useDeferredValue` or `startTransition` keeps typing responsive when filtering large local lists.

## 4. Tables, large data, infinite scroll
- Use a headless table library (TanStack Table) when you need sorting, filtering, pagination, column visibility; use semantic `<table>`, `<th scope>`, `<caption>` for tabular data.
- **Server-side** pagination/sorting/filtering for big datasets; send page, size, sort, filter to the API and keep them in the URL. Prefer **cursor** pagination for changing data.
- Virtualize long lists/tables (TanStack Virtual, react-window) beyond hundreds of rows; keep keyboard navigation and a stable row height or measured sizes.
- Infinite scroll: use `IntersectionObserver` on a sentinel; keep a "Load more" button as the accessible fallback; preserve scroll position on back; cap DOM size.
- Sticky headers and horizontal scroll: wrap in a labelled, focusable scroll container; do not break semantics.
- Selection and bulk actions: announce counts via live region; confirm destructive actions; support undo where possible.

## 5. Charts and maps
- Use the project's chart library (Recharts, Visx, ECharts, Chart.js, Nivo). Lazy-load it (heavy). Give each chart a text summary or data table alternative, a title, units, and non-color encodings (patterns, labels).
- Memoize data transformations; avoid re-creating `options` objects each render for imperative libs. Resize with `ResizeObserver`; dispose instances on unmount.
- Maps (Leaflet, MapLibre, Google Maps): lazy-load, handle no-WebGL and key/quotas, provide a list alternative, restrict API keys by referrer, and do not geocode on every keystroke.

## 6. Rich text and Markdown
- Use a maintained editor (TipTap/ProseMirror, Lexical, Slate, Quill) rather than `contentEditable` by hand. Store a structured format (JSON/Markdown) and sanitize any HTML output.
- Render Markdown with `react-markdown` (+ `remark-gfm`, `rehype-sanitize`) which avoids `dangerouslySetInnerHTML`. If you must use raw HTML, sanitize with DOMPurify first (see `security-privacy.md`).
- Syntax highlighting and heavy editors load lazily.

## 7. Payments and third-party widgets
- Use the provider's hosted fields/Elements/Checkout (Stripe, Razorpay, PayPal, Adyen). Card data must **never** touch your servers or state. Confirm payments on the **server** (webhooks), not from the client's success callback alone.
- Idempotency keys on payment creation; disable the pay button while pending; handle 3-D Secure/redirect returns; show clear failure states.
- Load third-party scripts lazily with `async`, SRI if offered; allow their origins in CSP narrowly; wrap in an error boundary so a widget failure does not break checkout.
- Keep API keys in the correct class: **publishable** keys in the client, **secret** keys only on the server.

## 8. PWA and offline
- Only add a service worker if offline/installability is a requirement (Workbox, `vite-plugin-pwa`). A buggy service worker can pin users to stale builds: version it, `skipWaiting`/update prompt UX, and test the update path.
- Cache static assets (cache-first with hashed names), API data carefully (stale-while-revalidate), never cache authenticated responses in shared caches.
- Provide a web app manifest (name, icons, `display`, theme color), an offline fallback page, and an "update available" prompt.
- Handle offline writes with a queue and conflict strategy, or disable the actions clearly.

## 9. Web Workers and heavy work
- Move CPU-heavy work (parsing big CSV/JSON, image processing, diffing, search indexing) to a Web Worker (Comlink helps); keep the main thread free for input. Transfer large buffers (`transferable`) instead of copying.
- For work that cannot move, chunk it (`scheduler.yield()`, `requestIdleCallback`, `setTimeout` slicing) or use `startTransition` for non-urgent UI updates.
- Lazy-load worker code and terminate workers on unmount.

## 10. Auth UI flows
- Pages: sign-in, sign-up, forgot/reset password, verify email, MFA, sessions/devices, sign-out. Use `autocomplete` (`username`, `current-password`, `new-password`, `one-time-code`) and `type="password"` with a show/hide toggle that is keyboard accessible.
- Generic error messages for credentials (no account enumeration); rate-limit feedback; lockout messaging.
- After login: redirect to a **validated** same-origin `returnTo`. After logout: clear client caches (query cache, local state, stores) so the next user does not see old data.
- Prefer a hosted/provider flow (OIDC/OAuth with PKCE, Auth0, Clerk, Auth.js, Cognito) over custom crypto. Session in `HttpOnly` cookies where possible (see `security-privacy.md`). Handle session expiry mid-use: save draft input, prompt re-auth, resume.
- Multi-tab: sync sign-out across tabs (`storage` event or `BroadcastChannel`).

## 11. Clipboard, dates, misc
- Clipboard: `navigator.clipboard.writeText` needs a secure context and a user gesture; handle rejection and show feedback ("Copied") via a live region.
- Dates: store UTC, parse ISO strings explicitly, use `Temporal` (when supported/polyfilled), `date-fns`, or `Intl`; avoid `new Date('YYYY-MM-DD')` pitfalls (parsed as UTC) and moment.js in new code.
- IDs: `useId` for DOM ids; `crypto.randomUUID()` for client-generated ids; never `Math.random()` for security.
- Lists with drag-and-drop reorder: use dnd-kit with keyboard sensors and announcements.
- Toasts: one toast system, `role="status"`/`aria-live`, auto-dismiss only for non-critical info with enough time (or pause on hover/focus).
