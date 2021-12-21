import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../native_ffi.dart';


///Call native IO for write and read file
class NativeIO {
  static Future<Uint8List?> readFile(String filePath) async {
    ///await isolate complete
    Completer<Uint8List?> _resultCompleter = Completer<Uint8List?>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateReadFile,
      {
        'filePath': filePath,
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

      ///Complete wait data
      _resultCompleter.complete(message);
    });

    ///wait for send port return data
    final result = await _resultCompleter.future;

    return result;
  }
}

void _isolateReadFile(Map<String, dynamic> data) {
  /// get data
  final String filePath = data['filePath'];
  final SendPort sendPort = data['sendPort'];


  ///convert url and certPath to Pointer to pass to native
  final Pointer<Utf8> filePathPointer = filePath.toNativeUtf8();

  ///call native curl post form data
  final response = readFileNative(filePathPointer);

  ///free pointer
  calloc.free(filePathPointer);

  ///convert Pointer to string in dart

  final bytesPointer = response.bytes;
  final lengthInBytes = response.length;

  final bytes = bytesPointer.asTypedList(lengthInBytes);

  sendPort.send(bytes);
}
