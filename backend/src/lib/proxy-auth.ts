import { NextRequest, NextResponse } from "next/server";
import {
  consumeSolve,
  entitlementPayload,
  findCodeByValue,
  isUsable,
} from "./codes";
import { TOKEN_COSTS, type SolveKind } from "./plans";
import type { ActivationCodeRow } from "./db";

export function extractBearer(req: NextRequest): string | null {
  const header = req.headers.get("authorization");
  if (!header) return null;
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  if (!match) return null;
  const token = match[1].trim();
  return token.length > 0 ? token : null;
}

export function jsonError(
  status: number,
  message: string,
  code?: string,
): NextResponse {
  return NextResponse.json(
    { error: { message, code: code ?? "error" } },
    { status },
  );
}

export async function requireActivationCode(
  req: NextRequest,
): Promise<{ code: string; row: ActivationCodeRow } | NextResponse> {
  const token = extractBearer(req);
  if (!token) {
    return jsonError(401, "Missing activation code", "missing_activation_code");
  }
  const row = await findCodeByValue(token);
  if (!row) {
    return jsonError(401, "Invalid activation code", "invalid_activation_code");
  }
  if (row.status === "revoked") {
    return jsonError(403, "Activation code revoked", "code_revoked");
  }
  if (row.expires_at && new Date(row.expires_at) <= new Date()) {
    return jsonError(403, "Activation code expired", "code_expired");
  }
  if (row.status === "exhausted" || row.solves_used >= row.max_solves) {
    return jsonError(402, "Token quota exhausted", "quota_exhausted");
  }
  if (!isUsable(row)) {
    return jsonError(403, "Activation code not usable", "code_unusable");
  }
  return { code: token, row };
}

/** Validate + consume tokens before forwarding a billable request. */
export async function requireAndConsumeSolve(
  req: NextRequest,
  kind: SolveKind = "text",
): Promise<{ code: string; row: ActivationCodeRow } | NextResponse> {
  const auth = await requireActivationCode(req);
  if (auth instanceof NextResponse) return auth;

  const updated = await consumeSolve(auth.code, TOKEN_COSTS[kind]);
  if (!updated) {
    return jsonError(402, "Token quota exhausted", "quota_exhausted");
  }
  return { code: auth.code, row: updated };
}

export function entitlementResponse(row: ActivationCodeRow) {
  return NextResponse.json(entitlementPayload(row));
}
