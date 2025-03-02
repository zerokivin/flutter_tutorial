import 'dart:math' as math;
import 'dart:ui' as ui;

abstract final class BarrierPath {
  static ui.Path make({
    required ui.Rect screen,
    required ui.Rect target,
    required double progress,
  }) {
    final path = ui.Path();
    final barrier = _addBarrier(path, screen: screen);
    final barrierWithTarget = _addTarget(
      barrier,
      screen: screen,
      target: target,
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
        required double progress,
      }) {
    path = ui.Path.from(path);

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) {
      return path;
    }

    final maxSize = math.max(screen.width, screen.height);
    final targetRRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: target.center,
        width: maxSize * (1 - progress) + target.width,
        height: maxSize * (1 - progress) + target.height,
      ),
      ui.Radius.circular(16),
    );

    return ui.Path.combine(
      ui.PathOperation.difference,
      path,
      ui.Path()..addRRect(targetRRect),
    );
  }
}
