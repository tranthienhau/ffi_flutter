import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:native_ffi/native_ffi.dart';

class NativeAws {
  ///Add certificates to path
  Future<void> init({
    required String certPath,
    required String accessKeyId,
    required String secretKeyId,
  }) async {
    _certPath = certPath;
    _accessKeyId = accessKeyId;
    _secretKeyId = secretKeyId;
  }

  Completer<void>? _lockRequest;

  ///In Android to use curl we must provide a certificates file
  late String _certPath;
  late String _accessKeyId;
  late String _secretKeyId;

  Future<void> uploadFile({
    required String filePath,
    required String fileName,
    required String bucketName,
  }) async {
    ///avoid call multiple times
    if (_lockRequest == null) {
      _lockRequest = Completer<void>();
    } else {
      await _lockRequest?.future;
      await Future.delayed(const Duration(milliseconds: 100));
      _lockRequest = Completer<void>();
    }

    Completer<void> _resultCompleter = Completer<void>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateUploadFile,
      {
        'filePath': filePath,
        'fileName': fileName,
        'bucketName': bucketName,
        'accessKeyId': _accessKeyId,
        'secretKeyId': _secretKeyId,
        'certPath': _certPath,
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
    _lockRequest?.complete();
  }

  Future<List<String>?> getAllBuckets() async {
    ///avoid call multiple times
    if (_lockRequest == null) {
      _lockRequest = Completer<void>();
    } else {
      await _lockRequest?.future;
      await Future.delayed(const Duration(milliseconds: 100));
      _lockRequest = Completer<void>();
    }

    Completer<List<String>?> _resultCompleter = Completer<List<String>?>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateGetBuckets,
      {
        'accessKeyId': _accessKeyId,
        'secretKeyId': _secretKeyId,
        'certPath': _certPath,
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

      if (message is List) {
        _resultCompleter.complete(message.cast<String>());
      } else {
        _resultCompleter.complete(null);
      }
    });

    ///wait for send port return data
    final result = await _resultCompleter.future;

    ///release for other request
    _lockRequest?.complete();
    return result;
  }
}

void _isolateUploadFile(Map<String, dynamic> data) {
  /// get data
  final String filePath = data['filePath'];
  final String fileName = data['fileName'];
  final String certPath = data['certPath'];
  final String secretKeyId = data['secretKeyId'];
  final String accessKeyId = data['accessKeyId'];
  final String bucketName = data['bucketName'];


  final SendPort sendPort = data['sendPort'];

  final Pointer<Utf8> filePathPointer = filePath.toNativeUtf8();
  final Pointer<Utf8> fileNamePointer = fileName.toNativeUtf8();
  final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();
  final Pointer<Utf8> bucketNamePointer = bucketName.toNativeUtf8();
  final Pointer<Utf8> secretKeyIdPointer = secretKeyId.toNativeUtf8();

  final Pointer<Utf8> accessKeyIdPointer = accessKeyId.toNativeUtf8();
  upLoadFileToS3(accessKeyIdPointer, secretKeyIdPointer, certPathPointer,
      bucketNamePointer, filePathPointer, fileNamePointer);

  ///free pointer
  calloc.free(secretKeyIdPointer);
  calloc.free(certPathPointer);
  calloc.free(accessKeyIdPointer);
  calloc.free(bucketNamePointer);
  calloc.free(fileNamePointer);
  calloc.free(filePathPointer);
  sendPort.send(null);
}

void _isolateGetBuckets(Map<String, dynamic> data) {
  /// get data
  final String secretKeyId = data['secretKeyId'];
  final String accessKeyId = data['accessKeyId'];
  final String certPath = data['certPath'];
  final SendPort sendPort = data['sendPort'];

// SendPort.lookupPortByName();
  ///convert url and certPath to Pointer to pass to native
  final Pointer<Utf8> secretKeyIdPointer = secretKeyId.toNativeUtf8();
  final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();
  final Pointer<Utf8> accessKeyIdPointer = accessKeyId.toNativeUtf8();

  final bucketListData =
      getBuckets(accessKeyIdPointer, secretKeyIdPointer, certPathPointer);

  List<String> buckets = <String>[];

  for (int i = 0; i < bucketListData.length; i++) {
    try {
      final result = getItemInCharArray(bucketListData.buckets, i);

      final bucket = result.toDartString();
      buckets.add(bucket);
    } catch (_) {}
  }

  freeBucketPointer(bucketListData.buckets, bucketListData.length);

  ///free pointer
  calloc.free(secretKeyIdPointer);
  calloc.free(certPathPointer);
  calloc.free(accessKeyIdPointer);

  sendPort.send(buckets);
}
