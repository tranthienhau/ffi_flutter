import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:native_ffi/native_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

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

  final PublishSubject<ImageFilterData> _progressFilterBehaviorSubject =
      PublishSubject<ImageFilterData>();

  Stream<ImageFilterData> get onImageFilterComplete =>
      _progressFilterBehaviorSubject.stream;

  Future<void> processAllFilters(String inputPath) async {
    Completer<void> _resultCompleter = Completer<void>();

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

    int filteCount = 0;
    port.listen((message) {
      filteCount++;

      ///ensure not call more than one times
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is ImageFilterData) {
        _progressFilterBehaviorSubject.sink.add(message);
      }

      if (filteCount == ImageFilter.values.length) {
        _resultCompleter.complete();
      }
      //
    });

    ///wait for send port return data
    await _resultCompleter.future;
  }

  Future<void> processImageFilter(ProcessImageArguments args) async {
    Completer<List<String>?> _resultCompleter = Completer<List<String>?>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessFilter,
      {
        'args': args,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      ///ensure not call more than one times
      if (_resultCompleter.isCompleted) {
        return;
      }

      _resultCompleter.complete();
    });

    ///wait for send port return data
    await _resultCompleter.future;

    ///release for other request
    // _lockRequest?.complete();
    // return result;
  }
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

    final outputPath = '$localPath/${fileName}_$filterName.jpg';

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

void _isolateProcessFilter(Map<String, dynamic> data) {
  final ProcessImageArguments args = data['args'];
  final SendPort sendPort = data['sendPort'];

  final Pointer<Utf8> inputPathPointer = args.inputPath.toNativeUtf8();
  final Pointer<Utf8> outputPathPointer = args.outputPath.toNativeUtf8();

  switch (args.filter) {
    case ImageFilter.cartoon:
      processCartoonFilter(
        inputPathPointer,
        outputPathPointer,
      );
      break;
    case ImageFilter.gray:
      processGrayFilter(
        inputPathPointer,
        outputPathPointer,
      );
      break;
    case ImageFilter.sepia:
      processSepiaFilter(
        inputPathPointer,
        outputPathPointer,
      );
      break;
    case ImageFilter.edgePreserving:
      processEdgePreservingFilter(
        inputPathPointer,
        outputPathPointer,
      );
      break;
    case ImageFilter.stylization:
      processStylizationFilter(
        inputPathPointer,
        outputPathPointer,
      );
      break;
  }

  calloc.free(inputPathPointer);
  calloc.free(outputPathPointer);
  sendPort.send(null);
}
