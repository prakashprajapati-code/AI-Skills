// app/api/<resource>/route.ts - keep thin; logic belongs in a service.
import { NextResponse } from "next/server";
import { z } from "zod";
import { requireUserForApi } from "@/lib/server/auth"; // <returns user or null; do not redirect in APIs>
import { createThing } from "@/features/<domain>/server/service";

export const runtime = "nodejs"; // DB drivers, nodemailer and fs need Node, not edge

const bodySchema = z.object({ name: z.string().trim().min(1).max(100) });

const json = (body: unknown, status: number) => NextResponse.json(body, { status });

export async function POST(request: Request) {
  const user = await requireUserForApi(request);
  if (!user) return json({ ok: false, error: { code: "UNAUTHENTICATED", message: "Sign in required." } }, 401);

  let raw: unknown;
  try {
    raw = await request.json();
  } catch {
    return json({ ok: false, error: { code: "INVALID", message: "Invalid JSON." } }, 400);
  }

  const parsed = bodySchema.safeParse(raw);
  if (!parsed.success) {
    return json({ ok: false, error: { code: "INVALID", message: "Validation failed.", fieldErrors: parsed.error.flatten().fieldErrors } }, 400);
  }

  try {
    const thing = await createThing(user.id, parsed.data);
    return json({ ok: true, data: { id: thing.id } }, 201);
  } catch (error) {
    console.error("[POST /api/<resource>] failed", error);
    return json({ ok: false, error: { code: "UNEXPECTED", message: "Something went wrong." } }, 500);
  }
}
