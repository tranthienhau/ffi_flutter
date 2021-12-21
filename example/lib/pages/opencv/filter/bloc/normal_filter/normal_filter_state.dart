part of 'normal_filter_bloc.dart';

class NormalFilterData {
  final String thumnail;
  final String? original;

  const NormalFilterData({
    required this.thumnail,
    this.original,
  });

  NormalFilterData copyWith({
    String? thumnail,
    String? original,
  }) {
    return NormalFilterData(
      thumnail: thumnail ?? this.thumnail,
      original: original ?? this.original,
    );
  }
}

class NormalFilterBlocData {
  final Uint8List? filterBytes;

  // final Map<ImageFilter, String?> imageFilterMap;
  final Map<ImageFilter, NormalFilterData?> imageFilterDataMap;
  final int selectionIndex;

  const NormalFilterBlocData({
    this.filterBytes,
    required this.imageFilterDataMap,
    required this.selectionIndex,
  });

  NormalFilterBlocData setFilterNull() {
    return NormalFilterBlocData(
      filterBytes: null,
      imageFilterDataMap: imageFilterDataMap,
      selectionIndex: selectionIndex,
    );
  }

  NormalFilterBlocData copyWith({
    Uint8List? filterBytes,
    Map<ImageFilter, NormalFilterData?>? imageFilterDataMap,
    int? selectionIndex,
  }) {
    return NormalFilterBlocData(
      filterBytes: filterBytes ?? this.filterBytes,
      imageFilterDataMap: imageFilterDataMap ?? this.imageFilterDataMap,
      selectionIndex: selectionIndex ?? this.selectionIndex,
    );
  }
}

@immutable
abstract class NormalFilterState {
  const NormalFilterState(this.data);

  ///Data filter contain key: type of filter and value:imagePath
  final NormalFilterBlocData data;
}

class NormalFilterLoading extends NormalFilterState {
  const NormalFilterLoading(NormalFilterBlocData data) : super(data);
}

class NormalFilterSelectionChange extends NormalFilterState {
  const NormalFilterSelectionChange(NormalFilterBlocData data) : super(data);
}

class NormalFilterUploadSuccess extends NormalFilterState {
  const NormalFilterUploadSuccess(NormalFilterBlocData data) : super(data);
}

///State call [FilterApplied] and complete apply filter
class NormalFilterLoadSuccess extends NormalFilterState {
  const NormalFilterLoadSuccess(NormalFilterBlocData data) : super(data);
}

class NormalFilterUpdateSuccess extends NormalFilterState {
  const NormalFilterUpdateSuccess(NormalFilterBlocData data) : super(data);
}

class NormalFilterBusy extends NormalFilterState {
  const NormalFilterBusy(NormalFilterBlocData data) : super(data);
}

///State call [FilterApplied] and raise exception
class NormalFilterUploadFailure extends NormalFilterState {
  const NormalFilterUploadFailure(
      {required NormalFilterBlocData data, required this.error})
      : super(data);

  final String error;
}
