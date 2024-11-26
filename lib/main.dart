import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:reorder/reorder_item_listview.dart';

void main() {
  runApp(const MacOSDocApp());
}

class MacOSDocApp extends StatefulWidget {
  const MacOSDocApp({super.key});

  @override
  State<MacOSDocApp> createState() => _MacOSDocAppState();
}

class _MacOSDocAppState extends State<MacOSDocApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dock Demo'),
        ),
        body: Center(
          child: Dock(
            items: const [Icons.person, Icons.message, Icons.call, Icons.camera, Icons.photo],
            builder: (e) {
              return Center(child: Icon(e, color: Colors.white));
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T extends Object?> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T) builder;
  const Dock({super.key, this.items = const [], required this.builder});

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object?> extends State<Dock<T>> {
  ScrollController scrollController = ScrollController();
  final GlobalKey _containerKey = GlobalKey();
  late final List<T> _items = widget.items.toList();
  late int? hoveredIndex;
  late double baseItemHeight = 40;
  late double baseTranslationY = 0.0;

  @override
  void initState() {
    super.initState();
    hoveredIndex = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getOffsets();
    });
  }

  Offset _topLeftOffset = Offset.zero;
  Offset _topRightOffset = Offset.zero;
  Offset _bottomLeftOffset = Offset.zero;
  Offset _bottomRightOffset = Offset.zero;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      height: 68,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black12),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderItemListView(
            onReorderEnd: (i) {
              setState(() {});
            },
            bottomLeft: _bottomLeftOffset,
            shrinkWrap: true,
            scrollController: scrollController,
            topLeft: _topLeftOffset,
            startingDragBehavior: DragStartBehavior.down,
            scrollDirection: Axis.horizontal,
            bottomRight: _bottomRightOffset,
            topRight: _topRightOffset,
            onReorder: (int oldIndex, int newIndex) {
              _getOffsets();
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final T item = _items.removeAt(oldIndex);
                hoveredIndex = newIndex;
                _items.insert(newIndex, item);
              });
            },
            children: _items.map((item) {
              int index = _items.indexOf(item);
              return MouseRegion(
                key: ValueKey(item),
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() {
                  hoveredIndex = index;
                }),
                onExit: (_) => setState(() {
                  hoveredIndex = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()..translate(0.0, getYAxis(index), 0.0),
                  margin: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      height: getAnimatedSize(index),
                      width: getAnimatedSize(index),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.primaries[item.hashCode % Colors.primaries.length]),
                      child: widget.builder(item),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _getOffsets() {
    final RenderBox renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    setState(() {
      _topLeftOffset = position;
      _topRightOffset = Offset(position.dx + renderBox.size.width + 50, position.dy + 50);
      _bottomLeftOffset = Offset(position.dx, position.dy + renderBox.size.height + 50);
      _bottomRightOffset = Offset(position.dx + renderBox.size.width + 50, position.dy + renderBox.size.height + 50);
    });
  }

  double getAnimatedSize(int index) {
    return getValueOfProperty(
      index: index,
      baseValue: baseItemHeight,
      maxValue: 100,
      nonHoveredMaxValue: 50,
    );
  }

  double getYAxis(int index) {
    return getValueOfProperty(
      index: index,
      baseValue: baseTranslationY,
      maxValue: -22,
      nonHoveredMaxValue: -14,
    );
  }

  double getValueOfProperty({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    if (hoveredIndex == null) {
      return baseValue;
    }

    final difference = (hoveredIndex! - index).abs();
    final itemsAffected = _items.length;

    if (difference == 0) {
      propertyValue = maxValue;
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;
    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }
}
