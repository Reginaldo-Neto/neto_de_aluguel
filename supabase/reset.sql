-- ============================================================
--  Neto de Aluguel — RESET (APAGA DADOS!)
--  Rode no SQL Editor do Supabase ANTES do schema.sql para
--  começar do zero. TODAS as acoes abaixo sao IRREVERSIVEIS.
--  Confirme que voce esta no projeto certo.
-- ============================================================

-- 1) Remove o trigger e a função do app
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- 2) Derruba as tabelas do app (e todos os seus dados)
--    cascade remove também as policies e dependências.
drop table if exists public.sessions cascade;
drop table if exists public.profiles cascade;

-- 3) (OPCIONAL) Apaga só os USUÁRIOS DE TESTE do seed (@exemplo.com)
--    Descomente para executar:
-- delete from auth.users where email like '%@exemplo.com';

-- 4) (PERIGO) Apaga TODAS as contas de autenticação do projeto.
--    Use apenas se quiser zerar o Auth por completo.
--    Descomente com MUITO cuidado:
-- delete from auth.users;

-- Depois deste reset, rode o schema.sql para recriar tudo limpo.
