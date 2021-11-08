import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:native_add/native_curl.dart';

///Native curl reponse in ([downloadFile], [nativeCurlPost], [nativeCurlGet])
class NativeCurlResponse extends Struct {
  external Pointer<Utf8> data;

  @Int32()
  external int status;
}

///Dart curl response
class CurlResponse {
  CurlResponse({required this.data, required this.statusCode});

  final String data;

  final int statusCode;
}
