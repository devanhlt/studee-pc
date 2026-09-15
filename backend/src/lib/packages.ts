import { getSql } from "./db";

export type PackageRow = {
  id: string;
  label: string;
  amount_vnd: number;
  max_tokens: number;
  ttl_days: number;
  active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

export type PackageInput = {
  id: string;
  label: string;
  amount_vnd: number;
  max_tokens: number;
  ttl_days: number;
  active?: boolean;
  sort_order?: number;
};

const PACKAGE_ID_RE = /^[a-z0-9][a-z0-9_-]{0,31}$/;

export function isValidPackageId(value: string): boolean {
  return PACKAGE_ID_RE.test(value);
}

export function packageToPreset(row: PackageRow) {
  return {
    label: row.label,
    maxSolves: row.max_tokens,
    amountVnd: row.amount_vnd,
    ttlDays: row.ttl_days,
  };
}

export async function listPackages(opts?: {
  activeOnly?: boolean;
}): Promise<PackageRow[]> {
  const sql = getSql();
  if (opts?.activeOnly) {
    const rows = await sql`
      SELECT * FROM packages
      WHERE active = true
      ORDER BY sort_order ASC, id ASC
    `;
    return rows as PackageRow[];
  }
  const rows = await sql`
    SELECT * FROM packages
    ORDER BY sort_order ASC, id ASC
  `;
  return rows as PackageRow[];
}

export async function getPackageById(
  id: string,
): Promise<PackageRow | null> {
  const sql = getSql();
  const rows = await sql`
    SELECT * FROM packages WHERE id = ${id} LIMIT 1
  `;
  return (rows[0] as PackageRow | undefined) ?? null;
}

export async function countPackages(): Promise<number> {
  const sql = getSql();
  const rows = await sql`SELECT count(*)::int AS n FROM packages`;
  return (rows[0] as { n: number } | undefined)?.n ?? 0;
}

export async function countActivePackages(excludeId?: string): Promise<number> {
  const sql = getSql();
  if (excludeId) {
    const rows = await sql`
      SELECT count(*)::int AS n FROM packages
      WHERE active = true AND id <> ${excludeId}
    `;
    return (rows[0] as { n: number } | undefined)?.n ?? 0;
  }
  const rows = await sql`
    SELECT count(*)::int AS n FROM packages WHERE active = true
  `;
  return (rows[0] as { n: number } | undefined)?.n ?? 0;
}

function normalizeInput(input: PackageInput): PackageInput {
  const id = input.id.trim().toLowerCase();
  const label = input.label.trim();
  const amount_vnd = Math.floor(Number(input.amount_vnd));
  const max_tokens = Math.floor(Number(input.max_tokens));
  const ttl_days = Math.floor(Number(input.ttl_days));
  const sort_order = Math.floor(Number(input.sort_order ?? 0));

  if (!isValidPackageId(id)) {
    throw new Error("Invalid package id");
  }
  if (!label) {
    throw new Error("Label is required");
  }
  if (!Number.isFinite(amount_vnd) || amount_vnd <= 0) {
    throw new Error("amount_vnd must be > 0");
  }
  if (!Number.isFinite(max_tokens) || max_tokens <= 0) {
    throw new Error("max_tokens must be > 0");
  }
  if (!Number.isFinite(ttl_days) || ttl_days < 1) {
    throw new Error("ttl_days must be >= 1");
  }

  return {
    id,
    label,
    amount_vnd,
    max_tokens,
    ttl_days,
    active: input.active !== false,
    sort_order: Number.isFinite(sort_order) ? sort_order : 0,
  };
}

export async function createPackage(input: PackageInput): Promise<PackageRow> {
  const data = normalizeInput(input);
  const sql = getSql();
  try {
    const rows = await sql`
      INSERT INTO packages (
        id, label, amount_vnd, max_tokens, ttl_days, active, sort_order
      ) VALUES (
        ${data.id},
        ${data.label},
        ${data.amount_vnd},
        ${data.max_tokens},
        ${data.ttl_days},
        ${data.active ?? true},
        ${data.sort_order ?? 0}
      )
      RETURNING *
    `;
    return rows[0] as PackageRow;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    if (message.includes("unique") || message.includes("duplicate")) {
      throw new Error("Package id already exists");
    }
    throw err;
  }
}

export async function updatePackage(
  id: string,
  patch: Partial<Omit<PackageInput, "id">> & { active?: boolean },
): Promise<PackageRow> {
  const existing = await getPackageById(id);
  if (!existing) {
    throw new Error("Package not found");
  }

  const nextActive =
    typeof patch.active === "boolean" ? patch.active : existing.active;
  if (!nextActive) {
    const otherActive = await countActivePackages(id);
    if (otherActive < 1) {
      throw new Error("At least one active package is required");
    }
  }

  const merged = normalizeInput({
    id,
    label: patch.label ?? existing.label,
    amount_vnd: patch.amount_vnd ?? existing.amount_vnd,
    max_tokens: patch.max_tokens ?? existing.max_tokens,
    ttl_days: patch.ttl_days ?? existing.ttl_days,
    active: nextActive,
    sort_order: patch.sort_order ?? existing.sort_order,
  });

  const sql = getSql();
  const rows = await sql`
    UPDATE packages SET
      label = ${merged.label},
      amount_vnd = ${merged.amount_vnd},
      max_tokens = ${merged.max_tokens},
      ttl_days = ${merged.ttl_days},
      active = ${merged.active ?? true},
      sort_order = ${merged.sort_order ?? 0},
      updated_at = now()
    WHERE id = ${id}
    RETURNING *
  `;
  const row = rows[0] as PackageRow | undefined;
  if (!row) throw new Error("Package not found");
  return row;
}

export async function deletePackage(id: string): Promise<void> {
  const total = await countPackages();
  if (total <= 1) {
    throw new Error("At least one package is required");
  }
  const existing = await getPackageById(id);
  if (!existing) {
    throw new Error("Package not found");
  }
  if (existing.active) {
    const otherActive = await countActivePackages(id);
    if (otherActive < 1) {
      throw new Error("At least one active package is required");
    }
  }
  const sql = getSql();
  await sql`DELETE FROM packages WHERE id = ${id}`;
}
