import 'dart:typed_data';

import 'package:ffi_flutter_example/pages/opencv/filter/ui/filter_category_page.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/bloc/memory_filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/tabs/color_filter_tab.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/tabs/transfer_filter_tab.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:ffi_flutter_example/widgets/scroll_tab_view.dart';
import 'package:ffi_flutter_example/widgets/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: _buildBody(),
          );
        }
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Image filter page'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (String result) async {
            BlocProvider.of<MemoryFilterBloc>(context)
                .add(MemoryFilterImageSaved());
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Save',
              child: Text('Save image'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: BlocConsumer<MemoryFilterBloc, MemoryFilterState>(
          listener: (context, state) {
        if (state is MemoryFilterImageSaveSuccess) {
          ToastUtils.done(
            subTitle: 'Save successfully',
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
          return const SizedBox();
        }
        return Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildPage(data)),
                _buildBottomTabs(data, context),
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
            //
            // switch (category) {
            //   case 'Normal':
            //     final data =
            //         BlocProvider.of<NormalFilterBloc>(context).state.data;
            //     BlocProvider.of<FilterBloc>(context)
            //         .add(FilterCurrentImageLoaded(data.filterBytes));
            //     break;
            //   case 'Cartoon':
            //     final data =
            //         BlocProvider.of<TransferFilterBloc>(context).state.data;
            //     BlocProvider.of<FilterBloc>(context)
            //         .add(FilterCurrentImageLoaded(data?.transferImage));
            //     break;
            // }
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
