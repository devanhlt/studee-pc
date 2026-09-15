"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import type {
  ProviderSecretKey,
  SecretStatus,
} from "@/lib/provider-secrets";

const LABELS: Record<ProviderSecretKey, string> = {
  deepseek_api_key: "DeepSeek API key",
  mathpix_app_id: "Mathpix App ID",
  mathpix_app_key: "Mathpix App Key",
};

const SOURCE_LABEL: Record<SecretStatus["source"], string> = {
  db: "DB override",
  env: "Env (Vercel)",
  missing: "Chưa cấu hình",
};

export function AdminKeysClient({
  initialSecrets,
}: {
  initialSecrets: SecretStatus[];
}) {
  const router = useRouter();
  const [secrets, setSecrets] = useState(initialSecrets);
  const [drafts, setDrafts] = useState<Record<ProviderSecretKey, string>>({
    deepseek_api_key: "",
    mathpix_app_id: "",
    mathpix_app_key: "",
  });
  const [busyKey, setBusyKey] = useState<ProviderSecretKey | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);

  async function save(key: ProviderSecretKey, e: FormEvent) {
    e.preventDefault();
    setBusyKey(key);
    setError(null);
    setOkMsg(null);
    try {
      const res = await fetch("/api/admin/keys", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ key, value: drafts[key] }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Lưu thất bại");
        setBusyKey(null);
        return;
      }
      setSecrets(data.secrets as SecretStatus[]);
      setDrafts((prev) => ({ ...prev, [key]: "" }));
      setOkMsg(`Đã cập nhật ${LABELS[key]}`);
      setBusyKey(null);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusyKey(null);
    }
  }

  async function clearOverride(key: ProviderSecretKey) {
    if (!confirm(`Xóa override DB cho ${LABELS[key]}? Sẽ quay về env.`)) return;
    setBusyKey(key);
    setError(null);
    setOkMsg(null);
    try {
      const res = await fetch("/api/admin/keys", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ key }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Xóa thất bại");
        setBusyKey(null);
        return;
      }
      setSecrets(data.secrets as SecretStatus[]);
      setOkMsg(`Đã xóa override ${LABELS[key]}`);
      setBusyKey(null);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusyKey(null);
    }
  }

  return (
    <div className="stack">
      {error ? <p className="err">{error}</p> : null}
      {okMsg ? <p className="ok">{okMsg}</p> : null}

      {secrets.map((s) => (
        <section key={s.key} className="card">
          <div className="card-head">
            <div>
              <h2>{LABELS[s.key]}</h2>
              <p className="muted" style={{ margin: "0.35rem 0 0", fontSize: "0.85rem" }}>
                Nguồn: {SOURCE_LABEL[s.source]}
                {s.masked ? (
                  <>
                    {" · "}
                    <span className="mono">{s.masked}</span>
                  </>
                ) : null}
                {s.updated_at ? (
                  <> · cập nhật {new Date(s.updated_at).toLocaleString()}</>
                ) : null}
              </p>
            </div>
            {s.source === "db" ? (
              <button
                className="btn btn-danger"
                type="button"
                disabled={busyKey === s.key}
                onClick={() => clearOverride(s.key)}
              >
                Xóa override
              </button>
            ) : null}
          </div>

          <form onSubmit={(e) => save(s.key, e)} className="form-row">
            <div className="field">
              <label htmlFor={s.key}>Giá trị mới</label>
              <input
                id={s.key}
                type="password"
                autoComplete="off"
                value={drafts[s.key]}
                onChange={(e) =>
                  setDrafts((prev) => ({ ...prev, [s.key]: e.target.value }))
                }
                placeholder="Dán key mới để rotate…"
                required
              />
            </div>
            <button className="btn" type="submit" disabled={busyKey === s.key}>
              {busyKey === s.key ? "Đang lưu…" : "Lưu"}
            </button>
          </form>
        </section>
      ))}
    </div>
  );
}
