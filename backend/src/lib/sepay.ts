import { timingSafeEqual } from "crypto";
import type { NextRequest } from "next/server";
import { PAY_CODE_PREFIX } from "./checkout";
import { getWebhookSecret } from "./vietqr";

export type SepayWebhookPayload = {
  id?: number | string;
  gateway?: string;
  transactionDate?: string;
  accountNumber?: string;
  subAccount?: string | null;
  code?: string | null;
  content?: string;
  transferType?: string;
  description?: string;
  transferAmount?: number;
  accumulated?: number;
  referenceCode?: string;
};

function secretsEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

/**
 * If a webhook secret is configured in admin, require
 * `Authorization: Apikey <secret>`. Otherwise allow (amount/STK/pay-code still required).
 */
export async function verifyWebhook(req: NextRequest): Promise<boolean> {
  const expected = await getWebhookSecret();
  if (!expected) return true;

  const header = req.headers.get("authorization") ?? "";
  const match = /^Apikey\s+(.+)$/i.exec(header.trim());
  if (!match) return false;
  return secretsEqual(match[1]!.trim(), expected);
}

const PAY_CODE_RE = new RegExp(
  `${PAY_CODE_PREFIX}[A-Z0-9]{8}`,
  "i",
);

/** Prefer SePay-extracted `code`, then scan content/description. */
export function extractPayCode(payload: SepayWebhookPayload): string | null {
  const candidates = [payload.code, payload.content, payload.description];
  for (const raw of candidates) {
    if (!raw || typeof raw !== "string") continue;
    const trimmed = raw.trim();
    if (!trimmed) continue;
    if (PAY_CODE_RE.test(trimmed) && trimmed.toUpperCase().startsWith(PAY_CODE_PREFIX)) {
      const exact = trimmed.toUpperCase().match(PAY_CODE_RE);
      if (exact) return exact[0]!.toUpperCase();
    }
    const found = trimmed.toUpperCase().match(PAY_CODE_RE);
    if (found) return found[0]!.toUpperCase();
  }
  return null;
}

export function parseSepayPayload(body: unknown): SepayWebhookPayload | null {
  if (!body || typeof body !== "object") return null;
  return body as SepayWebhookPayload;
}
