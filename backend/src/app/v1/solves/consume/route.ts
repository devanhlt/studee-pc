import { NextRequest, NextResponse } from "next/server";
import { consumeSolve, entitlementPayload } from "@/lib/codes";
import { isSolveKind, TOKEN_COSTS } from "@/lib/plans";
import { jsonError, requireActivationCode } from "@/lib/proxy-auth";

export const runtime = "nodejs";

/**
 * Charge tokens for one question solve (`kind`: text | picture).
 * Call once per completed question (not per OCR/LLM hop).
 */
export async function POST(req: NextRequest) {
  const auth = await requireActivationCode(req);
  if (auth instanceof Response) return auth;

  const body = (await req.json().catch(() => null)) as { kind?: unknown } | null;
  const kind = body?.kind;
  if (!isSolveKind(kind)) {
    return jsonError(400, "Invalid solve kind", "invalid_solve_kind");
  }

  const updated = await consumeSolve(auth.code, TOKEN_COSTS[kind]);
  if (!updated) {
    return jsonError(402, "Token quota exhausted", "quota_exhausted");
  }
  return NextResponse.json({
    ok: true,
    entitlement: entitlementPayload(updated),
  });
}
