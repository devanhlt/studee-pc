import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Shared desktop shortcut helpers (⌘ on macOS, Ctrl elsewhere).
///
/// On mobile, [label]/[tooltip]/[chord] return the bare title so buttons
/// do not show keyboard chords that do not apply.
abstract final class AppShortcuts {
  static bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static bool get _isApple => !kIsWeb && Platform.isMacOS;

  static bool get hasKeyboardShortcuts => _isDesktop;

  /// Modifier used with letter shortcuts (Meta on Apple, Control elsewhere).
  static SingleActivator activator(
    LogicalKeyboardKey key, {
    bool shift = false,
  }) {
    return SingleActivator(
      key,
      meta: _isApple,
      control: !_isApple,
      shift: shift,
    );
  }

  static String get mod => _isApple ? '⌘' : 'Ctrl';
  static String get shiftMod => _isApple ? '⇧⌘' : 'Ctrl+Shift';

  static String chord(String key, {bool shift = false, bool bare = false}) {
    final k = key.trim();
    if (bare || !_isDesktop) return k;
    if (shift) return '$shiftMod$k';
    return '$mod$k';
  }

  static String label(
    String title,
    String key, {
    bool shift = false,
    bool bare = false,
  }) {
    if (!_isDesktop) return title;
    return '$title (${chord(key, shift: shift, bare: bare)})';
  }

  static String tooltip(
    String title,
    String key, {
    bool shift = false,
    bool bare = false,
  }) {
    if (!_isDesktop) return title;
    return '$title · ${chord(key, shift: shift, bare: bare)}';
  }
}
