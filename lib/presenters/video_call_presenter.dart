import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

class VideoCallNotifier extends FamilyNotifier<SessionModel, SessionModel> {
  @override
  SessionModel build(SessionModel arg) => arg;
}

final videoCallProvider = NotifierProviderFamily<VideoCallNotifier,
    SessionModel, SessionModel>(VideoCallNotifier.new);
