import 'package:flutter/foundation.dart';

/// A fixed-size ring of the most recent toasts, for a debug screen.
///
/// Replaces reaching into an app-specific logger: the package keeps the last
/// [capacity] entries and the host reads them whenever it wants.
class ToastHistory {
  ToastHistory({this.capacity = 20}) : assert(capacity > 0);

  final int capacity;
  final List<String> _entries = [];

  /// Most recent last.
  List<String> get entries => List.unmodifiable(_entries);

  void add(String entry) {
    _entries.add(entry);
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
  }

  void clear() => _entries.clear();

  /// A timestamp in the `HH:mm:ss.mmm` form used by the default entry format.
  static String timestamp([DateTime? at]) {
    final now = at ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}'
        '.${now.millisecond.toString().padLeft(3, '0')}';
  }
}

/// Called for every toast shown, for logging or analytics.
typedef ToastLogger = void Function(String entry);

/// Writes toast entries to the debug console.
void debugPrintToast(String entry) => debugPrint('[toast] $entry');
