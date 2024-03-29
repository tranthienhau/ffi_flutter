import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageTransferFacade {
  final _predictionModelFile = 'models/prediction_model.tflite';
  final _transformModelFile = 'models/transfer_model.tflite';

  static const int MODEL_TRANSFER_IMAGE_SIZE = 384;
  static const int MODEL_PREDICTION_IMAGE_SIZE = 256;
  static const int MODEL_PREDICTION_BLEND_SIZE = 256;

  late Interpreter interpreterPrediction;
  late Interpreter interpreterTransform;

  final contentBottleneck = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];

  final styleBottleneckBlended = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];

  final styleBottleneck = [
    [
      [List.generate(100, (index) => 0.0)]
    ]
  ];

  Future<void> loadModel() async {
    final options = InterpreterOptions();
    options.threads = 4;
    options.useNnApiForAndroid = true;
    interpreterPrediction =
        await Interpreter.fromAsset(_predictionModelFile, options: options);
    interpreterTransform =
        await Interpreter.fromAsset(_transformModelFile, options: options);


  }

  Future<Uint8List> loadStyleImage(String styleImagePath) async {
    var styleImageByteData = await rootBundle.load(styleImagePath);
    return styleImageByteData.buffer.asUint8List();
  }

  Future<void> selectStyle(Uint8List styleData) async {
    var styleImage = img.decodeImage(styleData);

    var modelPredictionImage = img.copyResize(styleImage!,
        width: MODEL_PREDICTION_IMAGE_SIZE,
        height: MODEL_PREDICTION_IMAGE_SIZE);

    // content_image 384 384 3
    var modelPredictionInput = _imageToByteListUInt8(
        modelPredictionImage, MODEL_PREDICTION_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    var inputsForPrediction = [modelPredictionInput];

    // style_bottleneck 1 1 100
    var outputsForPrediction = <int, Object>{};

    outputsForPrediction[0] = styleBottleneck;

    // style predict model
    interpreterPrediction.runForMultipleInputs(
        inputsForPrediction, outputsForPrediction);
  }

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

  Future<void> selectImage(Uint8List originData) async {
    originImage = img.decodeImage(originData);
    if (originImage != null) {
      ///Content
      var modelContentImage = img.copyResize(originImage!,
          width: MODEL_PREDICTION_BLEND_SIZE,
          height: MODEL_PREDICTION_BLEND_SIZE);

      var modelContentInput = _imageToByteListUInt8(
          modelContentImage, MODEL_PREDICTION_BLEND_SIZE, 0, 255);

      var inputsForContent = [modelContentInput];

      var outputsForContent = <int, Object>{};

      outputsForContent[0] = contentBottleneck;
      // Calculate style bottleneck of the content image.

      interpreterPrediction.runForMultipleInputs(
          inputsForContent, outputsForContent);

      ///modelTransferImage
      Image modelTransferImage = img.copyResize(originImage!,
          width: MODEL_TRANSFER_IMAGE_SIZE, height: MODEL_TRANSFER_IMAGE_SIZE);

      modelTransferInput = _imageToByteListUInt8(
          modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);
    }
  }


  Future<Uint8List> transfer(Uint8List originData,
      [double contentBlendingRatio = 0.5]) async {
    final modelTransferInput = this.modelTransferInput;
    final originImage = this.originImage;
    if (modelTransferInput == null || originImage == null) {
      throw Exception("Can not transfer data");
    }

    final contentBottleneck = [
      [
        [List.generate(100, (i) => this.contentBottleneck[0][0][0][i])]
      ]
    ];

    for (int i = 0; i < contentBottleneck[0][0][0].length; i++) {
      contentBottleneck[0][0][0][i] =
          contentBottleneck[0][0][0][i] * contentBlendingRatio;
    }

    final styleBottleneck = [
      [
        [List.generate(100, (i) => this.styleBottleneck[0][0][0][i])]
      ]
    ];

    for (int i = 0; i < styleBottleneck[0][0][0].length; i++) {
      styleBottleneck[0][0][0][i] =
          styleBottleneck[0][0][0][i] * (1 - contentBlendingRatio);
    }

    for (int i = 0; i < styleBottleneckBlended[0][0][0].length; i++) {
      styleBottleneckBlended[0][0][0][i] =
          contentBottleneck[0][0][0][i] + styleBottleneck[0][0][0][i];
    }

    // content_image + styleBottleneck
    var inputsForStyleTransfer = [modelTransferInput, styleBottleneckBlended];

    outputsForStyleTransfer[0] = outputImageData;

    interpreterTransform.runForMultipleInputs(
        inputsForStyleTransfer, outputsForStyleTransfer);

    var outputImage =
        _convertArrayToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    var rotateOutputImage = img.copyRotate(outputImage, 90);
    var flipOutputImage = img.flipHorizontal(rotateOutputImage);
    var resultImage = img.copyResize(flipOutputImage,
        width: originImage.width, height: originImage.height);

    return Uint8List.fromList(img.encodeJpg(resultImage));
  }

  img.Image _convertArrayToImage(
      List<List<List<List<double>>>> imageArray, int inputSize) {
    img.Image image = img.Image.rgb(inputSize, inputSize);
    for (var x = 0; x < imageArray[0].length; x++) {
      for (var y = 0; y < imageArray[0][0].length; y++) {
        var r = (imageArray[0][x][y][0] * 255).toInt();
        var g = (imageArray[0][x][y][1] * 255).toInt();
        var b = (imageArray[0][x][y][2] * 255).toInt();
        image.setPixelRgba(x, y, r, g, b);
      }
    }

    return image;
  }

  Uint8List _imageToByteListUInt8(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
