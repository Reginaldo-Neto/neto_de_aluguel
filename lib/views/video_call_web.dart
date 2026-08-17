// Stub para web: a função real só é chamada em mobile (kIsWeb guard no view).
// A importação condicional exige que este arquivo exista e exporte o mesmo símbolo.
Future<void> launchJitsiNative({
  required String roomName,
  required String displayName,
  String? email,
  required void Function() onEnded,
}) async {
  // no-op on web — handled directly in video_call_view.dart via url_launcher
}
