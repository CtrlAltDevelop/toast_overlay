import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toast_overlay/toast_overlay.dart';

/// Pumps an app whose navigator key the controller resolves against, and
/// returns the controller.
Future<ToastController> _pumpApp(WidgetTester tester, {int maxStack = 1}) async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );

  return ToastController(
    overlayResolver: () => navigatorKey.currentState?.overlay,
    maxStack: maxStack,
  );
}

Future<void> _settleIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('action', () {
    testWidgets('runs its callback and dismisses the toast', (tester) async {
      final controller = await _pumpApp(tester);
      var pressed = 0;

      controller.show(
        ToastConfig(
          status: ToastStatus.info,
          title: 'Message archived',
          duration: null,
          action: ToastAction(label: 'Undo', onPressed: () => pressed++),
        ),
      );
      await _settleIn(tester);

      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(pressed, 1);
      expect(find.text('Message archived'), findsNothing);
    });

    testWidgets('keeps the toast up when it asks to', (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        ToastConfig(
          status: ToastStatus.info,
          title: 'Retrying',
          duration: null,
          action: ToastAction(
            label: 'Retry',
            onPressed: () {},
            dismissOnPressed: false,
          ),
        ),
      );
      await _settleIn(tester);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retrying'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
    });
  });

  group('onTap', () {
    testWidgets('fires and dismisses when the card is tapped', (tester) async {
      final controller = await _pumpApp(tester);
      var tapped = 0;

      controller.show(
        ToastConfig(
          status: ToastStatus.info,
          title: 'Open the order',
          duration: null,
          onTap: () => tapped++,
        ),
      );
      await _settleIn(tester);

      await tester.tap(find.text('Open the order'));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.text('Open the order'), findsNothing);
    });

    testWidgets('leaves the card inert when null', (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Just a message',
          duration: null,
        ),
      );
      await _settleIn(tester);

      await tester.tap(find.text('Just a message'));
      await tester.pumpAndSettle();

      expect(find.text('Just a message'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
    });
  });

  group('swipe', () {
    testWidgets('a flick towards the edge dismisses', (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Flick me',
          duration: null,
        ),
      );
      await _settleIn(tester);

      await tester.fling(find.text('Flick me'), const Offset(0, -200), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Flick me'), findsNothing);
    });

    testWidgets('a flick away from the edge does not', (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Stay put',
          duration: null,
        ),
      );
      await _settleIn(tester);

      await tester.fling(find.text('Stay put'), const Offset(0, 200), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Stay put'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('is off when dismissible is false', (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Pinned',
          duration: null,
          dismissible: false,
        ),
      );
      await _settleIn(tester);

      await tester.fling(find.text('Pinned'), const Offset(0, -200), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Pinned'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
    });
  });

  group('dismissToast', () {
    testWidgets('removes one toast and leaves the rest', (tester) async {
      final controller = await _pumpApp(tester, maxStack: 2);

      final first = controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'First',
          duration: null,
        ),
      );
      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Second',
          duration: null,
        ),
      );
      await _settleIn(tester);

      controller.dismissToast(first);
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(controller.visibleCount, 1);

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('ignores an unknown id', (tester) async {
      final controller = await _pumpApp(tester);
      expect(() => controller.dismissToast('nope'), returnsNormally);
    });

    testWidgets('dismissAll empties the stack', (tester) async {
      final controller = await _pumpApp(tester, maxStack: 3);

      for (final title in ['A', 'B']) {
        controller.show(
          ToastConfig(
            status: ToastStatus.info,
            title: title,
            duration: null,
          ),
        );
      }
      await _settleIn(tester);

      controller.dismissAll();
      await tester.pumpAndSettle();

      expect(controller.visibleCount, 0);
      expect(controller.isShowing, isFalse);
    });
  });

  group('auto-dismiss', () {
    testWidgets('a hover pauses the countdown and leaving resumes it',
        (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Hover me',
          duration: Duration(seconds: 3),
        ),
      );
      await _settleIn(tester);

      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: tester.getCenter(find.text('Hover me')));
      addTearDown(pointer.removePointer);
      await tester.pump();

      // Well past the three seconds the toast would otherwise have lived.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Hover me'), findsOneWidget);

      await pointer.moveTo(const Offset(0, 590));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.text('Hover me'), findsNothing);
    });

    testWidgets('a toast with a reference id never auto-dismisses',
        (tester) async {
      final controller = await _pumpApp(tester);

      controller.show(
        const ToastConfig(
          status: ToastStatus.error,
          title: 'Order rejected',
          referenceId: 'ERR-42',
        ),
      );
      await _settleIn(tester);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Order rejected'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
    });
  });

  testWidgets('the reference id shows on any status, not just errors',
      (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.warning,
        title: 'Partially filled',
        referenceId: 'WRN-7',
      ),
    );
    await _settleIn(tester);

    expect(find.textContaining('WRN-7'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('the card is capped at the theme maxWidth', (tester) async {
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'Not this wide',
        duration: null,
      ),
    );
    await _settleIn(tester);

    final card = tester.getSize(
      find
          .descendant(of: find.byType(ToastCard), matching: find.byType(Stack))
          .first,
    );
    expect(card.width, lessThanOrEqualTo(520));

    controller.dismiss();
    await tester.pump();
  });
}
