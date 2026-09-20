class AppConstants {
  // غيرها لما الباك اند يجهز. نفس القيمة ستستخدم في كل السيرفس.
  // للـ emulator: http://10.0.2.2:3000/api
  // للـ staging/docker: ضع رابط السيرفر هنا.
  static const String baseUrl = 'http://localhost:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const String assetsEndpoint = '/assets';
  static const String locationsEndpoint = '/locations';
  static const String transfersEndpoint = '/transfers';
  static const String workOrdersEndpoint = '/work-orders';
  static const String riskQueueEndpoint = '/risk-queue';
  static const String stocktakeEndpoint = '/stocktake';

  static const String tokenKey = 'ast_auth_token';
  static const String userKey = 'ast_auth_user';
}
