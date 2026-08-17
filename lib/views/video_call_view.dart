import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/session.dart';
import '../services/video_service.dart';
import '../presenters/home_presenter.dart';

// SDK do Jitsi só existe em Android/iOS — importamos condicionalmente
import 'video_call_native.dart' if (dart.library.html) 'video_call_web.dart';

class VideoCallView extends HookConsumerWidget {
  final SessionModel session;
  const VideoCallView({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    final roomName = VideoService().roomName(session.id);
    final launched = useState(false);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (launched.value) return;
        launched.value = true;

        if (kIsWeb) {
          // Web: abre a sala Jitsi em nova aba
          final url = Uri.parse('https://meet.jit.si/$roomName');
          await launchUrl(url, webOnlyWindowName: '_blank');
        } else {
          // Mobile: usa o SDK nativo
          await launchJitsiNative(
            roomName: roomName,
            displayName: user?.name ?? 'Participante',
            email: user?.email,
            onEnded: () {
              if (context.mounted) context.go('/home');
            },
          );
        }
      });
      return null;
    }, const []);

    final helperName = session.helper?.name ?? 'voluntário';

    if (kIsWeb) {
      return _WebCallScreen(
        helperName: helperName,
        jitsiUrl: 'https://meet.jit.si/$roomName',
        onDone: () => context.go('/home'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Conectando com $helperName...',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'A chamada vai abrir em instantes',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebCallScreen extends StatelessWidget {
  final String helperName;
  final String jitsiUrl;
  final VoidCallback onDone;

  const _WebCallScreen({
    required this.helperName,
    required this.jitsiUrl,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_new_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sala aberta em nova aba',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'A videochamada com $helperName foi aberta no navegador. '
                'Volte aqui quando encerrar.',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(jitsiUrl);
                  await launchUrl(url, webOnlyWindowName: '_blank');
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                label: const Text('Reabrir sala',
                    style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Chamada encerrada — voltar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
