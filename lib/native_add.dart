import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

final DynamicLibrary nativeAddLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_add.so")
    : DynamicLibrary.process();

final Pointer<Utf8> Function(Pointer<Utf8>) nativeCurlGet = nativeAddLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>("curl_get")
    .asFunction();

class NativeAdd {
  static const MethodChannel _channel = MethodChannel('native_add');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static String curlGet(String url) {
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final response = nativeCurlGet(urlPointer);

    calloc.free(urlPointer);

    final result = response.toDartString();

    return result;
  }
}
