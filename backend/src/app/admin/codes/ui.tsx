"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useMemo, useState } from "react";

export type CodeRow = {
  id: string;
  code: string;
  plan: string;
  max_solves: number;
  solves_used: number;
  status: string;
  note: string | null;
  created_at: string;
  expires_at: string | null;
  last_used_at: string | null;
};

export type PackageOption = {
  id: string;
  label: string;
  max_tokens: number;
  active: boolean;
};

export function AdminCodesClient({
  initialCodes,
  packages,
}: {
  initialCodes: CodeRow[];
  packages: PackageOption[];
}) {
  const router = useRouter();
  const selectable = packages.filter((p) => p.active);
  const fallback = selectable[0] ?? packages[0];
  const [codes, setCodes] = useState(initialCodes);
  const [plan, setPlan] = useState(fallback?.id ?? "");
  const [maxSolves, setMaxSolves] = useState(
    String(fallback?.max_tokens ?? 10000),
  );
  const [note, setNote] = useState("");
  const [expiresAt, setExpiresAt] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [created, setCreated] = useState<string | null>(null);

  const sorted = useMemo(() => codes, [codes]);
  const packageMap = useMemo(
    () => Object.fromEntries(packages.map((p) => [p.id, p])),
    [packages],
  );

  function onPlanChange(next: string) {
    setPlan(next);
    const pkg = packageMap[next];
    if (pkg) setMaxSolves(String(pkg.max_tokens));
  }

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setCreated(null);
    try {
      const res = await fetch("/api/admin/codes", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          plan,
          max_solves: Number(maxSolves),
          note: note.trim() || undefined,
          expires_at: expiresAt ? new Date(expiresAt).toISOString() : null,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Tạo mã thất bại");
        setBusy(false);
        return;
      }
      setCodes((prev) => [data.code as CodeRow, ...prev]);
      setCreated((data.code as CodeRow).code);
      setNote("");
      setExpiresAt("");
      setBusy(false);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusy(false);
    }
  }

  async function revoke(id: string) {
    if (!confirm("Thu hồi mã này?")) return;
    const res = await fetch(`/api/admin/codes/${id}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "revoke" }),
    });
    if (!res.ok) return;
    const data = await res.json();
    setCodes((prev) =>
      prev.map((c) => (c.id === id ? (data.code as CodeRow) : c)),
    );
  }

  if (!fallback) {
    return (
      <section className="card">
        <p className="err">
          Chưa có gói nào.{" "}
          <Link href="/admin/packages">Tạo gói trước</Link>.
        </p>
      </section>
    );
  }

  return (
    <div className="stack">
      <section className="card">
        <h2>Tạo mã mới</h2>
        <form onSubmit={onCreate} className="form-grid">
          <div className="field">
            <label htmlFor="plan">Gói</label>
            <select
              id="plan"
              value={plan}
              onChange={(e) => onPlanChange(e.target.value)}
            >
              {(selectable.length > 0 ? selectable : packages).map((pkg) => (
                <option key={pkg.id} value={pkg.id}>
                  {pkg.label} ({pkg.max_tokens.toLocaleString("en-US")} token)
                  {!pkg.active ? " · ẩn" : ""}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="max">Max token</label>
            <input
              id="max"
              type="number"
              min={1}
              value={maxSolves}
              onChange={(e) => setMaxSolves(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="note">Ghi chú</label>
            <input
              id="note"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Tuỳ chọn"
            />
          </div>
          <div className="field">
            <label htmlFor="expires">Hết hạn</label>
            <input
              id="expires"
              type="datetime-local"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
            />
          </div>
          {error ? <p className="err">{error}</p> : null}
          {created ? (
            <p className="ok">
              Đã tạo: <code>{created}</code>
            </p>
          ) : null}
          <button className="btn" type="submit" disabled={busy || !plan}>
            {busy ? "Đang tạo…" : "Tạo mã"}
          </button>
        </form>
      </section>

      <section className="card">
        <h2>Danh sách mã</h2>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Gói</th>
                <th>Quota</th>
                <th>Trạng thái</th>
                <th>Tạo lúc</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {sorted.length === 0 ? (
                <tr>
                  <td colSpan={6} className="muted">
                    Chưa có mã nào.
                  </td>
                </tr>
              ) : (
                sorted.map((c) => (
                  <tr key={c.id}>
                    <td>
                      <Link className="mono" href={`/admin/codes/${c.id}`}>
                        {c.code}
                      </Link>
                      {c.note ? (
                        <div
                          className="muted"
                          style={{ fontSize: "0.8rem", marginTop: 2 }}
                        >
                          {c.note}
                        </div>
                      ) : null}
                    </td>
                    <td>{packageMap[c.plan]?.label ?? c.plan}</td>
                    <td className="mono">
                      {c.solves_used.toLocaleString("en-US")}/
                      {c.max_solves.toLocaleString("en-US")} token
                    </td>
                    <td>
                      <span className={`badge badge-${c.status}`}>
                        {c.status}
                      </span>
                    </td>
                    <td className="muted nowrap">
                      {new Date(c.created_at).toLocaleString()}
                    </td>
                    <td>
                      <div className="row-actions">
                        {c.status === "active" ? (
                          <button
                            className="btn btn-danger"
                            type="button"
                            onClick={() => revoke(c.id)}
                          >
                            Thu hồi
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
