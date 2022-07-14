@JS()
library agora_rtc_engine_web;

import 'dart:async';
import 'dart:convert';

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:ui' as ui;

import 'package:agora_rtc_engine/src/enums.dart';
import 'package:agora_rtc_engine/src/impl/render/rtc_render_view_interface.dart';
import 'package:agora_rtc_engine/src/impl/web/rtc_render_view_impl_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('IrisRtcEngine')
class _IrisRtcEngine {
  external _IrisRtcEngine();

  external _IrisRtcChannel get channel;

  external _IrisRtcDeviceManager get deviceManager;

  external Future<dynamic> callApi(int apiType, String params, [Object? extra]);

  external void setEventHandler(Function params);
}

@JS('IrisRtcChannel')
class _IrisRtcChannel {
  external Future<dynamic> callApi(int apiType, String params, [Object? extra]);

  external void setEventHandler(Function params);
}

@JS('IrisRtcDeviceManager')
class _IrisRtcDeviceManager {
  external Future<dynamic> callApiAudio(int apiType, String params,
      [Object? extra]);

  external Future<dynamic> callApiVideo(int apiType, String params,
      [Object? extra]);
}

/// A web implementation of the AgoraRtcEngine plugin.
class AgoraRtcEngineWeb {
  // ignore: public_member_api_docs
  static void registerWith(Registrar registrar) {
    final methodChannel = MethodChannel(
      'agora_rtc_engine',
      const StandardMethodCodec(),
      registrar,
    );
    final eventChannel = PluginEventChannel(
        'agora_rtc_engine/events', const StandardMethodCodec(), registrar);

    final pluginInstance = AgoraRtcEngineWeb();
    methodChannel.setMethodCallHandler(pluginInstance.handleMethodCall);
    eventChannel.setController(pluginInstance._controllerEngine);

    MethodChannel(
      'agora_rtc_channel',
      const StandardMethodCodec(),
      registrar,
    ).setMethodCallHandler(pluginInstance.handleChannelMethodCall);
    PluginEventChannel(
            'agora_rtc_channel/events', const StandardMethodCodec(), registrar)
        .setController(pluginInstance._controllerChannel);

    MethodChannel(
      'agora_rtc_audio_device_manager',
      const StandardMethodCodec(),
      registrar,
    ).setMethodCallHandler(pluginInstance.handleADMMethodCall);

    MethodChannel(
      'agora_rtc_video_device_manager',
      const StandardMethodCodec(),
      registrar,
    ).setMethodCallHandler(pluginInstance.handleVDMMethodCall);

    RtcRenderViewInterface.instance = RtcRenderViewImplWeb();

    MethodChannel('agora_rtc_engine/web_surface_view_controller',
            const StandardMethodCodec(), registrar)
        .setMethodCallHandler((call) {
      if (call.method == 'create_view') {
        final viewId = call.arguments;
        var element = DivElement();

        MethodChannel('agora_rtc_engine/surface_view_$viewId',
                const StandardMethodCodec(), registrar)
            .setMethodCallHandler(
                (call) => pluginInstance.handleViewMethodCall(call, element));

        print('registerViewFactory viewId: $viewId, element: $element');

        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(
            'agora_rtc_engine/surface_view_$viewId', (int viewId) {
          return element;
        });

        return Future.value(null);
      }

      throw UnsupportedError('Not supported for method: ${call.method}');
    });

    var element = ScriptElement()
      ..src =
          'assets/packages/agora_rtc_engine/assets/AgoraRtcWrapper.bundle.js'
      ..type = 'application/javascript';
    late StreamSubscription<Event> loadSubscription;
    loadSubscription = element.onLoad.listen((event) {
      loadSubscription.cancel();
      pluginInstance._onBundleLoaded();
      pluginInstance._engineMain = _IrisRtcEngine();
      pluginInstance._engineSub = _IrisRtcEngine();
    });
    document.body!.append(element);
  }

  final _controllerEngine = StreamController();
  final _controllerChannel = StreamController();
  late _IrisRtcEngine _engineMain;
  late _IrisRtcEngine _engineSub;

  final Completer<void> _loadBundleCompleter = Completer<void>();

  void _onBundleLoaded() {
    _loadBundleCompleter.complete(null);
  }

