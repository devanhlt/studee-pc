import { NextRequest, NextResponse } from "next/server";
import {
  expireStale,
  getIssuedActivationForSession,
  getSession,
  secretsEqual,
} from "@/lib/checkout";
import { jsonError } from "@/lib/proxy-auth";

export const runtime = "nodejs";

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const secret = req.nextUrl.searchParams.get("secret")?.trim() ?? "";
  if (!id || !secret) {
    return jsonError(400, "Missing id or secret", "missing_params");
  }

  let session = await getSession(id);
  if (!session) {
    return jsonError(404, "Checkout not found", "checkout_not_found");
  }
  if (!secretsEqual(session.client_secret, secret)) {
    return jsonError(403, "Invalid secret", "invalid_secret");
  }

  if (
    (session.status === "pending" || session.status === "claimed") &&
    new Date(session.expires_at) <= new Date()
  ) {
    session = (await expireStale(session.id)) ?? session;
  }

  const payload: Record<string, unknown> = {
    id: session.id,
    status: session.status,
    plan: session.plan,
    amount_vnd: session.amount_vnd,
    pay_code: session.pay_code,
    expires_at: session.expires_at,
  };

  if (session.status === "paid") {
    const issued = await getIssuedActivationForSession(session);
    if (issued?.code) payload.activation_code = issued.code;
    if (issued?.expiresAt) payload.code_expires_at = issued.expiresAt;
  }

  return NextResponse.json(payload);
}
