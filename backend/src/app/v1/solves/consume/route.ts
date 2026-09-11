import { NextRequest, NextResponse } from "next/server";
import { consumeSolve, entitlementPayload } from "@/lib/codes";
import { jsonError, requireActivationCode } from "@/lib/proxy-auth";

export const runtime = "nodejs";

/**
 * Charge exactly one solve against the activation code.
 * Call once per completed question solve (not per OCR/LLM hop).
 */
export async function POST(req: NextRequest) {
  const auth = await requireActivationCode(req);
  if (auth instanceof Response) return auth;

  const updated = await consumeSolve(auth.code);
  if (!updated) {
    return jsonError(402, "Solve quota exhausted", "quota_exhausted");
  }
  return NextResponse.json({
    ok: true,
    entitlement: entitlementPayload(updated),
  });
}
