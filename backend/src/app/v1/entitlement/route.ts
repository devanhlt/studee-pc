import { NextRequest } from "next/server";
import { entitlementPayload, findCodeByValue } from "@/lib/codes";
import { extractBearer, jsonError } from "@/lib/proxy-auth";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET(req: NextRequest) {
  const token = extractBearer(req);
  if (!token) {
    return jsonError(401, "Missing activation code", "missing_activation_code");
  }
  const row = await findCodeByValue(token);
  if (!row) {
    return jsonError(401, "Invalid activation code", "invalid_activation_code");
  }
  return NextResponse.json(entitlementPayload(row));
}
