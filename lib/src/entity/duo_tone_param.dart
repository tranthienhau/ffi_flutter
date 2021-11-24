import 'dart:ffi';

class DuoToneParam extends Struct {
  @Float()
  external double exponent;

  @Int32()
  external int s1;

  @Int32()
  external int s2;

  @Int32()
  external int s3;
}
