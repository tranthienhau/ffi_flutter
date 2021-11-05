import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

///link to native library
final DynamicLibrary nativeCurlLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_curl.so")
    : DynamicLibrary.process();

///link to native function
final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) nativeCurlGet =
    nativeCurlLib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Utf8>, Pointer<Utf8>)>>("curl_get")
        .asFunction();

///link to native function
final Pointer<Utf8> Function(
        Pointer<Utf8>, Pointer<Utf8>, Pointer<CurlFormData>, int)
    nativeCurlPost = nativeCurlLib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<CurlFormData>, Uint8)>>("curl_post")
        .asFunction();

// C function: struct Place create_place(char *name, double latitude, double longitude)
typedef CreateCurlFormDataNative = CurlFormData Function(
    Pointer<Utf8> name, Pointer<Utf8> value);
typedef CreateCurlFormData = CurlFormData Function(
    Pointer<Utf8> name, Pointer<Utf8> value);

///FormData in request
///Example --form 'name=value' \
class CurlFormData extends Struct {
  external Pointer<Utf8> name;

  external Pointer<Utf8> value;
}

class NativeCurl {
  ///[url]: url to get data
  ///[certPath]: in Android, you must save certificates.pem and provide [certPath] to access to https
  static String curlGet(String url, String certPath) {
    ///convert url and certPath to Pointer to pass to native
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();

    ///call native curl get
    final response = nativeCurlGet(urlPointer, certPathPointer);

    ///free pointer
    calloc.free(urlPointer);
    calloc.free(certPathPointer);

    ///convert Pointer to string in dart
    final result = response.toDartString();

    return result;
  }

  static Pointer<CurlFormData> formDataToArray(Map<String, String> formData) {
    final ptr =
        malloc.allocate<CurlFormData>(sizeOf<CurlFormData>() * formData.length);
    final createCurlFormData = nativeCurlLib.lookupFunction<
        CreateCurlFormDataNative, CreateCurlFormData>('create_form_data');
    int count = 0;
    for (final entry in formData.entries) {
      final name = entry.key;
      final value = entry.value;

      ///convert url and certPath to Pointer to pass to native
      final Pointer<Utf8> namePointer = name.toNativeUtf8();

      final Pointer<Utf8> valuePointer = value.toNativeUtf8();

      ///call native curl get
      final formData = createCurlFormData(namePointer, valuePointer);

      ///free pointer
      calloc.free(namePointer);
      calloc.free(valuePointer);
      ptr.elementAt(count).ref.name = formData.name;
      ptr.elementAt(count).ref.value = formData.value;
      count++;
    }

    return ptr;
  }

  ///[url]: url to get data
  ///[certPath]: in Android, you must save certificates.pem and provide [certPath] to access to https
  static String uploadFormData({
    required String url,
    required String certPath,
    required Map<String, String> formData,
  }) {
    ///convert url and certPath to Pointer to pass to native
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();

    final Pointer<CurlFormData> formDataPointer = formDataToArray(formData);

    final response = nativeCurlPost(
        urlPointer, certPathPointer, formDataPointer, formData.length);

    ///free pointer
    calloc.free(urlPointer);
    calloc.free(certPathPointer);

    ///convert Pointer to string in dart
    final result = response.toDartString();

    return result;
  }

// static void createFormData(String name, String value) {
//   ///convert value name to Pointer to pass to native
//   final Pointer<Utf8> valuePointer = name.toNativeUtf8();
//
//   final Pointer<Utf8> valuePathPointer = value.toNativeUtf8();
//   final createCurlFormData = nativeCurlLib.lookupFunction<
//       CreateCurlFormDataNative, CreateCurlFormData>('create_form_data');
//
//   ///call native curl get
//   final formData = createCurlFormData(valuePointer, valuePathPointer);
//
//
//   ///free pointer
//   calloc.free(valuePointer);
//   calloc.free(valuePathPointer);
// }
}
