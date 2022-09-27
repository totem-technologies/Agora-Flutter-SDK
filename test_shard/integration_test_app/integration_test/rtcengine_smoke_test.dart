import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'generated/rtcengine_smoke_test.generated.dart' as generated;
import 'package:integration_test_app/main.dart' as app;
import 'package:path/path.dart' as path;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  generated.rtcEngineSmokeTestCases();

  testWidgets(
    'getEffectDuration',
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

      try {
        ByteData data =
            await rootBundle.load("assets/Agora.io-Interactions.mp3");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String filePath =
            path.join(appDocDir.path, 'Agora.io-Interactions.mp3');
        final file = File(filePath);
        if (!(await file.exists())) {
          await file.create();
          await file.writeAsBytes(bytes);
        }

        await rtcEngine.getEffectDuration(
          filePath,
        );
      } catch (e) {
        if (e is! AgoraRtcException) {
          debugPrint('[getEffectDuration] error: ${e.toString()}');
        }
        expect(e is AgoraRtcException, true);
        debugPrint(
            '[getEffectDuration] errorcode: ${(e as AgoraRtcException).code}');
      }

      await rtcEngine.release();
    },
//  skip: !(),
  );

  testWidgets(
    'registerAudioEncodedFrameObserver',
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
      await rtcEngine.enableVideo();

      Completer<bool>? eventCalledCompleter = Completer();
      final AudioEncodedFrameObserver observer = AudioEncodedFrameObserver(
        onRecordAudioEncodedFrame: (Uint8List frameBuffer, int length,
            EncodedAudioFrameInfo audioEncodedFrameInfo) {
          if (eventCalledCompleter == null) return;
          eventCalledCompleter.complete(true);
        },
        onPlaybackAudioEncodedFrame: (Uint8List frameBuffer, int length,
            EncodedAudioFrameInfo audioEncodedFrameInfo) {},
        onMixedAudioEncodedFrame: (Uint8List frameBuffer, int length,
            EncodedAudioFrameInfo audioEncodedFrameInfo) {},
      );
      rtcEngine.registerAudioEncodedFrameObserver(
          config: const AudioEncodedFrameObserverConfig(
              postionType: AudioEncodedFrameObserverPosition
                  .audioEncodedFrameObserverPositionRecord,
              encodingType: AudioEncodingType.audioEncodingTypeAac16000Medium),
          observer: observer);

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

      rtcEngine.unregisterAudioEncodedFrameObserver(
        observer,
      );

      await rtcEngine.release();
    },
//  skip: !(),
  );
}
