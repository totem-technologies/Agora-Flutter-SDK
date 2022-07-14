import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

abstract class RtcRenderViewInterface {
  const RtcRenderViewInterface();

  static RtcRenderViewInterface _instance = EmptyRtcRenderViewInterfaceImpl();

  static RtcRenderViewInterface get instance => _instance;

  static set instance(RtcRenderViewInterface instance) {
    _instance = instance;
  }

  Future<int> createView();

  Widget buildView(
      int creationViewId, PlatformViewCreatedCallback? onPlatformViewCreated);

  Future<void> dispose(int creationViewId);
}

class EmptyRtcRenderViewInterfaceImpl extends RtcRenderViewInterface {
  const EmptyRtcRenderViewInterfaceImpl();
  @override
  Future<int> createView() {
    throw UnimplementedError();
  }

  @override
  Widget buildView(
      int creationViewId, PlatformViewCreatedCallback? onPlatformViewCreated) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose(int creationViewId) {
    // TODO: implement dispose
    throw UnimplementedError();
  }
}
