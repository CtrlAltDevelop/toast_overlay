import 'package:material_ui/material_ui.dart';

/// A countdown ring drawn around [child].
///
/// [value] runs 0 → 1 as the toast's lifetime elapses; the ring is drawn
/// inverted so it empties as time runs out.
class ToastTimerProgress extends StatelessWidget {
  const ToastTimerProgress({
    super.key,
    required this.value,
    required this.color,
    required this.child,
    this.size = 20,
    this.strokeWidth = 1.5,
  });

  final Animation<double>? value;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = value?.value;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress == null ? null : 1.0 - progress,
            strokeWidth: strokeWidth,
            color: color,
          ),
          Center(child: child),
        ],
      ),
    );
  }
}
