// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef CustomReorderCallback = void Function(int oldIndex, int newIndex);

typedef CustomReorderItemProxyDecorator = Widget Function(Widget child, int index, Animation<double> animation);

class CustomReorderableList extends StatefulWidget {
  const CustomReorderableList({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    this.proxyDecorator,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.autoScrollerVelocityScalar,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.onDragStart,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ReorderCallback onReorder;
  final void Function(int index)? onReorderStart;
  final void Function(int index)? onReorderEnd;
  final ReorderItemProxyDecorator? proxyDecorator;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double anchor;
  final double? cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final double? itemExtent;
  final ItemExtentBuilder? itemExtentBuilder;
  final Widget? prototypeItem;
  final double? autoScrollerVelocityScalar;
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final void Function(bool, int) onDragStart;

  static ReorderableListState of(BuildContext context) {
    final ReorderableListState? result = context.findAncestorStateOfType<ReorderableListState>();
    return result!;
  }

  static CustomReorderableListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<CustomReorderableListState>();
  }

  @override
  CustomReorderableListState createState() => CustomReorderableListState();
}

class CustomReorderableListState extends State<CustomReorderableList> {
  final GlobalKey<ReorderViewListState> _sliverReorderableListKey = GlobalKey();

  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    _sliverReorderableListKey.currentState!.startItemDragReorder(index: index, event: event, recognizer: recognizer);
  }

  void cancelReorder() {
    _sliverReorderableListKey.currentState!.cancelReorder();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      anchor: widget.anchor,
      cacheExtent: widget.cacheExtent,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: ReorderViewList(
            bottomLeft: widget.bottomLeft,
            bottomRight: widget.bottomRight,
            topLeft: widget.topLeft,
            topRight: widget.topRight,
            key: _sliverReorderableListKey,
            itemExtent: widget.itemExtent,
            prototypeItem: widget.prototypeItem,
            itemBuilder: widget.itemBuilder,
            itemCount: widget.itemCount,
            onReorder: widget.onReorder,
            onReorderStart: widget.onReorderStart,
            onReorderEnd: widget.onReorderEnd,
            proxyDecorator: widget.proxyDecorator,
            autoScrollerVelocityScalar: widget.autoScrollerVelocityScalar,
          ),
        ),
      ],
    );
  }
}

class ReorderViewList extends StatefulWidget {
  const ReorderViewList({
    super.key,
    required this.itemBuilder,
    this.findChildIndexCallback,
    required this.itemCount,
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.itemExtent,
    this.itemExtentBuilder,
    this.prototypeItem,
    this.proxyDecorator,
    double? autoScrollerVelocityScalar,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  }) : autoScrollerVelocityScalar = autoScrollerVelocityScalar ?? _kDefaultAutoScrollVelocityScalar;

  // An eyeballed value for a smooth scrolling experience.
  static const double _kDefaultAutoScrollVelocityScalar = 50;

  final IndexedWidgetBuilder itemBuilder;

  final ChildIndexGetter? findChildIndexCallback;

  final int itemCount;

  final ReorderCallback onReorder;

  final void Function(int)? onReorderStart;

  final void Function(int)? onReorderEnd;

  final ReorderItemProxyDecorator? proxyDecorator;

  final double? itemExtent;

  final ItemExtentBuilder? itemExtentBuilder;

  final Widget? prototypeItem;

  final double autoScrollerVelocityScalar;

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  @override
  ReorderViewListState createState() => ReorderViewListState();

  static ReorderViewListState of(BuildContext context) {
    final ReorderViewListState? result = context.findAncestorStateOfType<ReorderViewListState>();
    return result!;
  }

  static ReorderViewListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ReorderViewListState>();
  }
}

class ReorderViewListState extends State<ReorderViewList> with TickerProviderStateMixin {
  final Map<int, _CustomReorderableItemState> _items = <int, _CustomReorderableItemState>{};

  final Map<int, _CustomReorderableItemState> _reorderItems = <int, _CustomReorderableItemState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _CustomDragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  int? _recognizerPointer;

  EdgeDraggingAutoScroller? _autoScroller;

  Offset? updatedDragPosition;

  int? draggableIndex;

