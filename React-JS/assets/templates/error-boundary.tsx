// Reusable error boundary (class component: the only way to catch render errors without a library).
// Place at app root, route level, and around independent widgets.
// If the project already uses `react-error-boundary`, use that instead of this file.
import { Component, type ErrorInfo, type ReactNode } from 'react';

type Props = {
  children: ReactNode;
  /** Render prop or node shown when a child throws. */
  fallback: ReactNode | ((args: { error: Error; reset: () => void }) => ReactNode);
  /** When any value changes (e.g. route, id), the boundary clears its error automatically. */
  resetKeys?: ReadonlyArray<unknown>;
  /** Report to monitoring (Sentry etc.). Never throw from here. */
  onError?: (error: Error, info: ErrorInfo) => void;
  onReset?: () => void;
};

type State = { error: Error | null };

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    try {
      this.props.onError?.(error, info);
    } catch {
      /* reporting must never break the fallback UI */
    }
  }

  componentDidUpdate(prev: Props) {
    if (this.state.error && haveKeysChanged(prev.resetKeys, this.props.resetKeys)) {
      this.reset();
    }
  }

  reset = () => {
    this.props.onReset?.();
    this.setState({ error: null });
  };

  render() {
    const { error } = this.state;
    if (error === null) return this.props.children;
    const { fallback } = this.props;
    return typeof fallback === 'function' ? fallback({ error, reset: this.reset }) : fallback;
  }
}

function haveKeysChanged(a: ReadonlyArray<unknown> = [], b: ReadonlyArray<unknown> = []) {
  return a.length !== b.length || a.some((item, i) => !Object.is(item, b[i]));
}

// Example fallback (accessible: role="alert", clear action, no raw error text shown to users)
export function DefaultErrorFallback({ reset }: { reset: () => void }) {
  return (
    <div role="alert">
      <h2>Something went wrong</h2>
      <p>We couldn&rsquo;t load this section. Please try again.</p>
      <button type="button" onClick={reset}>Try again</button>
    </div>
  );
}

/* Usage:
<ErrorBoundary
  fallback={({ reset }) => <DefaultErrorFallback reset={reset} />}
  resetKeys={[location.pathname]}
  onError={(error, info) => reportError(error, { componentStack: info.componentStack })}
>
  <Suspense fallback={<Skeleton />}>
    <OrdersWidget />
  </Suspense>
</ErrorBoundary>
*/
