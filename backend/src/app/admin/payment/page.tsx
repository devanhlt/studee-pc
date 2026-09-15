import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { getPaymentSettings, qrImageUrl } from "@/lib/vietqr";
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
    <main className="admin-page">
      <header className="page-head">
        <p className="kicker">Studee Admin</p>
        <h1>Thanh toán</h1>
        <p>
          VietQR + URL webhook để dán vào SePay. Sau khi chuyển khoản khớp, app
          nhận mã kích hoạt qua SSE.
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
