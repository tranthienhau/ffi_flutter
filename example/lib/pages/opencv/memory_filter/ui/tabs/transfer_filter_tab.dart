import 'package:ffi_flutter_example/pages/opencv/memory_filter/bloc/memory_filter_bloc.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferFilterTab extends StatelessWidget {
  const TransferFilterTab({Key? key}) : super(key: key);

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
          final transferFilterData = data.transferFilterData;
          final originImage = data.originImage;
          final transferImage = data.transferImage;

          child = Image.memory(
            originImage,
            width: 100,
            height: 100,
            gaplessPlayback: true,
            fit: BoxFit.fitWidth,
          );

          if (transferImage != null) {
            child = Image.memory(
              transferImage,
              width: 100,
              height: 100,
              gaplessPlayback: true,
              fit: BoxFit.fitWidth,
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Center(child: child),
                        if(state is MemoryFilterTransferFilterBusy)
                          const LoadingIndicator()
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final imagePath = transferFilterData
                            .transferFilterList[index].thumbnailPath;

                        return GestureDetector(
                          onTap: () {
                            BlocProvider.of<MemoryFilterBloc>(context)
                                .add(MemoryFilterTransferFiltered(imagePath));
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              border: transferFilterData.selectedIndex == index
                                  ? Border.all(
                                      color: Colors.yellow,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(imagePath),
                            ),
                          ),
                        );
                      },
                      itemCount: transferFilterData.transferFilterList.length,
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
}
