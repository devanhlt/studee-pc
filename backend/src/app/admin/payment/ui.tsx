"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useMemo, useState } from "react";

type PaymentState = {
  bank: string;
  account: string;
  holder: string;
  webhook_url: string;
  webhook_secret_present: boolean;
  webhook_secret_masked: string | null;
  preview_qr_url: string | null;
};

function generateSecret(): string {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export function AdminPaymentClient({ initial }: { initial: PaymentState }) {
  const router = useRouter();
  const [bank, setBank] = useState(initial.bank);
  const [account, setAccount] = useState(initial.account);
  const [holder, setHolder] = useState(initial.holder);
  const [webhookUrl] = useState(initial.webhook_url);
  const [webhookSecretDraft, setWebhookSecretDraft] = useState("");
  const [clearSecret, setClearSecret] = useState(false);
  const [secretPresent, setSecretPresent] = useState(
    initial.webhook_secret_present,
  );
  const [secretMasked, setSecretMasked] = useState(
    initial.webhook_secret_masked,
  );
  const [previewQr, setPreviewQr] = useState(initial.preview_qr_url);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);
  const [copied, setCopied] = useState<string | null>(null);

  const livePreview = useMemo(() => {
    if (!bank.trim() || !account.trim() || !holder.trim()) return previewQr;
    const params = new URLSearchParams({
      amount: "19000",
      addInfo: "STUDEEPREVIEW",
      accountName: holder.trim(),
    });
    const b = bank.trim().replace(/[^a-zA-Z0-9]/g, "");
    const a = account.trim().replace(/[^a-zA-Z0-9]/g, "");
    if (!b || !a) return previewQr;
    return `https://img.vietqr.io/image/${b}-${a}-compact.png?${params.toString()}`;
  }, [bank, account, holder, previewQr]);

  async function copyText(label: string, value: string) {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(label);
      setTimeout(() => setCopied(null), 2000);
    } catch {
      setError("Không sao chép được. Hãy chọn và copy thủ công.");
    }
  }

  async function save(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setOkMsg(null);
    try {
      const res = await fetch("/api/admin/payment", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          bank,
          account,
          holder,
          webhook_secret: clearSecret
            ? null
            : webhookSecretDraft.trim() || null,
          clear_webhook_secret: clearSecret,
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data?.error?.message ?? "Lưu thất bại");
        setBusy(false);
        return;
      }
      setBank(data.bank ?? "");
      setAccount(data.account ?? "");
      setHolder(data.holder ?? "");
      setSecretPresent(Boolean(data.webhook_secret_present));
      setSecretMasked(data.webhook_secret_masked ?? null);
      setPreviewQr(data.preview_qr_url ?? null);
      setWebhookSecretDraft("");
      setClearSecret(false);
      setOkMsg("Đã lưu cấu hình thanh toán.");
      setBusy(false);
      router.refresh();
    } catch {
      setError("Không kết nối được máy chủ.");
      setBusy(false);
    }
  }

  return (
    <div className="stack">
      {error ? <p className="err">{error}</p> : null}
      {okMsg ? <p className="ok">{okMsg}</p> : null}

      <section className="card">
        <h2>Webhook endpoint</h2>
        <p className="muted" style={{ margin: "0 0 1rem", fontSize: "0.9rem" }}>
          Dán URL này vào SePay → Webhooks. Event: <strong>Tiền vào</strong>.
          Payload: <strong>JSON</strong>. Không gọi API SePay từ đây — bạn tạo
          webhook thủ công trên dashboard SePay.
        </p>
        <div className="form-row">
          <code className="mono code-box">{webhookUrl}</code>
          <button
            className="btn"
            type="button"
            onClick={() => copyText("url", webhookUrl)}
          >
            {copied === "url" ? "Đã copy" : "Copy"}
          </button>
        </div>

        <div style={{ marginTop: "1.25rem" }}>
          <label htmlFor="webhook_secret">
            Webhook secret (tuỳ chọn — dán vào SePay làm API Key)
          </label>
          <div className="form-row triple">
            <input
              id="webhook_secret"
              type="password"
              autoComplete="off"
              value={webhookSecretDraft}
              onChange={(e) => {
                setWebhookSecretDraft(e.target.value);
                setClearSecret(false);
              }}
              placeholder={
                secretPresent
                  ? `Đã có: ${secretMasked ?? "••••"} — nhập mới để thay`
                  : "Để trống nếu chưa dùng API Key trên SePay"
              }
            />
            <button
              className="btn btn-ghost"
              type="button"
              onClick={() => {
                const s = generateSecret();
                setWebhookSecretDraft(s);
                setClearSecret(false);
                void copyText("secret", s);
              }}
            >
              Generate
            </button>
            <button
              className="btn btn-ghost"
              type="button"
              disabled={!webhookSecretDraft}
              onClick={() => copyText("secret", webhookSecretDraft)}
            >
              {copied === "secret" ? "Đã copy" : "Copy"}
            </button>
          </div>
          {secretPresent ? (
            <label className="check">
              <input
                type="checkbox"
                checked={clearSecret}
                onChange={(e) => setClearSecret(e.target.checked)}
              />
              Xóa webhook secret hiện tại
            </label>
          ) : null}
        </div>
      </section>

      <section className="card">
        <h2>VietQR</h2>
        <p className="muted" style={{ margin: "0 0 1rem", fontSize: "0.9rem" }}>
          Đủ 3 trường để tạo mã QR chuyển khoản (img.vietqr.io). App sẽ nhận URL
          QR từ backend khi tạo checkout.
        </p>
        <form onSubmit={save} className="form-stack">
          <div className="field">
            <label htmlFor="bank">Ngân hàng (BIN hoặc short name)</label>
            <input
              id="bank"
              value={bank}
              onChange={(e) => setBank(e.target.value)}
              placeholder="vd. 970436 hoặc VCB"
              required
            />
          </div>
          <div className="field">
            <label htmlFor="account">Số tài khoản</label>
            <input
              id="account"
              value={account}
              onChange={(e) => setAccount(e.target.value)}
              placeholder="Số TK thụ hưởng"
              required
            />
          </div>
          <div className="field">
            <label htmlFor="holder">Chủ tài khoản</label>
            <input
              id="holder"
              value={holder}
              onChange={(e) => setHolder(e.target.value)}
              placeholder="Tên chủ TK"
              required
            />
          </div>
          <button className="btn" type="submit" disabled={busy}>
            {busy ? "Đang lưu…" : "Lưu cấu hình"}
          </button>
        </form>

        {livePreview ? (
          <div className="qr-preview">
            <p className="muted" style={{ fontSize: "0.85rem" }}>
              Preview · 19.000₫ · STUDEEPREVIEW
            </p>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={livePreview}
              alt="VietQR preview"
              width={240}
              height={240}
            />
          </div>
        ) : null}
      </section>
    </div>
  );
}
