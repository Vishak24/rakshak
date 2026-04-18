/// API Endpoints for Rakshak Sentinel
class ApiEndpoints {
  ApiEndpoints._();

  static const String base =
      'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com';

  static const String predict = '$base/predict';

  // Auth endpoints (future)
  static const String login = '$base/auth/login';
  static const String logout = '$base/auth/logout';
  static const String verifyOtp = '$base/auth/verify-otp';

  // SOS endpoints (future)
  static const String triggerSos = '$base/sos/trigger';
  static const String getSosStatus = '$base/sos/status';
  static const String cancelSos = '$base/sos/cancel';

  // User endpoints (future)
  static const String getUserProfile = '$base/user/profile';
  static const String getEmergencyContacts = '$base/user/contacts';
}
