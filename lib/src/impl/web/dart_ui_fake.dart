import 'dart:html' as html;

class platformViewRegistry {
  static bool registerViewFactory(
      String viewTypeId, html.Element Function(int viewId) viewFactory) {
    return false;
  }
}
