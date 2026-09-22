import 'package:dio/dio.dart';
import '../../models/maintenance_template_model.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

/// AST-FR-05: قوالب الصيانة حسب الفئة/الموديل.
class TemplateService {
  TemplateService({ApiService? api}) : _api = api ?? ApiService.instance;
  final ApiService _api;

  Future<List<MaintenanceTemplate>> fetchTemplates({String? category}) async {
    try {
      final res = await _api.get(
        AppConstants.maintenanceTemplatesEndpoint,
        query: const {'limit': '200'},
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      var list = ((body['data'] as List? ?? []))
          .map((e) => MaintenanceTemplate.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      if (category != null && category != 'all') {
        list = list
            .where((t) =>
                t.category == category || t.categoryId == category)
            .toList();
      }
      return list;
    } on DioException catch (e) {
      // لا endpoint بديل: mock عند غياب السيرفر أو 404.
      if ((AppConstants.allowMockFallback && e.response == null) ||
          e.response?.statusCode == 404) {
        return _mock(category);
      }
      rethrow;
    }
  }

  List<MaintenanceTemplate> _mock(String? category) {
    const all = [
      MaintenanceTemplate(
        id: 'tpl-pc-90',
        name: 'PC Periodic Service',
        category: 'computer',
        triggerType: 'calendar',
        intervalDays: 90,
        checklist: ['Clean fans', 'Update antivirus', 'Check SMART disk'],
        lastServiceDate: '2026-07-01',
      ),
      MaintenanceTemplate(
        id: 'tpl-printer-500',
        name: 'Printer Roller Service',
        category: 'printer',
        triggerType: 'runtime',
        runtimeHours: 500,
        checklist: ['Clean rollers', 'Check toner level'],
      ),
      MaintenanceTemplate(
        id: 'tpl-furniture-cond',
        name: 'Furniture Condition Check',
        category: 'furniture',
        triggerType: 'condition',
        conditionRule: 'on reported damage or yearly',
        checklist: ['Inspect joints', 'Tighten screws'],
        lastServiceDate: '2026-01-15',
      ),
    ];
    if (category == null || category == 'all') return all;
    return all.where((t) => t.category == category).toList();
  }
}
