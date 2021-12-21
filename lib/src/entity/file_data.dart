import 'dart:ffi';

///Native file data in [readFileNative]
class FileData extends Struct {
  external Pointer<Uint8> bytes;

  @Int32()
  external int length;
}