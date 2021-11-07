import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

///link to native library
final DynamicLibrary nativeCurlLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_curl.so")
    : DynamicLibrary.process();

///link to [curl_get] to call http get
final Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) nativeCurlGet =
nativeCurlLib
    .lookup<
    NativeFunction<
        Pointer<Utf8> Function(
            Pointer<Utf8>, Pointer<Utf8>)>>("curl_get")
    .asFunction();

///link to [curl_post] to post form data
final Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer, int)
nativeCurlPost = nativeCurlLib
    .lookup<
    NativeFunction<
        Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
            Pointer, Int32)>>("curl_post_form_data")
    .asFunction();


///link to [create_form_data_pointer] to allocate form data pointer array
final Pointer Function(int length)
createPointerArrayFormData = nativeCurlLib
    .lookup<
    NativeFunction<
        Pointer Function(
            Int32 length)>>("allocate_form_data_pointer")
    .asFunction();

///link to [set_value_formdata_pointer_array] to set element value form data pointer array
final void Function(Pointer formDataArray, int index,
    Pointer<Utf8> name, Pointer<Utf8> value, int type)
setValueFormDataArrayPointer = nativeCurlLib
    .lookup<
    NativeFunction<
        Void Function(
            Pointer formDataArray,
            Int32 index,
            Pointer<Utf8> name,
            Pointer<Utf8> value,
            Int32 type)>>("set_value_formdata_pointer_array")
    .asFunction();
