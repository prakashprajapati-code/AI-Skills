// In-memory sliding window. Resets on restart and is NOT shared across instances.
// For multi-instance or serverless production use Redis / an edge rate limiter instead.
const WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS ?? 60_000);
const MAX_HITS = Number(process.env.RATE_LIMIT_MAX ?? 5);
const MAX_KEYS = 10_000;
const hits = new Map<string, number[]>();

/** Trust x-forwarded-for only behind a proxy you control; document your proxy chain. */
export function getClientIp(request: Request): string {
  const forwarded = request.headers.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0].trim();
  return request.headers.get("x-real-ip")?.trim() || "unknown";
}

export function isRateLimited(request: Request, now = Date.now()): boolean {
  const ip = getClientIp(request);
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
  if (recent.length >= MAX_HITS) {
    hits.set(ip, recent);
    return true;
  }
  recent.push(now);
  hits.set(ip, recent);
  if (hits.size > MAX_KEYS) {
    for (const [key, times] of hits) {
      if (now - times[times.length - 1] >= WINDOW_MS) hits.delete(key);
    }
  }
  return false;
}