  late ScrollableState _scrollable;
  Axis get _scrollDirection => axisDirectionToAxis(_scrollable.axisDirection);
  bool get _reverse => axisDirectionIsReversed(_scrollable.axisDirection);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context);
    if (_autoScroller?.scrollable != _scrollable) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        _scrollable,
        onScrollViewScrolled: _handleScrollableAutoScrolled,
        velocityScalar: widget.autoScrollerVelocityScalar,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReorderViewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      cancelReorder();
    }

    if (widget.autoScrollerVelocityScalar != oldWidget.autoScrollerVelocityScalar) {
      _autoScroller?.stopAutoScroll();
      _autoScroller = EdgeDraggingAutoScroller(
        _scrollable,
        onScrollViewScrolled: _handleScrollableAutoScrolled,
        velocityScalar: widget.autoScrollerVelocityScalar,
      );
    }
  }

  @override
  void dispose() {
    _dragReset();
    _recognizer?.dispose();
    super.dispose();
  }

  void startItemDragReorder({
    required int index,
    required PointerDownEvent event,
    required MultiDragGestureRecognizer recognizer,
  }) {
    assert(0 <= index && index < widget.itemCount);

    setState(() {
      if (_dragInfo != null) {
        cancelReorder();
      } else if (_recognizer != null && _recognizerPointer != event.pointer) {
        _recognizer!.dispose();
        _recognizer = null;
        _recognizerPointer = null;
      }

      if (_items.containsKey(index)) {
        _dragIndex = index;
        _recognizer = recognizer
          ..onStart = _dragStart
          ..addPointer(event);
        _recognizerPointer = event.pointer;
      } else {
        throw Exception('Attempting to start a drag on a non-visible item');
      }
    });
  }

  void cancelReorder() {
    setState(() {
      _dragReset();
    });
  }

  void _registerItem(_CustomReorderableItemState item) {
    if (_dragInfo != null && _items[item.index] != item) {
      item.updateForGap(_dragInfo!.index, _dragInfo!.index, _dragInfo!.itemExtent, false, _reverse);
    }
    _items[item.index] = item;
    _reorderItems[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.rebuild();
    }
  }

  void _unregisterItem(int index, _CustomReorderableItemState item) {
    final _CustomReorderableItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final _CustomReorderableItemState item = _items[_dragIndex!]!;

    // _items.remove(item.index);
    item.dragging = true;
    widget.onReorderStart?.call(_dragIndex!);
    item.rebuild();

    _insertIndex = item.index;
    _dragInfo = _CustomDragInfo(
      item: item,
      initialPosition: position,
      scrollDirection: _scrollDirection,
      onUpdate: _dragUpdate,
      onCancel: _dragCancel,
      onEnd: _dragEnd,
      onDropCompleted: _dropCompleted,
      proxyDecorator: widget.proxyDecorator,
      tickerProvider: this,
    );
    _dragInfo!.startDrag();

    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);
    assert(_overlayEntry == null);
    _overlayEntry = OverlayEntry(builder: _dragInfo!.createProxy);
    overlay.insert(_overlayEntry!);

    for (final _CustomReorderableItemState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) {
        continue;
      }
      childItem.updateForGap(_insertIndex!, _insertIndex!, _dragInfo!.itemExtent, false, _reverse);
    }
    draggableIndex = _insertIndex;
    setState(() {});
    return _dragInfo;
  }

  void _dragUpdate(_CustomDragInfo item, Offset position, Offset delta) {
    bool isInside = isPointInsideRectangle(widget.topLeft, widget.topRight, widget.bottomLeft, widget.bottomRight, position);
    updatedDragPosition = position;
    draggableIndex = item.index;
    if (isInside) {
      // _items.remove(item.index);
      setState(() {});
    } else {}

    setState(() {
      _overlayEntry?.markNeedsBuild();
      _dragUpdateItems();
      _autoScroller?.startAutoScrollIfNecessary(_dragTargetRect);
    });
  }

  bool isPointInsideRectangle(Offset topLeft, Offset topRight, Offset bottomLeft, Offset bottomRight, Offset point) {
    // Find the bounding box of the rectangle
    double left = topLeft.dx; // Left boundary (minimum x)
    double right = topRight.dx; // Right boundary (maximum x)
    double top = topLeft.dy; // Top boundary (minimum y)
    double bottom = bottomLeft.dy; // Bottom boundary (maximum y)

    // Check if the point is within the bounding box
    return point.dx >= left && point.dx <= right && point.dy >= top && point.dy <= bottom;
  }

  void _dragCancel(_CustomDragInfo item) {
    draggableIndex = null;

    setState(() {
      _dragReset();
    });
  }

  void _dragEnd(_CustomDragInfo item) {
    setState(() {
      draggableIndex = null;
      if (_insertIndex == item.index) {
        _finalDropPosition = _itemOffsetAt(_insertIndex!);
      } else if (_reverse) {
        if (_insertIndex! >= _items.length) {
          // Drop at the starting position of the last element and offset its own extent
          _finalDropPosition = _itemOffsetAt(_items.length - 1) - _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          // Drop at the end of the current element occupying the insert position
          _finalDropPosition = _itemOffsetAt(_insertIndex!) + _extentOffset(_itemExtentAt(_insertIndex!), _scrollDirection);
        }
      } else {
        if (_insertIndex! == 0) {
          // Drop at the starting position of the first element and offset its own extent
          _finalDropPosition = _itemOffsetAt(0) - _extentOffset(item.itemExtent, _scrollDirection);
        } else {
          // Drop at the end of the previous element occupying the insert position
          final int atIndex = _insertIndex! - 1;
          _finalDropPosition = _itemOffsetAt(atIndex) + _extentOffset(_itemExtentAt(atIndex), _scrollDirection);
        }
      }
    });
    widget.onReorderEnd?.call(_insertIndex!);
  }

  void _dropCompleted() {
    draggableIndex = null;

    final int fromIndex = _dragIndex!;
    final int toIndex = _insertIndex!;
    if (fromIndex != toIndex) {
      widget.onReorder.call(fromIndex, toIndex);
    }

    setState(() {
      _dragReset();
    });
  }

  void _dragReset() {
    if (_dragInfo != null) {
      if (_dragIndex != null && _items.containsKey(_dragIndex)) {
        final _CustomReorderableItemState dragItem = _items[_dragIndex!]!;
        dragItem._dragging = false;
        dragItem.rebuild();
        _dragIndex = null;
      }
      _dragInfo?.dispose();
      _dragInfo = null;
      _autoScroller?.stopAutoScroll();
      _resetItemGap();
      _recognizer?.dispose();
      _recognizer = null;
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
      _finalDropPosition = null;
    }
  }

  void _resetItemGap() {
    for (final _CustomReorderableItemState item in _items.values) {
      item.resetGap();
    }
  }

  void _handleScrollableAutoScrolled() {
    if (_dragInfo == null) {
      return;
    }
    _dragUpdateItems();
    // Continue scrolling if the drag is still in progress.
    _autoScroller?.startAutoScrollIfNecessary(_dragTargetRect);
  }

  void _dragUpdateItems() {
    bool isInside = updatedDragPosition == null ? true : isPointInsideRectangle(widget.topLeft, widget.topRight, widget.bottomLeft, widget.bottomRight, updatedDragPosition!);
    if (isInside) {
      final double gapExtent = _dragInfo!.itemExtent;
      final double proxyItemStart = _offsetExtent(_dragInfo!.dragPosition - _dragInfo!.dragOffset, _scrollDirection);
      final double proxyItemEnd = proxyItemStart + gapExtent;

      // Find the new index for inserting the item being dragged.
      int newIndex = _insertIndex!;

      for (final _CustomReorderableItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }

        final Rect geometry = item.targetGeometry();
        final double itemStart = _scrollDirection == Axis.vertical ? geometry.top : geometry.left;
        final double itemExtent = _scrollDirection == Axis.vertical ? geometry.height : geometry.width;
        final double itemEnd = itemStart + itemExtent;
        final double itemMiddle = itemStart + itemExtent / 2;

        if (_reverse) {
          if (itemEnd >= proxyItemEnd && proxyItemEnd >= itemMiddle) {
            // The start of the proxy is in the beginning half of the item, so
            // we should swap the item with the gap and we are done looking for
            // the new index.
            newIndex = item.index;
            break;
          } else if (itemMiddle >= proxyItemStart && proxyItemStart >= itemStart) {
            // The end of the proxy is in the ending half of the item, so
            // we should swap the item with the gap and we are done looking for
            // the new index.
            newIndex = item.index + 1;
            break;
          } else if (itemStart > proxyItemEnd && newIndex < (item.index + 1)) {
            newIndex = item.index + 1;
          } else if (proxyItemStart > itemEnd && newIndex > item.index) {
            newIndex = item.index;
          }
        } else {
          if (itemStart <= proxyItemStart && proxyItemStart <= itemMiddle) {
            // The start of the proxy is in the beginning half of the item, so
            // we should swap the item with the gap and we are done looking for
            // the new index.
            newIndex = item.index;
            break;
          } else if (itemMiddle <= proxyItemEnd && proxyItemEnd <= itemEnd) {
            // The end of the proxy is in the ending half of the item, so
            // we should swap the item with the gap and we are done looking for
            // the new index.
            newIndex = item.index + 1;
            break;
          } else if (itemEnd < proxyItemStart && newIndex < (item.index + 1)) {
            newIndex = item.index + 1;
          } else if (proxyItemEnd < itemStart && newIndex > item.index) {
            newIndex = item.index;
          }
        }
      }

      if (newIndex != _insertIndex) {
        _insertIndex = newIndex;
        for (final _CustomReorderableItemState item in _items.values) {
          if (item.index == _dragIndex! || !item.mounted) {
            continue;
          }
          item.updateForGap(_dragIndex!, newIndex, gapExtent, true, _reverse);
        }
      }
    } else {
      for (final _CustomReorderableItemState item in _items.values) {
        if (item.index == _dragIndex! || !item.mounted) {
          continue;
        }
        item.updateForGap(_dragIndex!, _insertIndex!, 0, true, _reverse);
      }
    }
  }

  Rect get _dragTargetRect {
    final Offset origin = _dragInfo!.dragPosition - _dragInfo!.dragOffset;
    return Rect.fromLTWH(origin.dx, origin.dy, _dragInfo!.itemSize.width, _dragInfo!.itemSize.height);
  }

  Offset _itemOffsetAt(int index) {
    return _items[index]!.targetGeometry().topLeft;
  }

  double _itemExtentAt(int index) {
    return _sizeExtent(_items[index]!.targetGeometry().size, _scrollDirection);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    // Handle the case where dragInfo is non-null and we're creating a placeholder for the dragged item
    if (_dragInfo != null && index >= widget.itemCount) {
      return switch (_scrollDirection) {
        Axis.horizontal => SizedBox(width: _insertIndex == index ? 0 : _dragInfo!.itemExtent),
        Axis.vertical => SizedBox(height: _insertIndex == index ? 0 : _dragInfo!.itemExtent),
      };
    }
    // if (_insertIndex == index) {
    //   return SizedBox.shrink(); // Empty space when dragging
    // }
    bool isInside = isPointInsideRectangle(widget.topLeft, widget.topRight, widget.bottomLeft, widget.bottomRight, updatedDragPosition ?? Offset.zero);

    final Widget child = widget.itemBuilder(context, index);

    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);

    return _CustomReorderableItem(
      key: _ReorderableItemGlobalKey(child.key!, index, this),
      index: index,
      capturedThemes: InheritedTheme.capture(from: context, to: overlay.context),
      child: _wrapWithSemantics(
          !isInside && _items[draggableIndex] == _items[index]
              ? Container(
                  height: 50,
                  width: 50,
                  color: Colors.black,
                  key: ValueKey(index),
                )
              : child,
          index),
    );
  }

  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions = <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.itemCount);
    void moveBefore() => reorder(index, index - 1);
    // To move after, go to index+2 because it is moved to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
    final bool isHorizontal = _scrollDirection == Axis.horizontal;
    // If the item can move to before its current position in the list.
    if (index > 0) {
      semanticsActions[CustomSemanticsAction(label: localizations.reorderItemToStart)] = moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (isHorizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr ? localizations.reorderItemLeft : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] = moveBefore;
    }

    // If the item can move to after its current position in the list.
    if (index < widget.itemCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (isHorizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr ? localizations.reorderItemRight : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] = moveAfter;
      semanticsActions[CustomSemanticsAction(label: localizations.reorderItemToEnd)] = moveToEnd;
    }

    // Pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // Also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the list.

    return Semantics(
      container: true,
      customSemanticsActions: semanticsActions,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SliverChildBuilderDelegate childrenDelegate = SliverChildBuilderDelegate(
      _itemBuilder,
      childCount: widget.itemCount,
      findChildIndexCallback: widget.findChildIndexCallback,
    );
    if (widget.itemExtent != null) {
      return SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: widget.itemExtent!,
      );
    } else if (widget.itemExtentBuilder != null) {
      return SliverVariedExtentList(
        delegate: childrenDelegate,
        itemExtentBuilder: widget.itemExtentBuilder!,
      );
    } else if (widget.prototypeItem != null) {
      return SliverPrototypeExtentList(
        delegate: childrenDelegate,
        prototypeItem: widget.prototypeItem!,
      );
    }
    return SliverList(delegate: childrenDelegate);
  }
}

