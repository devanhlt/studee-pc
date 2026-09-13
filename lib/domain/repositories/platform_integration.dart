import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Bytes captured from a screen region, camera, or gallery (never logged).
class CapturedImage extends Equatable {
  const CapturedImage({
    required this.bytes,
    required this.width,
    required this.height,
    this.mimeType = 'image/png',
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String mimeType;

  @override
  List<Object?> get props => [bytes, width, height, mimeType];
}

/// Configurable global shortcut binding.
class ShortcutDefinition extends Equatable {
  const ShortcutDefinition({
    required this.id,
    required this.key,
    this.modifiers = const [],
    this.description,
  });

  final String id;
  final String key;
  final List<String> modifiers;
  final String? description;

  @override
  List<Object?> get props => [id, key, modifiers, description];
}

/// Fired when a registered global shortcut is pressed.
class DesktopShortcutEvent extends Equatable {
  const DesktopShortcutEvent({
    required this.shortcutId,
    required this.triggeredAt,
  });

  final String shortcutId;
  final DateTime triggeredAt;

  @override
  List<Object?> get props => [shortcutId, triggeredAt];
}

/// OS-level capture, overlay, and shortcut integration for desktop and mobile.
abstract interface class PlatformIntegration {
  /// Region screen capture (desktop only).
  bool get supportsScreenCapture;

  /// Live camera capture (mobile only).
  bool get supportsCamera;

  /// Always-on-top overlay window (desktop only).
  bool get supportsOverlay;

  Future<void> setAlwaysOnTop(bool enabled);

  Future<void> setClickThrough(bool enabled);

  Future<void> showOverlay();

  Future<void> hideOverlay();

  /// Desktop region capture. Returns null on platforms without screen capture.
  Future<CapturedImage?> captureRegion();

  /// Mobile camera capture. Returns null on platforms without a camera UI.
  Future<CapturedImage?> captureFromCamera();

  /// Pick an existing image (file picker on desktop, gallery on mobile).
  Future<CapturedImage?> pickImage();

  /// Opens macOS Screen Recording privacy settings (no-op elsewhere).
  Future<void> openScreenCaptureSettings();

  /// Whether macOS reports Screen Recording access for this process.
  Future<bool> isScreenCaptureAllowed();

  /// Clears stale Screen Recording TCC entries (Debug + packaged), then
  /// re-prompts. Use when System Settings shows "on" but capture still fails.
  Future<void> resetAndRequestScreenCaptureAccess();

  Future<void> registerGlobalShortcut(ShortcutDefinition shortcut);

  Stream<DesktopShortcutEvent> get shortcutEvents;
}
