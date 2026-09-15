import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { listCodes } from "@/lib/codes";
import { listPackages } from "@/lib/packages";
import { AdminCodesClient } from "./ui";

export const dynamic = "force-dynamic";

export default async function AdminCodesPage() {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
  const [codes, packages] = await Promise.all([listCodes(), listPackages()]);
  return (
    <main className="admin-page wide">
      <header className="page-head">
        <p className="kicker">Studee Admin</p>
        <h1>Mã kích hoạt</h1>
        <p>Tạo và theo dõi quota token theo từng mã kích hoạt.</p>
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
        packages={packages.map((p) => ({
          id: p.id,
          label: p.label,
          max_tokens: p.max_tokens,
          active: p.active,
        }))}
      />
    </main>
  );
}
