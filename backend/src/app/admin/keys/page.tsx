import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { getProviderSecretStatuses } from "@/lib/provider-secrets";
import { AdminKeysClient } from "./ui";

export const dynamic = "force-dynamic";

export default async function AdminKeysPage() {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
  const secrets = await getProviderSecretStatuses();
  return (
    <main className="admin-page">
      <header className="page-head">
        <p className="kicker">Studee Admin</p>
        <h1>API keys</h1>
        <p>
          Rotate DeepSeek / Mathpix dùng cho proxy. DB override ưu tiên hơn env;
          xóa override để quay về Vercel env.
        </p>
      </header>

      <AdminKeysClient initialSecrets={secrets} />
    </main>
  );
}
