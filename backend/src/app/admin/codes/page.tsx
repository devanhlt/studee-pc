import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { listCodes } from "@/lib/codes";
import { PLAN_PRESETS } from "@/lib/plans";
import { AdminCodesClient } from "./ui";

export const dynamic = "force-dynamic";

export default async function AdminCodesPage() {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
  const codes = await listCodes();
  return (
    <main style={{ maxWidth: 1100, margin: "0 auto", padding: "2rem 1.25rem 3rem" }}>
      <header style={{ marginBottom: "0.5rem" }}>
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
          Mã kích hoạt
        </h1>
        <p className="muted" style={{ margin: "0.4rem 0 0" }}>
          Tạo và theo dõi quota token. Giải bằng chữ = 100 token, bằng ảnh = 200 token.
        </p>
      </header>

      <AdminCodesClient
        initialCodes={codes.map((c) => ({
          id: c.id,
          code: c.code,
          plan: c.plan,
          max_solves: c.max_solves,
          solves_used: c.solves_used,
          status: c.status,
          note: c.note,
          created_at: c.created_at,
          expires_at: c.expires_at,
          last_used_at: c.last_used_at,
        }))}
        presets={PLAN_PRESETS}
      />
    </main>
  );
}
