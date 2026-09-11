import { NextRequest } from "next/server";
import { requireActivationCode } from "@/lib/proxy-auth";
import { proxyDeepSeekChat } from "@/lib/upstream";

export const runtime = "nodejs";
export const maxDuration = 120;

/** Proxies chat completions. Does not consume solve quota (counted once per solve). */
export async function POST(req: NextRequest) {
  const auth = await requireActivationCode(req);
  if (auth instanceof Response) return auth;
  return proxyDeepSeekChat(req);
}
