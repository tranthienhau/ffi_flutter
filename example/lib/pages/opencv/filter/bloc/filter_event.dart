part of 'filter_bloc.dart';

@immutable
abstract class FilterEvent {}

///Load all filter of [imagePath]
class FilterLoaded extends FilterEvent {
  FilterLoaded(this.imagePath);

  final String imagePath;
}

class FilterImageSelected extends FilterEvent {
  FilterImageSelected(this.index);

  final int index;
}

class FilterUpload extends FilterEvent {}

class FilterUpdated extends FilterEvent {
  FilterUpdated(this.filterData);

  final ImageFilterData filterData;
}
