import { NextRequest, NextResponse } from "next/server";
import { requireActivationCode } from "@/lib/proxy-auth";

export const runtime = "nodejs";

/**
 * Connectivity probe used by the Flutter client.
 * Validates the activation code without calling Mathpix or consuming quota.
 */
export async function GET(req: NextRequest) {
  const auth = await requireActivationCode(req);
  if (auth instanceof Response) return auth;
  return NextResponse.json({
    ok: true,
    entitlement: {
      plan: auth.row.plan,
      max_solves: auth.row.max_solves,
      solves_used: auth.row.solves_used,
      remaining: Math.max(0, auth.row.max_solves - auth.row.solves_used),
      status: auth.row.status,
    },
  });
}
