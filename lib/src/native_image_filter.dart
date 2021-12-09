import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ffi_flutter/native_ffi.dart';
import 'package:logger/logger.dart';

class NativeImageData {
  final Pointer originMat;
  final Uint8List originBytes;
  final Pointer<Int32> byteLength;

  const NativeImageData({
    required this.originMat,
    required this.originBytes,
    required this.byteLength,
  });
}

class NativeImageFilterData {
  final ImageFilter filter;
  final Uint8List bytes;

  const NativeImageFilterData({
    required this.filter,
    required this.bytes,
  });
}

class NativeImageFilter {
  NativeImageData? _filterData;
  final Logger logger = Logger();

  Future<Uint8List> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File file = File.fromUri(myUri);
    Uint8List bytes = await file.readAsBytes();

    return bytes;
  }

  Future<void> loadOriginBytes(Uint8List bytes) async {
    await dispose();

    Completer<Map<String, dynamic>?> _resultCompleter =
        Completer<Map<String, dynamic>?>();
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateCreateMatPointer,
      {
        'bytes': bytes,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is Map<String, dynamic>) {
        _resultCompleter.complete(message);
        return;
      }

      _resultCompleter.complete(null);
    });

    final Map<String, dynamic>? result = await _resultCompleter.future;

    if (result == null) {
      throw Exception('Can not create cv:Mat pointer');
    }

    final Pointer matPointer = Pointer.fromAddress(result['matAddress']);
    final Pointer<Int32> byteLength =
        Pointer.fromAddress(result['byteLengthAddress']);

    _filterData = NativeImageData(
      byteLength: byteLength,
      originBytes: bytes,
      originMat: matPointer,
    );

    logger.i('Complete create cv:Mat pointer');
  }

  Future<Uint8List> loadOriginImagePath(String imagePath) async {
    await dispose();

    final bytes = await _readFileByte(imagePath);

    Completer<Map<String, dynamic>?> _resultCompleter =
        Completer<Map<String, dynamic>?>();
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateCreateMatPointer,
      {
        'bytes': bytes,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is Map<String, dynamic>) {
        _resultCompleter.complete(message);
        return;
      }

      _resultCompleter.complete(null);
    });

    final Map<String, dynamic>? result = await _resultCompleter.future;

    if (result == null) {
      throw Exception('Can not create cv:Mat pointer');
    }

    final Pointer matPointer = Pointer.fromAddress(result['matAddress']);
    final Pointer<Int32> byteLength =
        Pointer.fromAddress(result['byteLengthAddress']);

    _filterData = NativeImageData(
      byteLength: byteLength,
      originBytes: bytes,
      originMat: matPointer,
    );

    logger.i('Complete create cv:Mat pointer');
    return bytes;
  }

  Future<Uint8List?> processDuoToneFilter({
    required double exponent,
    required int s1,
    required int s2,
    required int s3,
  }) async {
    assert(s1 >= 0 && s1 <= 2);
    assert(s2 >= 0 && s2 <= 3);
    assert(s3 >= 0 && s3 <= 1);

    Completer<int?> _resultCompleter = Completer<int?>();

    final port = ReceivePort();
    final filterData = _filterData;

    if (filterData == null) {
      throw Exception('Please call loadOriginImagePath first');
    }

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessDuoToneFilter,
      {
        'matAddress': filterData.originMat.address,
        'byteLengthAddress': filterData.byteLength.address,
        'exponent': exponent,
        's1': s1,
        's2': s2,
        's3': s3,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is int) {
        _resultCompleter.complete(message);
        return;
      }

      _resultCompleter.complete(null);
    });

    final int? byteAddress = await _resultCompleter.future;
    if (byteAddress == null) {
      logger.e('processDuoToneFilter', 'Failed to process duo tone filter');
      return null;
    }

    Pointer<Uint8> imageBytesPointer = Pointer.fromAddress(byteAddress);

    Uint8List imageBytes =
        imageBytesPointer.asTypedList(filterData.byteLength.value);

    final copy = Uint8List.fromList(imageBytes);
    malloc.free(imageBytesPointer);

    return copy;
  }

  Future<Uint8List?> processImageFilter({
    required ImageFilter filter,
  }) async {
    Completer<Uint8List?> _resultCompleter = Completer<Uint8List?>();

    final port = ReceivePort();
    final filterData = _filterData;

    if (filterData == null) {
      throw Exception('Please call loadOriginImagePath first');
    }

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessFilter,
      {
        'matAddress': filterData.originMat.address,
        'byteLengthAddress': filterData.byteLength.address,
        'filter': filter,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is Map<String, dynamic>) {
        final bytes = message['bytes'];
        if (bytes is Uint8List) {
          _resultCompleter.complete(bytes);
          return;
        }
      }

      _resultCompleter.complete(null);
    });

    final Uint8List? bytes = await _resultCompleter.future;
    if (bytes == null) {
      logger.e('processImageFilter', 'Failed to process image filter');
      return null;
    }

    return bytes;
  }

  Future<Stream<NativeImageFilterData?>> processAllFiltersStream() async {
    ///create receiport to get response
    final port = ReceivePort();
    final filterData = _filterData;

    if (filterData == null) {
      throw Exception('Please call loadOriginImagePath first');
    }

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateProcessAllFilters,
      {
        'matAddress': filterData.originMat.address,
        'byteLengthAddress': filterData.byteLength.address,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    return port.map((message) {
      if (message is Map<String, dynamic>) {
        final filter = message['filter'];
        final bytes = message['bytes'];

        if (filter != null && bytes != null) {
          return NativeImageFilterData(
            filter: message['filter'],
            bytes: message['bytes'],
          );
        }
      }

      return null;
    });
  }

  Future<void> dispose() async {
    final NativeImageData? data = _filterData;
    if (data != null) {
      malloc.free(data.originMat);
      malloc.free(data.byteLength);
    }

    _filterData = null;
  }
}

