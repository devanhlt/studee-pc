import { NextRequest } from "next/server";
import { requireActivationCode } from "@/lib/proxy-auth";
import { proxyMathpix } from "@/lib/upstream";

export const runtime = "nodejs";
export const maxDuration = 60;

type Ctx = { params: Promise<{ path: string[] }> };

/** Poll status / download .mmd — no extra solve charge. */
export async function GET(req: NextRequest, ctx: Ctx) {
  const auth = await requireActivationCode(req);
  if (auth instanceof Response) return auth;
  const { path } = await ctx.params;
  const suffix = path.map(encodeURIComponent).join("/");
  return proxyMathpix(req, `/v3/pdf/${suffix}`);
}
