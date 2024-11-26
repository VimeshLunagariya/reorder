import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:reorder/reorder_view_logic.dart';

class CustomReorderableDelayedDragStartListener extends CustomReorderableDragStartListener {
  const CustomReorderableDelayedDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(debugOwner: this);
  }
}

class CustomReorderableDragStartListener extends StatelessWidget {
  const CustomReorderableDragStartListener({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
  });

  final Widget child;

  final int index;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (PointerDownEvent event) => _startDragging(context, event) : null,
      child: child,
    );
  }

  @protected
  MultiDragGestureRecognizer createRecognizer() {
    return ImmediateMultiDragGestureRecognizer(debugOwner: this);
  }

  void _startDragging(BuildContext context, PointerDownEvent event) {
    final DeviceGestureSettings? gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    final ReorderViewListState? list = ReorderViewList.maybeOf(context);

    list?.startItemDragReorder(
      index: index,
      event: event,
      recognizer: createRecognizer()..gestureSettings = gestureSettings,
    );
  }
}
