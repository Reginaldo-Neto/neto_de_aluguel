# 📹 Neto de Aluguel - Plataforma de Videochamadas para Idosos e Ajudantes

Aplicação desenvolvida em **Flutter** integrada ao **Supabase**, que conecta idosos a ajudantes qualificados por meio de videochamadas organizadas por categorias de atendimento.

O objetivo do projeto é oferecer uma solução acessível, simples e segura para suporte remoto — seja para companhia, suporte tecnológico, orientação básica, atividades recreativas ou auxílio administrativo.

---

## 🚀 Tecnologias Utilizadas

- **Frontend:** Flutter  
- **Gerenciamento de Estado:** Riverpod + Hooks  
- **Backend:** Supabase (Auth, Database, Storage, Functions)  
- **Autenticação:** Supabase Auth (JWT)  
- **Banco de Dados:** PostgreSQL (via Supabase)  
- **Armazenamento:** Supabase Storage (fotos, documentos, gravações opcionais)  
- **Videochamadas:** **Daily.co**  
- **Notificações:** **OneSignal** para push, Supabase SMTP para emails  
- **CI/CD:** **Bitrise** para builds Android/iOS

---

## 🎯 Funcionalidades

### 👤 Idosos
- Cadastro e login simplificado (email/senha ou magic link)  
- Busca por categorias de atendimento  
- Agendamento de videochamadas com ajudantes disponíveis  
- Histórico de atendimentos  
- Avaliação de ajudantes  
- Interface com acessibilidade ampliada (fontes grandes, alto contraste, suporte a VoiceOver)

### 🧑‍⚕️ Ajudantes
- Cadastro com categorias de atuação  
- Definição de disponibilidade por horário/dia  
- Recebimento de solicitações de videochamada  
- Histórico de atendimentos  
- Sistema de avaliação pelos idosos  

### 🔒 Segurança
- Autenticação segura com Supabase Auth (JWT)  
- Controle de acesso por tipo de usuário (Elder / Helper)  
- Row Level Security (RLS) no PostgreSQL  
- Criptografia e proteção de dados sensíveis (ex: CPF, documentos)  
- Tokens temporários para videochamadas (para evitar fraudes)

---

## 📋 Regras de Negócio Idealizadas

1. **Usuários e papéis**
   - Cada usuário deve ser cadastrado como **Idoso** ou **Ajudante**.  
   - Um Idoso não pode acessar dados de outros Idosos.  
   - Um Ajudante só pode ver sessões agendadas com ele.

2. **Agendamento**
   - Idosos escolhem categoria e horário disponível do ajudante.  
   - Sessão só pode ser marcada se houver disponibilidade confirmada pelo ajudante.  
   - Cancelamentos e alterações devem atualizar histórico e enviar notificações.

3. **Videochamada**
   - Videochamada inicia usando **Daily.co** com token temporário.  
   - Chamada só pode ocorrer entre Idoso e Ajudante cadastrados para aquela sessão.  
   - Sessões finalizadas são marcadas como concluídas e disponíveis para avaliação.

4. **Avaliação**
   - Idosos avaliam os Ajudantes após cada sessão.  
   - Avaliações são visíveis para outros Idosos na busca, influenciando a reputação do ajudante.

5. **Notificações**
   - Push via **OneSignal** deve avisar sobre agendamentos, lembretes e alterações.  
   - Emails via Supabase SMTP (SendGrid) para confirmações e alertas.  
   - Respeita preferências do usuário e horários aceitáveis.

6. **Segurança e privacidade**
   - Todos os dados sensíveis criptografados em banco ou storage.  
   - RLS garante que cada usuário só acesse seus próprios dados.  
   - Tokens de videochamada expiram rapidamente para garantir segurança.

7. **Histórico**
   - Todas as sessões (agendadas, concluídas ou canceladas) ficam registradas.  
   - Usuários podem consultar histórico de atendimentos e avaliações.

---

## 📌 Estrutura de Pastas

```text
/lib
 ├─ main.dart
 ├─ app.dart
 ├─ models/
 │   ├─ user.dart
 │   ├─ session.dart
 │   └─ category.dart
 ├─ providers/
 │   ├─ auth_provider.dart
 │   ├─ session_provider.dart
 │   └─ video_provider.dart
 ├─ screens/
 │   ├─ login_screen.dart
 │   ├─ home_screen.dart
 │   ├─ session_screen.dart
 │   └─ video_call_screen.dart
 ├─ widgets/
 │   ├─ buttons.dart
 │   ├─ cards.dart
 │   └─ loading.dart
 └─ services/
     ├─ supabase_service.dart
     ├─ notification_service.dart
     └─ video_service.dart