class _CustomReorderableItem extends StatefulWidget {
  const _CustomReorderableItem({
    required Key super.key,
    required this.index,
    required this.child,
    required this.capturedThemes,
  });

  final int index;
  final Widget child;
  final CapturedThemes capturedThemes;

  @override
  _CustomReorderableItemState createState() => _CustomReorderableItemState();
}

class _CustomReorderableItemState extends State<_CustomReorderableItem> {
  late ReorderViewListState _listState;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  Key get key => widget.key!;
  int get index => widget.index;

  bool get dragging => _dragging;
  set dragging(bool dragging) {
    if (mounted) {
      setState(() {
        _dragging = dragging;
      });
    }
  }

  bool _dragging = false;
  BoxConstraints? get childLayoutConstraints => _childLayoutConstraints;
  BoxConstraints? _childLayoutConstraints;

  @override
  void initState() {
    _listState = ReorderViewList.of(context);
    _listState._registerItem(this);
    super.initState();
  }

  @override
  void dispose() {
    _offsetAnimation?.dispose();
    _listState._unregisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CustomReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _listState._unregisterItem(oldWidget.index, this);
      _listState._registerItem(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dragging) {
      final Size size = _extentSize(_listState._dragInfo!.itemExtent, _listState._scrollDirection);
      return SizedBox.fromSize(size: size);
    }
    _listState._registerItem(this);

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      _childLayoutConstraints = constraints;
      return Transform(
        transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
        child: widget.child,
      );
    });
  }

  @override
  void deactivate() {
    _listState._unregisterItem(index, this);
    super.deactivate();
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final double animValue = Curves.easeInOut.transform(_offsetAnimation!.value);
      return Offset.lerp(_startOffset, _targetOffset, animValue)!;
    }
    return _targetOffset;
  }

  void updateForGap(int dragIndex, int gapIndex, double gapExtent, bool animate, bool reverse) {
    // An offset needs to be added to create a gap when we are between the
    // moving element (dragIndex) and the current gap position (gapIndex).
    // For how to update the gap position, refer to [_dragUpdateItems].
    final Offset newTargetOffset;
    if (gapIndex < dragIndex && index < dragIndex && index >= gapIndex) {
      newTargetOffset = _extentOffset(reverse ? -gapExtent : gapExtent, _listState._scrollDirection);
    } else if (gapIndex > dragIndex && index > dragIndex && index < gapIndex) {
      newTargetOffset = _extentOffset(reverse ? gapExtent : -gapExtent, _listState._scrollDirection);
    } else {
      newTargetOffset = Offset.zero;
    }

    if (newTargetOffset != _targetOffset) {
      _targetOffset = newTargetOffset;
      if (animate) {
        if (_offsetAnimation == null) {
          _offsetAnimation = AnimationController(
            vsync: _listState,
            duration: const Duration(milliseconds: 250),
          )
            ..addListener(rebuild)
            ..addStatusListener((AnimationStatus status) {
              if (status.isCompleted) {
                _startOffset = _targetOffset;
                _offsetAnimation!.dispose();
                _offsetAnimation = null;
              }
            })
            ..forward();
        } else {
          _startOffset = offset;
          _offsetAnimation!.forward(from: 0.0);
        }
      } else {
        if (_offsetAnimation != null) {
          _offsetAnimation!.dispose();
          _offsetAnimation = null;
        }
        _startOffset = _targetOffset;
      }

      setState(() {});
      rebuild();
    }
  }

  void resetGap() {
    if (_offsetAnimation != null) {
      _offsetAnimation!.dispose();
      _offsetAnimation = null;
    }

    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
    rebuild();
  }

  Rect targetGeometry() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;

    return itemPosition & itemRenderBox.size;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}

