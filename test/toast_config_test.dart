import 'package:flutter_test/flutter_test.dart';
import 'package:toast_overlay/toast_overlay.dart';

void main() {
  test('detects a reference id only when non-empty', () {
    const withId = ToastConfig(
      status: ToastStatus.error,
      title: 'x',
      referenceId: 'abc',
    );
    const empty = ToastConfig(
      status: ToastStatus.error,
      title: 'x',
      referenceId: '',
    );
    const none = ToastConfig(status: ToastStatus.error, title: 'x');

    expect(withId.hasReferenceId, isTrue);
    expect(empty.hasReferenceId, isFalse);
    expect(none.hasReferenceId, isFalse);
  });

  test('detects a subtitle only when non-empty', () {
    const withSubtitle = ToastConfig(
      status: ToastStatus.info,
      title: 'x',
      subtitle: 'y',
    );

    expect(withSubtitle.hasSubtitle, isTrue);
    expect(
      const ToastConfig(status: ToastStatus.info, title: 'x', subtitle: '')
          .hasSubtitle,
      isFalse,
    );
  });

  test('clearDuration removes the auto-dismiss timer', () {
    const config = ToastConfig(status: ToastStatus.info, title: 'x');

    expect(config.isAutoDismissing, isTrue);
    expect(config.copyWith(clearDuration: true).isAutoDismissing, isFalse);
  });

  test('compares by value', () {
    const a = ToastConfig(status: ToastStatus.info, title: 'x');
    const b = ToastConfig(status: ToastStatus.info, title: 'x');
    const c = ToastConfig(status: ToastStatus.error, title: 'x');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });

  group('enums', () {
    test('expose a stable shortName', () {
      expect(ToastStatus.error.shortName, 'error');
      expect(ToastPosition.bottom.shortName, 'bottom');
    });

    test('entrance offset moves the toast toward its anchored edge', () {
      expect(ToastPosition.top.entranceYOffset, isNegative);
      expect(ToastPosition.bottom.entranceYOffset, isPositive);
      expect(ToastPosition.top.isTop, isTrue);
    });
  });

  group('ToastHistory', () {
    test('keeps only the most recent entries', () {
      final history = ToastHistory(capacity: 2);

      history
        ..add('a')
        ..add('b')
        ..add('c');

      expect(history.entries, ['b', 'c']);
    });

    test('clear empties the ring', () {
      final history = ToastHistory()..add('a');

      history.clear();

      expect(history.entries, isEmpty);
    });

    test('formats a zero-padded timestamp', () {
      expect(
        ToastHistory.timestamp(DateTime(2026, 1, 1, 9, 5, 3, 7)),
        '09:05:03.007',
      );
    });
  });

  test('ToastStrings resolves a default title per status', () {
    const strings = ToastStrings(error: 'Oops');

    expect(strings.defaultTitle(ToastStatus.error), 'Oops');
    expect(strings.defaultTitle(ToastStatus.success), 'Success');
  });
}
