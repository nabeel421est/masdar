-- Masdar: shared data table. Only emails listed in masdar_members can read or write.
create table if not exists public.masdar_members (email text primary key);
alter table public.masdar_members enable row level security;

create or replace function public.is_masdar_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.masdar_members m where lower(m.email) = lower(auth.jwt() ->> 'email'));
$$;
revoke all on function public.is_masdar_member() from public, anon;
grant execute on function public.is_masdar_member() to authenticated;

create table if not exists public.masdar_docs (
  col text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (col, id)
);
alter table public.masdar_docs enable row level security;
revoke all on public.masdar_docs from anon;
grant select, insert, update, delete on public.masdar_docs to authenticated;

create policy masdar_docs_select on public.masdar_docs for select to authenticated using (public.is_masdar_member());
create policy masdar_docs_insert on public.masdar_docs for insert to authenticated with check (public.is_masdar_member());
create policy masdar_docs_update on public.masdar_docs for update to authenticated using (public.is_masdar_member()) with check (public.is_masdar_member());
create policy masdar_docs_delete on public.masdar_docs for delete to authenticated using (public.is_masdar_member());

alter publication supabase_realtime add table public.masdar_docs;
