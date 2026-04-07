/// Serviço de videochamada via Daily.co.
/// No protótipo retorna tokens mockados.
class VideoService {
  static const bool _useMock = true;

  Future<String> createRoomToken({required String sessionId}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'mock-token-$sessionId-${DateTime.now().millisecondsSinceEpoch}';
    }
    // TODO: implementar criação de sala no Daily.co
    throw UnimplementedError();
  }

  Future<void> endCall({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
