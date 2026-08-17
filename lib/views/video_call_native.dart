import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

Future<void> launchJitsiNative({
  required String roomName,
  required String displayName,
  String? email,
  required void Function() onEnded,
}) async {
  final jitsiMeet = JitsiMeet();

  final options = JitsiMeetConferenceOptions(
    serverURL: 'https://meet.jit.si',
    room: roomName,
    configOverrides: {
      'startWithAudioMuted': false,
      'startWithVideoMuted': false,
      'subject': 'Neto de Aluguel',
      'disableDeepLinking': true,
    },
    featureFlags: {
      FeatureFlags.unsafeRoomWarningEnabled: false,
      FeatureFlags.addPeopleEnabled: false,
      FeatureFlags.calenderEnabled: false,
      FeatureFlags.inviteEnabled: false,
      FeatureFlags.liveStreamingEnabled: false,
      FeatureFlags.meetingPasswordEnabled: false,
      FeatureFlags.recordingEnabled: false,
      FeatureFlags.tileViewEnabled: false,
      FeatureFlags.videoShareEnabled: false,
      FeatureFlags.chatEnabled: false,
      FeatureFlags.pipEnabled: true,
      FeatureFlags.conferenceTimerEnabled: true,
      FeatureFlags.toolboxEnabled: true,
    },
    userInfo: JitsiMeetUserInfo(
      displayName: displayName,
      email: email,
    ),
  );

  final listener = JitsiMeetEventListener(
    readyToClose: onEnded,
    conferenceTerminated: (url, error) => onEnded(),
  );

  await jitsiMeet.join(options, listener);
}
