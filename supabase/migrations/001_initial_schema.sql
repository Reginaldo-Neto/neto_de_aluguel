-- ============================================================
-- Neto de Aluguel — Schema inicial
-- ============================================================

-- Perfis de usuários (estende auth.users)
create table if not exists public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  name        text        not null,
  role        text        not null check (role in ('elder', 'helper')),
  bio         text,
  hourly_rate numeric(10,2),
  categories  text[]      not null default '{}',
  rating      numeric(3,2) not null default 0,
  total_sessions int      not null default 0,
  is_available boolean    not null default true,
  created_at  timestamptz not null default now()
);

-- Sessões
create table if not exists public.sessions (
  id               uuid        primary key default gen_random_uuid(),
  elder_id         uuid        not null references public.profiles(id) on delete cascade,
  helper_id        uuid        not null references public.profiles(id) on delete cascade,
  scheduled_at     timestamptz not null,
  duration_minutes int         not null default 60,
  category         text        not null,
  status           text        not null default 'pending'
                               check (status in ('pending','confirmed','inProgress','completed','cancelled')),
  rating           numeric(3,2),
  notes            text,
  created_at       timestamptz not null default now()
);

-- ── Row Level Security ──────────────────────────────────────────

alter table public.profiles   enable row level security;
alter table public.sessions   enable row level security;

-- Qualquer usuário autenticado pode ver o próprio perfil
create policy "Usuário vê próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

-- Todos os usuários autenticados podem ver helpers
create policy "Helpers visíveis a todos"
  on public.profiles for select
  using (role = 'helper');

-- Usuário pode atualizar somente o próprio perfil
create policy "Usuário edita próprio perfil"
  on public.profiles for update
  using (auth.uid() = id);

-- Sessões: cada parte (idoso ou ajudante) vê as suas
create policy "Partes da sessão podem ver"
  on public.sessions for select
  using (auth.uid() = elder_id or auth.uid() = helper_id);

-- Somente o idoso pode criar sessões
create policy "Idoso cria sessão"
  on public.sessions for insert
  with check (auth.uid() = elder_id);

-- Partes podem atualizar o status da sessão
create policy "Partes atualizam sessão"
  on public.sessions for update
  using (auth.uid() = elder_id or auth.uid() = helper_id);

-- ── Trigger: cria perfil automaticamente ao registrar ──────────

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'elder')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
