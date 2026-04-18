import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/risk_prediction_request.dart';
import '../../../core/models/risk_score.dart';
import '../../../core/models/risk_score_response.dart';
import '../domain/intelligence_service.dart';

class IntelligenceRepository implements IntelligenceService {
  @override
  Future<RiskScore> scanLocation(double latitude, double longitude) async {
    final request = RiskPredictionRequest.fromLocation(
      latitude: latitude,
      longitude: longitude,
    );

    final response = await http
        .post(
          Uri.parse(ApiEndpoints.predict),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HttpException('Prediction failed (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RiskScoreResponse.fromJson(json).toRiskScore();
  }

  @override
  Future<List<RiskScore>> getRiskHistory() async {
    return const [];
  }
}
