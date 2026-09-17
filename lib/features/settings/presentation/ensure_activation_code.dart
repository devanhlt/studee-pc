import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared copy when a backend-backed action needs an activation code.
const kMissingActivationCodeMessage =
    'Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.';

/// Returns true when an activation code is present.
///
/// Otherwise shows a warning SnackBar and opens Settings.
Future<bool> ensureActivationCode(
  BuildContext context, {
  required Future<bool> Function() hasCode,
  bool openSettings = true,
}) async {
  try {
    if (await hasCode()) return true;
  } on Object catch (_) {
    // Treat lookup failure as missing code so the user still gets a warning.
  }
  if (!context.mounted) return false;
  warnMissingActivationCode(context, openSettings: openSettings);
  return false;
}

/// SnackBar (+ optional Settings navigation) for a missing activation code.
void warnMissingActivationCode(
  BuildContext context, {
  bool openSettings = true,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(kMissingActivationCodeMessage)),
  );
  if (openSettings) context.push('/settings');
}

/// True when [message] is the standard missing-activation warning (or close).
bool isMissingActivationMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final m = message.toLowerCase();
  return m.contains('mã kích hoạt') || m.contains('kích hoạt để');
}
