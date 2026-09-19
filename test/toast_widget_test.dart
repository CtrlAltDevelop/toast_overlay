import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toast_overlay/toast_overlay.dart';

/// Pumps an app whose navigator key the controller resolves against, and
/// returns the controller.
Future<ToastController> _pumpApp(
  WidgetTester tester, {
  ToastStrings strings = const ToastStrings(),
  ToastStrings Function(BuildContext)? stringsBuilder,
  ToastTheme? toastTheme,
  ToastLogger? logger,
  int maxStack = 1,
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        extensions: toastTheme == null
            ? const <ThemeExtension>[]
            : [toastTheme],
      ),
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );

  return ToastController(
    overlayResolver: () => navigatorKey.currentState?.overlay,
    strings: strings,
    stringsBuilder: stringsBuilder,
    logger: logger,
    maxStack: maxStack,
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

    controller.show(const ToastConfig(status: ToastStatus.warning, title: ''));
    await tester.pump();

    expect(find.text('Heads up'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
  });

  testWidgets('stringsBuilder resolves against the toast context', (
    tester,
  ) async {
    final controller = await _pumpApp(
      tester,
      strings: const ToastStrings(warning: 'static'),
      // Resolved per toast, so it follows a locale change instead of being
      // frozen at controller-construction time.
      stringsBuilder: (context) => ToastStrings(
        warning: Directionality.of(context) == TextDirection.ltr
            ? 'resolved'
            : 'resolved-rtl',
      ),
    );

    controller.show(const ToastConfig(status: ToastStatus.warning, title: ''));
    await tester.pump();

    expect(find.text('resolved'), findsOneWidget);
    expect(find.text('static'), findsNothing);

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

  testWidgets('shows the subtitle and the reference id together', (
    tester,
  ) async {
    final controller = await _pumpApp(tester);

    controller.show(
      const ToastConfig(
        status: ToastStatus.error,
        title: 'Withdrawal failed',
        subtitle: 'Your bank declined the transfer.',
        referenceId: 'REF-123',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your bank declined the transfer.'), findsOneWidget);
    expect(find.text('Ref: REF-123'), findsOneWidget);

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

  group('stacking', () {
    testWidgets('keeps both toasts on screen when maxStack allows it', (
      tester,
    ) async {
      final controller = await _pumpApp(tester, maxStack: 3);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'First',
          duration: null,
        ),
      );
      controller.show(
        const ToastConfig(
          status: ToastStatus.success,
          title: 'Second',
          duration: null,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(controller.visibleCount, 2);

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('drops the oldest toast past the limit', (tester) async {
      final controller = await _pumpApp(tester, maxStack: 2);

      for (final title in ['First', 'Second', 'Third']) {
        controller.show(
          ToastConfig(status: ToastStatus.info, title: title, duration: null),
        );
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(controller.visibleCount, 2);

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('the toast nearest the edge keeps its offset', (tester) async {
      final controller = await _pumpApp(tester, maxStack: 2);

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'First',
          offset: 40,
          duration: null,
        ),
      );
      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Second',
          offset: 40,
          duration: null,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final cards = find.byType(ToastCard);
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));

      // The first card carries the 40pt gap from the edge; the second is only
      // the stack spacing below it, not another 40pt down.
      expect(first.top, 0);
      expect(second.top - first.bottom, closeTo(8, 0.5));

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('closing one stacked toast leaves the other', (tester) async {
      final controller = await _pumpApp(tester, maxStack: 2);

      controller.show(
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(ToastCloseButton).first);
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(controller.visibleCount, 1);

      controller.dismiss();
      await tester.pump();
    });
  });

  group('theme', () {
    testWidgets('cardRadius and iconRadius drive the default shapes', (
      tester,
    ) async {
      const theme = ToastTheme(
        surface: Color(0xFFFFFFFF),
        borderColor: Color(0xFFEEEEEE),
        titleColor: Color(0xFF000000),
        subtitleColor: Color(0xFF666666),
        closeIconColor: Color(0xFF999999),
        statusColors: {},
        cardRadius: BorderRadius.all(Radius.circular(24)),
        iconRadius: BorderRadius.all(Radius.circular(18)),
      );

      expect(theme.resolvedCardShape, isA<RoundedSuperellipseBorder>());
      final card = theme.resolvedCardShape as RoundedSuperellipseBorder;
      expect(card.borderRadius.resolve(TextDirection.ltr).topLeft.x, 24);

      final icon = theme.resolvedIconShape as RoundedSuperellipseBorder;
      expect(icon.borderRadius.resolve(TextDirection.ltr).topLeft.x, 18);

      // An explicit shape still wins.
      expect(
        theme.copyWith(cardShape: const StadiumBorder()).resolvedCardShape,
        isA<StadiumBorder>(),
      );
    });

    testWidgets('fontFamily applies to the title and subtitle', (tester) async {
      final controller = await _pumpApp(
        tester,
        toastTheme: const ToastTheme(
          surface: Color(0xFFFFFFFF),
          borderColor: Color(0xFFEEEEEE),
          titleColor: Color(0xFF000000),
          subtitleColor: Color(0xFF666666),
          closeIconColor: Color(0xFF999999),
          statusColors: {},
          fontFamily: 'Georgia',
        ),
      );

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Styled',
          subtitle: 'Also styled',
          duration: null,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.widget<Text>(find.text('Styled')).style?.fontFamily,
        'Georgia',
      );
      expect(
        tester.widget<Text>(find.text('Also styled')).style?.fontFamily,
        'Georgia',
      );

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('titleStyle keeps the weight and colour it sets', (
      tester,
    ) async {
      final controller = await _pumpApp(
        tester,
        toastTheme: const ToastTheme(
          surface: Color(0xFFFFFFFF),
          borderColor: Color(0xFFEEEEEE),
          titleColor: Color(0xFF000000),
          subtitleColor: Color(0xFF666666),
          closeIconColor: Color(0xFF999999),
          statusColors: {},
          titleStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: Color(0xFF112233),
          ),
        ),
      );

      controller.show(
        const ToastConfig(
          status: ToastStatus.info,
          title: 'Light title',
          duration: null,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final style = tester.widget<Text>(find.text('Light title')).style!;
      expect(style.fontWeight, FontWeight.w300);
      expect(style.color, const Color(0xFF112233));
      expect(style.fontSize, 20);

      controller.dismiss();
      await tester.pump();
    });

    testWidgets('referenceStyle styles the Ref line', (tester) async {
      final controller = await _pumpApp(
        tester,
        toastTheme: const ToastTheme(
          surface: Color(0xFFFFFFFF),
          borderColor: Color(0xFFEEEEEE),
          titleColor: Color(0xFF000000),
          subtitleColor: Color(0xFF666666),
          closeIconColor: Color(0xFF999999),
          statusColors: {},
          referenceStyle: TextStyle(fontSize: 11, color: Color(0xFF445566)),
        ),
      );

      controller.show(
        const ToastConfig(
          status: ToastStatus.error,
          title: 'Failed',
          referenceId: 'REF-7',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final style = tester.widget<Text>(find.text('Ref: REF-7')).style!;
      expect(style.fontSize, 11);
      expect(style.color, const Color(0xFF445566));

      controller.dismiss();
      await tester.pump();
    });
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

      Toast.show(status: ToastStatus.success, title: 'Global', duration: null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Global'), findsOneWidget);
      expect(Toast.history.entries, hasLength(1));

      Toast.dismiss();
      await tester.pump();
    });
  });
}
