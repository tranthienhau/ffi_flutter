import 'dart:typed_data';

class GalleryAsset {

  final String id;

  final Uint8List bytes;

  final String title;

  const GalleryAsset({
    required this.id,
    required this.bytes,
    required this.title,
  });
}
