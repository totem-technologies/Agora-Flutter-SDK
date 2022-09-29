import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'generated/mediaengine_smoke_test.generated.dart' as generated;
import 'package:integration_test_app/main.dart' as app;

import 'package:integration_test_app/fake_remote_user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  generated.mediaEngineSmokeTestCases();

  testWidgets(
    'registerAudioFrameObserver',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      String engineAppId = const String.fromEnvironment('TEST_APP_ID',
          defaultValue: '<YOUR_APP_ID>');

      RtcEngineEx rtcEngine = createAgoraRtcEngineEx();
      await rtcEngine.initialize(RtcEngineContext(
        appId: engineAppId,
        areaCode: AreaCode.areaCodeGlob.value(),
      ));

      final mediaEngine = rtcEngine.getMediaEngine();
      Completer<bool> eventCalledCompleter = Completer();
      final AudioFrameObserver observer = AudioFrameObserver(
        onRecordAudioFrame: (String channelId, AudioFrame audioFrame) {},
        onPlaybackAudioFrame: (String channelId, AudioFrame audioFrame) {
          if (eventCalledCompleter.isCompleted) return;
          eventCalledCompleter.complete(true);
        },
        onMixedAudioFrame: (String channelId, AudioFrame audioFrame) {},
        onPlaybackAudioFrameBeforeMixing:
            (String channelId, int uid, AudioFrame audioFrame) {},
      );
      mediaEngine.registerAudioFrameObserver(
        observer,
      );

      await rtcEngine.enableVideo();

      await rtcEngine.joinChannel(
        token: '',
        channelId: 'testonaction',
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      final remoteUser = FakeRemoteUser(rtcEngine);

      await remoteUser.joinChannel('testonaction');

      final eventCalled = await eventCalledCompleter.future;
      expect(eventCalled, isTrue);

      mediaEngine.unregisterAudioFrameObserver(observer);
      await remoteUser.leaveChannel();
      await rtcEngine.leaveChannel();

      await mediaEngine.release();
      await rtcEngine.release();
    },
  );

  testWidgets(
    'registerVideoFrameObserver',
    (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      String engineAppId = const String.fromEnvironment('TEST_APP_ID',
          defaultValue: '<YOUR_APP_ID>');

      RtcEngineEx rtcEngine = createAgoraRtcEngineEx();
      await rtcEngine.initialize(RtcEngineContext(
        appId: engineAppId,
        areaCode: AreaCode.areaCodeGlob.value(),
      ));

      final mediaEngine = rtcEngine.getMediaEngine();
      Completer<bool> eventCalledCompleter = Completer();

      final VideoFrameObserver observer = VideoFrameObserver(
        onCaptureVideoFrame: (videoFrame) {
          debugPrint(
              '[onCaptureVideoFrame] videoFrame: ${videoFrame.toJson()}');
        },
        onRenderVideoFrame:
            (String channelId, int remoteUid, VideoFrame videoFrame) {
          // logSink.log(
          //     '[onRenderVideoFrame] channelId: $channelId, remoteUid: $remoteUid, videoFrame: ${videoFrame.toJson()}');
          debugPrint(
              '[onRenderVideoFrame] channelId: $channelId, remoteUid: $remoteUid, videoFrame: ${videoFrame.toJson()}');
          if (eventCalledCompleter.isCompleted) return;
          eventCalledCompleter.complete(true);
        },
      );

      mediaEngine.registerVideoFrameObserver(
        observer,
      );

      await rtcEngine.enableVideo();

      await rtcEngine.joinChannel(
        token: '',
        channelId: 'testonaction',
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      final remoteUser = FakeRemoteUser(rtcEngine);

      await remoteUser.joinChannel('testonaction');

      final eventCalled = await eventCalledCompleter.future;
      expect(eventCalled, isTrue);

      mediaEngine.unregisterVideoFrameObserver(observer);
      await remoteUser.leaveChannel();
      await rtcEngine.leaveChannel();

      await mediaEngine.release();
      await rtcEngine.release();
    },
  );
}