  _IrisRtcEngine _engine(Map<String, dynamic> args) {
    bool subProcess = args['subProcess'];
    if (subProcess) {
      return _engineSub;
    } else {
      return _engineMain;
    }
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    await _loadBundleCompleter.future;

    var args = <String, dynamic>{};
    if (call.arguments != null) {
      args = Map<String, dynamic>.from(call.arguments);
    }
    print('handleMethodCall: call.method: ${call.method}, args: ${call.arguments}');
    if (call.method == 'callApi') {
      int apiType = args['apiType'];
      if (apiType == 0) {
        _engine(args).setEventHandler(allowInterop((String event, String data) {
          _controllerEngine.add({
            'methodName': event,
            'data': data,
            'subProcess': _engine(args) == _engineSub,
          });
        }));
        _engine(args)
            .channel
            .setEventHandler(allowInterop((String event, String data) {
          _controllerChannel.add({
            'methodName': event,
            'data': data,
          });
        }));
      }
      String param = args['params'];
      return promiseToFuture(_engine(args).callApi(apiType, param));
    } else {
      throw PlatformException(code: ErrorCode.NotSupported.toString());
    }
  }

  // ignore: public_member_api_docs
  Future<dynamic> handleChannelMethodCall(MethodCall call) async {
    await _loadBundleCompleter.future;

    var args = <String, dynamic>{};
    if (call.arguments != null) {
      args = Map<String, dynamic>.from(call.arguments);
    }
    if (call.method == 'callApi') {
      int apiType = args['apiType'];
      String param = args['params'];
      return promiseToFuture(_engineMain.channel.callApi(apiType, param));
    } else {
      throw PlatformException(code: ErrorCode.NotSupported.toString());
    }
  }

  // ignore: public_member_api_docs
  Future<dynamic> handleADMMethodCall(MethodCall call) async {
    await _loadBundleCompleter.future;

    var args = <String, dynamic>{};
    if (call.arguments != null) {
      args = Map<String, dynamic>.from(call.arguments);
    }
    if (call.method == 'callApi') {
      int apiType = args['apiType'];
      String param = args['params'];
      return promiseToFuture(
          _engineMain.deviceManager.callApiAudio(apiType, param));
    } else {
      throw PlatformException(code: ErrorCode.NotSupported.toString());
    }
  }

  // ignore: public_member_api_docs
  Future<dynamic> handleVDMMethodCall(MethodCall call) async {
    await _loadBundleCompleter.future;

    var args = <String, dynamic>{};
    if (call.arguments != null) {
      args = Map<String, dynamic>.from(call.arguments);
    }
    if (call.method == 'callApi') {
      int apiType = args['apiType'];
      String param = args['params'];
      return promiseToFuture(
          _engineMain.deviceManager.callApiVideo(apiType, param));
    } else {
      throw PlatformException(code: ErrorCode.NotSupported.toString());
    }
  }

  // ignore: public_member_api_docs
  Future<dynamic> handleViewMethodCall(MethodCall call, Element element) async {
    await _loadBundleCompleter.future;

    print('handleViewMethodCall call.method: ${call.method}, call.arguments: ${call.arguments}, element: $element');

    var data = <String, dynamic>{};
    if (call.arguments != null) {
      data = Map<String, dynamic>.from(call.arguments);
    }
    if (call.method == 'setData') {
      final uid = data['userId'];
      if (uid == 0) {
        const kEngineSetupLocalVideo = 20;
        return promiseToFuture(_engine(data).callApi(
            kEngineSetupLocalVideo,
            jsonEncode({
              'canvas': {
                'uid': 0,
                'channelId': data['channelId'],
                'renderMode': data['renderMode'],
                'mirrorMode': data['mirrorMode'],
              },
            }),
            element));
      } else {
        const kEngineSetupRemoteVideo = 21;
        return promiseToFuture(_engine(data).callApi(
            kEngineSetupRemoteVideo,
            jsonEncode({
              'canvas': {
                'uid': uid,
                'channelId': data['channelId'],
                'renderMode': data['renderMode'],
                'mirrorMode': data['mirrorMode'],
              }
            }),
            element));
      }
    } else {
      throw PlatformException(
        code: 'Unimplemented',
        details:
            'agora_rtc_engine for web doesn\'t implement \'${call.method}\'',
      );
    }
  }
}
