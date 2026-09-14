import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped after token quota changes so [entitlementProvider] refetches.
final quotaRevisionProvider = StateProvider<int>((ref) => 0);

