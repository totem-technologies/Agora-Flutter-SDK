
import 'iris_tester_platform_interface.dart';

class IrisTester {
  Future<String?> getPlatformVersion() {
    return IrisTesterPlatform.instance.getPlatformVersion();
  }
}
