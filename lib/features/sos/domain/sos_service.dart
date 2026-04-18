/// SOS service interface
abstract class SosService {
  /// Trigger SOS alert
  Future<bool> triggerSos();

  /// Cancel SOS alert
  Future<bool> cancelSos();

  /// Get SOS status
  Future<Map<String, dynamic>> getSosStatus();

  /// Check if SOS is active
  Future<bool> isSosActive();
}