Pointer<Uint8> _intListToArray(Uint8List list) {
  final Pointer<Uint8> ptr = malloc.allocate<Uint8>(list.length);
  for (var i = 0; i < list.length; i++) {
    ptr.elementAt(i).value = list[i];
  }
  return ptr;
}

void _isolateCreateMatPointer(Map<String, dynamic> data) {
  final Uint8List bytes = data['bytes'];
  final SendPort sendPort = data['sendPort'];
  Pointer<Uint8> pointerImage = _intListToArray(bytes);

  Pointer<Int32> imgByteLength = malloc.allocate<Int32>(sizeOf<Int32>());
  imgByteLength.value = bytes.length;
  final matPointer = createMatPointerFromBytes(pointerImage, imgByteLength);

  malloc.free(pointerImage);

  sendPort.send({
    'matAddress': matPointer.address,
    'byteLengthAddress': imgByteLength.address,
  });
}

void _isolateProcessDuoToneFilter(Map<String, dynamic> data) {
  final double exponent = data['exponent'];
  final int s1 = data['s1'];
  final int s2 = data['s2'];
  final int s3 = data['s3'];
  final int matAddress = data['matAddress'];
  final SendPort sendPort = data['sendPort'];

  final Pointer<Void> matPointer = Pointer.fromAddress(matAddress);
  // final Pointer<Int32> imgByteLength = Pointer.fromAddress(byteLengthAddress);

  /// exp: 1,s1: 2, s2: 3, s3: 1
  Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
  ptr.ref.exponent = exponent;
  ptr.ref.s1 = s1;
  ptr.ref.s2 = s2;
  ptr.ref.s3 = s3;

  Pointer<Uint8> imageBytesPointer =
      processMatToDuoToneBytes(matPointer, ptr.ref);

  sendPort.send(imageBytesPointer.address);
}

