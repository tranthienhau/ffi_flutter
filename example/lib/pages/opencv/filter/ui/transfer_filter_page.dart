import 'package:ffi_flutter_example/pages/opencv/filter/bloc/filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/bloc/transfer_filter/transfer_filter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferFilterPage extends StatefulWidget {
  const TransferFilterPage({Key? key, required this.imagePath})
      : super(key: key);

  final String imagePath;

  @override
  _TransferFilterPageState createState() => _TransferFilterPageState();
}

class _TransferFilterPageState extends State<TransferFilterPage>
    with AutomaticKeepAliveClientMixin {
  int selectStyle = -1;
  late final TransferFilterBloc _imageBloc;

  @override
  void initState() {
    _imageBloc = BlocProvider.of<TransferFilterBloc>(context);
    _imageBloc.add(TransferFilterLoaded(widget.imagePath));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xff020304),
      body: SafeArea(
        child: BlocConsumer<TransferFilterBloc, TransferFilterState>(
          listener: (context, state) {
            final transferImage = state.data?.transferImage;
            final data =   BlocProvider.of<FilterBloc>(context).state.data;
            if(data.filterType == 'Cartoon'){
              BlocProvider.of<FilterBloc>(context)
                  .add(FilterCurrentImageLoaded(transferImage));
            }

          },
          builder: (context, state) {
            Widget child = const SizedBox();

            final data = state.data;
            if (data != null) {
              final originImage = data.originImage;
              final transferImage = data.transferImage;
              child = Image.memory(
                originImage,
                gaplessPlayback: true,
              );

              if (transferImage != null) {
                child = Image.memory(
                  transferImage,
                  gaplessPlayback: true,
                );
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: child,
                      ),
                      const SizedBox(height: 20),
                      _buildSlider(data.blend),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            String stylePath = 'assets/images/style$index.jpg';
                            if (index == 26) {
                              stylePath = 'assets/images/style$index.jpeg';
                            }
                            return GestureDetector(
                              onTap: () {
                                _imageBloc.add(
                                    TransferFilterImageStyleLoaded(stylePath));
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  border: selectStyle == index
                                      ? Border.all(
                                          color: Colors.yellow,
                                          width: 2,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(stylePath),
                                ),
                              ),
                            );
                          },
                          itemCount: 27,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  Center(
                    child: state is TransferFilterBusy
                        ? _loadingWidget()
                        : Container(),
                  )
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSlider(double value) {
    return Slider(
      value: value,
      min: 0,
      max: 10,
      divisions: 10,
      label: value.toString(),
      onChanged: (double value) {
        _imageBloc.add(TransferFilterBlendChanged(value.toInt()));
      },
    );
  }

  Widget _loadingWidget() {
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Waiting for complete...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
// final TransferFilterBloc _filterBloc = TransferFilterBloc();
//
// @override
// void initState() {
//   _filterBloc.add(TransferFilterLoaded(widget.imagePath));
//   super.initState();
// }
//
// @override
// void dispose() {
//   _filterBloc.close();
//   super.dispose();
// }
//
// @override
// Widget build(BuildContext context) {
//   return Container();
// }
//
// Widget _buildBody() {
//   return BlocConsumer<TransferFilterBloc, TransferFilterState>(
//     bloc: _filterBloc,
//
//     listener: (context, state) {
//       // if (state is TransferFilterUploadSuccess) {
//       //   ToastUtils.done(
//       //     subTitle: 'Upload successfully',
//       //   );
//       //   return;
//       // }
//       //
//       // if (state is TransferFilterUploadFailure) {
//       //   ToastUtils.error(error: 'Upload failed: ${state.error}');
//       //   return;
//       // }
//     },
//     builder: (context, state) {
//       // final imageFilterMap = state.data.imageFilterMap;
//       final imageFilterDataMap = state.data.imageFilterDataMap;
//       if (state is TransferFilterLoading) {
//         return const Center(
//           child: LoadingIndicator(
//             backgroundColor: Colors.white,
//           ),
//         );
//       }
//
//       return Stack(
//         children: [
//           PreviewPhotoGallery(
//             onPageChanged: (int index) {},
//             previewBuilder: (BuildContext context, int index) {
//               final ImageFilter filter =
//                   imageFilterDataMap.keys.elementAt(index);
//               final filterData = imageFilterDataMap[filter];
//               if (filterData != null) {
//                 return Container(
//                   margin:
//                       const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//                   child: Stack(
//                     children: [
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           borderRadius: const BorderRadius.all(
//                             Radius.circular(8),
//                           ),
//                           image: DecorationImage(
//                             image: FileImage(File(filterData.thumnail)),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Container(
//                         width: 100,
//                         height: 100,
//                         decoration: BoxDecoration(
//                           borderRadius:
//                               const BorderRadius.all(Radius.circular(8)),
//                           color: Colors.black.withAlpha(150),
//                         ),
//                       )
//                     ],
//                   ),
//                 );
//               }
//
//               return Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: const SizedBox(
//                       width: 100,
//                       height: 100,
//                       child: Center(
//                         child: LoadingIndicator(
//                           backgroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       borderRadius:
//                           const BorderRadius.all(Radius.circular(8)),
//                       color: Colors.black.withAlpha(150),
//                     ),
//                   ),
//                 ],
//               );
//             },
//             itemCount: imageFilterDataMap.length,
//             selectedPreviewBuilder: (BuildContext context, int index) {
//               final ImageFilter filter =
//                   imageFilterDataMap.keys.elementAt(index);
//               final filterData = imageFilterDataMap[filter];
//               if (filterData != null) {
//                 return Container(
//                   margin:
//                       const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.all(
//                       Radius.circular(8),
//                     ),
//                     image: DecorationImage(
//                       image: FileImage(File(filterData.thumnail)),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 );
//               }
//
//               return ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: const SizedBox(
//                   width: 100,
//                   height: 100,
//                   child: Center(
//                     child: LoadingIndicator(
//                       backgroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               );
//             },
//             photoBuilder: (BuildContext context, int index) {
//               final ImageFilter filter =
//                   imageFilterDataMap.keys.elementAt(index);
//               final original = imageFilterDataMap[filter]?.original;
//               if (original != null) {
//                 return FileImage(File(original));
//               }
//
//               return MemoryImage(kTransparentImage);
//             },
//             initialPage: 0,
//           ),
//           if (state is TransferFilterBusy)
//             LoadingIndicator(
//               backgroundColor: Colors.grey.withOpacity(0.5),
//             ),
//         ],
//       );
//     },
//   );
// }
}
