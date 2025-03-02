import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'path/arrow_path.dart';
import 'path/barrier_path.dart';
import 'util/text_position_helper.dart';

class TutorialTooltipController {
  _TutorialTargetState? _attachTarget;

  void show() => _attachTarget?._showOverlay();

  void hide() => _attachTarget?._closeOverlay();
}

class TutorialTarget extends StatefulWidget {
  final TutorialTooltipController controller;
  final Widget child;

  final InlineSpan text;
  final TextDirection? textDirection;

  final Color barrierColor;
  final Color arrowColor;
  final Duration openingDuration;

  final double padding;

  final VoidCallback? onBarrierTap;
  final HitTestBehavior targetHitBehavior;

  const TutorialTarget({
    required this.controller,
    required this.child,
    required this.text,
    this.barrierColor = Colors.black54,
    this.arrowColor = Colors.white,
    this.openingDuration = const Duration(milliseconds: 200),
    this.padding = 32,
    this.targetHitBehavior = HitTestBehavior.opaque,
    this.onBarrierTap,
    this.textDirection,
    super.key,
  });

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget>
    with SingleTickerProviderStateMixin {
  final TapGestureRecognizer _recognizer = TapGestureRecognizer();
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: widget.openingDuration,
  );

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _recognizer.onTap = widget.onBarrierTap ?? _closeOverlay;
    widget.controller._attachTarget = this;
  }

  @override
  void dispose() {
    widget.controller._attachTarget = null;
    _recognizer.dispose();
    _animationController.dispose();
    _closeOverlay();

    super.dispose();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    final box = context.findRenderObject()! as RenderBox;

    final overlayEntry = _overlayEntry = OverlayEntry(
      builder: (context) {
        final targetSize = box.size;

        return Positioned.fill(
          child: _Tutorial(
            text: widget.text,
            barrierColor: widget.barrierColor,
            arrowColor: widget.arrowColor,
            target: Rect.fromCenter(
              center: box.localToGlobal(
                targetSize.center(Offset.zero),
                ancestor: overlay.context.findRenderObject(),
              ),
              width: targetSize.width,
              height: targetSize.height,
            ),
            textDirection: widget.textDirection,
            padding: widget.padding,
            behavior: widget.targetHitBehavior,
            onPointerDown: _recognizer.addPointer,
            progress: _animationController.view,
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    _animationController.forward();
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;

    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return _TutorialTarget(
      onRepaint: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry?.markNeedsBuild();
        });
      },
      child: RepaintBoundary(
        child: widget.child,
      ),
    );
  }
}

class _Tutorial extends LeafRenderObjectWidget {
  final InlineSpan text;
  final TextDirection? textDirection;

  final Color barrierColor;
  final Color arrowColor;

  final Rect target;
  final double padding;

  final HitTestBehavior behavior;
  final PointerDownEventListener? onPointerDown;

  final Animation<double>? progress;

  const _Tutorial({
    required this.text,
    required this.barrierColor,
    required this.arrowColor,
    required this.target,
    required this.behavior,
    required this.padding,
    this.textDirection,
    this.onPointerDown,
    this.progress,
  });

  Rect get _resultTarget => Rect.fromCenter(
    center: target.center,
    width: target.width + padding,
    height: target.height + padding,
  );

  @override
  _RenderTutorial createRenderObject(BuildContext context) {
    return _RenderTutorial(
      text: text,
      textDirection: textDirection ?? Directionality.of(context),
      barrierColor: barrierColor,
      arrowColor: arrowColor,
      target: _resultTarget,
      behavior: behavior,
      onPointerDown: onPointerDown,
      progress: progress,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context,
      _RenderTutorial renderObject,
      ) {
    renderObject
      ..text = text
      ..textDirection = textDirection ?? Directionality.of(context)
      ..barrierColor = barrierColor
      ..arrowColor = arrowColor
      ..target = _resultTarget
      ..behavior = behavior
      ..onPointerDown = onPointerDown
      ..progress = progress;
  }

  @override
  LeafRenderObjectElement createElement() => _TutorialElement(this);
}

class _RenderTutorial extends RenderBox {
  TextPainter _textPainter;

