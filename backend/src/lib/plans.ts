/** One legacy "lượt giải" equals this many tokens. */
export const TOKENS_PER_LEGACY_SOLVE = 100;

export const TOKEN_COSTS = {
  text: 100,
  picture: 200,
} as const;

export type SolveKind = keyof typeof TOKEN_COSTS;

export function isSolveKind(value: unknown): value is SolveKind {
  return value === "text" || value === "picture";
}

/** Seed defaults used only when bootstrapping the packages table. */
export const DEFAULT_PACKAGE_SEEDS = [
  {
    id: "basic",
    label: "Basic",
    maxSolves: 100 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 19000,
    ttlDays: 30,
  },
  {
    id: "pro",
    label: "Pro",
    maxSolves: 500 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 49000,
    ttlDays: 60,
  },
  {
    id: "3xpro",
    label: "3xPro",
    maxSolves: 1500 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 88000,
    ttlDays: 90,
  },
] as const;

export function codeExpiresAtFromDays(
  ttlDays: number,
  now = new Date(),
): string {
  const expires = new Date(now);
  expires.setUTCDate(expires.getUTCDate() + Math.max(1, Math.floor(ttlDays)));
  return expires.toISOString();
}
