part of 'memory_filter_bloc.dart';

@immutable
abstract class MemoryFilterEvent {}

class MemoryFilterLoaded extends MemoryFilterEvent {
  final String imagePath;
  final Uint8List thumnail;

  MemoryFilterLoaded({required this.imagePath, required this.thumnail});
}

class MemoryFilterThumbnailLoaded extends MemoryFilterEvent {
  final NativeImageFilterData data;

  MemoryFilterThumbnailLoaded(this.data);
}

class MemoryFilterCategoryChanged extends MemoryFilterEvent {
  final String category;

  MemoryFilterCategoryChanged(this.category);
}

class MemoryFilterColorFiltered extends MemoryFilterEvent {
  final ImageFilter filter;

  MemoryFilterColorFiltered(this.filter);
}


class MemoryFilterTransferFiltered extends MemoryFilterEvent {
  final String stylePath;

  MemoryFilterTransferFiltered(this.stylePath);
}

class MemoryFilterTransferFilterCompleted extends MemoryFilterEvent {
  final Uint8List bytes;
  final int selectedIndex;

  MemoryFilterTransferFilterCompleted(this.bytes, this.selectedIndex);
}

class MemoryFilterImageSaved extends MemoryFilterEvent {}