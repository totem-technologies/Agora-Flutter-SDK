import 'dart:typed_data';

import 'package:agora_rtc_engine/src/impl/api_caller.dart';
import 'package:iris_event/iris_event.dart';

class EventLoop implements IrisEventHandler {
  final Map<Type, Set<IrisEventHandler>> _eventHandlers = {};

  void run() {
    apiCaller.addEventHandler(this);
  }

  void terminate() {
    _eventHandlers.clear();
    apiCaller.removeEventHandler(this);
  }

  @override
  void onEvent(String event, String data, List<Uint8List> buffers) {
    for (final es in _eventHandlers.values) {
      for (final e in es) {
        e.onEvent(event, data, buffers);
      }
    }
  }

  void addEventHandler(Type objectType, IrisEventHandler eventHandler) {
    final events =
        _eventHandlers.putIfAbsent(objectType, () => <IrisEventHandler>{});
    events.add(eventHandler);
  }

  void addEventHandlerIfTypeAbsent(
      Type objectType, IrisEventHandler eventHandler) {
    final events =
        _eventHandlers.putIfAbsent(objectType, () => <IrisEventHandler>{});
    if (events.isEmpty) {
      events.add(eventHandler);
    }
  }

  void removeEventHandler(Type objectType, IrisEventHandler eventHandler) {
    final events = _eventHandlers[objectType];
    events?.remove(eventHandler);
  }

  void removeEventHandlers(Type objectType) {
    _eventHandlers.remove(objectType);
  }
}
