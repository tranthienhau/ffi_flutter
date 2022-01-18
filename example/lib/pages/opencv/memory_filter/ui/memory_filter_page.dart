import 'dart:typed_data';

import 'package:ffi_flutter_example/pages/opencv/filter/ui/filter_category_page.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/bloc/memory_filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/tabs/color_filter_tab.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/tabs/transfer_filter_tab.dart';
import 'package:ffi_flutter_example/widgets/app_button.dart';
import 'package:ffi_flutter_example/widgets/circle_button.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:ffi_flutter_example/widgets/scroll_tab_view.dart';
import 'package:ffi_flutter_example/widgets/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class MemoryFilterPage extends StatefulWidget {
  const MemoryFilterPage(
      {Key? key, required this.imagePath, required this.thumnail})
      : super(key: key);

  final String imagePath;
  final Uint8List thumnail;

  @override
  _MemoryFilterPageState createState() => _MemoryFilterPageState();
}

class _MemoryFilterPageState extends State<MemoryFilterPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => MemoryFilterBloc()
        ..add(MemoryFilterLoaded(
          thumnail: widget.thumnail,
          imagePath: widget.imagePath,
        )),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(context),
          body: _buildBody(),
        );
      }),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      title: const Text('Image filter page'),
      leading: Row(
        children: [
          const SizedBox(width: 20),
          CircleButton(
            size: 40,
            onPressed: () {
              Navigator.of(context).pop();
            },
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ],
      ),
      leadingWidth: 60,
      actions: [
        Center(
          child: CircleButton(
            size: 40,
            onPressed: () {
              _showLikeBottomSheet(
                context: context,
                onSaved: () {
                  BlocProvider.of<MemoryFilterBloc>(context)
                      .add(MemoryFilterImageSaved());
                },
                onShared: () {
                  BlocProvider.of<MemoryFilterBloc>(context).add(
                    MemoryFilterShared(),
                  );
                },
              );
            },
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.more_horiz,
              color: Colors.white,
            ),
          ),
        ),
        // PopupMenuButton<String>(
        //   child: Center(
        //     child: ClipOval(
        //       child: SizedBox(
        //         width: 40,
        //         height: 40,
        //         child: Material(
        //           color: Colors.white.withOpacity(0.2),
        //           child: const Icon(
        //             Icons.more_horiz,
        //             color: Colors.white,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        //   onSelected: (String result) async {
        //
        //     // BlocProvider.of<MemoryFilterBloc>(context)
        //     //     .add(MemoryFilterImageSaved());
        //   },
        //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        //     const PopupMenuItem<String>(
        //       value: 'Save',
        //       child: Text('Save image'),
        //     ),
        //   ],
        // ),
        const SizedBox(width: 15),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: BlocConsumer<MemoryFilterBloc, MemoryFilterState>(
          listener: (context, state) {
        if (state is MemoryFilterImageSaveSuccess) {
          ToastUtils.done(
            subTitle: 'Photo saved',
          );
          return;
        }

        if (state is MemoryFilterImageSaveFailure) {
          ToastUtils.error(error: 'Save failed: ${state.error}');
          return;
        }
      }, builder: (context, state) {
        final data = state.data;
        if (data == null) {
          return const Center(child: LoadingIndicator());
        }
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      _buildPage(data),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 110,
                        child: _buildBottomTabsNew(data, context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state is MemoryFilterBusy)
              const Center(child: LoadingIndicator())
          ],
        );
      }),
    );
  }

  Widget _buildPage(MemoryFilterData data) {
    final pageIndex = data.categories.indexOf(data.category);
    return FadeIndexedStack(
      index: pageIndex,
      duration: const Duration(milliseconds: 200),
      children: const [
        ColorFilterTab(),
        TransferFilterTab(),
      ],
    );
  }

  Widget _buildBottomTabsNew(MemoryFilterData data, BuildContext context) {
    final pageIndex = data.categories.indexOf(data.category);

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20, top: 10),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.categories
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: InkWell(
                    onTap: () {
                      BlocProvider.of<MemoryFilterBloc>(context).add(
                        MemoryFilterCategoryChanged(category),
                      );
                    },
                    child: _buildTab(
                      title: category,
                      isSelected: category == data.category,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20, top: 10),
      child: SizedBox(
        height: 40,
        child: ScrollTabViewHeader<String>(
          objects: data.categories,
          defaultIndex: pageIndex,
          showUnderLine: false,
          padding: EdgeInsets.zero,
          onSelectedChange: (String category) {
            BlocProvider.of<MemoryFilterBloc>(context)
                .add(MemoryFilterCategoryChanged(category));
          },
          headerBuilder:
              (BuildContext context, bool isSelected, String category) {
            return _buildTab(title: category, isSelected: isSelected);
            // return Text(
            //   category,
            //   style: Theme.of(context).textTheme.headline6?.copyWith(
            //     // color: Colors.white,
            //     fontSize: 20,
            //     fontWeight: FontWeight.w700,
            //   ),
            // );
          },
        ),
      ),
    );
  }

  Widget _buildTab({required String title, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff005FF9) : Colors.black,
        border: Border.all(
          color: isSelected
              ? const Color(0xff005FF9)
              : Colors.white.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBottomTabs(MemoryFilterData data, BuildContext context) {
    final pageIndex = data.categories.indexOf(data.category);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20, top: 10),
      child: SizedBox(
        height: 32,
        child: ScrollTabViewHeader<String>(
          objects: data.categories,
          defaultIndex: pageIndex,
          padding: EdgeInsets.zero,
          onSelectedChange: (String category) {
            BlocProvider.of<MemoryFilterBloc>(context)
                .add(MemoryFilterCategoryChanged(category));
          },
          headerBuilder:
              (BuildContext context, bool isSelected, String category) {
            return Text(
              category,
              style: Theme.of(context).textTheme.headline6?.copyWith(
                    // color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showLikeBottomSheet({
  required Function() onSaved,
  required Function() onShared,
  required BuildContext context,
}) async {
  await showModalBottomSheet(
    // barrierColor: AppColors.bottomSheetBackground.withOpacity(0.3),
    // isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
    ),
    backgroundColor: const Color(0xff252223),
    context: context,
    builder: (context) {
      return _FilterActionBottomSheet(
        onSaved: onSaved,
        onShared: onShared,
      );
    },
  );
}

class _FilterActionBottomSheet extends StatelessWidget {
  const _FilterActionBottomSheet(
      {Key? key, required this.onSaved, required this.onShared})
      : super(key: key);
  final Function() onSaved;
  final Function() onShared;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              AppButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  onSaved();
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          'Save to photo library',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        child: SvgPicture.asset('assets/icons/save.svg',
                            semanticsLabel: 'Acme Logo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  onShared();
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          'Share to social media',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        child: SvgPicture.asset('assets/icons/share.svg',
                            semanticsLabel: 'Acme Logo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
