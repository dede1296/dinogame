-- Dino·Hybride — sauvegarde en ligne.
-- À coller une fois dans Supabase : SQL Editor → New query → Run.

create table if not exists public.saves (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

-- Chaque joueur ne peut lire et écrire que sa propre sauvegarde.
alter table public.saves enable row level security;

create policy "lire sa sauvegarde" on public.saves
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "créer sa sauvegarde" on public.saves
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "modifier sa sauvegarde" on public.saves
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