  Rect _target;

  HitTestBehavior behavior;
  PointerDownEventListener? onPointerDown;

  Animation<double>? _progress;

  final Paint _barrierPaint;
  final Paint _arrowPaint;

  _RenderTutorial({
    required InlineSpan text,
    required TextDirection textDirection,
    required Color barrierColor,
    required Color arrowColor,
    required Rect target,
    required this.behavior,
    this.onPointerDown,
    Animation<double>? progress,
  })  : _target = target,
        _progress = progress,
        _textPainter = TextPainter(
          text: text,
          textDirection: textDirection,
        )..layout(),
        _barrierPaint = Paint()..color = barrierColor,
        _arrowPaint = Paint()
          ..color = arrowColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

  set text(InlineSpan value) {
    if (value != _textPainter.text) {
      _textPainter = TextPainter(
        text: value,
        textDirection: _textPainter.textDirection,
      )..layout();
      markNeedsPaint();
    }
  }

  set textDirection(TextDirection value) {
    if (value != _textPainter.textDirection) {
      _textPainter = TextPainter(
        text: _textPainter.text,
        textDirection: value,
      )..layout();
      markNeedsPaint();
    }
  }

  set barrierColor(Color value) {
    if (value != _barrierPaint.color) {
      _barrierPaint.color = value;
      markNeedsPaint();
    }
  }

  set arrowColor(Color value) {
    if (value != _arrowPaint.color) {
      _arrowPaint.color = value;
      markNeedsPaint();
    }
  }

  Rect get target => _target;

  set target(Rect value) {
    if (value != _target) {
      _target = value;
      markNeedsPaint();
    }
  }

  Animation<double>? get progress => _progress;

  set progress(Animation<double>? value) {
    if (value != _progress) {
      if (attached) {
        _progress?.removeListener(markNeedsPaint);
        _progress?.addListener(markNeedsPaint);
      }

      _progress = value;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _progress?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress?.removeListener(markNeedsPaint);

    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() => size = constraints.biggest;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      onPointerDown?.call(event);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (target.contains(position)) {
      if (behavior != HitTestBehavior.deferToChild) {
        result.add(BoxHitTestEntry(this, position));
      }

      return behavior == HitTestBehavior.opaque;
    } else {
      result.add(BoxHitTestEntry(this, position));

      return true;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final screen = Offset.zero & size;
    final progress = this.progress?.value ?? 1;

    final barrier = BarrierPath.make(
      screen: screen,
      target: target,
      progress: progress,
    );

    canvas.drawPath(barrier, _barrierPaint);

    if (progress == 1) {
      final textSize = Size(
        _textPainter.width,
        _textPainter.height,
      );

      final textTopLeft = TextPositionHelper.find(
        screen: screen,
        target: target,
        textSize: textSize,
      );

      _textPainter.paint(canvas, textTopLeft);

      final arrowPath = ArrowPath.make(
        screen: screen,
        target: target,
        text: Rect.fromPoints(
          textTopLeft,
          Offset(
            textTopLeft.dx + textSize.width,
            textTopLeft.dy + textSize.height,
          ),
        ),
      );

      canvas.drawPath(arrowPath, _arrowPaint);
    }
  }
}

class _TutorialElement extends LeafRenderObjectElement {
  _TutorialElement(_Tutorial super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {}
}

class _TutorialTarget extends SingleChildRenderObjectWidget {
  final VoidCallback onRepaint;

  const _TutorialTarget({
    required this.onRepaint,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTutorialTarget(
      onRepaint: onRepaint,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context,
      _RenderTutorialTarget renderObject,
      ) {
    renderObject.onRepaint = onRepaint;
  }
}

class _RenderTutorialTarget extends RenderProxyBox {
  VoidCallback onRepaint;

  _RenderTutorialTarget({
    required this.onRepaint,
  });

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    onRepaint();
  }
}
