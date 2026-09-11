-- Studee activation codes (run once against Neon)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS activation_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  plan text NOT NULL CHECK (plan IN ('basic', 'pro', '3xpro')),
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
