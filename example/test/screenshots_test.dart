// Renders the README screenshots from the real widgets, so they can be
// regenerated whenever the toast changes:
//
//   cd example && flutter test --update-goldens test/screenshots_test.dart
//
// The image lands in ../../screenshots/ and is shown in README.md.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toast_overlay/toast_overlay.dart';
import 'package:toast_overlay_example/example_toast_theme.dart';

/// A card, laid out exactly as the overlay lays it out, on a plain backdrop.
Widget _card(ToastConfig config) => ToastCard(
      config: config,
      strings: const ToastStrings(),
      animation: const AlwaysStoppedAnimation(1),
      onDismiss: _noop,
    );

void _noop() {}

Widget _canvas(
  List<Widget> cards, {
  Alignment alignment = Alignment.center,
  double spacing = 8,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BFF)),
        extensions: const [exampleToastTheme],
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Align(
          alignment: alignment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                cards[i],
              ],
            ],
          ),
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

/// `flutter test` renders text with the placeholder Ahem font unless real
/// fonts are registered, so load the ones the toast actually draws with: Roboto
/// and Material Icons from the Flutter SDK, and Remix Icons from pub-cache.
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final materialFonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    await (FontLoader(family)
          ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer))))
        .load();
  }

  await load('Roboto', '$materialFonts/Roboto-Regular.ttf');
  await load('MaterialIcons', '$materialFonts/MaterialIcons-Regular.otf');

  final remix = Directory('${Platform.environment['HOME']}'
          '/.pub-cache/hosted/pub.dev')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.split('/').last.startsWith('remixicon-'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (remix.isNotEmpty) {
    await load(
        'packages/remixicon/remix', '${remix.last.path}/fonts/remix.ttf');
  }
}

/// Renders [widget] at [size] logical pixels and writes it to
/// `screenshots/<name>.png`.
Future<void> _shot(
  WidgetTester tester,
  String name,
  Size size,
  Widget widget,
) async {
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await _pump(tester, widget);

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../screenshots/$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('one card per status', (tester) async {
    await _shot(
      tester,
      'alert',
      const Size(440, 320),
      _canvas([
        _card(const ToastConfig(
          status: ToastStatus.error,
          title: 'Invalid username or password',
          subtitle: 'The username or password you entered is incorrect.',
          offset: 0,
        )),
        _card(const ToastConfig(
          status: ToastStatus.warning,
          title: 'Low margin',
          subtitle: 'Consider closing some positions.',
          offset: 0,
        )),
        _card(const ToastConfig(
          status: ToastStatus.info,
          title: 'Market opens in 5 minutes',
          subtitle: 'Orders placed now are queued until the open.',
          offset: 0,
        )),
        _card(const ToastConfig(
          status: ToastStatus.success,
          title: 'Order placed',
          subtitle: 'Your position is now open.',
          offset: 0,
        )),
      ]),
    );
  });

  testWidgets('three toasts stacked against the top edge', (tester) async {
    await _shot(
      tester,
      'stacked',
      const Size(440, 250),
      _canvas(
        alignment: Alignment.topCenter,
        [
          // Only the card nearest the edge keeps its offset, exactly as
          // ToastStack lays them out.
          _card(const ToastConfig(
            status: ToastStatus.info,
            title: 'Syncing your positions',
            subtitle: 'This takes a moment on a slow connection.',
            offset: 24,
          )),
          _card(const ToastConfig(
            status: ToastStatus.warning,
            title: 'Low margin',
            subtitle: 'Consider closing some positions.',
            offset: 0,
          )),
          _card(const ToastConfig(
            status: ToastStatus.success,
            title: 'Positions synced',
            subtitle: 'Everything is up to date.',
            offset: 0,
          )),
        ],
      ),
    );
  });

  testWidgets('a toast anchored to the bottom edge', (tester) async {
    await _shot(
      tester,
      'bottom',
      const Size(440, 160),
      _canvas(
        alignment: Alignment.bottomCenter,
        [
          _card(const ToastConfig(
            status: ToastStatus.warning,
            title: 'Low margin',
            subtitle: 'Consider closing some positions.',
            position: ToastPosition.bottom,
            offset: 24,
          )),
        ],
      ),
    );
  });

  testWidgets('a reference id, with its copy button', (tester) async {
    await _shot(
      tester,
      'reference_id',
      const Size(440, 130),
      _canvas([
        _card(const ToastConfig(
          status: ToastStatus.error,
          title: 'Withdrawal failed',
          referenceId: 'REF-8F42-9001',
          offset: 0,
        )),
      ]),
    );
  });

  testWidgets('a title, a subtitle and a reference id', (tester) async {
    await _shot(
      tester,
      'subtitle_and_reference',
      const Size(440, 130),
      _canvas([
        _card(const ToastConfig(
          status: ToastStatus.error,
          title: 'Withdrawal failed',
          subtitle: 'Your bank declined the transfer. No funds have left '
              'your account.',
          referenceId: 'REF-8F42-9001',
          offset: 0,
        )),
      ]),
    );
  });
}
