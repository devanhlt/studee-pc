import { NextRequest, NextResponse } from "next/server";
import { getPackagesAppDisplayEnabled } from "@/lib/app-settings";
import {
  countRecentSessions,
  createSession,
} from "@/lib/checkout";
import { getPackageById } from "@/lib/packages";
import { jsonError } from "@/lib/proxy-auth";
import {
  getVietqrConfigOrNull,
  qrImageUrl,
} from "@/lib/vietqr";

export const runtime = "nodejs";

const MAX_CHECKOUTS_PER_HOUR = 40;

export async function POST(req: NextRequest) {
  if (!(await getPackagesAppDisplayEnabled())) {
    return jsonError(
      403,
      "In-app package sales are temporarily disabled",
      "packages_disabled",
    );
  }

  const body = (await req.json().catch(() => null)) as {
    plan?: string;
    contact?: string;
  } | null;

  const plan = body?.plan?.trim() ?? "";
  const pkg = plan ? await getPackageById(plan) : null;
  if (!pkg || !pkg.active) {
    return jsonError(400, "Invalid plan", "invalid_plan");
  }

  const config = await getVietqrConfigOrNull();
  if (!config) {
    return jsonError(
      503,
      "Payment QR is not configured yet",
      "vietqr_not_configured",
    );
  }

  const recent = await countRecentSessions(1);
  if (recent >= MAX_CHECKOUTS_PER_HOUR) {
    return jsonError(
      429,
      "Too many checkout requests. Try again later.",
      "checkout_rate_limited",
    );
  }

  const session = await createSession({
    plan: pkg.id,
    contact: body?.contact ?? null,
  });

  const qr_url = qrImageUrl({
    amountVnd: session.amount_vnd,
    payCode: session.pay_code,
    config,
  });

  return NextResponse.json({
    id: session.id,
    client_secret: session.client_secret,
    pay_code: session.pay_code,
    plan: session.plan,
    amount_vnd: session.amount_vnd,
    qr_url,
    bank: config.bank,
    account: config.account,
    account_holder: config.holder,
    expires_at: session.expires_at,
  });
}
