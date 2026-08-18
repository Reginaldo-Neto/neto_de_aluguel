-- ============================================================
--  Neto de Aluguel — Dias de indisponibilidade do voluntário
--  Cole no SQL Editor do Supabase e execute (Run).
-- ============================================================

create table if not exists public.helper_unavailability (
  id         uuid primary key default gen_random_uuid(),
  helper_id  uuid not null references public.profiles(id) on delete cascade,
  day        date not null,
  created_at timestamptz not null default now(),
  unique (helper_id, day)
);

create index if not exists helper_unavailability_helper_idx
  on public.helper_unavailability(helper_id);

alter table public.helper_unavailability enable row level security;

-- Leitura por qualquer autenticado (o idoso pode consultar ao agendar).
drop policy if exists unavail_select on public.helper_unavailability;
create policy unavail_select on public.helper_unavailability
  for select to authenticated using (true);

-- Só o próprio voluntário adiciona/remove os próprios dias.
drop policy if exists unavail_insert on public.helper_unavailability;
create policy unavail_insert on public.helper_unavailability
  for insert to authenticated with check (auth.uid() = helper_id);

drop policy if exists unavail_delete on public.helper_unavailability;
create policy unavail_delete on public.helper_unavailability
  for delete to authenticated using (auth.uid() = helper_id);
