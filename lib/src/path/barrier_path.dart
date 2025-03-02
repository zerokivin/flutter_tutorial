import 'dart:math' as math;
import 'dart:ui' as ui;

abstract final class BarrierPath {
  static ui.Path make({
    required ui.Rect screen,
    required ui.Rect target,
    required double targetBorderRadius,
    required double progress,
  }) {
    final path = ui.Path();
    final barrier = _addBarrier(path, screen: screen);
    final barrierWithTarget = _addTarget(
      barrier,
      screen: screen,
      target: target,
      targetBorderRadius: targetBorderRadius,
      progress: progress,
    );

    return barrierWithTarget;
  }

  static ui.Path _addBarrier(
      ui.Path path, {
        required ui.Rect screen,
      }) {
    path = ui.Path.from(path);

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      return path;
    }

    return path..addRect(screen);
  }

  static ui.Path _addTarget(
      ui.Path path, {
        required ui.Rect screen,
        required ui.Rect target,
        required double targetBorderRadius,
        required double progress,
      }) {
    path = ui.Path.from(path);

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) {
      return path;
    }

    final maxSize = math.max(screen.width, screen.height);
    final targetPath = ui.Path();
    final targetRect = ui.Rect.fromCenter(
      center: target.center,
      width: maxSize * (1 - progress) + target.width,
      height: maxSize * (1 - progress) + target.height,
    );

    if (targetBorderRadius > 0) {
      final targetRRect = ui.RRect.fromRectAndRadius(
        targetRect,
        ui.Radius.circular(targetBorderRadius),
      );

      targetPath.addRRect(targetRRect);
    } else {
      targetPath.addRect(targetRect);
    }

    return ui.Path.combine(
      ui.PathOperation.difference,
      path,
      targetPath,
    );
  }
}
