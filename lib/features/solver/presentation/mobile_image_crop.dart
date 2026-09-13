import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';

/// Whether this build should crop after camera/gallery pick.
bool get shouldCropMobileImages =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Writes [bytes] to a temp file, opens the native cropper, returns cropped
/// bytes. Returns null if the user cancels. Throws [ValidationFailure] on
/// cropper/IO failures.
Future<Uint8List?> cropImageBytes(
  BuildContext context, {
  required Uint8List bytes,
  String? preferredName,
  String mimeType = 'image/jpeg',
}) async {
  if (!shouldCropMobileImages) return bytes;
  if (bytes.isEmpty) {
    throw const ValidationFailure(
      userMessage: 'Ảnh không có nội dung. Chọn hoặc chụp lại nhé.',
      code: 'image_empty',
    );
  }

  final ext = mimeType.contains('png') ? 'png' : 'jpg';
  final dir = await getTemporaryDirectory();
  final source = File(
    p.join(
      dir.path,
      preferredName ??
          'studee_crop_src_${DateTime.now().millisecondsSinceEpoch}.$ext',
    ),
  );
  await source.writeAsBytes(bytes, flush: true);

  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      compressFormat: ext == 'png'
          ? ImageCompressFormat.png
          : ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh đề',
          toolbarColor: AppColors.surface,
          toolbarWidgetColor: AppColors.primaryText,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.accent,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          // Free-ratio only — no fixed 1:1 / 4:3 / 16:9 presets.
          hideBottomControls: true,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
          ],
        ),
        IOSUiSettings(
          title: 'Cắt ảnh đề',
          doneButtonTitle: 'Xong',
          cancelButtonTitle: 'Hủy',
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          aspectRatioLockEnabled: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );
    if (cropped == null) return null;
    final out = await cropped.readAsBytes();
    if (out.isEmpty) {
      throw const ValidationFailure(
        userMessage: 'Ảnh cắt không có nội dung. Thử lại nhé.',
        code: 'crop_empty',
      );
    }
    return Uint8List.fromList(out);
  } on AppFailure {
    rethrow;
  } on Object catch (e) {
    throw ValidationFailure(
      userMessage: 'Không cắt được ảnh. Thử chọn hoặc chụp lại nhé.',
      code: 'crop_failed',
      details: e.runtimeType.toString(),
    );
  } finally {
    try {
      if (await source.exists()) await source.delete();
    } on Object {
      // Best-effort cleanup.
    }
  }
}

/// Pick/camera/gallery, then crop on mobile. Returns null on user cancel.
/// Throws [AppFailure] on real errors so the UI can show a message.
Future<CapturedImage?> captureAndCropImage(
  BuildContext context, {
  required Future<CapturedImage?> Function() capture,
  required String emptyMessage,
}) async {
  final captured = await capture();
  if (captured == null) return null;
  if (captured.bytes.isEmpty) {
    throw ValidationFailure(
      userMessage: emptyMessage,
      code: 'image_empty',
    );
  }
  if (!shouldCropMobileImages) return captured;

  if (!context.mounted) return null;
  final cropped = await cropImageBytes(
    context,
    bytes: captured.bytes,
    mimeType: captured.mimeType,
  );
  if (cropped == null) return null;
  return CapturedImage(
    bytes: cropped,
    width: 0,
    height: 0,
    mimeType: captured.mimeType,
  );
}
