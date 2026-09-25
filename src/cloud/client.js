import { createClient } from "@supabase/supabase-js";

// Both values are public by design: access is enforced by row-level security in Supabase.
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

export const supabase = url && key
  ? createClient(url, key, { auth: { persistSession: true, autoRefreshToken: true } })
  : null;

export const cloudEnabled = supabase !== null;
