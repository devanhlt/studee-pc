import { NextRequest } from "next/server";
import {
  expireStale,
  getIssuedActivationForSession,
  getSession,
  secretsEqual,
} from "@/lib/checkout";

export const runtime = "nodejs";
export const maxDuration = 300;

function sseData(obj: unknown): string {
  return `data: ${JSON.stringify(obj)}\n\n`;
}

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const secret = req.nextUrl.searchParams.get("secret")?.trim() ?? "";
  if (!id || !secret) {
    return new Response(
      JSON.stringify({ error: { message: "Missing id or secret", code: "missing_params" } }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const session = await getSession(id);
  if (!session) {
    return new Response(
      JSON.stringify({ error: { message: "Checkout not found", code: "checkout_not_found" } }),
      { status: 404, headers: { "Content-Type": "application/json" } },
    );
  }
  if (!secretsEqual(session.client_secret, secret)) {
    return new Response(
      JSON.stringify({ error: { message: "Invalid secret", code: "invalid_secret" } }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  const encoder = new TextEncoder();
  let closed = false;

  const stream = new ReadableStream({
    async start(controller) {
      const send = (obj: unknown) => {
        if (closed) return;
        controller.enqueue(encoder.encode(sseData(obj)));
      };
      const heartbeat = () => {
        if (closed) return;
        controller.enqueue(encoder.encode(":heartbeat\n\n"));
      };
      const close = () => {
        if (closed) return;
        closed = true;
        try {
          controller.close();
        } catch {
          /* already closed */
        }
      };

      req.signal.addEventListener("abort", close);

      const emitStatus = async (): Promise<"continue" | "done"> => {
        let row = await getSession(id);
        if (!row) {
          send({ status: "expired" });
          return "done";
        }
        if (
          (row.status === "pending" || row.status === "claimed") &&
          new Date(row.expires_at) <= new Date()
        ) {
          row = (await expireStale(row.id)) ?? { ...row, status: "expired" };
        }

        if (row.status === "paid") {
          const issued = await getIssuedActivationForSession(row);
          send({
            status: "paid",
            activation_code: issued?.code ?? null,
            code_expires_at: issued?.expiresAt ?? null,
            plan: row.plan,
            amount_vnd: row.amount_vnd,
          });
          return "done";
        }
        if (row.status === "expired") {
          send({ status: "expired" });
          return "done";
        }
        send({
          status: row.status,
          plan: row.plan,
          amount_vnd: row.amount_vnd,
          pay_code: row.pay_code,
          expires_at: row.expires_at,
        });
        return "continue";
      };

      try {
        if ((await emitStatus()) === "done") {
          close();
          return;
        }

        let ticks = 0;
        while (!closed) {
          await new Promise((r) => setTimeout(r, 2000));
          if (closed) break;
          ticks += 1;
          if (ticks % 8 === 0) heartbeat();
          if ((await emitStatus()) === "done") {
            close();
            return;
          }
        }
      } catch {
        close();
      }
    },
    cancel() {
      closed = true;
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
      "X-Accel-Buffering": "no",
    },
  });
}
