/// Serviço de notificações via OneSignal + Supabase SMTP.
/// No protótipo apenas loga as notificações no console.
class NotificationService {
  Future<void> sendSessionConfirmation({
    required String userId,
    required String helperName,
    required DateTime scheduledAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // ignore: avoid_print
    print('[Notification] Sessão confirmada com $helperName em $scheduledAt');
  }

  Future<void> sendSessionReminder({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // ignore: avoid_print
    print('[Notification] Lembrete de sessão: $sessionId');
  }
}
