import 'dart:typed_data';

abstract class ImageTransferService {
  Future<void> init();
  // Future<void> loadImage(Uint8List data);
  // Future<void> selectStyle(Uint8List styleData);

  Future<Uint8List?> transfer({required Uint8List originData,
    required Uint8List styleData,
    double contentBlendingRatio = 0.5,
  });

  Future<Uint8List?> transferNewModel(Uint8List originData);

  Future<void> close();
}
