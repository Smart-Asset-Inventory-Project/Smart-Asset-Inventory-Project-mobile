class AppConstants {
  /// الباك اند الحقيقي (Vercel). ممنوع localhost.
  static const String baseUrl = 'https://assethub-backend.vercel.app/api';

  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';
  static const String assetsEndpoint = '/assets';
  static const String locationsEndpoint = '/locations';
  static const String locationsTreeEndpoint = '/locations/tree';
  static const String categoriesEndpoint = '/categories';
  static const String transfersEndpoint = '/transfers';
  static const String workOrdersEndpoint = '/work-orders';
  static const String maintenanceTemplatesEndpoint = '/maintenance-templates';
  static const String purchaseOrdersEndpoint = '/purchase-orders';
  static const String warrantiesEndpoint = '/warranties';
  static const String invoicesEndpoint = '/invoices';
  static const String suppliersEndpoint = '/suppliers';
  static const String retirementsEndpoint = '/retirements';
  static const String auditLogsEndpoint = '/audit-logs';
  static const String dashboardSummaryEndpoint = '/dashboard/summary';

  // مسارات بدون باك اند حتى الآن: fallback mock يعمل لها فقط.
  static const String riskQueueEndpoint = '/risk-queue';
  static const String templatesEndpoint = '/work-orders/templates';

  static const String tokenKey = 'ast_auth_token';
  static const String refreshTokenKey = 'ast_refresh_token';
  static const String userKey = 'ast_auth_user';

  /// false = الباك اند لايف. يتحول true فقط في اختبارات الـ widget
  /// أو عند انقطاع السيرفر (endpoints الموجودة فقط).
  /// endpoints الغائبة (risk/templates/procurement/retirement) تقع
  /// على mock عند 404 مهما كانت قيمة العلم.
  static bool allowMockFallback = false;
}
