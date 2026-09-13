import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';

/// Coordinates overlay capture / paste against [SolveService].
class OverlayController {
  OverlayController({
    required SolveService solveService,
    required PlatformIntegration desktop,
  })  : _solve = solveService,
        _desktop = desktop;

  final SolveService _solve;
  final PlatformIntegration _desktop;

  Future<CapturedImage?> captureRegion() => _desktop.captureRegion();

  Future<void> setAlwaysOnTop(bool enabled) =>
      _desktop.setAlwaysOnTop(enabled);

  SolveService get solve => _solve;
}

final overlayControllerProvider = Provider<OverlayController>((ref) {
  return OverlayController(
    solveService: ref.watch(solveServiceProvider),
    desktop: ref.watch(platformIntegrationProvider),
  );
});
