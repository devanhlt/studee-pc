"use client";

import { FormEvent, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

export type PackageRow = {
  id: string;
  label: string;
  amount_vnd: number;
  max_tokens: number;
  ttl_days: number;
  active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

function formatVnd(n: number) {
  return `${n.toLocaleString("vi-VN")}₫`;
}

function formatTokens(n: number) {
  return n.toLocaleString("en-US");
}

export function AdminPackagesClient({
  initialPackages,
  initialAppDisplayEnabled,
}: {
  initialPackages: PackageRow[];
  initialAppDisplayEnabled: boolean;
}) {
  const router = useRouter();
  const [packages, setPackages] = useState(initialPackages);
  const [appDisplayEnabled, setAppDisplayEnabled] = useState(
    initialAppDisplayEnabled,
  );
  const [displayBusy, setDisplayBusy] = useState(false);
  const [id, setId] = useState("");
  const [label, setLabel] = useState("");
  const [amount, setAmount] = useState("19000");
  const [tokens, setTokens] = useState("10000");
  const [ttl, setTtl] = useState("30");
  const [sortOrder, setSortOrder] = useState("40");
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [editing, setEditing] = useState<PackageRow | null>(null);

  const sorted = useMemo(
    () =>
      [...packages].sort(
        (a, b) => a.sort_order - b.sort_order || a.id.localeCompare(b.id),
      ),
    [packages],
  );

  const activeCount = packages.filter((p) => p.active).length;

  function startEdit(pkg: PackageRow) {
    setEditing(pkg);
    setLabel(pkg.label);
    setAmount(String(pkg.amount_vnd));
    setTokens(String(pkg.max_tokens));
    setTtl(String(pkg.ttl_days));
    setSortOrder(String(pkg.sort_order));
    setError(null);
  }

  function cancelEdit() {
    setEditing(null);
    setLabel("");
    setAmount("19000");
    setTokens("10000");
    setTtl("30");
    setSortOrder("40");
    setId("");
    setError(null);
  }

  async function toggleAppDisplay(next: boolean) {
    setDisplayBusy(true);
    setError(null);
    setOkMsg(null);
    try {
      const res = await fetch("/api/admin/packages", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ app_display_enabled: next }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Không lưu cấu hình được");
        setDisplayBusy(false);
        return;
      }
      setAppDisplayEnabled(Boolean(data.app_display_enabled));
      setOkMsg(
        next
          ? "Đã bật hiển thị gói trên app."
          : "Đã tắt hiển thị gói trên app.",
      );
      setDisplayBusy(false);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setDisplayBusy(false);
    }
  }

  async function onCreate(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/packages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id,
          label,
          amount_vnd: Number(amount),
          max_tokens: Number(tokens),
          ttl_days: Number(ttl),
          sort_order: Number(sortOrder),
          active: true,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Tạo gói thất bại");
        setBusy(false);
        return;
      }
      setPackages((prev) => [...prev, data.package as PackageRow]);
      cancelEdit();
      setBusy(false);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusy(false);
    }
  }

  async function onSaveEdit(e: FormEvent) {
    e.preventDefault();
    if (!editing) return;
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/admin/packages/${editing.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          label,
          amount_vnd: Number(amount),
          max_tokens: Number(tokens),
          ttl_days: Number(ttl),
          sort_order: Number(sortOrder),
          active: editing.active,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Cập nhật thất bại");
        setBusy(false);
        return;
      }
      const next = data.package as PackageRow;
      setPackages((prev) => prev.map((p) => (p.id === next.id ? next : p)));
      cancelEdit();
      setBusy(false);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusy(false);
    }
  }

  async function toggleActive(pkg: PackageRow) {
    if (pkg.active && activeCount <= 1) {
      setError("Cần ít nhất 1 gói đang bán.");
      return;
    }
    setError(null);
    const res = await fetch(`/api/admin/packages/${pkg.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ active: !pkg.active }),
    });
    const data = await res.json();
    if (!res.ok) {
      setError(data?.error?.message ?? "Không đổi trạng thái được");
      return;
    }
    const next = data.package as PackageRow;
    setPackages((prev) => prev.map((p) => (p.id === next.id ? next : p)));
    router.refresh();
  }

  async function remove(pkg: PackageRow) {
    if (packages.length <= 1) {
      setError("Cần ít nhất 1 gói.");
      return;
    }
    if (!confirm(`Xóa gói “${pkg.label}” (${pkg.id})?`)) return;
    setError(null);
    const res = await fetch(`/api/admin/packages/${pkg.id}`, {
      method: "DELETE",
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      setError(data?.error?.message ?? "Xóa thất bại");
      return;
    }
    setPackages((prev) => prev.filter((p) => p.id !== pkg.id));
    if (editing?.id === pkg.id) cancelEdit();
    router.refresh();
  }

  return (
    <div className="stack">
      <section className="card">
        <h2>Hiển thị trên app</h2>
        <p className="muted" style={{ marginTop: 0 }}>
          Khi tắt, app không hiện danh sách gói / nút yêu cầu mã và không tạo
          được checkout.
        </p>
        <label className="check">
          <input
            type="checkbox"
            checked={appDisplayEnabled}
            disabled={displayBusy}
            onChange={(e) => toggleAppDisplay(e.target.checked)}
          />
          Hiện gói trên app
        </label>
        {okMsg ? <p className="ok">{okMsg}</p> : null}
      </section>

      <section className="card">
        <h2>{editing ? `Sửa gói · ${editing.id}` : "Thêm gói"}</h2>
        <form
          onSubmit={editing ? onSaveEdit : onCreate}
          className="form-grid"
        >
          {!editing ? (
            <div className="field">
              <label htmlFor="pkg-id">ID (slug)</label>
              <input
                id="pkg-id"
                value={id}
                onChange={(e) => setId(e.target.value)}
                placeholder="vd: student"
                pattern="[a-z0-9][a-z0-9_-]{0,31}"
                required
              />
            </div>
          ) : null}
          <div className="field">
            <label htmlFor="pkg-label">Tên hiển thị</label>
            <input
              id="pkg-label"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="pkg-amount">Giá (₫)</label>
            <input
              id="pkg-amount"
              type="number"
              min={1}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="pkg-tokens">Token</label>
            <input
              id="pkg-tokens"
              type="number"
              min={1}
              value={tokens}
              onChange={(e) => setTokens(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="pkg-ttl">Hạn mã (ngày)</label>
            <input
              id="pkg-ttl"
              type="number"
              min={1}
              value={ttl}
              onChange={(e) => setTtl(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="pkg-sort">Thứ tự</label>
            <input
              id="pkg-sort"
              type="number"
              value={sortOrder}
              onChange={(e) => setSortOrder(e.target.value)}
            />
          </div>
          {error ? <p className="err">{error}</p> : null}
          <div className="row-actions">
            <button className="btn" type="submit" disabled={busy}>
              {busy
                ? "Đang lưu…"
                : editing
                  ? "Lưu thay đổi"
                  : "Thêm gói"}
            </button>
            {editing ? (
              <button
                className="btn btn-ghost"
                type="button"
                onClick={cancelEdit}
              >
                Hủy
              </button>
            ) : null}
          </div>
        </form>
      </section>

      <section className="card">
        <h2>Danh sách ({packages.length})</h2>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Gói</th>
                <th>Giá</th>
                <th>Token</th>
                <th>Hạn</th>
                <th>Trạng thái</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {sorted.map((pkg) => (
                <tr key={pkg.id}>
                  <td>
                    <strong>{pkg.label}</strong>
                    <div className="muted mono">{pkg.id}</div>
                  </td>
                  <td>{formatVnd(pkg.amount_vnd)}</td>
                  <td className="mono">{formatTokens(pkg.max_tokens)}</td>
                  <td>{pkg.ttl_days} ngày</td>
                  <td>
                    <span
                      className={
                        pkg.active ? "badge badge-active" : "badge"
                      }
                    >
                      {pkg.active ? "Đang bán" : "Ẩn"}
                    </span>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button
                        className="btn btn-ghost"
                        type="button"
                        onClick={() => startEdit(pkg)}
                      >
                        Sửa
                      </button>
                      <button
                        className="btn btn-ghost"
                        type="button"
                        onClick={() => toggleActive(pkg)}
                      >
                        {pkg.active ? "Ẩn" : "Bán"}
                      </button>
                      <button
                        className="btn btn-danger"
                        type="button"
                        onClick={() => remove(pkg)}
                        disabled={packages.length <= 1}
                      >
                        Xóa
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
