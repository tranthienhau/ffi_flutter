import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi_flutter_example/services/image/image_transfer_service.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TensorflowTransferService implements ImageTransferService {
  final _predictionModelFile = 'models/prediction_model.tflite';
  final _newTransferModelFile = 'models/converted_model_400.tflite';
  final _transformModelFile = 'models/transfer_model.tflite';

  static const int MODEL_TRANSFER_IMAGE_SIZE = 384;
  static const int MODEL_PREDICTION_IMAGE_SIZE = 256;
  static const int MODEL_PREDICTION_BLEND_SIZE = 256;

  static const int MODEL_NEW_STYLE_SIZE = 400;

  late Interpreter interpreterPrediction;
  late Interpreter newInterpreterTransfer;
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

  img.Image? originImage;

  Uint8List? modelTransferInput;

  final outputsForStyleTransfer = <int, Object>{};

  // stylized_image 1 384 384 3
  final outputImageData = [
    List.generate(
      MODEL_TRANSFER_IMAGE_SIZE,
      (index) => List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
        (index) => List.generate(3, (index) => 0.0),
      ),
    ),
  ];

  @override
  Future<void> init() async {

    // newInterpreterTransfer.close();
  }

  Future<void> selectStyle(Uint8List styleData) async {
    ///Load model
    final options = InterpreterOptions();
    options.threads = 2;
    // options.useNnApiForAndroid = true;

    interpreterPrediction =
    await Interpreter.fromAsset(_predictionModelFile, options: options);
    interpreterTransform =
    await Interpreter.fromAsset(_transformModelFile, options: options);


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

    // final newBytes = Uint8List.fromList(modelPredictionInput);

    // style predict model
    interpreterPrediction.runForMultipleInputs(
        inputsForPrediction, outputsForPrediction);
  }



  @override
  Future<Uint8List?> transferNewModel(Uint8List originData) async {
    final options = InterpreterOptions();
    options.threads = 2;
    newInterpreterTransfer =
    await Interpreter.fromAsset(_newTransferModelFile, options: options);
    var originImage = img.decodeImage(originData);

    var modelPredictionImage = img.copyResize(originImage!,
        width: MODEL_NEW_STYLE_SIZE, height: MODEL_NEW_STYLE_SIZE);

    var modelPredictionInput =
        _imageToByteListUInt8(modelPredictionImage, MODEL_NEW_STYLE_SIZE, 0, 1);

    Completer<Uint8List> _resultCompleter = Completer<Uint8List>();

    ///create receiport to get response
    final port = ReceivePort();

    final newOutputImageData = [
      List.generate(
        MODEL_NEW_STYLE_SIZE,
            (index) => List.generate(
          MODEL_NEW_STYLE_SIZE,
              (index) => List.generate(3, (index) => 0.0),
        ),
      ),
    ];

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateTransferNew,
      {
        'modelTransferInput': modelPredictionInput,
        'inputSize': MODEL_NEW_STYLE_SIZE,
        'interpreterTransform': newInterpreterTransfer.address,
        'originImage': originImage,
        'outputImageData': newOutputImageData,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    late Uint8List bytes;
    port.listen((message) {
      ///ensure not call more than one times
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is Uint8List) {
        bytes = message;
        _resultCompleter.complete(message);
      }


    });

    await _resultCompleter.future;
    newInterpreterTransfer.close();
    ///wait for send port return data
    return bytes;
  }


  @override
  Future<Uint8List?> transfer({required Uint8List originData,
    required Uint8List styleData,
    double contentBlendingRatio = 0.5,
  })async {

    ///Load model
    final options = InterpreterOptions();
    options.threads = 2;
    // options.useNnApiForAndroid = true;

    interpreterPrediction =
    await Interpreter.fromAsset(_predictionModelFile, options: options);
    interpreterTransform =
    await Interpreter.fromAsset(_transformModelFile, options: options);


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

    // final newBytes = Uint8List.fromList(modelPredictionInput);

    // style predict model
    interpreterPrediction.runForMultipleInputs(
        inputsForPrediction, outputsForPrediction);


   await loadImage(originData);

    Completer<void> _resultCompleter = Completer<void>();

    ///create receiport to get response
    final port = ReceivePort();

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateTransfer,
      {
        'modelTransferInput': modelTransferInput,
        'styleBottleneck': styleBottleneck,
        'contentBottleneck': contentBottleneck,
        'styleBottleneckBlended': styleBottleneckBlended,
        'contentBlendingRatio': contentBlendingRatio,
        'outputsForStyleTransfer': outputsForStyleTransfer,
        'interpreterTransform': interpreterTransform.address,
        'originImage': originImage,
        'outputImageData': outputImageData,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    Uint8List? bytes;
    port.listen((message) {
      ///ensure not call more than one times
      if (_resultCompleter.isCompleted) {
        return;
      }

      if (message is Uint8List) {
        bytes = message;
        // _resultCompleter.complete();
      }

      if (message == null) {
        _resultCompleter.complete();
      }
    });

    await _resultCompleter.future;
    interpreterPrediction.close();
    interpreterTransform.close();
    ///wait for send port return data
    return bytes;

    // final modelTransferInput = this.modelTransferInput;
    // final originImage = this.originImage;
    // if (modelTransferInput == null || originImage == null) {
    //   throw Exception("Can not transfer data");
    // }
    //
    // final contentBottleneck = [
    //   [
    //     [List.generate(100, (i) => this.contentBottleneck[0][0][0][i])]
    //   ]
    // ];
    //
    // for (int i = 0; i < contentBottleneck[0][0][0].length; i++) {
    //   contentBottleneck[0][0][0][i] =
    //       contentBottleneck[0][0][0][i] * contentBlendingRatio;
    // }
    //
    // final styleBottleneck = [
    //   [
    //     [List.generate(100, (i) => this.styleBottleneck[0][0][0][i])]
    //   ]
    // ];
    //
    // for (int i = 0; i < styleBottleneck[0][0][0].length; i++) {
    //   styleBottleneck[0][0][0][i] =
    //       styleBottleneck[0][0][0][i] * (1 - contentBlendingRatio);
    // }
    //
    // for (int i = 0; i < styleBottleneckBlended[0][0][0].length; i++) {
    //   styleBottleneckBlended[0][0][0][i] =
    //       contentBottleneck[0][0][0][i] + styleBottleneck[0][0][0][i];
    // }
    //
    // // content_image + styleBottleneck
    // var inputsForStyleTransfer = [modelTransferInput, styleBottleneckBlended];
    //
    // outputsForStyleTransfer[0] = outputImageData;
    //
    // interpreterTransform.runForMultipleInputs(
    //     inputsForStyleTransfer, outputsForStyleTransfer);
    //
    // var outputImage =
    //     _convertArrayToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    // var rotateOutputImage = img.copyRotate(outputImage, 90);
    // var flipOutputImage = img.flipHorizontal(rotateOutputImage);
    // var resultImage = img.copyResize(flipOutputImage,
    //     width: originImage.width, height: originImage.height);
    //
    // return Uint8List.fromList(img.encodeJpg(resultImage));
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


  Future<void> loadImage(Uint8List data) async {
    originImage = img.decodeImage(data);
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
      img.Image modelTransferImage = img.copyResize(originImage!,
          width: MODEL_TRANSFER_IMAGE_SIZE, height: MODEL_TRANSFER_IMAGE_SIZE);

      modelTransferInput = _imageToByteListUInt8(
          modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);
    }

  }

  @override
  Future<void> close() async {
    // interpreterPrediction.close();
    // interpreterTransform.close();
    // newInterpreterTransfer.close();
  }
}

