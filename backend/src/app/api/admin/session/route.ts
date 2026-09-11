import { NextRequest, NextResponse } from "next/server";
import {
  checkAdminPassword,
  clearAdminSessionCookie,
  isAdminAuthenticated,
  setAdminSessionCookie,
} from "@/lib/admin-auth";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  const body = (await req.json().catch(() => null)) as {
    password?: string;
  } | null;
  const password = body?.password ?? "";
  if (!checkAdminPassword(password)) {
    return NextResponse.json(
      { error: { message: "Invalid password", code: "bad_password" } },
      { status: 401 },
    );
  }
  await setAdminSessionCookie();
  return NextResponse.json({ ok: true });
}

export async function DELETE() {
  await clearAdminSessionCookie();
  return NextResponse.json({ ok: true });
}

export async function GET() {
  const ok = await isAdminAuthenticated();
  return NextResponse.json({ authenticated: ok }, { status: ok ? 200 : 401 });
}
