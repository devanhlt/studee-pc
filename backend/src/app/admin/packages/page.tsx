import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { getPackagesAppDisplayEnabled } from "@/lib/app-settings";
import { listPackages } from "@/lib/packages";
import { AdminPackagesClient } from "./ui";

export const dynamic = "force-dynamic";

export default async function AdminPackagesPage() {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
  const [packages, appDisplayEnabled] = await Promise.all([
    listPackages(),
    getPackagesAppDisplayEnabled(),
  ]);
  return (
    <main className="admin-page wide">
      <header className="page-head">
        <p className="kicker">Studee Admin</p>
        <h1>Gói token</h1>
        <p>
          Quản lý gói bán (giá, token, hạn mã). Cần ít nhất 1 gói đang bán.
        </p>
      </header>
      <AdminPackagesClient
        initialPackages={packages}
        initialAppDisplayEnabled={appDisplayEnabled}
      />
    </main>
  );
}
