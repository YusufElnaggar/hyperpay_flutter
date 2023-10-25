/* import 'package:flutter_test/flutter_test.dart';
import 'package:hyperpay_flutter/hyperpay_flutter_method_channel.dart';
import 'package:hyperpay_flutter/hyperpay_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHyperpayFlutterPlatform with MockPlatformInterfaceMixin implements HyperpayFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HyperpayFlutterPlatform initialPlatform = HyperpayFlutterPlatform.instance;

  test('$MethodChannelHyperpayFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHyperpayFlutter>());
  });
}
 */