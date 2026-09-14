import { neon } from "@neondatabase/serverless";

export type ActivationCodeRow = {
  id: string;
  code: string;
  plan: string;
  max_solves: number;
  solves_used: number;
  status: string;
  note: string | null;
  source: string;
  external_ref: string | null;
  created_at: string;
  expires_at: string | null;
  last_used_at: string | null;
};

export type CheckoutSessionRow = {
  id: string;
  pay_code: string;
  plan: string;
  amount_vnd: number;
  status: string;
  client_secret: string;
  contact: string | null;
  activation_code_id: string | null;
  sepay_tx_id: number | null;
  paid_amount_vnd: number | null;
  created_at: string;
  expires_at: string;
  paid_at: string | null;
};

export function getSql() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL is not set");
  }
  return neon(url);
}
