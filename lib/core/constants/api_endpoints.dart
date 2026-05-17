/// API Endpoints for Rakshak Sentinel
class ApiEndpoints {
  ApiEndpoints._();

  static const _base =
      'https://aksdwfbnn5.execute-api.ap-south-1.amazonaws.com';

  static const predict  = '$_base/predict';
  static const sos      = '$_base/sos';
  static const user     = '$_base/user';
  static const events   = '$_base/incidents';

  static const _gemmaBase = 'http://localhost:5001';
  static const gemmaCheckin  = '$_gemmaBase/gemma/checkin';
  static const gemmaEscalate = '$_gemmaBase/gemma/escalate';
}
