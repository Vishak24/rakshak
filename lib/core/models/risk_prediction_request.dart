/// Request payload for /predict endpoint
class RiskPredictionRequest {
  final double latitude;
  final double longitude;
  final int pincode;
  final int hour;
  final int dayOfWeek;
  final int isWeekend;
  final int isNight;
  final int isEvening;
  final int isRushHour;
  final int reportingDelayMinutes;
  final int responseTimeMinutes;
  final int victimAge;
  final int signalCountLast7d;
  final int signalCountLast30d;
  final double signalDensityRatio;
  final int areaEncoded;
  final int neighborhoodEncoded;

  const RiskPredictionRequest({
    required this.latitude,
    required this.longitude,
    required this.pincode,
    required this.hour,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isNight,
    required this.isEvening,
    required this.isRushHour,
    required this.reportingDelayMinutes,
    required this.responseTimeMinutes,
    required this.victimAge,
    required this.signalCountLast7d,
    required this.signalCountLast30d,
    required this.signalDensityRatio,
    required this.areaEncoded,
    required this.neighborhoodEncoded,
  });

  /// Creates a request from lat/lon with time fields derived from now
  /// and sensible defaults for demographic/signal fields.
  factory RiskPredictionRequest.fromLocation({
    required double latitude,
    required double longitude,
    int pincode = 600001,
    int reportingDelayMinutes = 30,
    int responseTimeMinutes = 20,
    int victimAge = 25,
    int signalCountLast7d = 8,
    int signalCountLast30d = 35,
    double signalDensityRatio = 0.23,
    int areaEncoded = 3,
    int neighborhoodEncoded = 7,
  }) {
    final now = DateTime.now();
    final h = now.hour;
    final dow = now.weekday % 7; // 0=Sun … 6=Sat
    final weekend = (dow == 0 || dow == 6) ? 1 : 0;
    final night = (h >= 21 || h < 6) ? 1 : 0;
    final evening = (h >= 18 && h < 21) ? 1 : 0;
    final rushHour = ((h >= 8 && h <= 10) || (h >= 17 && h <= 19)) ? 1 : 0;

    return RiskPredictionRequest(
      latitude: latitude,
      longitude: longitude,
      pincode: pincode,
      hour: h,
      dayOfWeek: dow,
      isWeekend: weekend,
      isNight: night,
      isEvening: evening,
      isRushHour: rushHour,
      reportingDelayMinutes: reportingDelayMinutes,
      responseTimeMinutes: responseTimeMinutes,
      victimAge: victimAge,
      signalCountLast7d: signalCountLast7d,
      signalCountLast30d: signalCountLast30d,
      signalDensityRatio: signalDensityRatio,
      areaEncoded: areaEncoded,
      neighborhoodEncoded: neighborhoodEncoded,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'pincode': pincode,
        'hour': hour,
        'day_of_week': dayOfWeek,
        'is_weekend': isWeekend,
        'is_night': isNight,
        'is_evening': isEvening,
        'is_rush_hour': isRushHour,
        'reporting_delay_minutes': reportingDelayMinutes,
        'response_time_minutes': responseTimeMinutes,
        'victim_age': victimAge,
        'signal_count_last_7d': signalCountLast7d,
        'signal_count_last_30d': signalCountLast30d,
        'signal_density_ratio': signalDensityRatio,
        'area_encoded': areaEncoded,
        'neighborhood_encoded': neighborhoodEncoded,
      };
}
