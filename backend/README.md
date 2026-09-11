# Studee middleware + admin

Next.js app that:

- Proxies DeepSeek (`/v1/chat/completions`) and Mathpix (`/v3/*`) with server keys
- Issues and enforces **activation codes** (solves quota only)
- Hosts admin UI at `/admin`

## Live

- API / admin (current): https://studee-api.vercel.app
- Custom domain (attached on Vercel): `studees.vinius.asia`
  - Add DNS on Cloudflare for `vinius.asia`:
    - **CNAME** `studees` → `cname.vercel-dns.com`
    - or **A** `studees` → `76.76.21.21`
  - Then set Flutter `BackendConfig.defaultBaseUrl` to `https://studees.vinius.asia`

Admin: https://studee-api.vercel.app/admin/login  
Password: value of `ADMIN_PASSWORD` in local `backend/.env.local` (gitignored).

- Codes: `/admin/codes`
- API key rotation: `/admin/keys` (DB overrides for DeepSeek / Mathpix; env remains fallback)
  - If OCR returns `mathpix_not_configured` / HTTP 503, paste Mathpix `app_id` + `app_key` there (or set `MATHPIX_*` env and redeploy).

## Setup

1. Neon Postgres — run [`sql/schema.sql`](sql/schema.sql).
2. Copy [`.env.example`](.env.example) → `.env.local` and fill values (set real `MATHPIX_APP_ID` / `MATHPIX_APP_KEY`).
3. `npm install && npm run dev`

## Deploy (Vercel)

- Project: `studee-api` (Root Directory = `backend`)
- Env: `DATABASE_URL`, `DEEPSEEK_API_KEY`, `MATHPIX_APP_ID`, `MATHPIX_APP_KEY`, `ADMIN_PASSWORD`, `ADMIN_SESSION_SECRET`
  (Admin can override provider keys in Neon via `/admin/keys` without redeploying.)

App clients send `Authorization: Bearer <activation_code>`.

## Solve quota

Proxy routes (`/v1/chat/completions`, `/v3/text`, `/v3/pdf`) **authenticate only** — they do not increment usage.

The app calls `POST /v1/solves/consume` **once per question solve** (OCR + N LLM hops = 1 solve).
