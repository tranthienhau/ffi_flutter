part of 'introduce_bloc.dart';

@immutable
abstract class IntroduceState {}

class IntroduceInitial extends IntroduceState {}

class IntroduceCameraCaptureSuccess extends IntroduceState {
  IntroduceCameraCaptureSuccess({
    required this.thumbnail,
    required this.imagePath,
  });

  final Uint8List thumbnail;
  final String imagePath;
}

class IntroduceBusy extends IntroduceState {}
