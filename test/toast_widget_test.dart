import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toast_overlay/toast_overlay.dart';

/// Pumps an app whose navigator key the controller resolves against, and
/// returns the controller.
Future<ToastController> _pumpApp(
  WidgetTester tester, {
  ToastStrings strings = const ToastStrings(),
  ToastTheme? toastTheme,
  ToastLogger? logger,
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        extensions:
            toastTheme == null ? const <ThemeExtension>[] : [toastTheme],
      ),
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );

  return ToastController(
    overlayResolver: () => navigatorKey.currentState?.overlay,
    strings: strings,
    logger: logger,
  );
}

void main() {
  testWidgets('shows the title and subtitle', (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.success,
        title: 'Order placed',
        subtitle: 'Your position is open.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Your position is open.'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('falls back to the status default title', (tester) async {
    final controller = await _pumpApp(
      tester,
      strings: const ToastStrings(warning: 'Heads up'),
    );

    controller.show(
      const ToastConfig(status: ToastStatus.warning, title: ''),
    );
    await tester.pump();

    expect(find.text('Heads up'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('auto-dismisses after its duration', (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'Transient',
        duration: Duration(seconds: 1),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Transient'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Transient'), findsNothing);
    expect(controller.isShowing, isFalse);
  });

  testWidgets('a reference id disables auto-dismiss', (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.error,
        title: 'Failed',
        referenceId: 'REF-123',
        duration: Duration(milliseconds: 100),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Still up: the user needs time to copy the id.
    expect(find.text('Ref: REF-123'), findsOneWidget);
    expect(controller.isShowing, isTrue);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('the close button dismisses', (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'Dismiss me',
        duration: null,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.bySemanticsLabel('Dismiss notification'));
    await tester.pumpAndSettle();

    expect(find.text('Dismiss me'), findsNothing);
  });

  testWidgets('copies the reference id to the clipboard', (tester) async {
    final controller = await _pumpApp(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    controller.show(
      const ToastConfig(
        status: ToastStatus.error,
        title: 'Failed',
        referenceId: 'REF-9',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.bySemanticsLabel('Copy reference id'));
    await tester.pump();

    expect(copied, 'REF-9');

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('showing a second toast replaces the first', (tester) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'First',
        duration: null,
      ),
    );
    await tester.pump();
    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'Second',
        duration: null,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('records history and calls the logger', (tester) async {
    final logged = <String>[];
    final controller = await _pumpApp(tester, logger: logged.add);

    controller.show(
      const ToastConfig(
        status: ToastStatus.error,
        title: 'Boom',
        subtitle: 'details',
        duration: null,
      ),
    );
    await tester.pump();

    expect(controller.history.entries.single, contains('[error] Boom'));
    expect(controller.history.entries.single, contains('details'));
    expect(logged.single, contains('[error] Boom'));

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('is a no-op when no overlay is available', (tester) async {
    final controller = ToastController(overlayResolver: () => null);

    controller.show(
      const ToastConfig(status: ToastStatus.info, title: 'Nowhere'),
    );

    expect(controller.isShowing, isFalse);
    // The toast is still recorded, so nothing is silently lost.
    expect(controller.history.entries, hasLength(1));
  });

  testWidgets('uses a registered ToastTheme', (tester) async {
    const surface = Color(0xFF123456);
    final controller = await _pumpApp(
      tester,
      toastTheme: const ToastTheme(
        surface: surface,
        borderColor: Color(0xFF000000),
        titleColor: Color(0xFFFFFFFF),
        subtitleColor: Color(0xFFCCCCCC),
        closeIconColor: Color(0xFFCCCCCC),
        statusColors: {},
      ),
    );

    controller.show(
      const ToastConfig(
        status: ToastStatus.info,
        title: 'Themed',
        duration: null,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final decoration = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<ShapeDecoration>()
        .toList();
    expect(decoration.any((d) => d.color == surface), isTrue);

    controller.dismiss();
    await tester.pump();
  });

  group('Toast facade', () {
    tearDown(Toast.reset);

    testWidgets('throws before init', (tester) async {
      expect(() => Toast.dismiss(), throwsStateError);
      expect(Toast.isInitialized, isFalse);
    });

    testWidgets('shows through the global instance', (tester) async {
      final controller = await _pumpApp(tester);
      Toast.initWith(controller);

      Toast.show(
        status: ToastStatus.success,
        title: 'Global',
        duration: null,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Global'), findsOneWidget);
      expect(Toast.history.entries, hasLength(1));

      Toast.dismiss();
      await tester.pump();
    });
  });
}
