import { randomBytes } from "crypto";
import { getSql, type ActivationCodeRow } from "./db";
import { isPlanId, PLAN_PRESETS, type PlanId } from "./plans";

export function generateActivationCode(): string {
  const raw = randomBytes(6).toString("hex").toUpperCase();
  return `STU-${raw.slice(0, 4)}-${raw.slice(4, 8)}-${raw.slice(8, 12)}`;
}

export function remainingSolves(row: ActivationCodeRow): number {
  return Math.max(0, row.max_solves - row.solves_used);
}

export function isUsable(row: ActivationCodeRow, now = new Date()): boolean {
  if (row.status !== "active") return false;
  if (row.solves_used >= row.max_solves) return false;
  if (row.expires_at && new Date(row.expires_at) <= now) return false;
  return true;
}

export async function findCodeByValue(
  code: string,
): Promise<ActivationCodeRow | null> {
  const sql = getSql();
  const rows = await sql`
    SELECT * FROM activation_codes WHERE code = ${code.trim()} LIMIT 1
  `;
  return (rows[0] as ActivationCodeRow | undefined) ?? null;
}

export async function listCodes(limit = 200): Promise<ActivationCodeRow[]> {
  const sql = getSql();
  const rows = await sql`
    SELECT * FROM activation_codes
    ORDER BY created_at DESC
    LIMIT ${limit}
  `;
  return rows as ActivationCodeRow[];
}

export async function getCodeById(
  id: string,
): Promise<ActivationCodeRow | null> {
  const sql = getSql();
  const rows = await sql`
    SELECT * FROM activation_codes WHERE id = ${id} LIMIT 1
  `;
  return (rows[0] as ActivationCodeRow | undefined) ?? null;
}

export async function createCode(input: {
  plan: PlanId;
  maxSolves?: number;
  note?: string;
  expiresAt?: string | null;
  source?: "admin" | "checkout";
  externalRef?: string | null;
}): Promise<ActivationCodeRow> {
  if (!isPlanId(input.plan)) {
    throw new Error("Invalid plan");
  }
  const maxSolves = input.maxSolves ?? PLAN_PRESETS[input.plan].maxSolves;
  const source = input.source ?? "admin";
  const sql = getSql();

  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateActivationCode();
    try {
      const rows = await sql`
        INSERT INTO activation_codes (
          code, plan, max_solves, note, source, external_ref, expires_at
        ) VALUES (
          ${code},
          ${input.plan},
          ${maxSolves},
          ${input.note?.trim() || null},
          ${source},
          ${input.externalRef?.trim() || null},
          ${input.expiresAt || null}
        )
        RETURNING *
      `;
      return rows[0] as ActivationCodeRow;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes("unique") && !message.includes("duplicate")) {
        throw err;
      }
    }
  }
  throw new Error("Could not generate unique activation code");
}

export async function revokeCode(id: string): Promise<ActivationCodeRow | null> {
  const sql = getSql();
  const rows = await sql`
    UPDATE activation_codes
    SET status = 'revoked'
    WHERE id = ${id} AND status = 'active'
    RETURNING *
  `;
  return (rows[0] as ActivationCodeRow | undefined) ?? null;
}

/** Atomically consume [tokens]. Returns updated row or null if not enough quota. */
export async function consumeSolve(
  code: string,
  tokens: number,
): Promise<ActivationCodeRow | null> {
  const amount = Math.floor(tokens);
  if (!Number.isFinite(amount) || amount <= 0) {
    return null;
  }
  const sql = getSql();
  const rows = await sql`
    UPDATE activation_codes
    SET
      solves_used = solves_used + ${amount},
      last_used_at = now(),
      status = CASE
        WHEN solves_used + ${amount} >= max_solves THEN 'exhausted'
        ELSE status
      END
    WHERE code = ${code.trim()}
      AND status = 'active'
      AND (max_solves - solves_used) >= ${amount}
      AND (expires_at IS NULL OR expires_at > now())
    RETURNING *
  `;
  return (rows[0] as ActivationCodeRow | undefined) ?? null;
}

export function entitlementPayload(row: ActivationCodeRow) {
  return {
    code: row.code,
    plan: row.plan,
    max_solves: row.max_solves,
    solves_used: row.solves_used,
    remaining: remainingSolves(row),
    max_tokens: row.max_solves,
    tokens_used: row.solves_used,
    remaining_tokens: remainingSolves(row),
    status: row.status,
    expires_at: row.expires_at,
  };
}
