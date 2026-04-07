import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/video_service.dart';

class VideoCallState {
  final SessionModel session;
  final bool isMuted;
  final bool isCameraOff;
  final bool isConnecting;
  final bool isEnded;
  final Duration elapsed;
  final String? roomToken;

  const VideoCallState({
    required this.session,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isConnecting = true,
    this.isEnded = false,
    this.elapsed = Duration.zero,
    this.roomToken,
  });

  VideoCallState copyWith({
    bool? isMuted,
    bool? isCameraOff,
    bool? isConnecting,
    bool? isEnded,
    Duration? elapsed,
    String? roomToken,
  }) {
    return VideoCallState(
      session: session,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isConnecting: isConnecting ?? this.isConnecting,
      isEnded: isEnded ?? this.isEnded,
      elapsed: elapsed ?? this.elapsed,
      roomToken: roomToken ?? this.roomToken,
    );
  }

  String get elapsedFormatted {
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class VideoCallNotifier extends FamilyNotifier<VideoCallState, SessionModel> {
  Timer? _timer;

  @override
  VideoCallState build(SessionModel arg) {
    ref.onDispose(() => _timer?.cancel());
    _connect();
    return VideoCallState(session: arg);
  }

  Future<void> _connect() async {
    final token = await VideoService().createRoomToken(sessionId: state.session.id);
    state = state.copyWith(roomToken: token, isConnecting: false);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
    });
  }

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);

  void toggleCamera() =>
      state = state.copyWith(isCameraOff: !state.isCameraOff);

  Future<void> endCall() async {
    _timer?.cancel();
    await VideoService().endCall(sessionId: state.session.id);
    state = state.copyWith(isEnded: true);
  }
}

final videoCallProvider = NotifierProviderFamily<VideoCallNotifier,
    VideoCallState, SessionModel>(VideoCallNotifier.new);
