part of 'gallery_bloc.dart';

class GalleryBlocData {
   GalleryBlocData({
    required this.mapGalleryCategory,
    required this.currentPage,
  });

  GalleryBlocData copyWith({
    Map<String, List<GalleryAsset>?>? mapGalleryCategory,
    int? currentPage,
  }) {
    return GalleryBlocData(
      mapGalleryCategory: mapGalleryCategory ?? this.mapGalleryCategory,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  final Map<String, List<GalleryAsset>?> mapGalleryCategory;
  final int currentPage;
}

@immutable
abstract class GalleryState {
  const GalleryState(this.data);

  final GalleryBlocData data;
}

class GalleryLoadSuccess extends GalleryState {
  const GalleryLoadSuccess(GalleryBlocData data) : super(data);
}

class GalleryLoading extends GalleryState {
  const GalleryLoading(GalleryBlocData data) : super(data);
}

class GalleryAssetLoadSuccess extends GalleryState {
  const GalleryAssetLoadSuccess({
    required GalleryBlocData data,
    required this.file,
    required this.thumnail,
  }) : super(data);

  final File file;
  final Uint8List thumnail;
}

class GalleryAssetLoadFailure extends GalleryState {
  const GalleryAssetLoadFailure(
      {required GalleryBlocData data, required this.error})
      : super(data);
  final String error;
}

class GalleryLoadFailure extends GalleryState {
  const GalleryLoadFailure({required GalleryBlocData data, required this.error})
      : super(data);

  final String error;
}
