import { getSql } from "./db";

/** When "0", the app hides the package catalog / in-app purchase UI. */
export const PACKAGES_APP_DISPLAY_KEY = "packages_app_display";

export async function getPackagesAppDisplayEnabled(): Promise<boolean> {
  try {
    const sql = getSql();
    const rows = await sql`
      SELECT value FROM provider_secrets
      WHERE key = ${PACKAGES_APP_DISPLAY_KEY}
      LIMIT 1
    `;
    const raw = (rows[0] as { value: string } | undefined)?.value?.trim();
    if (raw == null || raw === "") return true;
    return raw !== "0" && raw.toLowerCase() !== "false";
  } catch {
    return true;
  }
}

export async function setPackagesAppDisplayEnabled(
  enabled: boolean,
): Promise<void> {
  const sql = getSql();
  const value = enabled ? "1" : "0";
  await sql`
    INSERT INTO provider_secrets (key, value, updated_at)
    VALUES (${PACKAGES_APP_DISPLAY_KEY}, ${value}, now())
    ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_at = now()
  `;
}
