import '../../../core/constants/stub_data.dart';
import '../../../core/models/risk_score.dart';
import '../domain/sentinel_service.dart';

/// Stub implementation of SentinelService
class SentinelRepository implements SentinelService {
  bool _nightWatchActive = false;

  @override
  Future<RiskScore> getCurrentRiskScore() async {
    // Simulate API delay
    await Future.delayed(StubData.apiDelay);
    
    // Return medium risk as default
    return StubData.mediumRisk;
  }

  @override
  Future<bool> activateNightWatch() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _nightWatchActive = true;
    return true;
  }

  @override
  Future<bool> deactivateNightWatch() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _nightWatchActive = false;
    return true;
  }

  @override
  Future<bool> isNightWatchActive() async {
    return _nightWatchActive;
  }
}
