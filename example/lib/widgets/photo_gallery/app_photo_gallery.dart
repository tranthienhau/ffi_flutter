//@dart=2.12

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';

import '../loading_indicator.dart';

typedef ImageProviderBuilder = ImageProvider Function(
    BuildContext context, int index);

class PreviewPhotoGallery extends StatefulWidget {
  const PreviewPhotoGallery({
    Key? key,
    required this.itemCount,
    required this.previewBuilder,
    required this.selectedPreviewBuilder,
    required this.photoBuilder,
    this.initialPage = 0, this.onPageChanged,
  }) : super(key: key);

  final int itemCount;
  final Widget Function(BuildContext context, int index) previewBuilder;
  final Widget Function(BuildContext context, int index) selectedPreviewBuilder;
  final ImageProviderBuilder photoBuilder;
  final int initialPage;
  final PhotoViewGalleryPageChangedCallback? onPageChanged;
  @override
  _PreviewPhotoGalleryState createState() => _PreviewPhotoGalleryState();
}

class _PreviewPhotoGalleryState extends State<PreviewPhotoGallery> {
  ///Dùng để ẩn khi đang thực hiện thao tác trên hình và hiện thị khi kết thúc
  final BehaviorSubject<bool> _behaviorVisible = BehaviorSubject<bool>();

  @override
  void initState() {
    _behaviorVisible.add(true);
    super.initState();
  }

  @override
  void dispose() {
    _behaviorVisible.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: PhotoPreviewGallery.builder(
        initialPage: widget.initialPage,
        loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
          return const Center(child: LoadingIndicator());
        },
        onPageChanged: widget.onPageChanged,
        animationDuration: const Duration(milliseconds: 200),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: widget.photoBuilder(context, index),
            minScale: PhotoViewComputedScale.contained,
            initialScale: PhotoViewComputedScale.contained,
            onScaleStart:
                (BuildContext context, ScaleStartDetails details, _) {
              _behaviorVisible.add(false);
            },
            onScaleEnd: (BuildContext context, ScaleEndDetails details, _) {
              _behaviorVisible.add(true);
            },
          );
        },
        previewSize: const Size.fromHeight(100),
        previewPadding: EdgeInsets.only(
            left: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
        previewOptions: List<PhotoPreviewOptions>.generate(
          widget.itemCount,
              (index) => PhotoPreviewOptions.customBuilder(
            selectedBuilder: widget.selectedPreviewBuilder,
            builder: widget.previewBuilder,
          ),
        ),
        itemCount: widget.itemCount,
      ),
    );
  }
}
