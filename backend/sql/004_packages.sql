-- Sellable packages (admin-managed). Run after 003_quota_tokens.sql.

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

-- Allow any package id on codes / checkouts (catalog lives in packages).
ALTER TABLE activation_codes DROP CONSTRAINT IF EXISTS activation_codes_plan_check;
ALTER TABLE checkout_sessions DROP CONSTRAINT IF EXISTS checkout_sessions_plan_check;
