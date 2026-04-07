import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../presenters/video_call_presenter.dart';

class VideoCallView extends ConsumerWidget {
  final SessionModel session;
  const VideoCallView({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoCallProvider(session));
    final notifier = ref.read(videoCallProvider(session).notifier);

    if (state.isEnded) {
      return _CallEndedScreen(onDone: () => context.go('/home'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            _RemoteVideo(
              helperName: session.helper?.name ?? 'Ajudante',
              isConnecting: state.isConnecting,
            ),
            // Local video (PiP corner)
            Positioned(
              top: 16,
              right: 16,
              child: _LocalVideo(isCameraOff: state.isCameraOff),
            ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                helperName: session.helper?.name ?? 'Ajudante',
                elapsed: state.elapsedFormatted,
                isConnecting: state.isConnecting,
              ),
            ),
            // Controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _Controls(
                isMuted: state.isMuted,
                isCameraOff: state.isCameraOff,
                onToggleMute: notifier.toggleMute,
                onToggleCamera: notifier.toggleCamera,
                onEndCall: () async {
                  await notifier.endCall();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoteVideo extends StatelessWidget {
  final String helperName;
  final bool isConnecting;

  const _RemoteVideo({required this.helperName, required this.isConnecting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: isConnecting
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text('Conectando com $helperName...',
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: const Color(0xFF5C4BC1).withValues(alpha: 0.3),
                  child: Text(
                    helperName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  helperName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Em chamada',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
    );
  }
}

class _LocalVideo extends StatelessWidget {
  final bool isCameraOff;
  const _LocalVideo({required this.isCameraOff});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: isCameraOff
            ? const Color(0xFF333355)
            : const Color(0xFF2A4858),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: isCameraOff
          ? const Icon(Icons.videocam_off_rounded,
              color: Colors.white54, size: 28)
          : const Center(
              child: Text('Você', style: TextStyle(color: Colors.white70)),
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String helperName;
  final String elapsed;
  final bool isConnecting;

  const _TopBar({
    required this.helperName,
    required this.elapsed,
    required this.isConnecting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              helperName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          if (!isConnecting)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fiber_manual_record,
                      color: Colors.white, size: 10),
                  const SizedBox(width: 4),
                  Text(elapsed,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isMuted;
  final bool isCameraOff;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onEndCall;

  const _Controls({
    required this.isMuted,
    required this.isCameraOff,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Ativar' : 'Mutar',
          onTap: onToggleMute,
          active: isMuted,
        ),
        const SizedBox(width: 16),
        _EndCallButton(onTap: onEndCall),
        const SizedBox(width: 16),
        _ControlButton(
          icon: isCameraOff
              ? Icons.videocam_off_rounded
              : Icons.videocam_rounded,
          label: isCameraOff ? 'Ligar' : 'Câmera',
          onTap: onToggleCamera,
          active: isCameraOff,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.white : Colors.white38,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          const Text('Encerrar',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CallEndedScreen extends StatelessWidget {
  final VoidCallback onDone;
  const _CallEndedScreen({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_end_rounded, color: Colors.red, size: 64),
            const SizedBox(height: 20),
            const Text('Chamada encerrada',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Obrigado por usar o Neto de Aluguel!',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child:
                  const Text('Voltar ao início', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
