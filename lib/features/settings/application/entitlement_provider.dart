import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/features/settings/application/quota_revision.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

/// Current activation token quota. `null` when no usable code is saved.
final entitlementProvider = FutureProvider<EntitlementInfo?>((ref) async {
  ref.watch(quotaRevisionProvider);
  final result = await ref.watch(settingsServiceProvider).fetchEntitlement();
  return result.when(
    success: (info) => info,
    failure: (_) => null,
  );
});
