import 'package:ffi_flutter_example/pages/opencv/filter/ui/filter_category_page.dart';
import 'package:ffi_flutter_example/pages/opencv/filter/ui/filter_page.dart';
import 'package:ffi_flutter_example/pages/opencv/gallery/bloc/gallery_bloc.dart';
import 'package:ffi_flutter_example/pages/opencv/gallery/model/gallery_asset.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/memory_filter_page.dart';
import 'package:ffi_flutter_example/widgets/loading_indicator.dart';
import 'package:ffi_flutter_example/widgets/scroll_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GalleryBloc()
        ..add(
          GalleryLoaded(),
        ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image selection page'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<GalleryBloc, GalleryState>(
      listener: (context, state) {
        if (state is GalleryAssetLoadSuccess) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return MemoryFilterPage(
                  imagePath: state.file.path,
                  thumnail: state.thumnail,
                );
              },
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is GalleryLoading) {
          return const LoadingIndicator();
        }

        if (state.data.mapGalleryCategory.isEmpty) {
          return const Center(
            child: Text('No available image'),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              _buildTabs(state.data, context),
              Expanded(
                child: _buildPageView(state.data, context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageView(GalleryBlocData data, BuildContext context) {
    return FadeIndexedStack(
      children: data.mapGalleryCategory.entries
          .map(
            (entry) => _buildGalleryPage(entry.value, entry.key, context),
          )
          .toList(),
      index: data.currentPage,
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildGalleryPage(
      List<GalleryAsset>? assets, String galleryName, BuildContext context) {
    if (assets != null) {
      return SingleChildScrollView(
        child: Wrap(
          children: assets
              .map(
                (asset) => InkWell(
                  onTap: () {
                    BlocProvider.of<GalleryBloc>(context).add(GalleryAssetLoaded(
                      asset: asset,
                      galleryName: galleryName,
                    ));
                  },
                  child: Image.memory(
                    asset.bytes,
                    width: MediaQuery.of(context).size.width / 3,
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return const Center(child: LoadingIndicator());
  }

  Widget _buildTabs(GalleryBlocData data, BuildContext context) {
    final tabs = data.mapGalleryCategory.keys.toList();
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 20, top: 0),
      child: SizedBox(
        height: 40,
        child: ScrollTabViewHeader<String>(
          objects: tabs,
          defaultIndex: data.currentPage,
          padding: EdgeInsets.zero,
          onSelectedChange: (String value) {
            final pageIndex = tabs.indexOf(value);

            BlocProvider.of<GalleryBloc>(context)
                .add(GalleryPageChanged(pageIndex));
          },
          headerBuilder:
              (BuildContext context, bool isSelected, String object) {
            return Text(
              object,
              style: Theme.of(context).textTheme.headline6?.copyWith(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor,
                    fontWeight: FontWeight.w700,
                  ),
            );
          },
        ),
      ),
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
