import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import {
  getPaymentSettings,
  qrImageUrl,
} from "@/lib/vietqr";
import { AdminPaymentClient } from "./ui";

export const dynamic = "force-dynamic";

async function webhookUrlFromHeaders(): Promise<string> {
  const h = await headers();
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  const proto =
    h.get("x-forwarded-proto") ??
    (host.includes("localhost") ? "http" : "https");
  return `${proto}://${host}/api/sepay/webhook`;
}

export default async function AdminPaymentPage() {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }

  const settings = await getPaymentSettings();
  let preview_qr_url: string | null = null;
  if (settings.bank && settings.account && settings.holder) {
    preview_qr_url = qrImageUrl({
      amountVnd: 19000,
      payCode: "STUDEEPREVIEW",
      config: {
        bank: settings.bank,
        account: settings.account,
        holder: settings.holder,
      },
    });
  }

  return (
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "2rem 1.25rem 3rem" }}>
      <header style={{ marginBottom: "1.25rem" }}>
        <p
          className="muted"
          style={{
            margin: "0 0 0.35rem",
            fontSize: "0.78rem",
            letterSpacing: "0.12em",
            textTransform: "uppercase",
            color: "var(--accent)",
          }}
        >
          Studee Admin
        </p>
        <h1
          style={{
            margin: 0,
            fontFamily: "var(--font-display), serif",
            fontSize: "clamp(1.6rem, 3vw, 2rem)",
          }}
        >
          Thanh toán
        </h1>
        <p className="muted" style={{ margin: "0.4rem 0 0" }}>
          VietQR + URL webhook để dán vào SePay. Sau khi chuyển khoản khớp,
          app nhận mã kích hoạt qua SSE.
        </p>
      </header>

      <AdminPaymentClient
        initial={{
          bank: settings.bank ?? "",
          account: settings.account ?? "",
          holder: settings.holder ?? "",
          webhook_url: await webhookUrlFromHeaders(),
          webhook_secret_present: settings.webhookSecretPresent,
          webhook_secret_masked: settings.webhookSecretMasked,
          preview_qr_url,
        }}
      />
    </main>
  );
}
