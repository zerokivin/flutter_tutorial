import 'dart:ui' as ui;

class TextPositionHelper {
  static ui.Offset find({
    required ui.Rect screen,
    required ui.Rect target,
    required ui.Size textSize,
    double minimalEdgePadding = 16,
  }) {
    ui.Offset result;
    final dx = screen.center.dx - textSize.width / 2;
    if (target.center.dy > screen.center.dy) {
      result = ui.Offset(
        dx,
        (target.top + screen.top - textSize.height) / 2,
      );
    } else {
      result = ui.Offset(
        dx,
        (screen.bottom + target.bottom - textSize.height) / 2,
      );
    }

    if (result.dy < screen.top) {
      result = ui.Offset(
        result.dx,
        screen.top + minimalEdgePadding,
      );
    } else if (result.dy + textSize.height > screen.bottom) {
      result = ui.Offset(
        result.dx,
        screen.bottom - textSize.height - minimalEdgePadding,
      );
    }

    return result;
  }
}
