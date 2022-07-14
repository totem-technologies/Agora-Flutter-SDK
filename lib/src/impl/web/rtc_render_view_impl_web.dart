import 'package:agora_rtc_engine/src/impl/render/rtc_render_view_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';
// import 'dart_ui.dart' as ui;

class RtcRenderViewImplWeb extends RtcRenderViewInterface {
  int _creationViewIdCounter = 1;

  Map<int, RtcRenderViewController> _controllerById =
      <int, RtcRenderViewController>{};

  final MethodChannel _webSurfaceViewControllerChannel =
      const MethodChannel('agora_rtc_engine/web_surface_view_controller');

  @override
  Future<int> createView() async {
    final int creationViewId = _creationViewIdCounter++;
    await _webSurfaceViewControllerChannel.invokeMethod('create_view', creationViewId);
    final controller = RtcRenderViewController(creationViewId);
    _controllerById[creationViewId] = controller;

    return creationViewId;
  }

  @override
  Future<void> dispose(int creationViewId) async {
    _controllerById[creationViewId]?.dispose();
    _controllerById.remove(creationViewId);
  }

  @override
  Widget buildView(int creationViewId, PlatformViewCreatedCallback? onPlatformViewCreated) {
    return _controllerById[creationViewId]!.widget!;
  }
}

class RtcRenderViewController {
  RtcRenderViewController(this._creationViewId) {
    // _div = DivElement()
    //   ..id = _getViewType(_creationViewId)
    //   ..style.width = '100%'
    //   ..style.height = '100%';

    // ui.platformViewRegistry.registerViewFactory(
    //   _getViewType(_creationViewId),
    //   (int viewId) => _div,
    // );
  }

  final int _creationViewId;

  // The Flutter widget that contains the rendered Map.
  HtmlElementView? _widget;
  late HtmlElement _div;
  // Creates the 'viewType' for the _widget
  String _getViewType(int viewId) => 'agora_rtc_engine/surface_view_$viewId';

  /// The Flutter widget that will contain the rendered Map. Used for caching.
  Widget? get widget {
    if (_widget == null) {
      _widget = HtmlElementView(
        viewType: _getViewType(_creationViewId),
      );
    }
    return _widget;
  }

  void dispose() {
    _widget = null;
  }
}