typedef _DragItemUpdate = void Function(_CustomDragInfo item, Offset position, Offset delta);
typedef _DragItemCallback = void Function(_CustomDragInfo item);

class _CustomDragInfo extends Drag {
  _CustomDragInfo({
    required _CustomReorderableItemState item,
    Offset initialPosition = Offset.zero,
    this.scrollDirection = Axis.vertical,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    this.onDropCompleted,
    this.proxyDecorator,
    required this.tickerProvider,
  }) {
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:flutter/widgets.dart',
        className: '$_CustomDragInfo',
        object: this,
      );
    }
    final RenderBox itemRenderBox = item.context.findRenderObject()! as RenderBox;
    listState = item._listState;
    index = item.index;
    child = item.widget.child;
    capturedThemes = item.widget.capturedThemes;
    dragPosition = initialPosition;
    dragOffset = itemRenderBox.globalToLocal(initialPosition);
    itemSize = item.context.size!;
    itemExtent = _sizeExtent(itemSize, scrollDirection);
    itemLayoutConstraints = item.childLayoutConstraints!;
    scrollable = Scrollable.of(item.context);
  }

  final Axis scrollDirection;
  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDropCompleted;
  final ReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late ReorderViewListState listState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;
  late BoxConstraints itemLayoutConstraints;
  late double itemExtent;
  late CapturedThemes capturedThemes;
  ScrollableState? scrollable;
  AnimationController? _proxyAnimation;

  void dispose() {
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    }
    _proxyAnimation?.dispose();
  }

  void startDrag() {
    _proxyAnimation = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 250),
    )
      ..addStatusListener((AnimationStatus status) {
        if (status.isDismissed) {
          _dropCompleted();
        }
      })
      ..forward();
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = _restrictAxis(details.delta, scrollDirection);

    dragPosition += delta;

    onUpdate?.call(this, dragPosition, details.delta);
  }

  @override
  void end(DragEndDetails details) {
    _proxyAnimation!.reverse();
    onEnd?.call(this);
  }

  @override
  void cancel() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onCancel?.call(this);
  }

  void _dropCompleted() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onDropCompleted?.call();
  }

  Widget createProxy(BuildContext context) {
    return capturedThemes.wrap(
      _DragItemProxy(
        listState: listState,
        index: index,
        size: itemSize,
        constraints: itemLayoutConstraints,
        animation: _proxyAnimation!,
        position: dragPosition - dragOffset - _overlayOrigin(context),
        proxyDecorator: proxyDecorator,
        child: child,
      ),
    );
  }
}

