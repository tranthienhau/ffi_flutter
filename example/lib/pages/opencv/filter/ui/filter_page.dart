import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:native_add_example/pages/opencv/filter/bloc/filter_bloc.dart';
import 'package:native_add_example/widgets/loading_indicator.dart';
import 'package:native_add_example/widgets/photo_gallery/app_photo_gallery.dart';
import 'package:native_add_example/widgets/toast_utils.dart';
import 'package:native_ffi/native_ffi.dart';
import 'package:transparent_image/transparent_image.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key, required this.imagePath, required this.thumnail})
      : super(key: key);

  final String imagePath;
  final Uint8List thumnail;

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final FilterBloc _filterBloc = FilterBloc();

  @override
  void initState() {
    _filterBloc.add(FilterLoaded(
      imagePath: widget.imagePath,
      thumnail: widget.thumnail,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _filterBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Image filter page'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (String result) {
            _filterBloc.add(FilterUpload());
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Upload',
              child: Text('Upload selection image'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBody() {
    return BlocConsumer<FilterBloc, FilterState>(
      bloc: _filterBloc,
      listener: (context, state) {
        if (state is FilterUploadSuccess) {
          ToastUtils.done(
            subTitle: 'Upload successfully',
          );
          return;
        }

        if (state is FilterUploadFailure) {
          ToastUtils.error(error: 'Upload failed: ${state.error}');
          return;
        }
      },
      builder: (context, state) {
        // final imageFilterMap = state.data.imageFilterMap;
        final imageFilterDataMap = state.data.imageFilterDataMap;
        if (state is FilterLoading) {
          return const Center(
            child: LoadingIndicator(
              backgroundColor: Colors.white,
            ),
          );
        }

        return Stack(
          children: [
            PreviewPhotoGallery(
              onPageChanged: (int index) {},
              previewBuilder: (BuildContext context, int index) {
                final ImageFilter filter = imageFilterDataMap.keys.elementAt(index);
                final filterData = imageFilterDataMap[filter];
                if (filterData != null) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                            image: DecorationImage(
                              image: FileImage(File(filterData.thumnail)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            color: Colors.black.withAlpha(150),
                          ),
                        )
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const SizedBox(
                        width: 100,
                        height: 100,
                        child: Center(
                          child: LoadingIndicator(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        color: Colors.black.withAlpha(150),
                      ),
                    ),
                  ],
                );
              },
              itemCount: imageFilterDataMap.length,
              selectedPreviewBuilder: (BuildContext context, int index) {
                final ImageFilter filter = imageFilterDataMap.keys.elementAt(index);
                final filterData = imageFilterDataMap[filter];
                if (filterData != null) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                      image: DecorationImage(
                        image: FileImage(File(filterData.thumnail)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: LoadingIndicator(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
              photoBuilder: (BuildContext context, int index) {
                final ImageFilter filter = imageFilterDataMap.keys.elementAt(index);
                final original = imageFilterDataMap[filter]?.original;
                if (original != null) {
                  return FileImage(File(original));
                }

                return MemoryImage(kTransparentImage);
              },
              initialPage: 0,
            ),
            if (state is FilterBusy)
              LoadingIndicator(
                backgroundColor: Colors.grey.withOpacity(0.5),
              ),
          ],
        );
      },
    );
  }
}
