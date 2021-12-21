import 'dart:typed_data';

import 'package:ffi_flutter_example/pages/opencv/filter/bloc/filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/bloc/normal_filter/normal_filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/bloc/transfer_filter/transfer_filter_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/ui/transfer_filter_page.dart';
import 'package:ffi_flutter_example/widgets/scroll_tab_view.dart';
import 'package:ffi_flutter_example/widgets/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'filter_page.dart';

class FilterCategoryPage extends StatefulWidget {
  const FilterCategoryPage(
      {Key? key, required this.imagePath, required this.thumnail})
      : super(key: key);

  final String imagePath;
  final Uint8List thumnail;

  @override
  _FilterCategoryPageState createState() => _FilterCategoryPageState();
}

class _FilterCategoryPageState extends State<FilterCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) => NormalFilterBloc(),
        ),
        BlocProvider(
          create: (BuildContext context) => TransferFilterBloc(),
        ),
        BlocProvider(
          create: (BuildContext context) => FilterBloc(),
        ),
      ],
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
          onSelected: (String result) {
            BlocProvider.of<FilterBloc>(context).add(FilterCurrentImageSaved());
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Save',
              child: Text('Save filter image'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildPage()),
          _buildBottomTabs(),
        ],
      ),
    );
  }

  Widget _buildPage() {
    return BlocConsumer<FilterBloc, FilterState>(
      listener: (context, state) {
        if (state is FilterSaveSuccess) {
          ToastUtils.done(
            subTitle: 'Save successfully',
          );
          return;
        }

        if (state is FilterSaveFailure) {
          ToastUtils.error(error: 'Save failed: ${state.error}');
          return;
        }
      },
      builder: (context, state) {
        final pageIndex =
            state.data.filterCategories.indexOf(state.data.filterType);
        return FadeIndexedStack(
          index: pageIndex,
          duration: const Duration(milliseconds: 200),
          children: [
            FilterPage(
              imagePath: widget.imagePath,
              thumnail: widget.thumnail,
            ),
            TransferFilterPage(
              imagePath: widget.imagePath,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomTabs() {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        final data = state.data;
        final pageIndex = data.filterCategories.indexOf(data.filterType);
        return Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 20, top: 10),
          child: SizedBox(
            height: 32,
            child: ScrollTabViewHeader<String>(
              objects: data.filterCategories,
              defaultIndex: pageIndex,
              padding: EdgeInsets.zero,
              onSelectedChange: (String category) {
                BlocProvider.of<FilterBloc>(context)
                    .add(FilterPageChanged(category));

                switch (category) {
                  case 'Normal':
                    final data =
                        BlocProvider.of<NormalFilterBloc>(context).state.data;
                    BlocProvider.of<FilterBloc>(context)
                        .add(FilterCurrentImageLoaded(data.filterBytes));
                    break;
                  case 'Cartoon':
                    final data =
                        BlocProvider.of<TransferFilterBloc>(context).state.data;
                    BlocProvider.of<FilterBloc>(context)
                        .add(FilterCurrentImageLoaded(data?.transferImage));
                    break;
                }
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
      },
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);
  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
