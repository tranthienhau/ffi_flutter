import 'dart:async';

import 'package:flutter/services.dart';

class FfiFlutter {
  static const MethodChannel _channel = MethodChannel('ffi_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> openCameraFilter() async {
    _channel.invokeMethod('startCameraFilter');
  }
}
