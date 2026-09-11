"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useMemo, useState } from "react";
import type { PlanId } from "@/lib/plans";

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

type Presets = Record<PlanId, { label: string; maxSolves: number }>;

export function AdminCodesClient({
  initialCodes,
  presets,
}: {
  initialCodes: CodeRow[];
  presets: Presets;
}) {
  const router = useRouter();
  const [codes, setCodes] = useState(initialCodes);
  const [plan, setPlan] = useState<PlanId>("pro");
  const [maxSolves, setMaxSolves] = useState(String(presets.pro.maxSolves));
  const [note, setNote] = useState("");
  const [expiresAt, setExpiresAt] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [created, setCreated] = useState<string | null>(null);

  const sorted = useMemo(() => codes, [codes]);

  function onPlanChange(next: PlanId) {
    setPlan(next);
    setMaxSolves(String(presets[next].maxSolves));
  }

  async function logout() {
    await fetch("/api/admin/session", { method: "DELETE" });
    router.replace("/admin/login");
    router.refresh();
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

  return (
    <div style={{ display: "grid", gap: "1.5rem" }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          gap: "0.75rem",
          flexWrap: "wrap",
        }}
      >
        <nav style={{ display: "flex", gap: "0.85rem", fontSize: "0.92rem" }}>
          <span className="muted">Mã kích hoạt</span>
          <Link href="/admin/keys">API keys</Link>
        </nav>
        <button className="btn btn-ghost" type="button" onClick={logout}>
          Đăng xuất
        </button>
      </div>

      <section className="card">
        <h2 style={{ margin: "0 0 1rem", fontSize: "1.15rem" }}>Tạo mã mới</h2>
        <form
          onSubmit={onCreate}
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))",
            gap: "0.85rem 1rem",
            alignItems: "end",
          }}
        >
          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="plan">Gói</label>
            <select
              id="plan"
              value={plan}
              onChange={(e) => onPlanChange(e.target.value as PlanId)}
            >
              {(Object.keys(presets) as PlanId[]).map((id) => (
                <option key={id} value={id}>
                  {presets[id].label} ({presets[id].maxSolves} solves)
                </option>
              ))}
            </select>
          </div>
          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="max">Max solves</label>
            <input
              id="max"
              type="number"
              min={1}
              value={maxSolves}
              onChange={(e) => setMaxSolves(e.target.value)}
              required
            />
          </div>
          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="expires">Hết hạn (tuỳ chọn)</label>
            <input
              id="expires"
              type="datetime-local"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
            />
          </div>
          <div className="field" style={{ marginBottom: 0, gridColumn: "1 / -1" }}>
            <label htmlFor="note">Ghi chú</label>
            <input
              id="note"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Email khách / đơn hàng…"
            />
          </div>
          <div>
            <button className="btn" type="submit" disabled={busy}>
              {busy ? "Đang tạo…" : "Tạo mã"}
            </button>
          </div>
        </form>
        {error ? <p className="err" style={{ marginTop: "0.85rem" }}>{error}</p> : null}
        {created ? (
          <p style={{ marginTop: "0.85rem" }}>
            Mã mới: <span className="mono">{created}</span>
          </p>
        ) : null}
      </section>

      <section className="card" style={{ overflowX: "auto" }}>
        <table className="table">
          <thead>
            <tr>
              <th>Mã</th>
              <th>Gói</th>
              <th>Quota</th>
              <th>Trạng thái</th>
              <th>Tạo lúc</th>
              <th></th>
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
                      <div className="muted" style={{ fontSize: "0.8rem", marginTop: 2 }}>
                        {c.note}
                      </div>
                    ) : null}
                  </td>
                  <td>{c.plan}</td>
                  <td className="mono">
                    {c.solves_used}/{c.max_solves}
                  </td>
                  <td>
                    <span className={`badge badge-${c.status}`}>{c.status}</span>
                  </td>
                  <td className="muted" style={{ whiteSpace: "nowrap" }}>
                    {new Date(c.created_at).toLocaleString()}
                  </td>
                  <td>
                    {c.status === "active" ? (
                      <button
                        className="btn btn-danger"
                        type="button"
                        onClick={() => revoke(c.id)}
                      >
                        Thu hồi
                      </button>
                    ) : null}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