Offset _overlayOrigin(BuildContext context) {
  final OverlayState overlay = Overlay.of(context, debugRequiredFor: context.widget);
  final RenderBox overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
}

class _DragItemProxy extends StatelessWidget {
  const _DragItemProxy({
    required this.listState,
    required this.index,
    required this.child,
    required this.position,
    required this.size,
    required this.constraints,
    required this.animation,
    required this.proxyDecorator,
  });

  final ReorderViewListState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  final BoxConstraints constraints;
  final AnimationController animation;
  final ReorderItemProxyDecorator? proxyDecorator;

  @override
  Widget build(BuildContext context) {
    final Widget proxyChild = proxyDecorator?.call(child, index, animation.view) ?? child;
    final Offset overlayOrigin = _overlayOrigin(context);

    return MediaQuery(
      // Remove the top padding so that any nested list views in the item
      // won't pick up the scaffold's padding in the overlay.
      data: MediaQuery.of(context).removePadding(removeTop: true),
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          Offset effectivePosition = position;
          final Offset? dropPosition = listState._finalDropPosition;
          if (dropPosition != null) {
            effectivePosition = Offset.lerp(dropPosition - overlayOrigin, effectivePosition, Curves.easeOut.transform(animation.value))!;
          }
          return Positioned(
            left: effectivePosition.dx,
            top: effectivePosition.dy,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: OverflowBox(
                minWidth: constraints.minWidth,
                minHeight: constraints.minHeight,
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                alignment: listState._scrollDirection == Axis.horizontal ? Alignment.centerLeft : Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
        child: proxyChild,
      ),
    );
  }
}

double _sizeExtent(Size size, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => size.width,
    Axis.vertical => size.height,
  };
}

Size _extentSize(double extent, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Size(extent, 0),
    Axis.vertical => Size(0, extent),
  };
}

double _offsetExtent(Offset offset, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => offset.dx,
    Axis.vertical => offset.dy,
  };
}

Offset _extentOffset(double extent, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Offset(extent, 0.0),
    Axis.vertical => Offset(0.0, extent),
  };
}

Offset _restrictAxis(Offset offset, Axis scrollDirection) {
  return switch (scrollDirection) {
    Axis.horizontal => Offset(offset.dx, offset.dy),
    Axis.vertical => Offset(0.0, offset.dy),
  };
}

// A global key that takes its identity from the object and uses a value of a
// particular type to identify itself.
//
// The difference with GlobalObjectKey is that it uses [==] instead of [identical]
// of the objects used to generate widgets.
@optionalTypeArgs
class _ReorderableItemGlobalKey extends GlobalObjectKey {
  const _ReorderableItemGlobalKey(this.subKey, this.index, this.state) : super(subKey);

  final Key subKey;
  final int index;
  final ReorderViewListState state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableItemGlobalKey && other.subKey == subKey && other.index == index && other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, index, state);
}
