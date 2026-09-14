export type PlanId = "basic" | "pro" | "3xpro";

export function codeExpiresAtFromNow(plan: PlanId, now = new Date()): string {
  const expires = new Date(now);
  expires.setUTCDate(expires.getUTCDate() + PLAN_PRESETS[plan].ttlDays);
  return expires.toISOString();
}

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

export const PLAN_PRESETS: Record<
  PlanId,
  { label: string; maxSolves: number; amountVnd: number; ttlDays: number }
> = {
  basic: {
    label: "Basic",
    maxSolves: 100 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 19000,
    ttlDays: 30,
  },
  pro: {
    label: "Pro",
    maxSolves: 500 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 49000,
    ttlDays: 60,
  },
  "3xpro": {
    label: "3xPro",
    maxSolves: 1500 * TOKENS_PER_LEGACY_SOLVE,
    amountVnd: 88000,
    ttlDays: 90,
  },
};

export function isPlanId(value: string): value is PlanId {
  return value === "basic" || value === "pro" || value === "3xpro";
}
