import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/generated_plan.dart';
import '../services/generated_plan_service.dart';

class GeneratedPlanProvider extends ChangeNotifier {
  bool _isLoading = false;
  ApiResponse<void>? _error;

  List<GeneratedPlan> _plans = [];
  GeneratedPlan? _active;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;

  bool get isLoading => _isLoading;
  ApiResponse<void>? get error => _error;
  List<GeneratedPlan> get plans => _plans;
  GeneratedPlan? get active => _active;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasNextPage => _hasNextPage;
  bool get hasPrevPage => _hasPrevPage;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    if (_isLoading != v) {
      _isLoading = v;
      notifyListeners();
    }
  }

  void _setError(String msg) {
    _error = ApiResponse<void>.error(msg);
    notifyListeners();
  }

  Future<void> loadPlans({int page = 1, int limit = 20}) async {
    if (_isLoading) return;
    clearError();
    _setLoading(true);
    try {
      final resp = await GeneratedPlanService.listPlans(
        page: page,
        limit: limit,
      );
      if (resp.success && resp.data != null) {
        final rawPlans = resp.data!['plans'];
        final rawPagination = resp.data!['pagination'];

        if (rawPlans is List) {
          _plans =
              rawPlans
                  .whereType<Map>()
                  .map(
                    (m) => GeneratedPlan.fromJson(Map<String, dynamic>.from(m)),
                  )
                  .toList();
        } else {
          _plans = [];
        }

        if (rawPagination is Map) {
          final p = Map<String, dynamic>.from(rawPagination);
          _currentPage = (p['page'] as num?)?.toInt() ?? page;
          _totalPages = (p['totalPages'] as num?)?.toInt() ?? 1;
          _hasNextPage = p['hasNextPage'] == true;
          _hasPrevPage = p['hasPrevPage'] == true;
        } else {
          _currentPage = page;
          _totalPages = 1;
          _hasNextPage = false;
          _hasPrevPage = page > 1;
        }

        notifyListeners();
      } else {
        _setError(resp.message ?? 'Failed to load history');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPlan(String id) async {
    clearError();
    _setLoading(true);
    try {
      final resp = await GeneratedPlanService.getPlan(id);
      if (resp.success && resp.data != null) {
        _active = resp.data!;
        notifyListeners();
      } else {
        _setError(resp.message ?? 'Failed to load plan');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<GeneratedPlan?> savePlan({
    required Map<String, dynamic> input,
    required Map<String, dynamic> output,
    String? title,
  }) async {
    clearError();
    try {
      final resp = await GeneratedPlanService.savePlan(
        input: input,
        output: output,
        title: title,
      );
      if (resp.success && resp.data != null) {
        // optimistic prepend
        _plans = [resp.data!, ..._plans];
        notifyListeners();
        return resp.data!;
      } else {
        _setError(resp.message ?? 'Failed to save plan');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<void> deletePlan(String id) async {
    clearError();
    final resp = await GeneratedPlanService.deletePlan(id);
    if (resp.success) {
      _plans = _plans.where((p) => p.id != id).toList();
      if (_active?.id == id) _active = null;
      notifyListeners();
    } else {
      _setError(resp.message ?? 'Failed to delete plan');
    }
  }
}
