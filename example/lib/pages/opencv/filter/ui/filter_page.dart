import 'dart:io';
import 'dart:typed_data';

import 'package:ffi_flutter/native_ffi.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/bloc/filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/bloc/normal_filter/normal_filter_bloc.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:ffi_flutter_example/widgets/photo_gallery/app_photo_gallery.dart';
import 'package:ffi_flutter_example/widgets/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transparent_image/transparent_image.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key, required this.imagePath, required this.thumnail})
      : super(key: key);

  final String imagePath;
  final Uint8List thumnail;

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage>
    with AutomaticKeepAliveClientMixin {
  late NormalFilterBloc _filterBloc;

  @override
  void initState() {
    _filterBloc = BlocProvider.of<NormalFilterBloc>(context);
    _filterBloc.add(NormalFilterLoaded(
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
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<NormalFilterBloc, NormalFilterState>(
      bloc: _filterBloc,
      buildWhen: (_, current) => current is! NormalFilterSelectionChange,
      listener: (context, state) {
        final data = BlocProvider.of<FilterBloc>(context).state.data;
        final filterBytes = state.data.filterBytes;
        if (data.filterType == 'Normal') {
          BlocProvider.of<FilterBloc>(context)
              .add(FilterCurrentImageLoaded(filterBytes));
        }

        if (state is NormalFilterUploadSuccess) {
          ToastUtils.done(
            subTitle: 'Upload successfully',
          );
          return;
        }

        if (state is NormalFilterUploadFailure) {
          ToastUtils.error(error: 'Upload failed: ${state.error}');
          return;
        }
      },
      builder: (context, state) {
        // final imageFilterMap = state.data.imageFilterMap;
        final imageFilterDataMap = state.data.imageFilterDataMap;
        if (state is NormalFilterLoading) {
          return const Center(
            child: LoadingIndicator(
              backgroundColor: Colors.white,
            ),
          );
        }

        return Stack(
          children: [
            PreviewPhotoGallery(
              onPageChanged: (int index) {
                _filterBloc.add(NormalFilterImageSelected(index));
              },
              previewBuilder: (BuildContext context, int index) {
                final ImageFilter filter =
                    imageFilterDataMap.keys.elementAt(index);
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
                final ImageFilter filter =
                    imageFilterDataMap.keys.elementAt(index);
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
                final ImageFilter filter =
                    imageFilterDataMap.keys.elementAt(index);
                final original = imageFilterDataMap[filter]?.original;
                if (original != null) {
                  return FileImage(File(original));
                }

                return MemoryImage(kTransparentImage);
              },
              initialPage: 0,
            ),
            if (state is NormalFilterBusy)
              LoadingIndicator(
                backgroundColor: Colors.grey.withOpacity(0.5),
              ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
