import { NextRequest, NextResponse } from "next/server";
import { jsonError } from "./proxy-auth";
import { resolveProviderSecret } from "./provider-secrets";

const DEEPSEEK_BASE = "https://api.deepseek.com";
const MATHPIX_BASE = "https://api.mathpix.com";

async function forwardResponse(upstream: Response): Promise<NextResponse> {
  const body = await upstream.arrayBuffer();
  const headers = new Headers();
  const contentType = upstream.headers.get("content-type");
  if (contentType) headers.set("content-type", contentType);
  return new NextResponse(body, {
    status: upstream.status,
    headers,
  });
}

export async function proxyDeepSeekChat(
  req: NextRequest,
): Promise<NextResponse> {
  try {
    const key = await resolveProviderSecret("deepseek_api_key");
    if (!key) {
      return jsonError(
        503,
        "DeepSeek is not configured. Set DEEPSEEK_API_KEY in env or /admin/keys.",
        "deepseek_not_configured",
      );
    }
    const body = await req.arrayBuffer();
    const upstream = await fetch(`${DEEPSEEK_BASE}/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": req.headers.get("content-type") || "application/json",
      },
      body,
    });
    return forwardResponse(upstream);
  } catch (err) {
    console.error("proxyDeepSeekChat failed", err);
    return jsonError(502, "DeepSeek proxy failed", "deepseek_proxy_error");
  }
}

export async function proxyMathpix(
  req: NextRequest,
  path: string,
): Promise<NextResponse> {
  try {
    const appId = await resolveProviderSecret("mathpix_app_id");
    const appKey = await resolveProviderSecret("mathpix_app_key");
    if (!appId || !appKey) {
      return jsonError(
        503,
        "Mathpix is not configured. Set MATHPIX_APP_ID and MATHPIX_APP_KEY in env or paste them at /admin/keys.",
        "mathpix_not_configured",
      );
    }

    const url = new URL(path, MATHPIX_BASE);
    req.nextUrl.searchParams.forEach((value, key) => {
      url.searchParams.set(key, value);
    });

    const headers: Record<string, string> = {
      app_id: appId,
      app_key: appKey,
    };

    const init: RequestInit = {
      method: req.method,
      headers,
    };

    if (req.method !== "GET" && req.method !== "HEAD") {
      const contentType = req.headers.get("content-type");
      if (contentType) {
        headers["Content-Type"] = contentType;
      }
      init.body = await req.arrayBuffer();
    }

    const upstream = await fetch(url, init);
    return forwardResponse(upstream);
  } catch (err) {
    console.error("proxyMathpix failed", err);
    return jsonError(502, "Mathpix proxy failed", "mathpix_proxy_error");
  }
}
