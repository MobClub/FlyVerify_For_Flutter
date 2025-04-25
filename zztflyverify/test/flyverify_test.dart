import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyverify_plugin/flyverify.dart';

void main() {
  const MethodChannel channel = MethodChannel('flyverify');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlyVerify.platformVersion, '42');
  });
}
