part of 'filter_bloc.dart';

class FilterData {
  final String thumnail;
  final String? original;

  const FilterData({
    required this.thumnail,
    this.original,
  });

  FilterData copyWith({
    String? thumnail,
    String? original,
  }) {
    return FilterData(
      thumnail: thumnail ?? this.thumnail,
      original: original ?? this.original,
    );
  }
}

class FilterBlocData {
  const FilterBlocData({
    // required this.imageFilterMap,
    required this.selectionIndex,
    required this.imageFilterDataMap,
  });

  // final Map<ImageFilter, String?> imageFilterMap;
  final Map<ImageFilter, FilterData?> imageFilterDataMap;
  final int selectionIndex;

  FilterBlocData copyWith({
    // Map<ImageFilter, String?>? imageFilterMap,
    Map<ImageFilter, FilterData?>? imageFilterDataMap,
    int? selectionIndex,
  }) {
    return FilterBlocData(
      imageFilterDataMap: imageFilterDataMap ?? this.imageFilterDataMap,
      // imageFilterMap: imageFilterMap ?? this.imageFilterMap,
      selectionIndex: selectionIndex ?? this.selectionIndex,
    );
  }
}

@immutable
abstract class FilterState {
  const FilterState(this.data);

  ///Data filter contain key: type of filter and value:imagePath
  final FilterBlocData data;
}

class FilterLoading extends FilterState {
  const FilterLoading(FilterBlocData data) : super(data);
}

class FilterSelectionChange extends FilterState {
  const FilterSelectionChange(FilterBlocData data) : super(data);
}

class FilterUploadSuccess extends FilterState {
  const FilterUploadSuccess(FilterBlocData data) : super(data);
}

///State call [FilterApplied] and complete apply filter
class FilterLoadSuccess extends FilterState {
  const FilterLoadSuccess(FilterBlocData data) : super(data);
}

class FilterUpdateSuccess extends FilterState {
  const FilterUpdateSuccess(FilterBlocData data) : super(data);
}

class FilterBusy extends FilterState {
  const FilterBusy(FilterBlocData data) : super(data);
}

///State call [FilterApplied] and raise exception
class FilterUploadFailure extends FilterState {
  const FilterUploadFailure({required FilterBlocData data, required this.error})
      : super(data);

  final String error;
}
