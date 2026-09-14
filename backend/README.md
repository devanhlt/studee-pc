# Studee middleware + admin

Next.js app that:

- Proxies DeepSeek (`/v1/chat/completions`) and Mathpix (`/v3/*`) with server keys
- Issues and enforces **activation codes** (token quota)
- Auto-issues codes after bank transfer via **VietQR + SePay webhook + SSE**
- Hosts admin UI at `/admin`

## Live

- API / admin: https://studied.vinius.org
- Vercel alias (redirects to the custom domain): https://studee-api.vercel.app

Admin: https://studied.vinius.org/admin/login  
Password: value of `ADMIN_PASSWORD` in local `backend/.env.local` (gitignored).

- Codes: `/admin/codes`
- API key rotation: `/admin/keys` (DB overrides for DeepSeek / Mathpix; env remains fallback)
  - If OCR returns `mathpix_not_configured` / HTTP 503, paste Mathpix `app_id` + `app_key` there (or set `MATHPIX_*` env and redeploy).
- Payment: `/admin/payment` (VietQR bank details + webhook URL to paste into SePay)

## Setup

1. Neon Postgres — run [`sql/schema.sql`](sql/schema.sql), then [`sql/002_checkout.sql`](sql/002_checkout.sql), then [`sql/003_quota_tokens.sql`](sql/003_quota_tokens.sql) if upgrading an existing database.
2. Copy [`.env.example`](.env.example) → `.env.local` and fill values (set real `MATHPIX_APP_ID` / `MATHPIX_APP_KEY`).
3. `npm install && npm run dev`
4. Open `/admin/payment`, save bank / STK / chủ TK, **copy the webhook URL**, paste it into SePay by hand.

## SePay webhook (manual)

No SePay API key in Vercel env. The backend only **receives** webhooks.

1. Admin → **Thanh toán** → copy webhook URL (`…/api/sepay/webhook`).
2. In SePay dashboard → create webhook:
   - URL: paste the copied URL
   - Event: **Tiền vào**
   - Payload: **JSON**
   - Auto-retry: on
   - Payment-code prefix: `STUDEE` (Company → General settings)
3. Optional: generate a webhook secret on `/admin/payment`, copy it, set SePay auth to **API Key** with the same string.

Checkout flow: app `POST /v1/checkout` → shows VietQR → opens SSE `GET /v1/checkout/{id}/events` → SePay webhook matches `pay_code` → issues activation code → SSE pushes code to app.

## Deploy (Vercel)

- Project: `studee-api` (Root Directory = `backend`)
- Env: `DATABASE_URL`, `DEEPSEEK_API_KEY`, `MATHPIX_APP_ID`, `MATHPIX_APP_KEY`, `ADMIN_PASSWORD`, `ADMIN_SESSION_SECRET`
  (Admin can override provider keys in Neon via `/admin/keys` without redeploying. Bank / webhook secret live in `/admin/payment` — no new env vars.)

App clients send `Authorization: Bearer <activation_code>`.

## Solve quota

Proxy routes (`/v1/chat/completions`, `/v3/text`, `/v3/pdf`) **authenticate only** — they do not increment usage.

The app calls `POST /v1/solves/consume` **once per question** with `{ "kind": "text" | "picture" }`.
Text costs **100 token**, picture costs **200 token**. Plan quotas are legacy solve counts × 100 (Basic 10.000, Pro 50.000, 3xPro 150.000).
