import 'package:flutter/material.dart';
import 'package:toast_overlay/toast_overlay.dart';

import 'example_toast_theme.dart';

void main() => runApp(const ExampleApp());

final _navigatorKey = GlobalKey<NavigatorState>();

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Init once, as early as the navigator key exists.
    Toast.init(
      navigatorKey: _navigatorKey,
      strings: const ToastStrings(),
      logger: debugPrintToast,
      // Let up to three toasts stack against their edge; a fourth pushes the
      // oldest one out. Leave it at 1 to replace instead.
      maxStack: 3,
    );

    return MaterialApp(
      title: 'toast_overlay example',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BFF)),
        extensions: const [exampleToastTheme],
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  /// Shows three toasts in a row, which `maxStack: 3` keeps all on screen.
  void _showStack() {
    Toast.show(
      status: ToastStatus.info,
      title: 'Syncing your positions',
      subtitle: 'This takes a moment on a slow connection.',
      duration: const Duration(seconds: 6),
    );
    Toast.show(
      status: ToastStatus.warning,
      title: 'Low margin',
      subtitle: 'Consider closing some positions.',
      duration: const Duration(seconds: 6),
    );
    Toast.show(
      status: ToastStatus.success,
      title: 'Positions synced',
      subtitle: 'Everything is up to date.',
      duration: const Duration(seconds: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('toast_overlay')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => Toast.show(
                  status: ToastStatus.success,
                  title: 'Order placed',
                  subtitle: 'Your position is now open.',
                ),
                child: const Text('Success'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Toast.show(
                  status: ToastStatus.warning,
                  title: 'Low margin',
                  subtitle: 'Consider closing some positions.',
                  position: ToastPosition.bottom,
                ),
                child: const Text('Warning, from the bottom'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Toast.show(
                  status: ToastStatus.error,
                  title: 'Withdrawal failed',
                  subtitle: 'Please contact support.',
                  // A reference id disables auto-dismiss so it can be copied.
                  referenceId: 'REF-8F42-9001',
                ),
                child: const Text('Error, with a reference id'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Toast.show(
                  status: ToastStatus.info,
                  title: 'Market opens in 5 minutes',
                  subtitle: 'Orders placed now are queued until the open.',
                ),
                child: const Text('Info'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _showStack,
                child: const Text('Three at once, stacked'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
