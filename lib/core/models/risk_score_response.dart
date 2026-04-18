import 'risk_score.dart';

/// DTO for /predict response
class RiskScoreResponse {
  final String riskLevel;
  final int riskIndex;
  final double confidence;
  final RiskProbabilities probabilities;

  const RiskScoreResponse({
    required this.riskLevel,
    required this.riskIndex,
    required this.confidence,
    required this.probabilities,
  });

  factory RiskScoreResponse.fromJson(Map<String, dynamic> json) {
    return RiskScoreResponse(
      riskLevel: (json['risk_level'] as String).toUpperCase(),
      riskIndex: (json['risk_index'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: RiskProbabilities.fromJson(
        json['probabilities'] as Map<String, dynamic>,
      ),
    );
  }

  /// Maps to the app's RiskScore domain model
  RiskScore toRiskScore({String location = 'Current Location'}) {
    return RiskScore(
      score: riskIndex,
      level: _parseLevel(riskLevel),
      location: location,
      timestamp: DateTime.now(),
      factors: [
        'confidence: ${(confidence * 100).toStringAsFixed(0)}%',
        'high: ${(probabilities.high * 100).toStringAsFixed(0)}%',
        'medium: ${(probabilities.medium * 100).toStringAsFixed(0)}%',
        'low: ${(probabilities.low * 100).toStringAsFixed(0)}%',
      ],
    );
  }

  static RiskLevel _parseLevel(String level) {
    switch (level) {
      case 'LOW':
        return RiskLevel.low;
      case 'MEDIUM':
        return RiskLevel.medium;
      case 'HIGH':
        return RiskLevel.high;
      case 'CRITICAL':
        return RiskLevel.critical;
      default:
        return RiskLevel.medium;
    }
  }
}

class RiskProbabilities {
  final double low;
  final double medium;
  final double high;

  const RiskProbabilities({
    required this.low,
    required this.medium,
    required this.high,
  });

  factory RiskProbabilities.fromJson(Map<String, dynamic> json) {
    return RiskProbabilities(
      low: (json['low'] as num).toDouble(),
      medium: (json['medium'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
    );
  }
}
