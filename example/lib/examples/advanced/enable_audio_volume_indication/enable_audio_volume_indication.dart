import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine_example/config/agora.config.dart' as config;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../log_sink.dart';

/// EnableAudioVolumeIndication Example
class EnableAudioVolumeIndication extends StatefulWidget {
  /// Construct the [EnableAudioVolumeIndication]
  const EnableAudioVolumeIndication({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<EnableAudioVolumeIndication> {
  late final RtcEngine _engine;
  String channelId = config.channelId;
  bool isJoined = false;
  double _interval = 200;
  double _smooth = 3;
  bool _reportVad = false;
  bool _isEnableAudioVolumeIndicationLog = false;
  late TextEditingController _controller;
  late final LogSink _enableAudioVolumeIndicationLog;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: channelId);
    _enableAudioVolumeIndicationLog = LogSink();
    _initEngine();
  }

  @override
  void dispose() {
    super.dispose();
    _engine.destroy();
  }

  _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(config.appId));
    _addListeners();

    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
  }

  void _addListeners() {
    _engine.setEventHandler(RtcEngineEventHandler(
      warning: (warningCode) {
        logSink.log('warning $warningCode');
      },
      error: (errorCode) {
        logSink.log('error $errorCode');
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        logSink.log('joinChannelSuccess $channel $uid $elapsed');
        setState(() {
          isJoined = true;
        });
      },
      leaveChannel: (stats) async {
        logSink.log('leaveChannel ${stats.toJson()}');
        setState(() {
          isJoined = false;
        });
      },
      audioVolumeIndication: (List<AudioVolumeInfo> speakers, int totalVolume) {
        final speakersString =
            speakers.map((e) => e.toJson().toString()).join(', \n');
        _enableAudioVolumeIndicationLog
            .log('audioVolumeIndication:\n$speakersString: $totalVolume\n');
      },
    ));
  }

  _joinChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.microphone.request();
    }

    await _engine
        .joinChannel(config.token, _controller.text, null, config.uid)
        .catchError((onError) {
      logSink.log('error ${onError.toString()}');
    });
  }

  _leaveChannel() async {
    await _engine.enableAudioVolumeIndication(-1, 0, false);
    await _engine.leaveChannel();
    setState(() {
      isJoined = false;
      _interval = 200;
      _smooth = 3;
      _reportVad = false;
    });
  }

  Future<void> _enableAudioVolumeIndication() async {
    setState(() {
      _isEnableAudioVolumeIndicationLog = !_isEnableAudioVolumeIndicationLog;
    });

    await _engine.enableAudioVolumeIndication(
      _isEnableAudioVolumeIndicationLog ? _interval.toInt() : -1,
      _smooth.toInt(),
      _reportVad,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Channel ID'),
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: isJoined ? _leaveChannel : _joinChannel,
                    child: Text('${isJoined ? 'Leave' : 'Join'} channel'),
                  ),
                )
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('interval:'),
            Slider(
              value: _interval,
              min: 200,
              max: 1000,
              divisions: 8,
              label: 'interval',
              onChanged: isJoined
                  ? (double value) {
                      setState(() {
                        _interval = value;
                      });
                    }
                  : null,
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('smooth:'),
            Slider(
              value: _smooth,
              min: 0,
              max: 10,
              divisions: 10,
              label: 'smooth',
              onChanged: isJoined
                  ? (double value) {
                      setState(() {
                        _smooth = value;
                      });
                    }
                  : null,
            )
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('report_vad:'),
              Switch(
                value: _reportVad,
                onChanged: isJoined
                    ? (v) {
                        setState(() {
                          _reportVad = v;
                        });
                      }
                    : null,
              )
            ]),
          ],
        ),
        ElevatedButton(
          onPressed: isJoined ? _enableAudioVolumeIndication : null,
          child: Text(
              '${!_isEnableAudioVolumeIndicationLog ? 'enable' : 'disable'}AudioVolumeIndication'),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: LogWidget(
              logSink: _enableAudioVolumeIndicationLog,
              textStyle: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
        )
      ],
    );
  }
}