void _isolateTransfer(Map<String, dynamic> data) {
  final modelTransferInput = data['modelTransferInput'];
  final styleBottleneck = data['styleBottleneck'];
  final contentBottleneck = data['contentBottleneck'];
  final contentBlendingRatio = data['contentBlendingRatio'];
  final styleBottleneckBlended = data['styleBottleneckBlended'];
  final outputsForStyleTransfer = data['outputsForStyleTransfer'];
  final int interpreterTransformAddress = data['interpreterTransform'];
  final originImage = data['originImage'];
  final outputImageData = data['outputImageData'];
  final SendPort sendPort = data['sendPort'];
  Interpreter interpreterTransform =
      Interpreter.fromAddress(interpreterTransformAddress);

  final newContentBottleneck = [
    [
      [List.generate(100, (i) => contentBottleneck[0][0][0][i])]
    ]
  ];

  for (int i = 0; i < newContentBottleneck[0][0][0].length; i++) {
    newContentBottleneck[0][0][0][i] =
        newContentBottleneck[0][0][0][i] * contentBlendingRatio;
  }

  final newStyleBottleneck = [
    [
      [List.generate(100, (i) => styleBottleneck[0][0][0][i])]
    ]
  ];

  for (int i = 0; i < newStyleBottleneck[0][0][0].length; i++) {
    newStyleBottleneck[0][0][0][i] =
        newStyleBottleneck[0][0][0][i] * (1 - contentBlendingRatio);
  }

  for (int i = 0; i < styleBottleneckBlended[0][0][0].length; i++) {
    styleBottleneckBlended[0][0][0][i] =
        newContentBottleneck[0][0][0][i] + newStyleBottleneck[0][0][0][i];
  }

  // content_image + styleBottleneck
  final inputsForStyleTransfer = <Object>[
    modelTransferInput,
    styleBottleneckBlended
  ];

  outputsForStyleTransfer[0] = outputImageData;

  interpreterTransform.runForMultipleInputs(
      inputsForStyleTransfer, outputsForStyleTransfer);

  var outputImage = _convertArrayToImage(outputImageData, 384);
  var rotateOutputImage = img.copyRotate(outputImage, 90);
  var flipOutputImage = img.flipHorizontal(rotateOutputImage);
  var resultImage = img.copyResize(flipOutputImage,
      width: originImage.width, height: originImage.height);

  sendPort.send(Uint8List.fromList(img.encodeJpg(resultImage)));
}

