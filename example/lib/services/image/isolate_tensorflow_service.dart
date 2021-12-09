import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi_flutter_example/services/image/image_transfer_service.dart';

class IsolateTensorflowTransferService implements ImageTransferService {
  late ReceivePort _receivePort;

  @override
  Future<void> init() async {
    _receivePort = ReceivePort();
  }

  @override
  Future<void> loadImage(Uint8List data) {
    throw UnimplementedError();
  }

  @override
  Future<void> selectStyle(Uint8List styleData) {
    // TODO: implement selectStyle
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> transfer(Uint8List originData,
      [double contentBlendingRatio = 0.5]) {
    // TODO: implement transfer
    throw UnimplementedError();
  }
}

