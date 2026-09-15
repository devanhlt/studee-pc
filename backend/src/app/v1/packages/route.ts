import { NextResponse } from "next/server";
import { getPackagesAppDisplayEnabled } from "@/lib/app-settings";
import { listPackages } from "@/lib/packages";

export const runtime = "nodejs";

/** Public catalog of sellable packages for the app / website. */
export async function GET() {
  const enabled = await getPackagesAppDisplayEnabled();
  if (!enabled) {
    return NextResponse.json(
      { enabled: false, packages: [] },
      {
        headers: {
          "Cache-Control": "public, s-maxage=30, stale-while-revalidate=60",
        },
      },
    );
  }

  try {
    const packages = await listPackages({ activeOnly: true });
    return NextResponse.json(
      {
        enabled: true,
        packages: packages.map((p) => ({
          id: p.id,
          label: p.label,
          amount_vnd: p.amount_vnd,
          max_tokens: p.max_tokens,
          ttl_days: p.ttl_days,
          sort_order: p.sort_order,
        })),
      },
      {
        headers: {
          "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300",
        },
      },
    );
  } catch {
    const { DEFAULT_PACKAGE_SEEDS } = await import("@/lib/plans");
    return NextResponse.json({
      enabled: true,
      packages: DEFAULT_PACKAGE_SEEDS.map((p, i) => ({
        id: p.id,
        label: p.label,
        amount_vnd: p.amountVnd,
        max_tokens: p.maxSolves,
        ttl_days: p.ttlDays,
        sort_order: (i + 1) * 10,
      })),
    });
  }
}
