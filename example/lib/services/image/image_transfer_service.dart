import 'dart:typed_data';

abstract class ImageTransferService {
  Future<void> init();
  Future<void> loadImage(Uint8List data);
  Future<void> selectStyle(Uint8List styleData);

  Future<Uint8List?> transfer(Uint8List originData, [double contentBlendingRatio = 0.5]);
}
