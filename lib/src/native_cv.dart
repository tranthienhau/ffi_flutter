import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../native_ffi.dart';

class ImageFilterData {
  const ImageFilterData({
    required this.filter,
    required this.filterPath,
  });

  final ImageFilter filter;
  final String filterPath;
}

class NativeCv {
  static final NativeCv _instance = NativeCv._internal();

  factory NativeCv() {
    return _instance;
  }

  NativeCv._internal();

  Future<Stream<ImageFilterData?>> processAllFiltersStream(
      String inputPath) async {
    ///create receiport to get response
    final port = ReceivePort();
    final localPath = await _localPath;

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessAllFilters,
      {
        'inputPath': inputPath,
        'localPath': localPath,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    return port.map((message) {
      if (message is ImageFilterData) {
        return message;
      }

      return null;
    });
  }

  // Future<void> processImageFilter(ProcessImageArguments args) async {
  //   Completer<List<String>?> _resultCompleter = Completer<List<String>?>();
  //
  //   ///create receiport to get response
  //   final port = ReceivePort();
  //
  //   /// Spawning an isolate
  //   Isolate.spawn<Map<String, dynamic>>(
  //     _isolateProcessFilter,
  //     {
  //       'args': args,
  //       'sendPort': port.sendPort,
  //     },
  //     onError: port.sendPort,
  //     onExit: port.sendPort,
  //   );
  //
  //   port.listen((message) {
  //     ///ensure not call more than one times
  //     if (_resultCompleter.isCompleted) {
  //       return;
  //     }
  //
  //     _resultCompleter.complete();
  //   });
  //
  //   ///wait for send port return data
  //   await _resultCompleter.future;
  //
  //   ///release for other request
  // }
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

void _isolateProcessAllFilters(Map<String, dynamic> data) {
  final String inputPath = data['inputPath'];
  final String localPath = data['localPath'];
  final SendPort sendPort = data['sendPort'];

  final Pointer<Utf8> inputPathPointer = inputPath.toNativeUtf8();

  final matPointer = createMatPointer(inputPathPointer);

  ///free pointer
  calloc.free(inputPathPointer);

  final Logger logger = Logger();

  for (final filter in ImageFilter.values) {
    final fileName = inputPath.split('/').last.split('.').first;

    final filterName = filter.toString().split('.').last;

    String outputPath = '$localPath/${fileName}_$filterName.jpg';

    final Pointer<Utf8> outputPathPointer = outputPath.toNativeUtf8();

    switch (filter) {
      case ImageFilter.cartoon:
        processMatCartoonFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.gray:
        processMatGrayFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.sepia:
        processMatSepiaFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.edgePreserving:
        processMatEdgePreservingFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.stylization:
        processMatStylizationFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.original:
        outputPath = inputPath;
        break;

      case ImageFilter.invert:
        processMatInvertFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.pencilSketch:
        processMatPencilSketchFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.sharpen:
        processMatSharpenFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.hdr:
        processMatHdrFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.duoToneGreenEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;


      case ImageFilter.duoToneRedEx1:
        /// exp: 1,s1: 2, s2: 3, s3: 1
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneRedEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneRedEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneRedEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneRedEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneRedEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx1:
        /// exp: 2,s1: 0, s2: 1, s3: 0
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenDartEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneBlueGreenEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx1:
        /// exp: 1,s1: 1, s2: 2, s3: 0
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedDartEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
      case ImageFilter.duoToneGreenRedEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        createMatDuoTonePointer(matPointer, outputPathPointer, ptr.ref);
        calloc.free(ptr);
        break;
    }

    sendPort.send(ImageFilterData(
      filterPath: outputPath,
      filter: filter,
    ));

    logger.i('Filter $fileName complete');

    calloc.free(outputPathPointer);
  }

  calloc.free(matPointer);
}

// void _isolateProcessFilter(Map<String, dynamic> data) {
//   final ProcessImageArguments args = data['args'];
//   final SendPort sendPort = data['sendPort'];
//
//   final Pointer<Utf8> inputPathPointer = args.inputPath.toNativeUtf8();
//   final Pointer<Utf8> outputPathPointer = args.outputPath.toNativeUtf8();
//
//   switch (args.filter) {
//     case ImageFilter.cartoon:
//       processCartoonFilter(
//         inputPathPointer,
//         outputPathPointer,
//       );
//       break;
//     case ImageFilter.gray:
//       processGrayFilter(
//         inputPathPointer,
//         outputPathPointer,
//       );
//       break;
//     case ImageFilter.sepia:
//       processSepiaFilter(
//         inputPathPointer,
//         outputPathPointer,
//       );
//       break;
//     case ImageFilter.edgePreserving:
//       processEdgePreservingFilter(
//         inputPathPointer,
//         outputPathPointer,
//       );
//       break;
//     case ImageFilter.stylization:
//       processStylizationFilter(
//         inputPathPointer,
//         outputPathPointer,
//       );
//       break;
//     case ImageFilter.original:
//       break;
//
//     case ImageFilter.invert:
//
//       break;
//     case ImageFilter.pencilSketch:
//
//       break;
//     case ImageFilter.sharpen:
//
//       break;
//     case ImageFilter.hdr:
//
//       break;
//     case ImageFilter.duoToneGreenEx1:
//
//       break;
//     case ImageFilter.duoToneGreenEx2:
//
//       break;
//     case ImageFilter.duoToneGreenEx3:
//
//       break;
//     case ImageFilter.duoToneGreenEx4:
//
//       break;
//     case ImageFilter.duoToneGreenEx5:
//
//       break;
//     case ImageFilter.duoToneGreenEx6:
//
//       break;
//     case ImageFilter.duoToneRedEx1:
//
//       break;
//     case ImageFilter.duoToneRedEx2:
//
//       break;
//     case ImageFilter.duoToneRedEx3:
//
//       break;
//     case ImageFilter.duoToneRedEx4:
//
//       break;
//     case ImageFilter.duoToneRedEx5:
//
//       break;
//     case ImageFilter.duoToneRedEx6:
//
//       break;
//     case ImageFilter.duoToneBlueEx1:
//
//       break;
//     case ImageFilter.duoToneBlueEx2:
//
//       break;
//     case ImageFilter.duoToneBlueEx3:
//
//       break;
//     case ImageFilter.duoToneBlueEx4:
//
//       break;
//     case ImageFilter.duoToneBlueEx5:
//
//       break;
//     case ImageFilter.duoToneBlueEx6:
//
//       break;
//     case ImageFilter.duoToneBlueEx7:
//
//       break;
//     case ImageFilter.duoToneBlueEx8:
//
//       break;
//     case ImageFilter.duoToneBlueEx9:
//
//       break;
//     case ImageFilter.duoToneBlueEx10:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx1:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx2:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx3:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx4:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx5:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx6:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx7:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx8:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx9:
//
//       break;
//     case ImageFilter.duoToneBlueGreenEx10:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx1:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx2:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx3:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx4:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx5:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx6:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx7:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx8:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx9:
//
//       break;
//     case ImageFilter.duoToneBlueGreenDartEx10:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx1:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx2:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx3:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx4:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx5:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx6:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx7:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx8:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx9:
//
//       break;
//     case ImageFilter.duoToneGreenRedDartEx10:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx1:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx2:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx3:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx4:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx5:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx6:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx7:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx8:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx9:
//
//       break;
//     case ImageFilter.duoToneGreenRedEx10:
//
//       break;
//   }
//
//   calloc.free(inputPathPointer);
//   calloc.free(outputPathPointer);
//   sendPort.send(null);
// }
