import { getSql } from "./db";

export const PROVIDER_SECRET_KEYS = [
  "deepseek_api_key",
  "mathpix_app_id",
  "mathpix_app_key",
] as const;

export type ProviderSecretKey = (typeof PROVIDER_SECRET_KEYS)[number];

export type SecretSource = "db" | "env" | "missing";

export type SecretStatus = {
  key: ProviderSecretKey;
  source: SecretSource;
  masked: string | null;
  updated_at: string | null;
};

const ENV_FOR_KEY: Record<ProviderSecretKey, string> = {
  deepseek_api_key: "DEEPSEEK_API_KEY",
  mathpix_app_id: "MATHPIX_APP_ID",
  mathpix_app_key: "MATHPIX_APP_KEY",
};

let overrideCache: Map<string, { value: string; updated_at: string }> | null =
  null;
let overrideCacheAt = 0;
const CACHE_MS = 15_000;

export function invalidateProviderSecretsCache() {
  overrideCache = null;
  overrideCacheAt = 0;
}

function maskSecret(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return "(empty)";
  if (trimmed.length <= 8) return "••••" + trimmed.slice(-2);
  return trimmed.slice(0, 4) + "…" + trimmed.slice(-4);
}

async function loadDbOverrides(): Promise<
  Map<string, { value: string; updated_at: string }>
> {
  const now = Date.now();
  if (overrideCache && now - overrideCacheAt < CACHE_MS) {
    return overrideCache;
  }
  const sql = getSql();
  const rows = await sql`
    SELECT key, value, updated_at::text AS updated_at
    FROM provider_secrets
  `;
  const map = new Map<string, { value: string; updated_at: string }>();
  for (const row of rows as { key: string; value: string; updated_at: string }[]) {
    map.set(row.key, { value: row.value, updated_at: row.updated_at });
  }
  overrideCache = map;
  overrideCacheAt = now;
  return map;
}

export async function resolveProviderSecret(
  key: ProviderSecretKey,
): Promise<string | null> {
  try {
    const overrides = await loadDbOverrides();
    const fromDb = overrides.get(key)?.value?.trim();
    if (fromDb) return fromDb;
  } catch (err) {
    console.error("provider_secrets DB lookup failed; falling back to env", err);
  }
  const fromEnv = process.env[ENV_FOR_KEY[key]]?.trim();
  return fromEnv || null;
}

export async function getProviderSecretStatuses(): Promise<SecretStatus[]> {
  const overrides = await loadDbOverrides();
  return PROVIDER_SECRET_KEYS.map((key) => {
    const db = overrides.get(key);
    if (db?.value?.trim()) {
      return {
        key,
        source: "db" as const,
        masked: maskSecret(db.value),
        updated_at: db.updated_at,
      };
    }
    const envVal = process.env[ENV_FOR_KEY[key]]?.trim();
    if (envVal) {
      return {
        key,
        source: "env" as const,
        masked: maskSecret(envVal),
        updated_at: null,
      };
    }
    return {
      key,
      source: "missing" as const,
      masked: null,
      updated_at: null,
    };
  });
}

export async function setProviderSecret(
  key: ProviderSecretKey,
  value: string,
): Promise<void> {
  const trimmed = value.trim();
  if (!trimmed) {
    throw new Error("Secret value cannot be empty");
  }
  const sql = getSql();
  await sql`
    INSERT INTO provider_secrets (key, value, updated_at)
    VALUES (${key}, ${trimmed}, now())
    ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_at = now()
  `;
  invalidateProviderSecretsCache();
}

export async function clearProviderSecret(
  key: ProviderSecretKey,
): Promise<void> {
  const sql = getSql();
  await sql`DELETE FROM provider_secrets WHERE key = ${key}`;
  invalidateProviderSecretsCache();
}

export function isProviderSecretKey(value: string): value is ProviderSecretKey {
  return (PROVIDER_SECRET_KEYS as readonly string[]).includes(value);
}
