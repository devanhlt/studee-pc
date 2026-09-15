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
    <main className="login-wrap">
      <form className="card login-card" onSubmit={onSubmit}>
        <img
          className="login-logo"
          src="/app-icon.png"
          alt="Studee"
          width={56}
          height={56}
        />
        <p className="kicker">Studee</p>
        <h1>Admin</h1>
        <p className="lede">Đăng nhập để quản lý mã kích hoạt.</p>
        <div className="field" style={{ marginTop: "1.25rem" }}>
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
        <button
          className="btn"
          type="submit"
          disabled={busy}
          style={{ width: "100%", marginTop: "0.35rem" }}
        >
          {busy ? "Đang đăng nhập…" : "Đăng nhập"}
        </button>
      </form>
    </main>
  );
}
