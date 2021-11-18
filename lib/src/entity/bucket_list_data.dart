import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:native_ffi/native_ffi.dart';

///Native file data in [getBuckets]
class BucketListData extends Struct {
  external Pointer<Pointer<Utf8>> buckets;

  @Int32()
  external int length;
}