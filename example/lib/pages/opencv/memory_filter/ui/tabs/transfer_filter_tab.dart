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
            gaplessPlayback: true,
            fit: BoxFit.cover,
          );

          if (transferImage != null) {
            child = Image.memory(
              transferImage,
              gaplessPlayback: true,
              fit: BoxFit.cover,
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: child,
                            ),
                          ),
                        ),
                        if (state is MemoryFilterTransferFilterBusy)
                          const LoadingIndicator()
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final imagePath = transferFilterData
                            .transferFilterList[index].thumbnailPath;

                        return GestureDetector(
                          onTap: () {
                            BlocProvider.of<MemoryFilterBloc>(context)
                                .add(MemoryFilterTransferFiltered(index));
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              border: transferFilterData.selectedIndex == index
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: transferFilterData.transferFilterList.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(width: 10);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
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
