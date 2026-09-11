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
          API keys
        </h1>
        <p className="muted" style={{ margin: "0.4rem 0 0" }}>
          Rotate DeepSeek / Mathpix dùng cho proxy. DB override ưu tiên hơn env;
          xóa override để quay về Vercel env.
        </p>
      </header>

      <AdminKeysClient initialSecrets={secrets} />
    </main>
  );
}
