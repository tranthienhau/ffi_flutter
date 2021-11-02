import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

///link to native library
final DynamicLibrary nativeAddLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_add.so")
    : DynamicLibrary.process();

///link to native function
final Pointer<Utf8> Function(Pointer<Utf8>) nativeCurlGet = nativeAddLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>("curl_get")
    .asFunction();

class NativeCurl {
  static String curlGet(String url) {
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final response = nativeCurlGet(urlPointer);

    calloc.free(urlPointer);

    final result = response.toDartString();

    return result;
  }
}
