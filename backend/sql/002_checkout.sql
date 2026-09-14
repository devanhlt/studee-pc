-- Checkout sessions + SePay webhook audit (run against Neon after schema.sql)

CREATE TABLE IF NOT EXISTS checkout_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pay_code text NOT NULL UNIQUE,
  plan text NOT NULL CHECK (plan IN ('basic', 'pro', '3xpro')),
  amount_vnd integer NOT NULL CHECK (amount_vnd > 0),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'claimed', 'paid', 'expired')),
  client_secret text NOT NULL,
  contact text,
  activation_code_id uuid REFERENCES activation_codes(id),
  sepay_tx_id bigint,
  paid_amount_vnd integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  paid_at timestamptz
);

CREATE INDEX IF NOT EXISTS checkout_sessions_pay_code_idx
  ON checkout_sessions (pay_code);

CREATE INDEX IF NOT EXISTS checkout_sessions_status_created_idx
  ON checkout_sessions (status, created_at DESC);

-- SePay transaction id is stable across retries — use as dedup key
CREATE TABLE IF NOT EXISTS sepay_events (
  id bigint PRIMARY KEY,
  payload jsonb NOT NULL,
  matched_session uuid,
  received_at timestamptz NOT NULL DEFAULT now()
);
