import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:native_ffi/native_ffi.dart';

class NativeCv {
  static Future<void> processImageFilter(ProcessImageArguments args) async {
    Completer<List<String>?> _resultCompleter = Completer<List<String>?>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessCartoonFilter,
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

void _isolateProcessCartoonFilter(Map<String, dynamic> data) {
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
