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
  static const String custodyAssignmentsEndpoint = '/custody-assignments';
  static const String serviceEventsEndpoint = '/service-events';
  static const String warrantiesExpiringEndpoint = '/warranties/expiring';
  static const String workOrdersDueEndpoint = '/work-orders/due';

  /// Docs: page default 1, limit default 20, max 100. Never send >100.
  static const int pageSize = 100;

  // مسارات بدون باك اند حتى الآن: fallback mock يعمل لها فقط.
  static const String riskQueueEndpoint = '/risk-queue';
  static const String templatesEndpoint = '/work-orders/templates';

  static const String tokenKey = 'ast_auth_token';
  static const String refreshTokenKey = 'ast_refresh_token';
  static const String userKey = 'ast_auth_user';

  /// DEV_MOCK=true: mock عند الباك الميت فقط (بلا رد / 5xx).
  /// بدونه (تشغيل Android Studio العادي): باك إند نقي 100% بدون أي mock.
  /// الرفض الحقيقي (401/403/400) يظهر دائما ولا يُغطى في أي وضع.
  static bool allowMockFallback =
      const bool.fromEnvironment('DEV_MOCK', defaultValue: false);
}
