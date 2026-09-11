export type PlanId = "basic" | "pro" | "3xpro";

export const PLAN_PRESETS: Record<
  PlanId,
  { label: string; maxSolves: number }
> = {
  basic: { label: "Basic", maxSolves: 100 },
  pro: { label: "Pro", maxSolves: 500 },
  "3xpro": { label: "3xPro", maxSolves: 1500 },
};

export function isPlanId(value: string): value is PlanId {
  return value === "basic" || value === "pro" || value === "3xpro";
}
