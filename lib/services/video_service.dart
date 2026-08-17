/// Serviço de videochamada via Jitsi Meet (gratuito, open source).
class VideoService {
  /// Gera o nome da sala Jitsi a partir do ID da sessão.
  /// O nome precisa ser o mesmo nos dois lados para que entrem na mesma sala.
  String roomName(String sessionId) {
    final clean = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'netoaluguel$clean';
  }
}
