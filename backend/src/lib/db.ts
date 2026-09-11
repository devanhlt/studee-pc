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

export function getSql() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL is not set");
  }
  return neon(url);
}
