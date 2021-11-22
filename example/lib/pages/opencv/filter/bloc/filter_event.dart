part of 'filter_bloc.dart';

@immutable
abstract class FilterEvent {}

///Load all filter of [imagePath]
class FilterLoaded extends FilterEvent {
  FilterLoaded({required this.imagePath, required this.thumnail});

  final String imagePath;
  final Uint8List thumnail;
}

class FilterImageSelected extends FilterEvent {
  FilterImageSelected(this.index);

  final int index;
}

class FilterUpload extends FilterEvent {}

class FilterThumnailUpdated extends FilterEvent {
  final String thumnail;
  final ImageFilter filter;

  FilterThumnailUpdated({required this.thumnail , required this.filter});
}

class FilterOriginalUpdated extends FilterEvent {
  final String original;
  final ImageFilter filter;

  FilterOriginalUpdated({required this.original , required this.filter});
}


class FilterUpdated extends FilterEvent {
  FilterUpdated(this.filterData);

  final ImageFilterData filterData;
}
