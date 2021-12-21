part of 'filter_bloc.dart';

@immutable
abstract class FilterEvent {}

class FilterPageChanged extends FilterEvent {
  final String pageCategory;

  FilterPageChanged(this.pageCategory);
}

class FilterCurrentImageLoaded extends FilterEvent {
  final Uint8List? filterImage;

  FilterCurrentImageLoaded(this.filterImage);
}

class FilterCurrentImageSaved extends FilterEvent {}
