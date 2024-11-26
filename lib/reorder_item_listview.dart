import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:reorder/custom_reorder_listener.dart';
import 'package:reorder/reorder_view_logic.dart';

class ReorderItemListView extends StatefulWidget {
  ReorderItemListView(
      {super.key,
      required List<Widget> children,
      required this.onReorder,
      this.onReorderStart,
      this.onReorderEnd,
      this.scrollDirection = Axis.vertical,
      this.scrollController,
      this.shrinkWrap = false,
      this.startingDragBehavior = DragStartBehavior.start,
      required this.topLeft,
      required this.topRight,
      required this.bottomLeft,
      required this.bottomRight,
      this.header})
      : itemBuilder = ((BuildContext context, int index) => children[index]),
        itemCount = children.length;

  const ReorderItemListView.builder({
    super.key,
    required this.itemBuilder,
    required this.startingDragBehavior,
    required this.shrinkWrap,
    this.onReorderEnd,
    required this.onReorder,
    this.onReorderStart,
    required this.scrollDirection,
    this.header,
    required this.bottomLeft,
    required this.bottomRight,
    required this.topLeft,
    required this.topRight,
    this.scrollController,
    required this.itemCount,
  });

  final IndexedWidgetBuilder itemBuilder;
  final DragStartBehavior startingDragBehavior;
  final bool shrinkWrap;
  final void Function(int index)? onReorderEnd;
  final ReorderCallback onReorder;
  final void Function(int index)? onReorderStart;
  final Axis scrollDirection;
  final Widget? header;
  final Offset bottomLeft;
  final Offset bottomRight;
  final Offset topLeft;
  final Offset topRight;
  final ScrollController? scrollController;
  final int itemCount;

  @override
  State<ReorderItemListView> createState() => _ReorderItemListViewState();
}

class _ReorderItemListViewState extends State<ReorderItemListView> {
  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.zero;
    double? start = widget.header == null ? null : 0.0;
    double? end;

    final EdgeInsets startPadding, endPadding, listPadding;
    (startPadding, endPadding, listPadding) = switch (widget.scrollDirection) {
      Axis.horizontal || Axis.vertical when (start ?? end) == null => (EdgeInsets.zero, EdgeInsets.zero, padding),
      Axis.horizontal => (padding.copyWith(left: 0), padding.copyWith(right: 0), padding.copyWith(left: start, right: end)),
      Axis.vertical => (padding.copyWith(top: 0), padding.copyWith(bottom: 0), padding.copyWith(top: start, bottom: end)),
    };
    final (EdgeInsets headerPadding, EdgeInsets footerPadding) = (endPadding, startPadding);

    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      dragStartBehavior: widget.startingDragBehavior,
      slivers: <Widget>[
        if (widget.header != null) SliverPadding(padding: headerPadding, sliver: SliverToBoxAdapter(child: widget.header)),
        SliverPadding(
          padding: listPadding,
          sliver: ReorderViewList(
            bottomLeft: widget.bottomLeft,
            bottomRight: widget.bottomRight,
            topLeft: widget.topLeft,
            topRight: widget.topRight,
            itemBuilder: (BuildContext context, int index) {
              final Widget item = widget.itemBuilder(context, index);

              final Key itemGlobalKey = _GlobalKeyForReOrderList(item.key!, this);
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  CustomReorderableDragStartListener(index: index, child: item),
                ],
              );
            },
            itemCount: widget.itemCount,
            onReorderStart: widget.onReorderStart,
            onReorderEnd: widget.onReorderEnd,
            onReorder: widget.onReorder,
            proxyDecorator: (Widget child, int index, Animation<double> containerAnimation) {
              return AnimatedBuilder(
                animation: containerAnimation,
                builder: (BuildContext context, Widget? child) {
                  return Material(color: Colors.transparent, child: child);
                },
                child: child,
              );
            },
          ),
        ),
      ],
    );
  }
}

@optionalTypeArgs
class _GlobalKeyForReOrderList extends GlobalObjectKey {
  final State state;
  final Key subKey;
  const _GlobalKeyForReOrderList(this.subKey, this.state) : super(subKey);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _GlobalKeyForReOrderList && other.subKey == subKey && other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
