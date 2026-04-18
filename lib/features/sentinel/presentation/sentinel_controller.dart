import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/risk_score.dart';
import '../data/sentinel_repository.dart';
import '../domain/sentinel_service.dart';

/// Sentinel state
class SentinelState {
  final RiskScore? riskScore;
  final bool isLoading;
  final bool nightWatchActive;
  final String? error;

  const SentinelState({
    this.riskScore,
    this.isLoading = false,
    this.nightWatchActive = false,
    this.error,
  });

  SentinelState copyWith({
    RiskScore? riskScore,
    bool? isLoading,
    bool? nightWatchActive,
    String? error,
  }) {
    return SentinelState(
      riskScore: riskScore ?? this.riskScore,
      isLoading: isLoading ?? this.isLoading,
      nightWatchActive: nightWatchActive ?? this.nightWatchActive,
      error: error,
    );
  }
}

/// Sentinel controller
class SentinelController extends StateNotifier<SentinelState> {
  final SentinelService _sentinelService;

  SentinelController(this._sentinelService) : super(const SentinelState());

  Future<void> loadRiskScore() async {
    state = state.copyWith(isLoading: true);

    try {
      final riskScore = await _sentinelService.getCurrentRiskScore();
      state = state.copyWith(
        riskScore: riskScore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleNightWatch() async {
    final isActive = state.nightWatchActive;

    try {
      if (isActive) {
        await _sentinelService.deactivateNightWatch();
        state = state.copyWith(nightWatchActive: false);
      } else {
        await _sentinelService.activateNightWatch();
        state = state.copyWith(nightWatchActive: true);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Sentinel service provider
final sentinelServiceProvider = Provider<SentinelService>((ref) {
  return SentinelRepository();
});

/// Sentinel controller provider
final sentinelControllerProvider =
    StateNotifierProvider<SentinelController, SentinelState>((ref) {
  return SentinelController(ref.watch(sentinelServiceProvider));
});
