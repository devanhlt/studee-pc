import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import {
  getPackagesAppDisplayEnabled,
  setPackagesAppDisplayEnabled,
} from "@/lib/app-settings";
import {
  createPackage,
  listPackages,
  type PackageInput,
} from "@/lib/packages";

export const runtime = "nodejs";

export async function GET() {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const [packages, appDisplayEnabled] = await Promise.all([
    listPackages(),
    getPackagesAppDisplayEnabled(),
  ]);
  return NextResponse.json({
    packages,
    app_display_enabled: appDisplayEnabled,
  });
}

export async function PUT(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const body = (await req.json().catch(() => null)) as {
    app_display_enabled?: boolean;
  } | null;

  if (typeof body?.app_display_enabled !== "boolean") {
    return NextResponse.json(
      {
        error: {
          message: "app_display_enabled boolean required",
          code: "invalid_settings",
        },
      },
      { status: 400 },
    );
  }

  await setPackagesAppDisplayEnabled(body.app_display_enabled);
  return NextResponse.json({
    app_display_enabled: body.app_display_enabled,
  });
}

export async function POST(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const body = (await req.json().catch(() => null)) as Partial<PackageInput> | null;
  try {
    const pkg = await createPackage({
      id: String(body?.id ?? ""),
      label: String(body?.label ?? ""),
      amount_vnd: Number(body?.amount_vnd),
      max_tokens: Number(body?.max_tokens),
      ttl_days: Number(body?.ttl_days),
      active: body?.active !== false,
      sort_order: Number(body?.sort_order ?? 0),
    });
    return NextResponse.json({ package: pkg }, { status: 201 });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Create failed";
    return NextResponse.json(
      { error: { message, code: "invalid_package" } },
      { status: 400 },
    );
  }
}
