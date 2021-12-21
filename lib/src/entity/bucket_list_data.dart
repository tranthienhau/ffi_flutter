import 'dart:ffi';
import 'package:ffi/ffi.dart';


///Native file data in [getBuckets]
class BucketListData extends Struct {
  external Pointer<Pointer<Utf8>> buckets;

  @Int32()
  external int length;
}