-- ============================================================
--  Neto de Aluguel — Avaliação mútua
--  Adiciona a nota que o VOLUNTÁRIO dá ao IDOSO.
--  (A coluna "rating" continua sendo a nota do idoso ao voluntário.)
--  Cole no SQL Editor do Supabase e execute (Run).
-- ============================================================

alter table public.sessions
  add column if not exists elder_rating numeric;

-- As policies de UPDATE existentes (participante da sessão) já cobrem a
-- gravação de elder_rating; nada mais a fazer.
