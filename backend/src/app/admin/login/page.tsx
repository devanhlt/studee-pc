"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminLoginPage() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password }),
      });
      if (!res.ok) {
        setError("Sai mật khẩu.");
        setBusy(false);
        return;
      }
      router.replace("/admin/codes");
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusy(false);
    }
  }

  return (
    <main
      style={{
        minHeight: "100vh",
        display: "grid",
        placeItems: "center",
        padding: "1.5rem",
      }}
    >
      <form className="card" style={{ width: "min(100%, 380px)" }} onSubmit={onSubmit}>
        <p className="muted" style={{ margin: "0 0 0.35rem", fontSize: "0.78rem", letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--accent)" }}>
          Studee
        </p>
        <h1 style={{ margin: "0 0 0.35rem", fontFamily: "var(--font-display), serif", fontSize: "1.75rem" }}>
          Admin
        </h1>
        <p className="muted" style={{ margin: "0 0 1.25rem" }}>
          Đăng nhập để quản lý mã kích hoạt.
        </p>
        <div className="field">
          <label htmlFor="password">Mật khẩu</label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>
        {error ? <p className="err">{error}</p> : null}
        <button className="btn" type="submit" disabled={busy} style={{ width: "100%", marginTop: "0.5rem" }}>
          {busy ? "Đang đăng nhập…" : "Đăng nhập"}
        </button>
      </form>
    </main>
  );
}
