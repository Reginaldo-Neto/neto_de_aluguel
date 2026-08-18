-- ============================================================
--  Neto de Aluguel — Schema + RLS + Seed (Supabase / PostgreSQL)
--  Cole tudo no SQL Editor do Supabase e execute (Run).
--  Idempotente: pode rodar mais de uma vez sem quebrar.
-- ============================================================

-- Extensão para hash de senha no seed de exemplo.
create extension if not exists pgcrypto with schema extensions;

-- ------------------------------------------------------------
-- 1) Tabela PROFILES
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  name           text not null,
  role           text not null default 'elder' check (role in ('elder','helper')),
  avatar_url     text,
  categories     text[] not null default '{}',
  rating         numeric not null default 0,
  total_sessions integer not null default 0,
  bio            text,
  hourly_rate    numeric,
  is_available   boolean not null default true,
  created_at     timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2) Tabela SESSIONS
--    status usa os nomes do enum do app (camelCase): inProgress
-- ------------------------------------------------------------
create table if not exists public.sessions (
  id               uuid primary key default gen_random_uuid(),
  elder_id         uuid not null references public.profiles(id) on delete cascade,
  helper_id        uuid not null references public.profiles(id) on delete cascade,
  scheduled_at     timestamptz not null,
  duration_minutes integer not null default 60,
  category         text not null,
  status           text not null default 'pending'
                     check (status in ('pending','confirmed','inProgress','completed','cancelled')),
  rating           numeric,
  notes            text,
  created_at       timestamptz not null default now()
);

create index if not exists sessions_elder_idx  on public.sessions(elder_id);
create index if not exists sessions_helper_idx on public.sessions(helper_id);

-- ------------------------------------------------------------
-- 3) Trigger: cria o profile automaticamente no cadastro
--    Lê name/role do metadata enviado pelo app no signUp.
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'elder')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- 4) Row Level Security
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.sessions enable row level security;

-- PROFILES ---------------------------------------------------
-- Qualquer usuário autenticado lê os perfis (necessário para
-- listar voluntários e embutir elder/helper nas sessões).
drop policy if exists profiles_select_all on public.profiles;
create policy profiles_select_all on public.profiles
  for select to authenticated using (true);

-- Cada um só edita o próprio perfil (disponibilidade, categorias).
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

-- (INSERT em profiles é feito pelo trigger, que roda como SECURITY DEFINER.)

-- SESSIONS ---------------------------------------------------
-- Só participante (idoso ou voluntário) enxerga a sessão.
drop policy if exists sessions_select_participant on public.sessions;
create policy sessions_select_participant on public.sessions
  for select to authenticated
  using (auth.uid() = elder_id or auth.uid() = helper_id);

-- O idoso cria a própria sessão (agendar / ligar).
drop policy if exists sessions_insert_elder on public.sessions;
create policy sessions_insert_elder on public.sessions
  for insert to authenticated
  with check (auth.uid() = elder_id);

-- Participante atualiza a sessão (concluir / avaliar).
drop policy if exists sessions_update_participant on public.sessions;
create policy sessions_update_participant on public.sessions
  for update to authenticated
  using (auth.uid() = elder_id or auth.uid() = helper_id)
  with check (auth.uid() = elder_id or auth.uid() = helper_id);

-- ------------------------------------------------------------
-- 5) Seed: 5 voluntários de exemplo
--    Cria usuários reais no auth (login: senha "senha123"),
--    o trigger gera o profile, e o UPDATE enriquece os dados.
--    E-mails: ana@ / carlos@ / fernanda@ / roberto@ / juliana@ exemplo.com
-- ------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('a1a1a1a1-0000-4000-8000-000000000001'::uuid, 'ana@exemplo.com',      'Ana Paula Silva',       array['Companhia','Tecnologia'],              4.9, 124, 'Adoro conversar e ajudar com tecnologia. Muito paciente e carinhosa.', 35),
      ('a1a1a1a1-0000-4000-8000-000000000002'::uuid, 'carlos@exemplo.com',   'Carlos Eduardo Matos',  array['Tecnologia','Administrativo'],         4.7,  89, 'Especialista em ajudar com celular, computador e contas.',            40),
      ('a1a1a1a1-0000-4000-8000-000000000003'::uuid, 'fernanda@exemplo.com', 'Fernanda Lima',         array['Companhia','Recreação'],               5.0, 203, 'Amo jogos, histórias e atividades lúdicas. Especializada em idosos.', 30),
      ('a1a1a1a1-0000-4000-8000-000000000004'::uuid, 'roberto@exemplo.com',  'Roberto Oliveira',      array['Saúde','Administrativo'],              4.8,  67, 'Auxílio com saúde, organização de medicamentos e consultas.',        45),
      ('a1a1a1a1-0000-4000-8000-000000000005'::uuid, 'juliana@exemplo.com',  'Juliana Costa',         array['Recreação','Educação','Companhia'],    4.6,  45, 'Aulas de música, leitura e atividades criativas.',                   28)
    ) as t(id, email, name, cats, rating, sessions, bio, rate)
  loop
    -- 5a) usuário no auth (email já confirmado)
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000',
      r.id, 'authenticated', 'authenticated', r.email,
      extensions.crypt('senha123', extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('name', r.name, 'role', 'helper'),
      '', '', '', ''
    )
    on conflict (id) do nothing;

    -- 5b) identidade de email (permite login com senha)
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), r.id,
      jsonb_build_object('sub', r.id::text, 'email', r.email),
      'email', r.id::text,
      now(), now(), now()
    )
    on conflict do nothing;

    -- 5c) enriquece o profile criado pelo trigger
    update public.profiles set
      role           = 'helper',
      categories     = r.cats,
      rating         = r.rating,
      total_sessions = r.sessions,
      bio            = r.bio,
      hourly_rate    = r.rate,
      is_available   = true
    where id = r.id;
  end loop;
end $$;

-- Pronto. Voluntários aparecem na lista do idoso e podem logar
-- (ex.: ana@exemplo.com / senha123) para testar o lado voluntário.
