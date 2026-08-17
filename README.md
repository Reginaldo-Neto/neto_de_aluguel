# 📹 Neto de Aluguel - Plataforma de Videochamadas para Idosos e Ajudantes

Aplicação desenvolvida em **Flutter** integrada ao **Supabase**, que conecta idosos a ajudantes (voluntários) qualificados por meio de videochamadas organizadas por categorias de atendimento.

O objetivo do projeto é oferecer uma solução acessível, simples e segura para suporte remoto — seja para companhia, suporte tecnológico, orientação básica, atividades recreativas ou auxílio administrativo.

---

## 🚀 Tecnologias Utilizadas

- **Frontend:** Flutter
- **Gerenciamento de Estado:** Riverpod + Hooks (`flutter_hooks`)
- **Navegação:** GoRouter
- **Backend:** Supabase (Auth, Database, Storage)
- **Autenticação:** Supabase Auth (JWT)
- **Banco de Dados:** PostgreSQL (via Supabase) com Row Level Security
- **Videochamadas:** **Jitsi Meet** (gratuito e open source) — SDK nativo no mobile, sala aberta no navegador na web
- **Notificações:** OneSignal (push) + Supabase SMTP (email) — _atualmente mockado no protótipo_

> ℹ️ **Status das integrações:** Auth, perfis e sessões usam o Supabase de verdade.
> A videochamada usa o Jitsi Meet. As notificações ainda estão mockadas
> (`NotificationService` apenas registra no console).

---

## 🎯 Funcionalidades

### 👤 Idosos
- Cadastro e login simplificado (email/senha)
- Busca de voluntários por categoria de atendimento
- **Ligação instantânea** — conecta com o primeiro voluntário disponível
- Ligação direta e agendamento de videochamadas com voluntários específicos
- Interface com acessibilidade ampliada (fontes grandes, tema claro/escuro)

### 🧑‍🤝‍🧑 Ajudantes (voluntários)
- Cadastro com categorias de atuação (especialidades)
- Alternância de disponibilidade (online/offline), persistida no banco
- Recebimento e visualização de sessões agendadas
- Sistema de avaliação pelos idosos

### 🔒 Segurança
- Autenticação segura com Supabase Auth (JWT)
- Controle de acesso por tipo de usuário (Elder / Helper)
- Row Level Security (RLS) no PostgreSQL
- Trigger `handle_new_user()` cria automaticamente o perfil no cadastro

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
   - A videochamada usa **Jitsi Meet**; ambos os participantes entram na mesma
     sala, cujo nome é derivado do ID da sessão.
   - No mobile, a chamada abre pelo SDK nativo do Jitsi; na web, a sala é aberta
     em uma nova aba do navegador.
   - Sessões finalizadas são marcadas como concluídas e disponíveis para avaliação.

4. **Avaliação**
   - Idosos avaliam os Ajudantes após cada sessão.
   - Avaliações são visíveis para outros Idosos na busca, influenciando a reputação do ajudante.

5. **Notificações**
   - Push via **OneSignal** deve avisar sobre agendamentos, lembretes e alterações.
   - Emails via Supabase SMTP para confirmações e alertas.
   - Respeita preferências do usuário e horários aceitáveis.

6. **Segurança e privacidade**
   - RLS garante que cada usuário só acesse seus próprios dados.
   - Dados sensíveis protegidos em banco/storage.

7. **Histórico**
   - Todas as sessões (agendadas, concluídas ou canceladas) ficam registradas.
   - Usuários podem consultar histórico de atendimentos e avaliações.

---

## 📌 Estrutura de Pastas

Padrão **MVVM-like** com Riverpod: Services → Presenters (Notifiers) → Views.

```text
/lib
 ├─ main.dart                 # bootstrap: inicializa o Supabase e roda o app
 ├─ app.dart                  # MaterialApp, tema (claro/escuro) e rotas (GoRouter)
 ├─ config/
 │   ├─ supabase_config.dart          # credenciais (gitignored)
 │   └─ supabase_config.example.dart  # modelo para copiar
 ├─ models/
 │   ├─ user.dart             # UserModel + UserRole (elder/helper)
 │   ├─ session.dart          # SessionModel + SessionStatus
 │   └─ category.dart         # CategoryModel + categorias mock
 ├─ presenters/               # Riverpod Notifiers (lógica de negócio e estado)
 │   ├─ home_presenter.dart   # auth + lista de voluntários + sessões
 │   ├─ login_presenter.dart
 │   ├─ session_presenter.dart
 │   └─ video_call_presenter.dart
 ├─ views/                    # telas (HookConsumerWidget)
 │   ├─ login_view.dart
 │   ├─ home_view.dart        # renderiza _ElderHome ou _HelperHome pela role
 │   ├─ session_view.dart
 │   ├─ video_call_view.dart  # decide entre nativo e web
 │   ├─ video_call_native.dart
 │   └─ video_call_web.dart
 ├─ widgets/                  # componentes reutilizáveis
 │   ├─ helper_card.dart
 │   ├─ category_chip.dart
 │   └─ primary_button.dart
 └─ services/                 # integrações externas
     ├─ supabase_service.dart # auth + queries (profiles, sessions)
     ├─ notification_service.dart
     └─ video_service.dart    # gera o nome da sala Jitsi
```

---

## ⚙️ Instalação e Execução

### Pré-requisitos
- Flutter SDK (Dart `>=3.0.0 <4.0.0`)
- Um device/emulador Android ou iOS, ou um navegador (suporte web incluído)

### 1. Instalar dependências
```bash
flutter pub get
```

### 2. Configurar o Supabase
O arquivo `lib/config/supabase_config.dart` é gitignored. Copie o exemplo e
preencha com as credenciais do seu projeto Supabase:

```bash
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
```

O projeto Supabase precisa das tabelas `profiles` e `sessions`, com RLS
habilitado e um trigger `handle_new_user()` que cria a linha em `profiles`
automaticamente no cadastro.

### 3. Rodar o app
```bash
flutter run
```

### Outros comandos úteis
```bash
flutter analyze      # análise estática / lint
flutter test         # testes
flutter build apk    # build Android release
flutter build ios    # build iOS release
```

---

## 📱 Notas de Plataforma (Jitsi Meet)

- **Android:** exige `minSdk 26` (requisito do Jitsi SDK). Permissões de câmera,
  microfone e áudio já estão declaradas no `AndroidManifest.xml`.
- **iOS:** `Info.plist` já contém `NSCameraUsageDescription`,
  `NSMicrophoneUsageDescription` e os background modes de áudio/voip.
- **Web:** a sala do Jitsi é aberta em uma nova aba (`meet.jit.si`) via
  `url_launcher`, pois o SDK nativo não está disponível no navegador.
