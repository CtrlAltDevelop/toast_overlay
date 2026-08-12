# Changelog

## 0.1.0

Initial release.

- `Toast.show` / `ToastController` for overlay toasts with `error`, `success`,
  `info` and `warning` statuses, anchored top or bottom.
- Auto-dismiss with a countdown ring around the close button.
- Optional support `referenceId` rendered with a copy button; supplying one
  disables auto-dismiss so the user can copy it.
- `ToastTheme` extension for colours, text styles, shadows, shapes, icons and a
  `glowBuilder` backdrop, with a `ColorScheme`-derived fallback when none is
  registered.
- `ToastStrings` for host-supplied localisation, English by default.
- `ToastHistory` ring buffer and a `logger` callback.
- 48×48 tap targets and semantics labels on both action buttons.
