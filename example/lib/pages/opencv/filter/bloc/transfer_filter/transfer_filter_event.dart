part of 'transfer_filter_bloc.dart';

@immutable
abstract class TransferFilterEvent {}

class TransferFilterLoaded extends TransferFilterEvent {
  TransferFilterLoaded(this.imagePath);

  final String imagePath;
}

class TransferFilterImageStyleLoaded extends TransferFilterEvent {
  TransferFilterImageStyleLoaded(this.stylePath);

  final String stylePath;
}

class TransferFilterBlendChanged extends TransferFilterEvent {
  TransferFilterBlendChanged(this.blend);

  final int blend;
}