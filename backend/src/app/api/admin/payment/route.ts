import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import {
  getPaymentSettings,
  qrImageUrl,
  savePaymentSettings,
} from "@/lib/vietqr";

export const runtime = "nodejs";

function webhookUrlFromRequest(req: NextRequest): string {
  const host =
    req.headers.get("x-forwarded-host") ??
    req.headers.get("host") ??
    "localhost:3000";
  const proto =
    req.headers.get("x-forwarded-proto") ??
    (host.includes("localhost") ? "http" : "https");
  return `${proto}://${host}/api/sepay/webhook`;
}

export async function GET(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }

  const settings = await getPaymentSettings();
  let preview_qr_url: string | null = null;
  if (settings.bank && settings.account && settings.holder) {
    preview_qr_url = qrImageUrl({
      amountVnd: 19000,
      payCode: "STUDEEPREVIEW",
      config: {
        bank: settings.bank,
        account: settings.account,
        holder: settings.holder,
      },
    });
  }

  return NextResponse.json({
    bank: settings.bank,
    account: settings.account,
    holder: settings.holder,
    webhook_url: webhookUrlFromRequest(req),
    webhook_secret_present: settings.webhookSecretPresent,
    webhook_secret_masked: settings.webhookSecretMasked,
    preview_qr_url,
  });
}

export async function PUT(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }

  const body = (await req.json().catch(() => null)) as {
    bank?: string;
    account?: string;
    holder?: string;
    webhook_secret?: string | null;
    clear_webhook_secret?: boolean;
  } | null;

  try {
    await savePaymentSettings({
      bank: body?.bank ?? "",
      account: body?.account ?? "",
      holder: body?.holder ?? "",
      webhookSecret: body?.webhook_secret,
      clearWebhookSecret: body?.clear_webhook_secret === true,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Save failed";
    return NextResponse.json(
      { error: { message, code: "invalid_payment_settings" } },
      { status: 400 },
    );
  }

  const settings = await getPaymentSettings();
  let preview_qr_url: string | null = null;
  if (settings.bank && settings.account && settings.holder) {
    preview_qr_url = qrImageUrl({
      amountVnd: 19000,
      payCode: "STUDEEPREVIEW",
      config: {
        bank: settings.bank,
        account: settings.account,
        holder: settings.holder,
      },
    });
  }

  return NextResponse.json({
    ok: true,
    bank: settings.bank,
    account: settings.account,
    holder: settings.holder,
    webhook_url: webhookUrlFromRequest(req),
    webhook_secret_present: settings.webhookSecretPresent,
    webhook_secret_masked: settings.webhookSecretMasked,
    preview_qr_url,
  });
}
