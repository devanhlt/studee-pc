import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { createCode, listCodes } from "@/lib/codes";
import { isPlanId } from "@/lib/plans";

export const runtime = "nodejs";

export async function GET() {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const codes = await listCodes();
  return NextResponse.json({ codes });
}

export async function POST(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const body = (await req.json().catch(() => null)) as {
    plan?: string;
    max_solves?: number;
    note?: string;
    expires_at?: string | null;
  } | null;

  const plan = body?.plan ?? "";
  if (!isPlanId(plan)) {
    return NextResponse.json(
      { error: { message: "Invalid plan", code: "invalid_plan" } },
      { status: 400 },
    );
  }

  const maxSolves =
    typeof body?.max_solves === "number" && body.max_solves > 0
      ? Math.floor(body.max_solves)
      : undefined;

  const code = await createCode({
    plan,
    maxSolves,
    note: body?.note,
    expiresAt: body?.expires_at ?? null,
  });
  return NextResponse.json({ code }, { status: 201 });
}
