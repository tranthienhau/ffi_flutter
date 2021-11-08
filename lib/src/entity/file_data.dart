import 'dart:ffi';
import 'package:native_add/native_curl.dart';

///Native file data in [readFileNative]
class FileData extends Struct {
  external Pointer<Uint8> bytes;

  @Int32()
  external int length;
}