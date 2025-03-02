import 'dart:math' as math;
import 'dart:ui' as ui;

abstract final class ArrowPath {
  static ui.Path make({
    required ui.Rect screen,
    required ui.Rect target,
    required ui.Rect text,
    double edgePadding = 20,
    double tipLength = 15,
    double tipAngle = math.pi * 0.2,
  }) {
    final path = ui.Path();
    final line = _addLine(
      path,
      screen: screen,
      target: target,
      text: text,
      edgePadding: edgePadding,
    );
    final arrow = _addTip(
      line,
      tipLength: tipLength,
      tipAngle: tipAngle,
    );

    return arrow;
  }

  static ui.Path _addTip(
    ui.Path path, {
    required double tipLength,
    required double tipAngle,
  }) {
    path = ui.Path.from(path);

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) {
      return path;
    }

    final originalPosition = _getPathEndPosition(pathMetrics);
    if (originalPosition == null) {
      return path;
    }

    tipAngle = math.pi - tipAngle;
    final pathMetric = pathMetrics.last;

    final tangent = pathMetric.getTangentForOffset(pathMetric.length);
    if (tangent == null) {
      return path;
    }

    _addFullArrowTip(
      path: path,
      tangentVector: tangent.vector,
      tangentPosition: tangent.position,
      tipLength: tipLength,
      tipAngle: tipAngle,
    );

    return path;
  }

  static ui.Path _addLine(
    ui.Path path, {
    required ui.Rect screen,
    required ui.Rect target,
    required ui.Rect text,
    required double edgePadding,
  }) {
    path = ui.Path.from(path);

    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      return path;
    }

    final isTargetOnTop = screen.center.dy > target.center.dy;

    final startX = text.center.dx;
    final double startY;
    if (isTargetOnTop) {
      startY = text.top - edgePadding;
    } else {
      startY = text.bottom + edgePadding;
    }

    path.moveTo(startX, startY);

    if (target.left < (screen.center.dx + screen.left) / 2) {
      final endX = target.centerRight.dx + edgePadding;
      final endY = target.centerRight.dy;

      path.quadraticBezierTo(startX, endY, endX, endY);
    } else if (target.right > (screen.center.dx + screen.right) / 2) {
      final endX = target.centerLeft.dx - edgePadding;
      final endY = target.centerLeft.dy;

      path.quadraticBezierTo(startX, endY, endX, endY);
    } else {
      final dx = target.center.dx;
      if (isTargetOnTop) {
        path.lineTo(dx, target.bottom + edgePadding);
      } else {
        path.lineTo(dx, target.top - edgePadding);
      }
    }

    return path;
  }

  static void _addFullArrowTip({
    required ui.Path path,
    required ui.Offset tangentVector,
    required ui.Offset tangentPosition,
    required double tipLength,
    required double tipAngle,
  }) {
    _addPartialArrowTip(
      tangentVector: tangentVector,
      tangentPosition: tangentPosition,
      path: path,
      tipLength: tipLength,
      tipAngle: tipAngle,
    );
    _addPartialArrowTip(
      tangentVector: tangentVector,
      tangentPosition: tangentPosition,
      path: path,
      tipLength: tipLength,
      tipAngle: -tipAngle,
    );
  }

  static void _addPartialArrowTip({
    required ui.Path path,
    required ui.Offset tangentVector,
    required ui.Offset tangentPosition,
    required double tipLength,
    required double tipAngle,
  }) {
    final rotatedVector = _rotateVector(tangentVector, tipAngle);
    final tipVector = rotatedVector * tipLength;
    path.relativeMoveTo(tipVector.dx, tipVector.dy);
    path.relativeLineTo(-tipVector.dx, -tipVector.dy);
  }

  static ui.Offset? _getPathEndPosition(List<ui.PathMetric> pathMetrics) {
    final tangent = pathMetrics.last.getTangentForOffset(
      pathMetrics.last.length,
    );

    if (tangent == null) {
      return null;
    }

    return tangent.position;
  }

  static ui.Offset _rotateVector(ui.Offset vector, double angle) => ui.Offset(
        math.cos(angle) * vector.dx - math.sin(angle) * vector.dy,
        math.sin(angle) * vector.dx + math.cos(angle) * vector.dy,
      );
}
