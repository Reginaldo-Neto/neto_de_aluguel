/// Serviço de notificações (push via OneSignal + email via Supabase SMTP).
///
/// INTEGRAÇÃO PENDENTE — hoje as notificações são apenas registradas no
/// console de forma estruturada. A interface abaixo já é a definitiva; para
/// ativar o envio real basta preencher [_sendPush] e [_sendEmail]:
///
///  1. Push (OneSignal):
///     - adicionar `onesignal_flutter` ao pubspec e inicializar no main.dart
///       com o App ID;
///     - em [_sendPush], chamar a REST API do OneSignal
///       (POST https://onesignal.com/api/v1/notifications) usando
///       `include_external_user_ids: [userId]`;
///     - guardar App ID / REST API Key fora do versionamento (ex.: em
///       lib/config/, no mesmo esquema do supabase_config.dart).
///
///  2. Email (Supabase SMTP):
///     - configurar o SMTP no painel do Supabase;
///     - em [_sendEmail], invocar uma Edge Function que dispara o email.
///
/// Enquanto isso, cada método é seguro de chamar e não quebra o fluxo do app.
class NotificationService {
  /// Confirma ao idoso o agendamento de uma sessão.
  Future<void> sendSessionConfirmation({
    required String userId,
    required String helperName,
    required DateTime scheduledAt,
  }) {
    return _dispatch(
      userId: userId,
      title: 'Sessão confirmada',
      body: 'Sua conversa com $helperName foi agendada para '
          '${_formatDate(scheduledAt)}.',
    );
  }

  /// Lembra o usuário de uma sessão que está próxima.
  Future<void> sendSessionReminder({
    required String userId,
    required String helperName,
    required DateTime scheduledAt,
  }) {
    return _dispatch(
      userId: userId,
      title: 'Lembrete de conversa',
      body: 'Sua conversa com $helperName é em ${_formatDate(scheduledAt)}.',
    );
  }

  /// Avisa o voluntário de uma ligação imediata recebida.
  Future<void> sendInstantCallInvite({
    required String helperId,
    required String elderName,
  }) {
    return _dispatch(
      userId: helperId,
      title: 'Ligação recebida',
      body: '$elderName quer falar com você agora.',
    );
  }

  /// Avisa o usuário do cancelamento de uma sessão.
  Future<void> sendSessionCancellation({
    required String userId,
    required String helperName,
  }) {
    return _dispatch(
      userId: userId,
      title: 'Conversa cancelada',
      body: 'Sua conversa com $helperName foi cancelada.',
    );
  }

  // ──────────────────────────── Despacho ────────────────────────────

  Future<void> _dispatch({
    required String userId,
    required String title,
    required String body,
  }) async {
    _log('para=$userId • $title — $body');
    await _sendPush(userId: userId, title: title, body: body);
    await _sendEmail(userId: userId, subject: title, body: body);
  }

  /// Envio de push. TODO(onesignal): implementar via REST API do OneSignal.
  Future<void> _sendPush({
    required String userId,
    required String title,
    required String body,
  }) async {
    // No-op enquanto App ID / REST API Key não estiverem configurados.
  }

  /// Envio de email. TODO(smtp): implementar via Edge Function + SMTP Supabase.
  Future<void> _sendEmail({
    required String userId,
    required String subject,
    required String body,
  }) async {
    // No-op enquanto o SMTP não estiver configurado.
  }

  // ──────────────────────────── Utilitários ────────────────────────────

  void _log(String message) {
    final now = DateTime.now();
    final ts = '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
    // ignore: avoid_print
    print('[$ts] [Notification] $message');
  }

  String _formatDate(DateTime dt) =>
      '${_pad(dt.day)}/${_pad(dt.month)} às ${_pad(dt.hour)}:${_pad(dt.minute)}';

  String _pad(int n) => n.toString().padLeft(2, '0');
}
