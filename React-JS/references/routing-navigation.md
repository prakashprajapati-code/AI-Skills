# Routing and navigation

Read when adding or changing routes, navigation, guards, loaders, deep links, or code splitting. For Next.js file-based routing read `nextjs-app-router.md` as well.

Contents: 1. First, identify the router · 2. Universal rules · 3. React Router v7 · 4. TanStack Router · 5. Protected routes · 6. URL as state · 7. Navigation UX and a11y · 8. Testing routes

## 1. First, identify the router
Check `package.json` and the router file. Use what is installed; never add a second router.
- `react-router` / `react-router-dom` (v6 declarative, v7 data or framework mode)
- `@tanstack/react-router`
- Next.js (`app/` or `pages/`), Remix (merged into React Router v7 framework mode)
- Hand-rolled `window.location` routing: leave it unless asked, and do not extend it with new features.

## 2. Universal rules
- Define the route table in **one place** (`app/router.tsx`). Do not scatter `<Route>` definitions.
- Lazy-load route components (`React.lazy` or the router's `lazy`) so each route is its own chunk; wrap with `<Suspense>` and an error boundary (route-level `errorElement` / `ErrorBoundary`).
- Every router needs a **404 route** and a **route-level error UI**. A blank page on a bad URL is a bug.
- Build links with helpers or typed route objects, not string concatenation spread over the codebase. Encode params (`encodeURIComponent`) and never put secrets or tokens in URLs.
- Use real links for navigation: `<Link to>` / `<NavLink>` (renders `<a href>`), not `<button onClick={navigate}>`. That keeps middle-click, open-in-new-tab, crawlers and screen readers working. Use `navigate()` only for results of actions (after submit, after login).
- A hard refresh on any nested route must work. SPAs need a host fallback to `index.html` (see `release-readiness.md`).
- Scroll to top (or restore scroll) and move focus on route change; see section 7.

## 3. React Router v7 (modes)
React Router v7 has three modes; match the project's:
- **Declarative** (`<BrowserRouter>`, `<Routes>`): client-side only, no loaders.
- **Data** (`createBrowserRouter`, `RouterProvider`): `loader`, `action`, `errorElement`, `lazy`, `useNavigation`, `<Form>`.
- **Framework** (Vite plugin, `routes.ts`, typed route modules, SSR/SSG optional): the former Remix.

Guidance:
- With loaders, fetch route-critical data in the `loader` so navigation starts the request before render (avoids waterfalls). Return plain data. If the project uses TanStack Query, call `queryClient.ensureQueryData` inside the loader so loader and components share one cache.
- Use `action` + `<Form>` for mutations and let the router revalidate; do not duplicate with manual refetching.
- Use `useNavigation().state` for global pending UI; `useRouteError` inside `errorElement`.
- Framework mode loaders/actions run on the server: treat them as public endpoints (authenticate, authorize, validate). See `security-privacy.md`.
- v6 to v7 is mostly import changes (`react-router-dom` re-exports from `react-router`) plus future flags; follow `migration-upgrades.md`.

```tsx
// router.tsx (data mode sketch)
const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <RouteError />,
    children: [
      { index: true, lazy: () => import('./routes/home') },
      { path: 'orders/:orderId', lazy: () => import('./routes/order-detail') },
      { path: '*', element: <NotFound /> },
    ],
  },
]);
```

## 4. TanStack Router
- Fully type-safe paths, params and search params. Prefer its generated route tree; do not hand-edit generated files.
- Validate search params with a schema (`validateSearch` + Zod) so the URL is a typed contract.
- Use `beforeLoad` for auth guards and `loader` with the shared query client for data.

## 5. Protected routes
- A guard is **UX only**. The server must enforce access on every request (see `security-privacy.md`).
- Do the check in the router (loader / `beforeLoad` / layout route) so protected content never flashes. Redirect to sign-in with a validated `returnTo` (same-origin relative path only, never a full URL: open-redirect risk), then send the user back after login.
- Handle three states explicitly: unknown (still loading session; show skeleton), signed out (redirect), forbidden (403 page, not a redirect loop).
- Role-based UI hiding is cosmetic. Never rely on it for authorization.

```tsx
function RequireAuth() {
  const { status } = useSession();            // 'loading' | 'authenticated' | 'anonymous'
  const location = useLocation();
  if (status === 'loading') return <PageSkeleton />;
  if (status === 'anonymous') {
    const returnTo = location.pathname + location.search;   // relative only
    return <Navigate to={`/login?returnTo=${encodeURIComponent(returnTo)}`} replace />;
  }
  return <Outlet />;
}
```

## 6. URL as state
- Anything the user would expect to survive refresh, back/forward or sharing belongs in the URL: filters, sort, page, selected tab, search query, open item id.
- Keep it in search params (`useSearchParams`) rather than duplicating in `useState`. Derive UI from the URL (single source of truth).
- Debounce text inputs before writing to the URL; use `replace` (not `push`) for incremental changes so Back is not polluted.
- Parse and validate params. Treat `?page=abc` as invalid input, fall back to defaults.

## 7. Navigation UX and accessibility
- Update `document.title` per route (framework `meta`/`<title>` support, or a small hook). Screen-reader users rely on it.
- On route change, move focus to the page heading or main landmark (`tabIndex={-1}` + `focus()`), and announce via a polite live region when the framework does not do it.
- Mark the current link (`aria-current="page"`; `NavLink` does this).
- Prefetch likely next routes on hover/intent (router `prefetch`/`preload`), not everything.
- Show a pending indicator for slow transitions; keep the old screen visible (use transitions) instead of flashing blank.
- Preserve scroll position on back navigation; scroll to top on new navigation.

## 8. Testing routes
- Render with a memory router (`createMemoryRouter` / `MemoryRouter`, TanStack `createMemoryHistory`) at a specific URL and assert what the user sees.
- Test: guard redirect when signed out, returnTo after login, 404 page, error element when a loader throws, params parsing.
