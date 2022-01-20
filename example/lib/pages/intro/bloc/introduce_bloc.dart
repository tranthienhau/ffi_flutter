import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

part 'introduce_event.dart';

part 'introduce_state.dart';

class IntroduceBloc extends Bloc<IntroduceEvent, IntroduceState> {
  IntroduceBloc() : super(IntroduceInitial()) {
    on<IntroduceCameraCaptured>(_onCameraCaptured);
  }

  Future<void> _onCameraCaptured(
      IntroduceCameraCaptured event, Emitter<IntroduceState> emit) async {
    emit(IntroduceBusy());
    final receivePort = ReceivePort();

    String fileFullName = event.file.path.split('/').last;
    String fileExtension = fileFullName.split('.').last;
    String fileName = fileFullName.split('.').first;

    await Isolate.spawn(decodeIsolate,
        DecodeParam(File(event.file.path), receivePort.sendPort, 500));

    final image = await receivePort.first as Image;
    final localPath = await _localPath;
    final resizePath = '$localPath/${fileName}_resize.$fileExtension';

    final bytes = encodePng(image);
    final File resizeFile = await File(resizePath).writeAsBytes(bytes);

    final thumbnailPort = ReceivePort();

    await Isolate.spawn(decodeIsolate,
        DecodeParam(File(event.file.path), thumbnailPort.sendPort, 100));

    final thumbnailImage = await thumbnailPort.first as Image;
    final thumbnailBytes = encodePng(thumbnailImage);
    emit(IntroduceCameraCaptureSuccess(
      imagePath: resizeFile.path,
      thumbnail: Uint8List.fromList(thumbnailBytes)
    ));
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }
}

class DecodeParam {
  final File file;
  final SendPort sendPort;
  final int size;

  DecodeParam(this.file, this.sendPort, this.size);
}

void decodeIsolate(DecodeParam param) {
  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  final image = decodeImage(param.file.readAsBytesSync())!;
  // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
  final thumbnail = copyResize(image, width: param.size, height: param.size);
  param.sendPort.send(thumbnail);
}
