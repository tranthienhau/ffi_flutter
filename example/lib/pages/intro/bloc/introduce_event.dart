part of 'introduce_bloc.dart';

@immutable
abstract class IntroduceEvent {}

class IntroduceCameraCaptured extends IntroduceEvent {
  IntroduceCameraCaptured(this.file);

  final XFile file;
}
