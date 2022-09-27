import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'generated/mediaengine_smoke_test.generated.dart' as generated;
import 'package:integration_test_app/main.dart' as app;

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

      RtcEngine rtcEngine = createAgoraRtcEngine();
      await rtcEngine.initialize(RtcEngineContext(
        appId: engineAppId,
        areaCode: AreaCode.areaCodeGlob.value(),
      ));

      final mediaEngine = rtcEngine.getMediaEngine();
      Completer<bool>? eventCalledCompleter = Completer();
      final AudioFrameObserver observer = AudioFrameObserver(
        onRecordAudioFrame: (String channelId, AudioFrame audioFrame) {
          if (eventCalledCompleter == null) return;
          eventCalledCompleter.complete(true);
        },
        onPlaybackAudioFrame: (String channelId, AudioFrame audioFrame) {},
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

      final eventCalled = await eventCalledCompleter.future;
      expect(eventCalled, isTrue);
      eventCalledCompleter = null;

      mediaEngine.unregisterAudioFrameObserver(observer);
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

      RtcEngine rtcEngine = createAgoraRtcEngine();
      await rtcEngine.initialize(RtcEngineContext(
        appId: engineAppId,
        areaCode: AreaCode.areaCodeGlob.value(),
      ));

      final mediaEngine = rtcEngine.getMediaEngine();
      Completer<bool>? eventCalledCompleter = Completer();

      final VideoFrameObserver observer = VideoFrameObserver(
        onCaptureVideoFrame: (videoFrame) {
          debugPrint(
              '[onCaptureVideoFrame] videoFrame: ${videoFrame.toJson()}');

          if (eventCalledCompleter == null) return;
          eventCalledCompleter.complete(true);
        },
        onRenderVideoFrame:
            (String channelId, int remoteUid, VideoFrame videoFrame) {
          // logSink.log(
          //     '[onRenderVideoFrame] channelId: $channelId, remoteUid: $remoteUid, videoFrame: ${videoFrame.toJson()}');
          debugPrint(
              '[onRenderVideoFrame] channelId: $channelId, remoteUid: $remoteUid, videoFrame: ${videoFrame.toJson()}');
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

      final eventCalled = await eventCalledCompleter.future;
      expect(eventCalled, isTrue);
      eventCalledCompleter = null;

      mediaEngine.unregisterVideoFrameObserver(observer);
      await rtcEngine.leaveChannel();

      await mediaEngine.release();
      await rtcEngine.release();
    },
  );
}
