import 'package:ffi_flutter_example/pages/opencv/memory_filter/bloc/memory_filter_bloc.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ColorFilterTab extends StatelessWidget {
  const ColorFilterTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    return BlocBuilder<MemoryFilterBloc, MemoryFilterState>(
      builder: (context, state) {
        Widget child = const SizedBox();

        final data = state.data;
        if (data != null) {
          final colorFilterData = data.colorFilterData;
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final imageBytes = colorFilterData
                            .colorFilterList[index].thumbnailFilter;

                        if (imageBytes == null) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              border: colorFilterData.selectedIndex == index
                                  ? Border.all(
                                      color: Colors.yellow,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const LoadingIndicator(),
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            BlocProvider.of<MemoryFilterBloc>(context).add(
                              MemoryFilterColorFiltered(colorFilterData
                                  .colorFilterList[index].filter),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                border: colorFilterData.selectedIndex == index
                                    ? Border.all(
                                        color: Colors.yellow,
                                        width: 2,
                                      )
                                    : null,
                                image: DecorationImage(
                                  image: MemoryImage(imageBytes),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              // child: Image.memory(
                              //   imageBytes,
                              //   fit: BoxFit.cover,
                              // ),
                            ),
                          ),
                        );
                      },
                      itemCount: colorFilterData.colorFilterList.length,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              // Center(
              //   child: state is TransferFilterBusy
              //       ? _loadingWidget()
              //       : Container(),
              // )
            ],
          );
        }

        return const SizedBox();
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
}
