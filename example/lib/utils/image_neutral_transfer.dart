import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageNeutralTransfer {
  final _predictionModelFile = 'models/prediction_model.tflite';
  final _transformModelFile = 'models/transfer_model.tflite';

  static const int MODEL_TRANSFER_IMAGE_SIZE = 384;
  static const int MODEL_PREDICTION_IMAGE_SIZE = 256;
  static const int MODEL_PREDICTION_BLEND_SIZE = 256;

  late Interpreter _interpreterPrediction;
  late Interpreter _interpreterTransform;

  Interpreter get interpreterPrediction => _interpreterPrediction;

  Interpreter get interpreterTransform => _interpreterTransform;

  late List<List<List<List<double>>>> contentBottleneck = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];

  late List<List<List<List<double>>>>  styleBottleneckBlended = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];

  late List<List<List<List<double>>>>  styleBottleneck = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];


  Image? originImage;
  Uint8List? modelTransferInput;

  final outputsForStyleTransfer = <int, Object>{};

  // stylized_image 1 384 384 3
  late List<List<List<List<double>>>> outputImageData = [
    List.generate(
      MODEL_TRANSFER_IMAGE_SIZE,
          (index) => List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
            (index) => List.generate(3, (index) => 0.0),
      ),
    ),
  ];

  Future<void> loadModel({
    Interpreter? interpreterPrediction,
    Interpreter? interpreterTransform,
    List<List<List<List<double>>>>? contentBottleneck,
    List<List<List<List<double>>>>? styleBottleneck,
    List<List<List<List<double>>>>? styleBottleneckBlended,
  }) async {
    final options = InterpreterOptions();
    options.threads = 4;
    options.useNnApiForAndroid = true;
    _interpreterPrediction = interpreterPrediction ??
        await Interpreter.fromAsset(_predictionModelFile, options: options);
    _interpreterTransform = interpreterTransform ??
        await Interpreter.fromAsset(_transformModelFile, options: options);
  }

  /// Loads interpreter from asset
// void loadModel({Interpreter? interpreter}) async {
//   try {
//     _interpreter = interpreter ??
//         await Interpreter.fromAsset(
//           MODEL_FILE_NAME,
//           options: InterpreterOptions()..threads = 4,
//         );
//
//     var outputTensors = _interpreter.getOutputTensors();
//     _outputShapes = [];
//     _outputTypes = [];
//     outputTensors.forEach((tensor) {
//       _outputShapes.add(tensor.shape);
//       _outputTypes.add(tensor.type);
//     });
//   } catch (e) {
//     print("Error while creating interpreter: $e");
//   }
// }
}
