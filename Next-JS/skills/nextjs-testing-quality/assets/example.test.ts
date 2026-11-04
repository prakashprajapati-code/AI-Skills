// Example: unit-testing a Zod schema and a route handler. Adapt paths and names.
import { describe, expect, it } from "vitest";
import { createThingSchema } from "@/features/<domain>/schemas";
import { POST } from "@/app/api/<resource>/route";

describe("createThingSchema", () => {
  it("accepts a valid payload", () => {
    expect(createThingSchema.safeParse({ name: "Widget" }).success).toBe(true);
  });
  it("rejects empty and oversize names", () => {
    expect(createThingSchema.safeParse({ name: "" }).success).toBe(false);
    expect(createThingSchema.safeParse({ name: "x".repeat(101) }).success).toBe(false);
  });
});

describe("POST /api/<resource>", () => {
  const post = (body: unknown) =>
    POST(new Request("http://test/api/<resource>", { method: "POST", body: typeof body === "string" ? body : JSON.stringify(body) }));

  it("returns 400 for invalid JSON", async () => {
    expect((await post("{not json")).status).toBe(400);
  });
  it("returns 400 for invalid payload", async () => {
    expect((await post({ name: "" })).status).toBe(400);
  });
  // add: 401 without session, 403 for other user's resource, 201 happy path (with test DB or mocked service)
});
