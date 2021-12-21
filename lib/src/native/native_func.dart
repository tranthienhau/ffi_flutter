import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../../native_ffi.dart';

///link to native library
final DynamicLibrary _nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative-lib.so")
    : DynamicLibrary.process();

///link to [curl_get] to call http get
final NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>) nativeCurlGet =
    _nativeLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(
                    Pointer<Utf8>, Pointer<Utf8>)>>("curl_get")
        .asFunction();

///link to [curl_post] to post form data
final NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>, Pointer, int)
    nativeCurlPost = _nativeLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer, Int32)>>("curl_post_form_data")
        .asFunction();

///link to [create_form_data_pointer] to allocate form data pointer array
final Pointer Function(int length) createPointerArrayFormData = _nativeLib
    .lookup<NativeFunction<Pointer Function(Int32 length)>>(
        "allocate_form_data_pointer")
    .asFunction();

///link to [set_value_formdata_pointer_array] to set element value form data pointer array
final void Function(Pointer formDataArray, int index, Pointer<Utf8> name,
        Pointer<Utf8> value, int type) setValueFormDataArrayPointer =
    _nativeLib
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
    downloadFile = _nativeLib
        .lookup<
            NativeFunction<
                NativeCurlResponse Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Utf8>)>>("download_file")
        .asFunction();

///link to [read_file] to read bytes file
final FileData Function(Pointer<Utf8>) readFileNative = _nativeLib
    .lookup<NativeFunction<FileData Function(Pointer<Utf8>)>>("read_file")
    .asFunction();

final BucketListData Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
    getBuckets = _nativeLib
        .lookup<
            NativeFunction<
                BucketListData Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Utf8>)>>("get_buckets")
        .asFunction();

final void Function(Pointer, int) freeBucketPointer = _nativeLib
    .lookup<NativeFunction<Void Function(Pointer, Int32)>>("free_char_array")
    .asFunction();

final Pointer<Utf8> Function(Pointer, int) getItemInCharArray = _nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer, Int32)>>(
        "get_item_char_array")
    .asFunction();
final void Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>,
        Pointer<Utf8>, Pointer<Utf8>) upLoadFileToS3 =
    _nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>)>>("upload_file_to_s3")
        .asFunction();

final Pointer<Utf8> Function(Pointer<Utf8>) nativeCompressString = _nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
        "compress_string")
    .asFunction();

typedef _CProcessMatDuoToneImageFunc = Void Function(
    Pointer, Pointer<Utf8>, DuoToneParam);

typedef _ProcessMatDuoToneImageFunc = void Function(
    Pointer, Pointer<Utf8>, DuoToneParam);

final _ProcessMatDuoToneImageFunc createMatDuoTonePointer = _nativeLib
    .lookup<NativeFunction<_CProcessMatDuoToneImageFunc>>(
        'apply_mat_duo_tone_filter')
    .asFunction();

typedef _CProcessImageFunc = Void Function(Pointer<Utf8>, Pointer<Utf8>);

typedef _CProcessMatFunc = Void Function(
    Pointer<Void>, Pointer<Int32> imgLengthBytes);

typedef _CProcessMatFilterFunc = Void Function(Pointer, Pointer<Utf8>);

typedef _ProcessMatFilterFunc = void Function(Pointer, Pointer<Utf8>);

typedef _ProcessMatFunc = void Function(
    Pointer<Void>, Pointer<Int32> imgLengthBytes);

typedef _CCreateMatFilterFunc = Pointer Function(Pointer<Utf8>);

typedef _CreateMatFilterFunc = Pointer Function(Pointer<Utf8>);

typedef _ProcessImageFunc = void Function(Pointer<Utf8>, Pointer<Utf8>);

final _ProcessMatFunc processMatToBytesGrayscale = _nativeLib
    .lookup<NativeFunction<_CProcessMatFunc>>('process_mat_to_bytes_greyscale')
    .asFunction();

final Pointer<Void> Function(Pointer<Uint8> img, Pointer<Int32> imgLengthBytes)
    createMatPointerFromBytes = _nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Uint8>,
                    Pointer<Int32>)>>('create_mat_pointer_from_bytes')
        .asFunction();

final Pointer<Uint8> Function(Pointer<Void> matPointer, DuoToneParam param)
    processMatToDuoToneBytes = _nativeLib
        .lookup<
            NativeFunction<
                Pointer<Uint8> Function(
                    Pointer<Void> matPointer,
                    DuoToneParam param)>>('process_mat_to_duo_tone_bytes')
        .asFunction();

final _CreateMatFilterFunc createMatPointer = _nativeLib
    .lookup<NativeFunction<_CCreateMatFilterFunc>>('create_mat_pointer')
    .asFunction();

final _ProcessMatFilterFunc processMatGrayFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_gray_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatCartoonFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_cartoon_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatSepiaFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_sepia_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatEdgePreservingFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>(
        'apply_mat_edge_preserving_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatStylizationFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>(
        'apply_mat_stylization_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatSummerFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_summer_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatInvertFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_invert_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatPencilSketchFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>(
        'apply_mat_pencil_sketch_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatSharpenFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_sharpen_filter')
    .asFunction();

final _ProcessMatFilterFunc processMatHdrFilter = _nativeLib
    .lookup<NativeFunction<_CProcessMatFilterFunc>>('apply_mat_hdr_filter')
    .asFunction();

final _ProcessImageFunc processGrayFilter = _nativeLib
    .lookup<NativeFunction<_CProcessImageFunc>>('apply_gray_filter')
    .asFunction();

final _ProcessImageFunc processCartoonFilter = _nativeLib
    .lookup<NativeFunction<_CProcessImageFunc>>('apply_cartoon_filter')
    .asFunction();

final _ProcessImageFunc processSepiaFilter = _nativeLib
    .lookup<NativeFunction<_CProcessImageFunc>>('apply_sepia_filter')
    .asFunction();

final _ProcessImageFunc processEdgePreservingFilter = _nativeLib
    .lookup<NativeFunction<_CProcessImageFunc>>('apply_edge_preserving_filter')
    .asFunction();

final _ProcessImageFunc processStylizationFilter = _nativeLib
    .lookup<NativeFunction<_CProcessImageFunc>>('apply_stylization_filter')
    .asFunction();
