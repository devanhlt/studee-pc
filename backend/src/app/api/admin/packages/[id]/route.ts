import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import {
  deletePackage,
  getPackageById,
  updatePackage,
} from "@/lib/packages";

export const runtime = "nodejs";

type Ctx = { params: Promise<{ id: string }> };

export async function GET(_req: NextRequest, ctx: Ctx) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const { id } = await ctx.params;
  const pkg = await getPackageById(id);
  if (!pkg) {
    return NextResponse.json(
      { error: { message: "Not found", code: "not_found" } },
      { status: 404 },
    );
  }
  return NextResponse.json({ package: pkg });
}

export async function PUT(req: NextRequest, ctx: Ctx) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const { id } = await ctx.params;
  const body = (await req.json().catch(() => null)) as {
    label?: string;
    amount_vnd?: number;
    max_tokens?: number;
    ttl_days?: number;
    active?: boolean;
    sort_order?: number;
  } | null;

  try {
    const pkg = await updatePackage(id, {
      label: body?.label,
      amount_vnd: body?.amount_vnd,
      max_tokens: body?.max_tokens,
      ttl_days: body?.ttl_days,
      active: body?.active,
      sort_order: body?.sort_order,
    });
    return NextResponse.json({ package: pkg });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Update failed";
    const status = message.includes("not found")
      ? 404
      : message.includes("At least one")
        ? 409
        : 400;
    return NextResponse.json(
      { error: { message, code: "invalid_package" } },
      { status },
    );
  }
}

export async function DELETE(_req: NextRequest, ctx: Ctx) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const { id } = await ctx.params;
  try {
    await deletePackage(id);
    return NextResponse.json({ ok: true });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Delete failed";
    const status = message.includes("not found")
      ? 404
      : message.includes("At least one")
        ? 409
        : 400;
    return NextResponse.json(
      { error: { message, code: "invalid_package" } },
      { status },
    );
  }
}
