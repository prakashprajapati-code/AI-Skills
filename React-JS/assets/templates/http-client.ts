// One HTTP client per app: base URL, credentials, timeout, error normalization, safe retry, single-flight refresh.
// Adapt to the project (axios/ky/ofetch may already exist: use them instead of this file).
import { env } from './env';

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly requestId?: string,
    public readonly fieldErrors?: Record<string, string[]>,
  ) {
    super(message);
    this.name = 'ApiError';
  }
  get isUnauthorized() { return this.status === 401; }
  get isForbidden() { return this.status === 403; }
  get isNotFound() { return this.status === 404; }
  get isRetryable() { return this.status === 408 || this.status === 429 || this.status >= 500; }
}

type RequestOptions = Omit<RequestInit, 'body'> & {
  body?: unknown;
  timeoutMs?: number;
  /** Retry only idempotent requests. Defaults: GET/HEAD = 2 retries, others = 0. */
  retries?: number;
  /** Required for non-idempotent writes that may be retried or double-clicked. */
  idempotencyKey?: string;
};

const DEFAULT_TIMEOUT_MS = 15_000;
const IDEMPOTENT = new Set(['GET', 'HEAD', 'OPTIONS']);

let refreshInFlight: Promise<boolean> | null = null;
async function refreshSession(): Promise<boolean> {
  // Single-flight: ten parallel 401s trigger one refresh.
  refreshInFlight ??= fetch(`${env.API_URL}/auth/refresh`, { method: 'POST', credentials: 'include' })
    .then((r) => r.ok)
    .catch(() => false)
    .finally(() => { refreshInFlight = null; });
  return refreshInFlight;
}

export async function http<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const method = (options.method ?? 'GET').toUpperCase();
  const maxRetries = options.retries ?? (IDEMPOTENT.has(method) ? 2 : 0);
  let attempt = 0;
  let refreshed = false;

  for (;;) {
    const timeout = AbortSignal.timeout(options.timeoutMs ?? DEFAULT_TIMEOUT_MS);
    const signal = options.signal ? AbortSignal.any([options.signal, timeout]) : timeout;

    try {
      const res = await fetch(`${env.API_URL}${path}`, {
        ...options,
        method,
        signal,
        credentials: 'include',
        headers: {
          Accept: 'application/json',
          ...(options.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
          ...(options.idempotencyKey ? { 'Idempotency-Key': options.idempotencyKey } : {}),
          ...options.headers,
        },
        body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
      });

      if (res.status === 401 && !refreshed && !path.startsWith('/auth/')) {
        refreshed = true;
        if (await refreshSession()) continue;           // retry once after refresh, never loop
      }
      if (!res.ok) throw await toApiError(res);
      return (res.status === 204 ? undefined : await res.json()) as T;
    } catch (err) {
      const apiErr = err instanceof ApiError ? err : null;
      const aborted = options.signal?.aborted === true;                     // caller cancelled: do not retry
      const retryable = apiErr ? apiErr.isRetryable : !aborted;            // network error/timeouts are retryable
      if (!aborted && retryable && attempt < maxRetries) {
        attempt += 1;
        await sleep(backoff(attempt));
        continue;
      }
      throw err;
    }
  }
}

async function toApiError(res: Response): Promise<ApiError> {
  let body: any = null;
  try { body = await res.json(); } catch { /* non-JSON error body */ }
  return new ApiError(
    res.status,
    body?.code ?? `HTTP_${res.status}`,
    body?.message ?? res.statusText ?? 'Request failed',
    res.headers.get('x-request-id') ?? undefined,
    body?.fieldErrors,
  );
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const backoff = (attempt: number) => Math.min(1000 * 2 ** (attempt - 1), 8000) * (0.5 + Math.random() / 2); // jitter

/* Service layer example (no React here, validated, typed):
export const ordersApi = {
  list: async (signal?: AbortSignal) => OrderListSchema.parse(await http('/orders', { signal })),
  create: async (input: NewOrder) =>
    OrderSchema.parse(await http('/orders', { method: 'POST', body: input, idempotencyKey: crypto.randomUUID() })),
};
*/
