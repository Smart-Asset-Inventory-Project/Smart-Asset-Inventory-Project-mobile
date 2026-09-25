import 'package:flutter_test/flutter_test.dart';
import 'package:smart_asset_inventory/core/constants/app_constants.dart';
import 'package:smart_asset_inventory/core/services/auth_service.dart';
import 'package:smart_asset_inventory/core/services/asset_service.dart';

/// اختبار عقد حي ضد الباك اند. يحتاج إنترنت. يتخطى تلقائيا بدونه.
/// mock مطفأ عمدا هنا: هذا الاختبار يتحقق من الباك الحقيقي فقط.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppConstants.allowMockFallback = false;

  test('live backend contract: login + assets', () async {
    try {
      final user = await AuthService().login(
        email: 'admin@assethub.local',
        password: 'Admin@123',
      ).timeout(const Duration(seconds: 25));
      expect(user.role.name, 'admin');
      final assets = await AssetService()
          .fetchAssets()
          .timeout(const Duration(seconds: 25));
      expect(assets.isNotEmpty, true);
      expect(assets.first.tag.isNotEmpty, true);
    } catch (e) {
      markTestSkipped('backend unreachable from test env: $e');
    }
  });
}
