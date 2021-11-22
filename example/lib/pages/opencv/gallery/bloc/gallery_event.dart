part of 'gallery_bloc.dart';

@immutable
abstract class GalleryEvent {}

class GalleryLoaded extends GalleryEvent {}

class GalleryGalleryLoadMore extends GalleryEvent {
  final int page;

  GalleryGalleryLoadMore(this.page);
}

class GalleryPageChanged extends GalleryEvent {
  final int page;

  GalleryPageChanged(this.page);
}

class GalleryAssetLoaded extends GalleryEvent {
  final GalleryAsset asset;
  final String galleryName;

  GalleryAssetLoaded({required this.asset, required this.galleryName});
}
