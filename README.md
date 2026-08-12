# toast_overlay

An animated, themeable overlay toast for Flutter — with an auto-dismiss
countdown ring, and an optional support **reference id** the user can copy.

Unlike a `SnackBar`, it renders into the root `Overlay`, so it shows above
dialogs and bottom sheets and survives route changes. It has **no dependency on
your app's theme, assets or localisations** — you inject those.

## Install

```bash
flutter pub add toast_overlay
```

## Use

Initialise once with your root navigator key:

```dart
final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(navigatorKey: navigatorKey, /* … */);

Toast.init(navigatorKey: navigatorKey);
```

Then, from anywhere:

```dart
Toast.show(
  status: ToastStatus.success,
  title: 'Order placed',
  subtitle: 'Your position is now open.',
);
```

| Parameter | Default | Meaning |
| --- | --- | --- |
| `status` | — | `error`, `success`, `info`, `warning` |
| `title` | — | Falls back to the status default when empty |
| `subtitle` | null | Secondary line, up to 3 lines |
| `referenceId` | null | Shown with a copy button; **disables auto-dismiss** |
| `position` | `top` | `top` or `bottom` |
| `offset` | `kToolbarHeight` | Distance from the anchored edge |
| `duration` | 3s | `null` keeps it up until dismissed |

## Reference ids

On an error you often want to hand the user something to quote to support. Pass
a `referenceId` and the toast renders `Ref: <id>` with a copy button — and
**stops auto-dismissing**, because a toast that vanishes while you are copying
it is useless.

```dart
Toast.show(
  status: ToastStatus.error,
  title: 'Withdrawal failed',
  referenceId: response.traceId,
);
```

## Theming

Register a `ToastTheme` extension and the toast follows your light and dark
themes:

```dart
MaterialApp(
  theme: ThemeData(extensions: const [ToastTheme(
    surface: Color(0xFFF7F8FA),
    borderColor: Color(0xFFE5E7EB),
    titleColor: Color(0xFF0A0C12),
    subtitleColor: Color(0xFF6B7280),
    closeIconColor: Color(0xFF9CA3AF),
    statusColors: {
      ToastStatus.success: ToastStatusColors(
        background: Color(0xFFD1FADF),
        foreground: Color(0xFF12B76A),
      ),
      // …
    },
  )]),
);
```

**If you register nothing, it still works** — the palette is derived from the
ambient `ColorScheme`.

`ToastTheme` also carries `titleStyle`, `subtitleStyle`, `shadows`, `cardShape`,
`iconShape`, `icons`, and a `glowBuilder` for painting a decorative backdrop
behind the card:

```dart
glowBuilder: (context, status) => Image.asset(
  'assets/patterns/${status.shortName}_glow.png',
  fit: BoxFit.fitWidth,
),
```

## Localisation

The package ships English defaults and takes the rest from you, so it never
needs to own your ARB files:

```dart
Toast.init(
  navigatorKey: navigatorKey,
  strings: ToastStrings(
    error: l10n.toastTypeError,
    success: l10n.toastTypeSuccess,
    info: l10n.toastTypeInfo,
    warning: l10n.toastTypeWarning,
    referencePrefix: l10n.refPrefix,
    closeLabel: l10n.dismissNotification,
    copyReferenceLabel: l10n.copyReferenceId,
  ),
);
```

The two labels are the accessibility labels on the close and copy buttons; both
buttons have 48×48 tap targets.

## Without the global facade

`Toast` is a convenience wrapper. Inject a `ToastController` instead if you
prefer explicit dependencies — it is what the widget tests use:

```dart
final controller = ToastController(
  overlayResolver: () => navigatorKey.currentState?.overlay,
  strings: const ToastStrings(),
  logger: debugPrintToast,
);

controller.show(const ToastConfig(
  status: ToastStatus.info,
  title: 'Hello',
));
```

`overlayResolver` returning null makes `show` a safe no-op, which is what you
want before the first route is mounted. The toast is still recorded in history,
so nothing is silently lost.

## History and logging

The controller keeps the last 20 toasts for a debug screen, and can forward each
one to your own logger:

```dart
Toast.init(navigatorKey: navigatorKey, logger: myLogger.info);

for (final entry in Toast.history.entries) {
  print(entry); // 14:03:21.881 [error] Withdrawal failed — Please contact support.
}
```

## Behaviour notes

- Showing a toast replaces any toast already on screen.
- The countdown ring is only drawn while a toast is auto-dismissing.
- The card is wrapped in a `RepaintBoundary` and passed as the `child` of its
  `AnimatedBuilder`, so the animation does not rebuild the content.
- The toast respects `SafeArea` on the edge it is anchored to.

## License

MIT
