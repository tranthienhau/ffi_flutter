import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffi_flutter/ffi_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('ffi_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FfiFlutter.platformVersion, '42');
  });
}