void _isolateProcessFilter(Map<String, dynamic> param) {
  final int matAddress = param['matAddress'];
  final ImageFilter filter = param['filter'];
  final int byteLengthAddress = param['byteLengthAddress'];
  final SendPort sendPort = param['sendPort'];

  final Pointer<Void> matPointer = Pointer.fromAddress(matAddress);
  final Pointer<Int32> byteLengthPointer =
      Pointer.fromAddress(byteLengthAddress);

  final Logger logger = Logger();

  final Map<String, dynamic> data = {};
  data['filter'] = filter;
  switch (filter) {
    case ImageFilter.cartoon:
      // processMatCartoonFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.gray:
      // processMatGrayFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.sepia:
      // processMatSepiaFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.edgePreserving:
      // processMatEdgePreservingFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.stylization:
      // processMatStylizationFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.original:
      break;

    case ImageFilter.invert:
      // processMatInvertFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.pencilSketch:
      // processMatPencilSketchFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.sharpen:
      // processMatSharpenFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.hdr:
      // processMatHdrFilter(matPointer, outputPathPointer);
      break;
    case ImageFilter.duoToneGreenEx1:

      /// exp: 1,s1: 2, s2: 3, s3: 1
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;

      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;

    case ImageFilter.duoToneRedEx1:

      /// exp: 1,s1: 2, s2: 3, s3: 1
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneRedEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneRedEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneRedEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneRedEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneRedEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 2;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx1:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx7:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 7;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx8:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 8;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx9:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 9;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueEx10:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 10;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 3;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx1:

      /// exp: 2,s1: 0, s2: 1, s3: 0
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx7:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 7;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx8:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 8;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx9:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 9;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenDartEx10:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 10;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx1:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx7:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 7;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx8:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 8;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx9:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 9;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneBlueGreenEx10:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 10;
      ptr.ref.s1 = 0;
      ptr.ref.s2 = 1;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx1:

      /// exp: 1,s1: 1, s2: 2, s3: 0
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx7:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 7;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx8:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 8;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx9:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 9;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedDartEx10:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 10;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 0;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx1:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 1;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx2:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 2;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx3:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 3;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx4:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 4;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx5:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 5;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx6:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 6;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx7:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 7;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx8:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 8;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx9:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 9;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
    case ImageFilter.duoToneGreenRedEx10:
      Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
      ptr.ref.exponent = 10;
      ptr.ref.s1 = 1;
      ptr.ref.s2 = 2;
      ptr.ref.s3 = 1;
      Pointer<Uint8> imageBytesPointer =
          processMatToDuoToneBytes(matPointer, ptr.ref);
      Uint8List imageBytes =
          imageBytesPointer.asTypedList(byteLengthPointer.value);

      final copy = Uint8List.fromList(imageBytes);
      malloc.free(imageBytesPointer);

      data['bytes'] = copy;

      break;
  }

  sendPort.send(data);
}

void _isolateProcessAllFilters(Map<String, dynamic> data) {
  final int matAddress = data['matAddress'];
  final int byteLengthAddress = data['byteLengthAddress'];
  final SendPort sendPort = data['sendPort'];

  final Pointer<Void> matPointer = Pointer.fromAddress(matAddress);
  final Pointer<Int32> byteLengthPointer =
      Pointer.fromAddress(byteLengthAddress);

  final Logger logger = Logger();

  for (final filter in ImageFilter.values) {
    // final Pointer<Int32> imgByteLength = Pointer.fromAddress(byteLengthAddress);

    final Map<String, dynamic> data = {};
    data['filter'] = filter;
    switch (filter) {
      case ImageFilter.cartoon:
        // processMatCartoonFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.gray:
        // processMatGrayFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.sepia:
        // processMatSepiaFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.edgePreserving:
        // processMatEdgePreservingFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.stylization:
        // processMatStylizationFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.original:
        break;

      case ImageFilter.invert:
        // processMatInvertFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.pencilSketch:
        // processMatPencilSketchFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.sharpen:
        // processMatSharpenFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.hdr:
        // processMatHdrFilter(matPointer, outputPathPointer);
        break;
      case ImageFilter.duoToneGreenEx1:

        /// exp: 1,s1: 2, s2: 3, s3: 1
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;

        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;

      case ImageFilter.duoToneRedEx1:

        /// exp: 1,s1: 2, s2: 3, s3: 1
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneRedEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneRedEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneRedEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneRedEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneRedEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 2;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 3;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx1:

        /// exp: 2,s1: 0, s2: 1, s3: 0
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenDartEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneBlueGreenEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 0;
        ptr.ref.s2 = 1;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx1:

        /// exp: 1,s1: 1, s2: 2, s3: 0
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedDartEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 0;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx1:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 1;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx2:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 2;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx3:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 3;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx4:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 4;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx5:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 5;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx6:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 6;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx7:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 7;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx8:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 8;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx9:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 9;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
      case ImageFilter.duoToneGreenRedEx10:
        Pointer<DuoToneParam> ptr = malloc<DuoToneParam>();
        ptr.ref.exponent = 10;
        ptr.ref.s1 = 1;
        ptr.ref.s2 = 2;
        ptr.ref.s3 = 1;
        Pointer<Uint8> imageBytesPointer =
            processMatToDuoToneBytes(matPointer, ptr.ref);
        Uint8List imageBytes =
            imageBytesPointer.asTypedList(byteLengthPointer.value);

        final copy = Uint8List.fromList(imageBytes);
        malloc.free(imageBytesPointer);

        data['bytes'] = copy;

        break;
    }

    sendPort.send(data);

    logger.i('Filter complete');
  }
}
