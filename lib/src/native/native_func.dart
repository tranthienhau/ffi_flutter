import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:native_add/native_curl.dart';

///link to native library
final DynamicLibrary nativeCurlLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_curl.so")
    : DynamicLibrary.process();

///link to [curl_get] to call http get
final NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>) nativeCurlGet =
    nativeCurlLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(
                    Pointer<Utf8>, Pointer<Utf8>)>>("curl_get")
        .asFunction();

///link to [curl_post] to post form data
final NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>, Pointer, int)
    nativeCurlPost = nativeCurlLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer, Int32)>>("curl_post_form_data")
        .asFunction();

///link to [create_form_data_pointer] to allocate form data pointer array
final Pointer Function(int length) createPointerArrayFormData = nativeCurlLib
    .lookup<NativeFunction<Pointer Function(Int32 length)>>(
        "allocate_form_data_pointer")
    .asFunction();

///link to [set_value_formdata_pointer_array] to set element value form data pointer array
final void Function(Pointer formDataArray, int index, Pointer<Utf8> name,
        Pointer<Utf8> value, int type) setValueFormDataArrayPointer =
    nativeCurlLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer formDataArray,
                    Int32 index,
                    Pointer<Utf8> name,
                    Pointer<Utf8> value,
                    Int32 type)>>("set_value_formdata_pointer_array")
        .asFunction();

///link to [download_file] to call http get
final NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
    downloadFile = nativeCurlLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Utf8>)>>("download_file")
        .asFunction();

///link to [read_file] to read bytes file
final FileData Function(Pointer<Utf8>) readFileNative = nativeCurlLib
    .lookup<NativeFunction<FileData Function(Pointer<Utf8>)>>("read_file")
    .asFunction();

final BucketListData Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
    getBuckets = nativeCurlLib
        .lookup<
            NativeFunction<
                BucketListData Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Utf8>)>>("get_buckets")
        .asFunction();

final void Function(Pointer, int) freeBucketPointer = nativeCurlLib
    .lookup<NativeFunction<Void Function(Pointer , Int32)>>(
        "free_char_array")
    .asFunction();

final Pointer<Utf8> Function(Pointer, int) getItemInCharArray = nativeCurlLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer, Int32)>>(
    "get_item_char_array")
    .asFunction();
final void Function(Pointer<Utf8>, Pointer<Utf8> ,Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>) upLoadFileToS3 = nativeCurlLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>, Pointer<Utf8> ,Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>)>>(
    "upload_file_to_s3")
    .asFunction();


final Pointer<Utf8> Function(Pointer<Utf8>) nativeCompressString = nativeCurlLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
        "compress_string")
    .asFunction();
