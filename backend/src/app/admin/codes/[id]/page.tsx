import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { getCodeById, remainingSolves } from "@/lib/codes";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ id: string }> };

export default async function AdminCodeDetailPage({ params }: Props) {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
  const { id } = await params;
  const code = await getCodeById(id);
  if (!code) notFound();

  return (
    <main className="admin-page">
      <p>
        <Link className="back-link" href="/admin/codes">
          ← Danh sách mã
        </Link>
      </p>
      <section className="card">
        <p className="kicker">Chi tiết</p>
        <h1 className="mono" style={{ fontSize: "1.45rem", marginBottom: "1.15rem" }}>
          {code.code}
        </h1>
        <dl className="dl-grid">
          <dt>Gói</dt>
          <dd>{code.plan}</dd>
          <dt>Quota</dt>
          <dd className="mono">
            {code.solves_used} / {code.max_solves} token (còn{" "}
            {remainingSolves(code)})
          </dd>
          <dt>Trạng thái</dt>
          <dd>
            <span className={`badge badge-${code.status}`}>{code.status}</span>
          </dd>
          <dt>Nguồn</dt>
          <dd>{code.source}</dd>
          <dt>Ghi chú</dt>
          <dd>{code.note || "—"}</dd>
          <dt>Tạo lúc</dt>
          <dd>{new Date(code.created_at).toLocaleString()}</dd>
          <dt>Hết hạn</dt>
          <dd>
            {code.expires_at ? new Date(code.expires_at).toLocaleString() : "—"}
          </dd>
          <dt>Dùng gần nhất</dt>
          <dd>
            {code.last_used_at
              ? new Date(code.last_used_at).toLocaleString()
              : "—"}
          </dd>
        </dl>
      </section>
    </main>
  );
}
