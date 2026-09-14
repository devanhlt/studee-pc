import { getSql } from "./db";

export const VIETQR_KEYS = {
  bank: "vietqr_bank",
  account: "vietqr_account",
  holder: "vietqr_holder",
} as const;

export const SEPAY_WEBHOOK_SECRET_KEY = "sepay_webhook_secret";

export type VietqrConfig = {
  bank: string;
  account: string;
  holder: string;
};

function sanitizePathSegment(value: string): string {
  return value.replace(/[^a-zA-Z0-9]/g, "");
}

function maskSecret(value: string): string {
  if (value.length <= 8) return "••••" + value.slice(-2);
  return value.slice(0, 4) + "…" + value.slice(-4);
}

async function loadPaymentMap(): Promise<Map<string, string>> {
  const sql = getSql();
  const keys = [
    VIETQR_KEYS.bank,
    VIETQR_KEYS.account,
    VIETQR_KEYS.holder,
    SEPAY_WEBHOOK_SECRET_KEY,
  ];
  const map = new Map<string, string>();
  for (const key of keys) {
    const rows = await sql`
      SELECT key, value FROM provider_secrets WHERE key = ${key} LIMIT 1
    `;
    const row = rows[0] as { key: string; value: string } | undefined;
    if (row) map.set(row.key, row.value);
  }
  return map;
}

export async function getPaymentSettings(): Promise<{
  bank: string | null;
  account: string | null;
  holder: string | null;
  webhookSecretPresent: boolean;
  webhookSecretMasked: string | null;
}> {
  const map = await loadPaymentMap();
  const secret = map.get(SEPAY_WEBHOOK_SECRET_KEY)?.trim() || null;
  return {
    bank: map.get(VIETQR_KEYS.bank)?.trim() || null,
    account: map.get(VIETQR_KEYS.account)?.trim() || null,
    holder: map.get(VIETQR_KEYS.holder)?.trim() || null,
    webhookSecretPresent: Boolean(secret),
    webhookSecretMasked: secret ? maskSecret(secret) : null,
  };
}

export async function getVietqrConfigOrNull(): Promise<VietqrConfig | null> {
  const s = await getPaymentSettings();
  if (!s.bank || !s.account || !s.holder) return null;
  return { bank: s.bank, account: s.account, holder: s.holder };
}

export async function getWebhookSecret(): Promise<string | null> {
  const sql = getSql();
  const rows = await sql`
    SELECT value FROM provider_secrets
    WHERE key = ${SEPAY_WEBHOOK_SECRET_KEY}
    LIMIT 1
  `;
  const value = (rows[0] as { value: string } | undefined)?.value?.trim();
  return value || null;
}

export async function savePaymentSettings(input: {
  bank: string;
  account: string;
  holder: string;
  webhookSecret?: string | null;
  clearWebhookSecret?: boolean;
}): Promise<void> {
  const sql = getSql();
  const bank = input.bank.trim();
  const account = input.account.trim();
  const holder = input.holder.trim();
  if (!bank || !account || !holder) {
    throw new Error("Bank, account, and holder are required");
  }

  for (const [key, value] of [
    [VIETQR_KEYS.bank, bank],
    [VIETQR_KEYS.account, account],
    [VIETQR_KEYS.holder, holder],
  ] as const) {
    await sql`
      INSERT INTO provider_secrets (key, value, updated_at)
      VALUES (${key}, ${value}, now())
      ON CONFLICT (key) DO UPDATE
      SET value = EXCLUDED.value, updated_at = now()
    `;
  }

  if (input.clearWebhookSecret) {
    await sql`
      DELETE FROM provider_secrets WHERE key = ${SEPAY_WEBHOOK_SECRET_KEY}
    `;
  } else if (input.webhookSecret != null && input.webhookSecret.trim()) {
    const secret = input.webhookSecret.trim();
    await sql`
      INSERT INTO provider_secrets (key, value, updated_at)
      VALUES (${SEPAY_WEBHOOK_SECRET_KEY}, ${secret}, now())
      ON CONFLICT (key) DO UPDATE
      SET value = EXCLUDED.value, updated_at = now()
    `;
  }
}

export function qrImageUrl(input: {
  amountVnd: number;
  payCode: string;
  config: VietqrConfig;
}): string {
  const bank = sanitizePathSegment(input.config.bank);
  const account = sanitizePathSegment(input.config.account);
  if (!bank || !account) {
    throw new Error("Invalid VietQR bank/account");
  }
  const params = new URLSearchParams({
    amount: String(input.amountVnd),
    addInfo: input.payCode,
    accountName: input.config.holder,
  });
  return `https://img.vietqr.io/image/${bank}-${account}-compact.png?${params.toString()}`;
}
