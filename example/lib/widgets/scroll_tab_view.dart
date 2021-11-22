import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

typedef _HeaderBuilder<T> = Widget Function(
    BuildContext context, bool isSelected, T object);

class ScrollTabViewHeader<T> extends StatefulWidget {
  const ScrollTabViewHeader({
    Key? key,
    required this.objects,
    this.tabStyle,
    this.onSelectedChange,
    this.mainAxisAlignment,
    this.underLineColor,
    this.defaultIndex = 0,
    this.padding = const EdgeInsets.only(left: 5, right: 5),
    this.headerBuilder,
    this.spaceBetweenItem = 20,
  }) : super(key: key);

  @override
  _ScrollTabViewHeaderState<T> createState() => _ScrollTabViewHeaderState<T>();
  final List<T> objects;
  final TextStyle? tabStyle;
  final Function(T object)? onSelectedChange;
  final MainAxisAlignment? mainAxisAlignment;
  final Color? underLineColor;
  final int defaultIndex;
  final EdgeInsets padding;
  final _HeaderBuilder<T>? headerBuilder;
  final double spaceBetweenItem;
}

class _ScrollTabViewHeaderState<T> extends State<ScrollTabViewHeader<T>> {
  int _selectedIndex = 0;
  late AutoScrollController _controller;

  @override
  void didUpdateWidget(ScrollTabViewHeader<T> oldWidget) {
    if(widget.defaultIndex != _selectedIndex){
      setState(() {
        _selectedIndex = widget.defaultIndex;
      });
      _scrollToIndex(_selectedIndex);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _controller = AutoScrollController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.horizontal);
    _selectedIndex = widget.defaultIndex;
  }

  ///Xây dựng giao diện cho từng tab
  Widget _buildTabItem(int index, T object) {
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
          _scrollToIndex(_selectedIndex);
          if (widget.onSelectedChange != null) {
            widget.onSelectedChange?.call(object);
          }
        }
      },
      child: widget.headerBuilder == null
          ? Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(
                  width: 4,
                  color: _selectedIndex == index
                      ? widget.underLineColor ?? Theme.of(context).primaryColor
                      : Colors.transparent,
                ),
              )),
              child: Text(
                object.toString(),
                style: widget.tabStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            )
          : Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 4,
                    color: _selectedIndex == index
                        ? widget.underLineColor ??
                            Theme.of(context).primaryColor
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: widget.headerBuilder!(
                    context, _selectedIndex == index, object),
              )),
    );
  }

  ///Di chuyển tới tab dựa vào [index]
  Future<void> _scrollToIndex(int index) async {
    await _controller.scrollToIndex(index,
        preferPosition: AutoScrollPosition.middle);
    _controller.highlight(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      itemCount: widget.objects.length,
      itemBuilder: (BuildContext context, int index) {
        return AutoScrollTag(
          key: ValueKey<int>(index),
          controller: _controller,
          index: index,
          child: _buildTabItem(
            index,
            widget.objects[index],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(
          width: widget.spaceBetweenItem,
        );
      },
    );
  }
}
