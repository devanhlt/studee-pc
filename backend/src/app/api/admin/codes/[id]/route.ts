import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { getCodeById, revokeCode } from "@/lib/codes";

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
  const code = await getCodeById(id);
  if (!code) {
    return NextResponse.json(
      { error: { message: "Not found", code: "not_found" } },
      { status: 404 },
    );
  }
  return NextResponse.json({ code });
}

export async function POST(req: NextRequest, ctx: Ctx) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const body = (await req.json().catch(() => null)) as {
    action?: string;
  } | null;
  if (body?.action !== "revoke") {
    return NextResponse.json(
      { error: { message: "Unknown action", code: "bad_action" } },
      { status: 400 },
    );
  }
  const { id } = await ctx.params;
  const code = await revokeCode(id);
  if (!code) {
    return NextResponse.json(
      { error: { message: "Not found or already inactive", code: "not_found" } },
      { status: 404 },
    );
  }
  return NextResponse.json({ code });
}
