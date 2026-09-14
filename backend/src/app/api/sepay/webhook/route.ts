import { NextRequest, NextResponse } from "next/server";
import { fulfillCheckout } from "@/lib/checkout";
import { getSql } from "@/lib/db";
import {
  extractPayCode,
  parseSepayPayload,
  verifyWebhook,
} from "@/lib/sepay";
import { getVietqrConfigOrNull } from "@/lib/vietqr";

export const runtime = "nodejs";

function ok() {
  return NextResponse.json({ success: true });
}

export async function POST(req: NextRequest) {
  if (!(await verifyWebhook(req))) {
    return NextResponse.json(
      { success: false, error: "Unauthorized" },
      { status: 401 },
    );
  }

  const body = await req.json().catch(() => null);
  const payload = parseSepayPayload(body);
  if (!payload) {
    return ok();
  }

  const txIdRaw = payload.id;
  const txId =
    typeof txIdRaw === "number"
      ? txIdRaw
      : typeof txIdRaw === "string"
        ? Number.parseInt(txIdRaw, 10)
        : NaN;

  // SePay test sends often use id 0 — still process but dedup carefully.
  if (!Number.isFinite(txId)) {
    return ok();
  }

  const sql = getSql();
  try {
    await sql`
      INSERT INTO sepay_events (id, payload)
      VALUES (${txId}, ${JSON.stringify(payload)})
    `;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (message.includes("unique") || message.includes("duplicate")) {
      return ok();
    }
    throw err;
  }

  if (payload.transferType && payload.transferType !== "in") {
    return ok();
  }

  const config = await getVietqrConfigOrNull();
  if (!config) {
    return ok();
  }

  const accountNumber = (payload.accountNumber ?? "").trim();
  if (
    accountNumber &&
    accountNumber.replace(/\s/g, "") !== config.account.replace(/\s/g, "")
  ) {
    return ok();
  }

  const payCode = extractPayCode(payload);
  if (!payCode) {
    return ok();
  }

  const amount =
    typeof payload.transferAmount === "number" ? payload.transferAmount : 0;
  if (amount <= 0) {
    return ok();
  }

  try {
    const result = await fulfillCheckout({
      payCode,
      sepayTxId: txId,
      paidAmountVnd: amount,
    });
    if (result) {
      await sql`
        UPDATE sepay_events
        SET matched_session = ${result.session.id}
        WHERE id = ${txId}
      `;
    }
  } catch (err) {
    console.error("sepay webhook fulfill failed", err);
    return NextResponse.json(
      { success: false, error: "Server error" },
      { status: 500 },
    );
  }

  return ok();
}
