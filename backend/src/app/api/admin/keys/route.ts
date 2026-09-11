import { NextRequest, NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import {
  clearProviderSecret,
  getProviderSecretStatuses,
  isProviderSecretKey,
  setProviderSecret,
} from "@/lib/provider-secrets";

export const runtime = "nodejs";

export async function GET() {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }
  const secrets = await getProviderSecretStatuses();
  return NextResponse.json({ secrets });
}

export async function PUT(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }

  const body = (await req.json().catch(() => null)) as {
    key?: string;
    value?: string;
  } | null;

  const key = body?.key ?? "";
  const value = body?.value ?? "";
  if (!isProviderSecretKey(key)) {
    return NextResponse.json(
      { error: { message: "Invalid key", code: "invalid_key" } },
      { status: 400 },
    );
  }
  if (!value.trim()) {
    return NextResponse.json(
      { error: { message: "Value required", code: "empty_value" } },
      { status: 400 },
    );
  }

  await setProviderSecret(key, value);
  const secrets = await getProviderSecretStatuses();
  return NextResponse.json({ ok: true, secrets });
}

export async function DELETE(req: NextRequest) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: { message: "Unauthorized", code: "unauthorized" } },
      { status: 401 },
    );
  }

  const body = (await req.json().catch(() => null)) as { key?: string } | null;
  const key = body?.key ?? "";
  if (!isProviderSecretKey(key)) {
    return NextResponse.json(
      { error: { message: "Invalid key", code: "invalid_key" } },
      { status: 400 },
    );
  }

  await clearProviderSecret(key);
  const secrets = await getProviderSecretStatuses();
  return NextResponse.json({ ok: true, secrets });
}
