-- Studee activation codes (run once against Neon)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS packages (
  id text PRIMARY KEY,
  label text NOT NULL,
  amount_vnd integer NOT NULL CHECK (amount_vnd > 0),
  max_tokens integer NOT NULL CHECK (max_tokens > 0),
  ttl_days integer NOT NULL CHECK (ttl_days >= 1),
  active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS packages_active_sort_idx
  ON packages (active, sort_order, id);

INSERT INTO packages (id, label, amount_vnd, max_tokens, ttl_days, active, sort_order)
VALUES
  ('basic', 'Basic', 19000, 10000, 30, true, 10),
  ('pro', 'Pro', 49000, 50000, 60, true, 20),
  ('3xpro', '3xPro', 88000, 150000, 90, true, 30)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS activation_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  plan text NOT NULL,
  -- Token quota (legacy "lượt giải" scaled to token units).
  max_solves integer NOT NULL CHECK (max_solves > 0),
  solves_used integer NOT NULL DEFAULT 0 CHECK (solves_used >= 0),
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'revoked', 'exhausted')),
  note text,
  source text NOT NULL DEFAULT 'admin'
    CHECK (source IN ('admin', 'checkout')),
  external_ref text,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  last_used_at timestamptz
);

CREATE INDEX IF NOT EXISTS activation_codes_status_idx
  ON activation_codes (status);

CREATE INDEX IF NOT EXISTS activation_codes_created_at_idx
  ON activation_codes (created_at DESC);

-- Optional provider secret overrides (env vars remain the fallback)
CREATE TABLE IF NOT EXISTS provider_secrets (
  key text PRIMARY KEY,
  value text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
