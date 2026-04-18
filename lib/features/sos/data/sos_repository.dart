import '../../../core/constants/stub_data.dart';
import '../domain/sos_service.dart';

/// Stub implementation of SosService
class SosRepository implements SosService {
  bool _sosActive = false;

  @override
  Future<bool> triggerSos() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _sosActive = true;
    return true;
  }

  @override
  Future<bool> cancelSos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sosActive = false;
    return true;
  }

  @override
  Future<Map<String, dynamic>> getSosStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sosActive ? StubData.sosActive : StubData.sosSecured;
  }

  @override
  Future<bool> isSosActive() async {
    return _sosActive;
  }
}
