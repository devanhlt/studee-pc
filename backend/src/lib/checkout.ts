import { randomBytes, timingSafeEqual } from "crypto";
import { getSql, type CheckoutSessionRow } from "./db";
import { createCode } from "./codes";
import {
  codeExpiresAtFromNow,
  isPlanId,
  PLAN_PRESETS,
  type PlanId,
} from "./plans";

export const PAY_CODE_PREFIX = "STUDEE";
const PAY_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const CHECKOUT_TTL_MS = 15 * 60 * 1000;

export function generatePayCode(): string {
  const bytes = randomBytes(8);
  let suffix = "";
  for (let i = 0; i < 8; i++) {
    suffix += PAY_CODE_ALPHABET[bytes[i]! % PAY_CODE_ALPHABET.length];
  }
  return `${PAY_CODE_PREFIX}${suffix}`;
}

export function generateClientSecret(): string {
  return randomBytes(24).toString("hex");
}

export function secretsEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export async function createSession(input: {
  plan: PlanId;
  contact?: string | null;
}): Promise<CheckoutSessionRow> {
  if (!isPlanId(input.plan)) {
    throw new Error("Invalid plan");
  }
  const amountVnd = PLAN_PRESETS[input.plan].amountVnd;
  const expiresAt = new Date(Date.now() + CHECKOUT_TTL_MS).toISOString();
  const sql = getSql();

  for (let attempt = 0; attempt < 5; attempt++) {
    const payCode = generatePayCode();
    const clientSecret = generateClientSecret();
    try {
      const rows = await sql`
        INSERT INTO checkout_sessions (
          pay_code, plan, amount_vnd, client_secret, contact, expires_at
        ) VALUES (
          ${payCode},
          ${input.plan},
          ${amountVnd},
          ${clientSecret},
          ${input.contact?.trim() || null},
          ${expiresAt}
        )
        RETURNING *
      `;
      return rows[0] as CheckoutSessionRow;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes("unique") && !message.includes("duplicate")) {
        throw err;
      }
    }
  }
  throw new Error("Could not generate unique pay code");
}

export async function getSession(
  id: string,
): Promise<CheckoutSessionRow | null> {
  const sql = getSql();
  const rows = await sql`
    SELECT * FROM checkout_sessions WHERE id = ${id} LIMIT 1
  `;
  return (rows[0] as CheckoutSessionRow | undefined) ?? null;
}

export async function countRecentPendingByContactHint(
  contact: string,
): Promise<number> {
  const sql = getSql();
  const rows = await sql`
    SELECT count(*)::int AS n
    FROM checkout_sessions
    WHERE contact = ${contact}
      AND created_at > now() - interval '1 hour'
  `;
  return (rows[0] as { n: number } | undefined)?.n ?? 0;
}

export async function countRecentSessions(hours = 1): Promise<number> {
  const sql = getSql();
  // Neon HTTP driver: keep interval literal (hours is always 1 from callers today).
  void hours;
  const rows = await sql`
    SELECT count(*)::int AS n
    FROM checkout_sessions
    WHERE created_at > now() - interval '1 hour'
  `;
  return (rows[0] as { n: number } | undefined)?.n ?? 0;
}

export async function claimSessionByPayCode(
  payCode: string,
): Promise<CheckoutSessionRow | null> {
  const sql = getSql();
  const rows = await sql`
    UPDATE checkout_sessions
    SET status = 'claimed'
    WHERE pay_code = ${payCode.toUpperCase()}
      AND status = 'pending'
      AND expires_at > now()
    RETURNING *
  `;
  return (rows[0] as CheckoutSessionRow | undefined) ?? null;
}

export async function releaseClaim(sessionId: string): Promise<void> {
  const sql = getSql();
  await sql`
    UPDATE checkout_sessions
    SET status = 'pending'
    WHERE id = ${sessionId} AND status = 'claimed'
  `;
}

export async function markPaid(input: {
  sessionId: string;
  activationCodeId: string;
  sepayTxId: number;
  paidAmountVnd: number;
}): Promise<CheckoutSessionRow | null> {
  const sql = getSql();
  const rows = await sql`
    UPDATE checkout_sessions
    SET
      status = 'paid',
      activation_code_id = ${input.activationCodeId},
      sepay_tx_id = ${input.sepayTxId},
      paid_amount_vnd = ${input.paidAmountVnd},
      paid_at = now()
    WHERE id = ${input.sessionId} AND status = 'claimed'
    RETURNING *
  `;
  return (rows[0] as CheckoutSessionRow | undefined) ?? null;
}

export async function expireStale(sessionId: string): Promise<CheckoutSessionRow | null> {
  const sql = getSql();
  const rows = await sql`
    UPDATE checkout_sessions
    SET status = 'expired'
    WHERE id = ${sessionId}
      AND status IN ('pending', 'claimed')
      AND expires_at <= now()
    RETURNING *
  `;
  return (rows[0] as CheckoutSessionRow | undefined) ?? null;
}

/** Claim session, issue activation code, mark paid. Reverts claim on failure. */
export async function fulfillCheckout(input: {
  payCode: string;
  sepayTxId: number;
  paidAmountVnd: number;
}): Promise<{ session: CheckoutSessionRow; code: string } | null> {
  const claimed = await claimSessionByPayCode(input.payCode);
  if (!claimed) return null;

  if (input.paidAmountVnd < claimed.amount_vnd) {
    await releaseClaim(claimed.id);
    return null;
  }

  if (!isPlanId(claimed.plan)) {
    await releaseClaim(claimed.id);
    return null;
  }

  try {
    const codeRow = await createCode({
      plan: claimed.plan,
      source: "checkout",
      externalRef: claimed.id,
      expiresAt: codeExpiresAtFromNow(claimed.plan),
      note: claimed.contact
        ? `Checkout ${claimed.pay_code} · ${claimed.contact}`
        : `Checkout ${claimed.pay_code}`,
    });
    const paid = await markPaid({
      sessionId: claimed.id,
      activationCodeId: codeRow.id,
      sepayTxId: input.sepayTxId,
      paidAmountVnd: input.paidAmountVnd,
    });
    if (!paid) {
      await releaseClaim(claimed.id);
      return null;
    }
    return { session: paid, code: codeRow.code };
  } catch (err) {
    await releaseClaim(claimed.id);
    throw err;
  }
}

export async function getActivationCodeForSession(
  session: CheckoutSessionRow,
): Promise<string | null> {
  const issued = await getIssuedActivationForSession(session);
  return issued?.code ?? null;
}

export async function getIssuedActivationForSession(
  session: CheckoutSessionRow,
): Promise<{ code: string; expiresAt: string | null } | null> {
  if (!session.activation_code_id) return null;
  const sql = getSql();
  const rows = await sql`
    SELECT code, expires_at FROM activation_codes
    WHERE id = ${session.activation_code_id}
    LIMIT 1
  `;
  const row = rows[0] as
    | { code: string; expires_at: string | null }
    | undefined;
  if (!row) return null;
  return { code: row.code, expiresAt: row.expires_at };
}
