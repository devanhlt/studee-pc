-- Convert leftover solve-count quotas to tokens (×100).
-- Idempotent: skip rows already at token scale (>= 10000).
UPDATE activation_codes
SET
  max_solves = max_solves * 100,
  solves_used = solves_used * 100
WHERE max_solves < 10000;
