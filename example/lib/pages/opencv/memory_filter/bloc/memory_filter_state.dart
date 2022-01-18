part of 'memory_filter_bloc.dart';

class TransferFilter {
  final String thumbnailPath;
  final Uint8List? originFilter;

  const TransferFilter({
    required this.thumbnailPath,
    this.originFilter,
  });

  TransferFilter copyWith({
    String? thumbnailPath,
    Uint8List? originFilter,
  }) {
    return TransferFilter(
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originFilter: originFilter ?? this.originFilter,
    );
  }
}

class ColorFilter {
  final Uint8List? thumbnailFilter;
  final Uint8List? originFilter;
  final ImageFilter filter;

  const ColorFilter({
    this.thumbnailFilter,
    required this.filter,
    this.originFilter,
  });

  ColorFilter copyWith({
    Uint8List? thumbnailFilter,
    Uint8List? originFilter,
    ImageFilter? filter,
  }) {
    return ColorFilter(
      thumbnailFilter: thumbnailFilter ?? this.thumbnailFilter,
      originFilter: originFilter ?? this.originFilter,
      filter: filter ?? this.filter,
    );
  }
}

class TransferFilterListData {
  final int selectedIndex;
  final List<TransferFilter> transferFilterList;

  const TransferFilterListData({
    required this.selectedIndex,
    required this.transferFilterList,
  });

  TransferFilterListData copyWith({
    int? selectedIndex,
    List<TransferFilter>? transferFilterList,
  }) {
    return TransferFilterListData(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      transferFilterList: transferFilterList ?? this.transferFilterList,
    );
  }
}

class ColorFilterListData {
  final int selectedIndex;
  final List<ColorFilter> colorFilterList;

  ColorFilterListData copyWith({
    int? selectedIndex,
    List<ColorFilter>? colorFilterList,
  }) {
    return ColorFilterListData(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      colorFilterList: colorFilterList ?? this.colorFilterList,
    );
  }

  const ColorFilterListData({
    required this.selectedIndex,
    required this.colorFilterList,
  });
}

class MemoryFilterData {
  final Uint8List? transferImage;
  final Uint8List originImage;
  final TransferFilterListData transferFilterData;
  final ColorFilterListData colorFilterData;

  final String category;
  final List<String> categories;

  const MemoryFilterData({
    this.transferImage,
    required this.categories,
    required this.category,
    required this.originImage,
    required this.transferFilterData,
    required this.colorFilterData,
  });

  MemoryFilterData copyWith({
    Uint8List? transferImage,
    Uint8List? originImage,
    TransferFilterListData? transferFilterData,
    ColorFilterListData? colorFilterData,
    String? category,
    List<String>? categories,
  }) {
    return MemoryFilterData(
      category: category ?? this.category,
      categories: categories ?? this.categories,
      transferImage: transferImage ?? this.transferImage,
      originImage: originImage ?? this.originImage,
      transferFilterData: transferFilterData ?? this.transferFilterData,
      colorFilterData: colorFilterData ?? this.colorFilterData,
    );
  }
}

@immutable
abstract class MemoryFilterState {
  const MemoryFilterState([this.data]);

  final MemoryFilterData? data;
}

class MemoryFilterLoading extends MemoryFilterState {
  // const MemoryFilterLoading(MemoryFilterData data):super(data);

}

class MemoryFilterLoadSuccess extends MemoryFilterState {
  const MemoryFilterLoadSuccess(MemoryFilterData data) : super(data);
}

class MemoryFilterUpdateSuccess extends MemoryFilterState {
  const MemoryFilterUpdateSuccess(MemoryFilterData data) : super(data);
}

class MemoryFilterTransferFilterBusy extends MemoryFilterState {
  const MemoryFilterTransferFilterBusy(MemoryFilterData data) : super(data);
}

class MemoryFilterBusy extends MemoryFilterState {
  const MemoryFilterBusy(MemoryFilterData data) : super(data);
}

class MemoryFilterImageSaveSuccess extends MemoryFilterState {
  const MemoryFilterImageSaveSuccess(MemoryFilterData data) : super(data);
}

class MemoryFilterImageShareSuccess extends MemoryFilterState {
  const MemoryFilterImageShareSuccess(MemoryFilterData data) : super(data);
}


class MemoryFilterImageSaveFailure extends MemoryFilterState {
  const MemoryFilterImageSaveFailure(MemoryFilterData data, this.error) : super(data);

  final String error;
}
