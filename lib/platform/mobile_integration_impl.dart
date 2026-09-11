import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/desktop_integration.dart';

/// Mobile adapter: no overlay/hotkeys; “capture” opens the photo library.
///
/// Live camera stays in UI ([showCameraCaptureDialog]). This covers shared
/// [DesktopIntegration.captureRegion] call sites (Solve / Ingest screenshot).
class MobileIntegrationImpl implements DesktopIntegration {
  MobileIntegrationImpl();

  final AppLogger _log = AppLogger('MobileIntegration');
  final StreamController<DesktopShortcutEvent> _shortcutController =
      StreamController<DesktopShortcutEvent>.broadcast();

  void dispose() {
    unawaited(_shortcutController.close());
  }

  @override
  Stream<DesktopShortcutEvent> get shortcutEvents => _shortcutController.stream;

  @override
  Future<void> setAlwaysOnTop(bool enabled) async {}

  @override
  Future<void> setClickThrough(bool enabled) async {}

  @override
  Future<void> showOverlay() async {}

  @override
  Future<void> hideOverlay() async {}

  @override
  Future<void> openScreenCaptureSettings() async {}

  @override
  Future<bool> isScreenCaptureAllowed() async => true;

  @override
  Future<void> resetAndRequestScreenCaptureAccess() async {}

  @override
  Future<void> registerGlobalShortcut(ShortcutDefinition shortcut) async {}

  @override
  Future<CapturedImage?> captureRegion() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      final files = result?.files;
      if (files == null || files.isEmpty) return null;
      final file = files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return null;

      final name = file.name.toLowerCase();
      final mime = name.endsWith('.jpg') || name.endsWith('.jpeg')
          ? 'image/jpeg'
          : 'image/png';

      return CapturedImage(
        bytes: Uint8List.fromList(bytes),
        width: 0,
        height: 0,
        mimeType: mime,
      );
    } on Object catch (e) {
      _log.warning('captureRegion (gallery) failed: ${e.runtimeType}');
      return null;
    }
  }
}
