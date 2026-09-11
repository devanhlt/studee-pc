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
    <main style={{ maxWidth: 720, margin: "0 auto", padding: "2rem 1.25rem 3rem" }}>
      <p style={{ marginBottom: "1rem" }}>
        <Link href="/admin/codes">← Danh sách mã</Link>
      </p>
      <section className="card">
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
          Chi tiết
        </p>
        <h1 className="mono" style={{ margin: "0 0 1.25rem", fontSize: "1.5rem" }}>
          {code.code}
        </h1>
        <dl
          style={{
            display: "grid",
            gridTemplateColumns: "140px 1fr",
            gap: "0.65rem 1rem",
            margin: 0,
          }}
        >
          <dt className="muted">Gói</dt>
          <dd style={{ margin: 0 }}>{code.plan}</dd>
          <dt className="muted">Quota</dt>
          <dd style={{ margin: 0 }} className="mono">
            {code.solves_used} / {code.max_solves} (còn {remainingSolves(code)})
          </dd>
          <dt className="muted">Trạng thái</dt>
          <dd style={{ margin: 0 }}>
            <span className={`badge badge-${code.status}`}>{code.status}</span>
          </dd>
          <dt className="muted">Nguồn</dt>
          <dd style={{ margin: 0 }}>{code.source}</dd>
          <dt className="muted">Ghi chú</dt>
          <dd style={{ margin: 0 }}>{code.note || "—"}</dd>
          <dt className="muted">Tạo lúc</dt>
          <dd style={{ margin: 0 }}>{new Date(code.created_at).toLocaleString()}</dd>
          <dt className="muted">Hết hạn</dt>
          <dd style={{ margin: 0 }}>
            {code.expires_at ? new Date(code.expires_at).toLocaleString() : "—"}
          </dd>
          <dt className="muted">Dùng gần nhất</dt>
          <dd style={{ margin: 0 }}>
            {code.last_used_at
              ? new Date(code.last_used_at).toLocaleString()
              : "—"}
          </dd>
        </dl>
      </section>
    </main>
  );
}
