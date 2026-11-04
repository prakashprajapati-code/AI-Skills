// next.config.ts: merge into your existing config.
import type { NextConfig } from "next";

const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  // Enable only when the whole site is served over HTTPS:
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
  // Add a Content-Security-Policy (start with Content-Security-Policy-Report-Only). See references/threat-checklist.md.
];

const nextConfig: NextConfig = {
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
  // allowedDevOrigins: ["<your-dev-tunnel-host>"], // local only; do not commit real hostnames
};

export default nextConfig;
