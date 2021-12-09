part of 'normal_filter_bloc.dart';

@immutable
abstract class NormalFilterEvent {}

///Load all filter of [imagePath]
class NormalFilterLoaded extends NormalFilterEvent {
  NormalFilterLoaded({required this.imagePath, required this.thumnail});

  final String imagePath;
  final Uint8List thumnail;
}

class NormalFilterImageSelected extends NormalFilterEvent {
  NormalFilterImageSelected(this.index);

  final int index;
}

class NormalFilterUpload extends NormalFilterEvent {}

class NormalFilterThumnailUpdated extends NormalFilterEvent {
  final String thumnail;
  final ImageFilter filter;

  NormalFilterThumnailUpdated({required this.thumnail, required this.filter});
}

class NormalFilterOriginalUpdated extends NormalFilterEvent {
  final String original;
  final ImageFilter filter;

  NormalFilterOriginalUpdated({required this.original, required this.filter});
}

class FilterUpdated extends NormalFilterEvent {
  FilterUpdated(this.filterData);

  final ImageFilterData filterData;
}