void _isolateTransferNew(Map<String, dynamic> data) {
  final modelTransferInput = data['modelTransferInput'];

  final int interpreterTransformAddress = data['interpreterTransform'];

  final originImage = data['originImage'];

  final inputSize = data['inputSize'];

  final outputImageData = data['outputImageData'];

  final SendPort sendPort = data['sendPort'];

  Interpreter interpreterTransform =
      Interpreter.fromAddress(interpreterTransformAddress);

  final outputsForPrediction = <int, Object>{};

  outputsForPrediction[0] = outputImageData;

  final inputsForPrediction = <Object>[modelTransferInput];

  // style predict model
  interpreterTransform.runForMultipleInputs(
      inputsForPrediction, outputsForPrediction);

  final outputImage = _convertArrayToImageNew(outputImageData, inputSize);

  final rotateOutputImage = img.copyRotate(outputImage, 90);

  final flipOutputImage = img.flipHorizontal(rotateOutputImage);

  final resultImage = img.copyResize(
    flipOutputImage,
    width: originImage.width,
    height: originImage.height,
  );

  final imageBytes = img.encodeJpg(resultImage);

  sendPort.send(imageBytes);
}

img.Image _convertArrayToImageNew(
    List<List<List<List<double>>>> imageArray, int inputSize) {
  img.Image image = img.Image.rgb(inputSize, inputSize);
  for (var x = 0; x < imageArray[0].length; x++) {
    for (var y = 0; y < imageArray[0][0].length; y++) {
      var r = (imageArray[0][x][y][0]).toInt();
      var g = (imageArray[0][x][y][1]).toInt();
      var b = (imageArray[0][x][y][2]).toInt();
      image.setPixelRgba(x, y, r, g, b);
    }
  }

  return image;
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
