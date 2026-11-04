// features/<domain>/server/actions.ts
"use server";

import { revalidateTag } from "next/cache";
import { z } from "zod";
import { requireUser } from "@/lib/server/auth"; // <your auth helper: throws/redirects if no session>
import { can } from "@/lib/server/permissions"; // <your authorization check>
import { createThing } from "./service"; // <business logic + transaction>

const createThingSchema = z.object({
  name: z.string().trim().min(1, "Required").max(100),
  // add fields; keep caps on every string
});

export type ActionState =
  | { ok: true; data: { id: string } }
  | { ok: false; error: { code: "INVALID" | "FORBIDDEN" | "UNEXPECTED"; message: string; fieldErrors?: Record<string, string[]> } }
  | null;

export async function createThingAction(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const user = await requireUser(); // 1. authenticate

  const parsed = createThingSchema.safeParse(Object.fromEntries(formData)); // 2. validate
  if (!parsed.success) {
    return { ok: false, error: { code: "INVALID", message: "Please fix the highlighted fields.", fieldErrors: parsed.error.flatten().fieldErrors } };
  }

  if (!can(user, "thing:create")) {
    return { ok: false, error: { code: "FORBIDDEN", message: "You do not have permission." } }; // 3. authorize
  }

  try {
    const thing = await createThing(user.id, parsed.data); // 4. execute (transaction lives in the service)
    revalidateTag("things"); // 5. revalidate what changed
    return { ok: true, data: { id: thing.id } };
  } catch (error) {
    console.error("[createThingAction] failed", error); // log details server-side only
    return { ok: false, error: { code: "UNEXPECTED", message: "Something went wrong. Please try again." } };
  }
}
