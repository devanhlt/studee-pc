import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/backend/backend_config.dart';
import 'package:studee_pc/features/settings/application/activation_request_config.dart';

class PackagesCatalog {
  const PackagesCatalog({
    required this.enabled,
    required this.packages,
  });

  final bool enabled;
  final List<SellablePackage> packages;
}

/// Fetches the public sellable package catalog.
class PackagesClient {
  PackagesClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final AppLogger _log = AppLogger('PackagesClient');

  Future<Result<PackagesCatalog>> fetchCatalog() async {
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}${BackendConfig.packagesPath}',
      );
      final response = await _http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          NetworkFailure(
            userMessage: 'Không tải được danh sách gói. Thử lại nhé.',
            code: 'packages_http',
            details: 'HTTP ${response.statusCode}',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(
          NetworkFailure(
            userMessage: 'Phản hồi máy chủ không hợp lệ.',
            code: 'packages_bad_json',
          ),
        );
      }

      final enabled = decoded['enabled'] != false;
      final raw = decoded['packages'];
      if (raw is! List) {
        return const Failure(
          NetworkFailure(
            userMessage: 'Phản hồi máy chủ không hợp lệ.',
            code: 'packages_bad_shape',
          ),
        );
      }

      final packages = <SellablePackage>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          packages.add(SellablePackage.fromJson(item));
        } else if (item is Map) {
          packages.add(
            SellablePackage.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      packages.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });

      return Success(PackagesCatalog(enabled: enabled, packages: packages));
    } on Object catch (e) {
      _log.warning('fetchCatalog failed: ${e.runtimeType}');
      return Failure(
        NetworkFailure(
          userMessage: 'Không tải được danh sách gói. Thử lại nhé.',
          code: 'packages_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Convenience for callers that only want packages when display is enabled.
  Future<Result<List<SellablePackage>>> listPackages() async {
    final catalog = await fetchCatalog();
    return catalog.when(
      success: (c) {
        if (!c.enabled) {
          return const Failure(
            NetworkFailure(
              userMessage: 'Tạm thời không mở bán mã trên app.',
              code: 'packages_disabled',
            ),
          );
        }
        if (c.packages.isEmpty) {
          return const Failure(
            NetworkFailure(
              userMessage: 'Hiện chưa có gói nào để mua.',
              code: 'packages_empty',
            ),
          );
        }
        return Success(c.packages);
      },
      failure: Failure.new,
    );
  }
}
