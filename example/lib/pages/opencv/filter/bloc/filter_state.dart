part of 'filter_bloc.dart';

class FilterData {
  const FilterData({
    required this.filterType,
    required this.filterCategories,
     this.filterImage,
  });

  FilterData copyWith({
    String? filterType,
    List<String>? filterCategories,
    Uint8List? filterImage,
  }) {
    return FilterData(
      filterType: filterType ?? this.filterType,
      filterImage: filterImage ?? this.filterImage,
      filterCategories: filterCategories ?? this.filterCategories,
    );
  }

  final String filterType;
  final Uint8List? filterImage;
  final List<String> filterCategories;
}

@immutable
abstract class FilterState {
  const FilterState(this.data);

  final FilterData data;
}

class FilterLoading extends FilterState {
  const FilterLoading(FilterData data) : super(data);
}

class FilterLoadSuccess extends FilterState {
  const FilterLoadSuccess(FilterData data) : super(data);
}

class FilterBusy extends FilterState {
  const FilterBusy(FilterData data) : super(data);
}

class FilterSaveSuccess extends FilterState {
  const FilterSaveSuccess(FilterData data) : super(data);
}

class FilterSaveFailure extends FilterState {
  const FilterSaveFailure({required this.error, required FilterData data}) : super(data);
  final String error;
}