import 'package:flutter/material.dart';
import 'package:toast_overlay/toast_overlay.dart';

void main() => runApp(const ExampleApp());

final _navigatorKey = GlobalKey<NavigatorState>();

/// A brand palette, wired in as a [ToastTheme] extension.
const _lightToastTheme = ToastTheme(
  surface: Color(0xFFF7F8FA),
  borderColor: Color(0xFFE5E7EB),
  titleColor: Color(0xFF0A0C12),
  subtitleColor: Color(0xFF6B7280),
  closeIconColor: Color(0xFF9CA3AF),
  statusColors: {
    ToastStatus.error: ToastStatusColors(
      background: Color(0xFFFEE4E2),
      foreground: Color(0xFFF04438),
    ),
    ToastStatus.success: ToastStatusColors(
      background: Color(0xFFD1FADF),
      foreground: Color(0xFF12B76A),
    ),
    ToastStatus.info: ToastStatusColors(
      background: Color(0xFFE4E9FF),
      foreground: Color(0xFF3B5BFF),
    ),
    ToastStatus.warning: ToastStatusColors(
      background: Color(0xFFFEF0C7),
      foreground: Color(0xFFF79009),
    ),
  },
  shadows: [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ],
);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Init once, as early as the navigator key exists.
    Toast.init(
      navigatorKey: _navigatorKey,
      strings: const ToastStrings(),
      logger: debugPrintToast,
    );

    return MaterialApp(
      title: 'toast_overlay example',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BFF)),
        extensions: const [_lightToastTheme],
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

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
                  title: '',
                  subtitle: 'Empty title falls back to the status default.',
                ),
                child: const Text('Info, default title'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
