# toast_overlay

[![pub package](https://img.shields.io/pub/v/toast_overlay.svg)](https://pub.dev/packages/toast_overlay)
[![pub points](https://img.shields.io/pub/points/toast_overlay)](https://pub.dev/packages/toast_overlay/score)
[![CI](https://github.com/CtrlAltDevelop/toast_overlay/actions/workflows/ci.yml/badge.svg)](https://github.com/CtrlAltDevelop/toast_overlay/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/CtrlAltDevelop/toast_overlay/blob/main/LICENSE)

An animated, themeable overlay toast for Flutter — with an auto-dismiss
countdown ring, and an optional support **reference id** the user can copy.

Unlike a `SnackBar`, it renders into the root `Overlay`, so it shows above
dialogs and bottom sheets and survives route changes. It has **no dependency on
your app's theme, assets or localisations** — you inject those.

| Three stacked at the top | One anchored to the bottom | A reference id, with a subtitle above it |
| --- | --- | --- |
| ![Three stacked toasts](screenshots/stacked.png) | ![A toast anchored to the bottom](screenshots/bottom.png) | ![An error toast with a subtitle and a reference id](screenshots/subtitle_and_reference.png) |

## Install

```bash
flutter pub add toast_overlay
```

Or add it to `pubspec.yaml` yourself — it is a runtime dependency:

```yaml
dependencies:
  toast_overlay: ">=1.2.1 <2.0.0"
  material_ui: ">=1.0.0 <2.0.0"
```

then:

```bash
flutter pub get
```

### Requires `package:material_ui`

Since 1.0.0 this package builds on [`material_ui`][material_ui], the standalone
Material library, rather than `package:flutter/material.dart`. The two declare
separate types, so your app has to be on `material_ui` as well — otherwise
`ToastTheme` cannot be registered in your `ThemeData`.

If your app still imports `package:flutter/material.dart`, migrate it with
Flutter's own fix:

```bash
dart fix --apply --code=migrate_design_widgets
```

Staying on `package:flutter/material.dart` for now? Use `toast_overlay: ^0.3.0`.

It needs Flutter 3.44.0 or newer (Dart 3.12.0), which is `material_ui`'s own
floor.

[material_ui]: https://pub.dev/packages/material_ui

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
| `action` | null | A `ToastAction` button under the text — `Undo`, `Retry` |
| `onTap` | null | Called when the card body is tapped; dismisses after |
| `position` | `top` | `top` or `bottom` |
| `offset` | `kToolbarHeight` | Distance from the anchored edge |
| `duration` | 3s | `null` keeps it up until dismissed |
| `dismissible` | true | Whether a swipe towards the edge dismisses |
| `pauseOnHover` | true | Whether a hovering pointer pauses the countdown |

`Toast.show` returns the toast's id, which `Toast.dismissToast` takes to remove
that one toast with its exit animation:

```dart
final id = Toast.show(status: ToastStatus.info, title: 'Uploading…', duration: null);
await upload();
Toast.dismissToast(id);
```

`Toast.dismissAll()` animates every toast out; `Toast.dismiss()` cuts them
immediately, without the exit animation.

## Actions and taps

Give a toast a button, and the toast dismisses itself once it is pressed:

```dart
Toast.show(
  status: ToastStatus.info,
  title: 'Order cancelled',
  action: ToastAction(
    label: 'Undo',                 // supply it already localised
    onPressed: restoreOrder,
    dismissOnPressed: true,        // false keeps the toast up
  ),
);
```

`onTap` makes the whole card tappable — for a toast that opens the thing it is
about. The close and copy buttons keep working; they win the gesture arena.

## Dismissing

Beyond the close button, a toast is dismissed by a swipe towards its anchored
edge — up for a top toast, down for a bottom one. A drag past 40% of the card's
height, or a flick, sends it away; anything less springs back. Dragging the
other way does nothing, so it never fights a scroll underneath. Set
`dismissible: false` to pin a toast to the close button alone.

On desktop and web a pointer resting on the card pauses the countdown and
resumes it on the way out, so a toast does not vanish mid-sentence. A touch
pointer never hovers, so `pauseOnHover` costs nothing on mobile.

## Stacking

By default each toast replaces the one on screen. Raise `maxStack` and they
stack against their edge instead — the oldest drops off once the limit is hit:

```dart
Toast.init(
  navigatorKey: navigatorKey,
  maxStack: 3,      // 1 (the default) replaces instead of stacking
  stackSpacing: 8,  // gap between two cards
);
```

Top-anchored and bottom-anchored toasts stack separately, each against its own
edge, and only the card nearest the edge keeps its `offset`.

## Reference ids

When something fails you often want to hand the user something to quote to
support. Pass
a `referenceId` and the toast renders `Ref: <id>` with a copy button — and
**stops auto-dismissing**, because a toast that vanishes while you are copying
it is useless. It sits under the `subtitle` when you pass both, and works on
any status, not only `error`.

```dart
Toast.show(
  status: ToastStatus.error,
  title: 'Withdrawal failed',
  referenceId: response.traceId,
);
```

![An error toast with a reference id](screenshots/reference_id.png)

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

### Corners

`cardRadius` and `iconRadius` are `BorderRadius`, so corners can differ — 12 and
6 all round by default:

```dart
ToastTheme(
  // …
  cardRadius: BorderRadius.circular(20),
  iconRadius: const BorderRadius.only(
    topLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  ),
);
```

Pass `cardShape` or `iconShape` instead when you want a shape of your own; they
override the radii.

### Type

`fontFamily` swaps the typeface on every line. For finer control, `titleStyle`,
`subtitleStyle` and `referenceStyle` are used exactly as given — a weight,
colour or family you set there is never overwritten:

```dart
ToastTheme(
  // …
  fontFamily: 'Inter',
  titleStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  subtitleStyle: TextStyle(fontSize: 13, height: 1.3),
  referenceStyle: TextStyle(fontSize: 12, letterSpacing: 0.4),
);
```

### Everything else

`ToastTheme` also carries `shadows`, `icons`, `maxWidth`, the action button's
`actionColor` and `actionStyle`, and a `glowBuilder` for painting a decorative
backdrop behind the card:

```dart
glowBuilder: (context, status) => DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.08, 0.85],
      colors: [tint.withValues(alpha: 0), tint.withValues(alpha: 0.09)],
    ),
  ),
),
```

Return whatever you like — an `Image.asset` works too, but a gradient costs no
decode, no texture upload and no image cache, which is worth having on a layer
that is purely decorative. The glows in the screenshots above ship with the
example, not the package — see `example/lib/example_toast_theme.dart`.

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

The two labels are the accessibility labels on the close and copy buttons. The
close button keeps a 48×48 tap target — it is laid out over the card, so the
room costs the toast no height.

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

## Accessibility

- The title and subtitle are one live region, so a screen reader reads them as
  a unit. On platforms that support announcements the toast is also announced
  when it appears — assertively for an error, politely otherwise — because a
  toast in an overlay is otherwise easy to miss before it auto-dismisses.
- The close and copy buttons are laid out small but keep a 48dp tap target, and
  carry the labels from `ToastStrings`.
- The swipe is excluded from semantics: the close button is the accessible way
  out, and a drag handler would merge the card into one unusable node.

## Behaviour notes

- Showing a toast replaces any toast already on screen, unless `maxStack` is
  above 1.
- The card is capped at `ToastTheme.maxWidth` (520 by default) and centred, so
  it does not stretch across a desktop window. `double.infinity` restores the
  full-width card.
- The countdown ring is only drawn while a toast is auto-dismissing.
- The card is wrapped in a `RepaintBoundary` and passed as the `child` of its
  `AnimatedBuilder`, so the animation does not rebuild the content.
- The toast respects `SafeArea` on the edge it is anchored to.

## License

MIT
