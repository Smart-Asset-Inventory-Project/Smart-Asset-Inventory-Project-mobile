import 'package:flutter/material.dart';
import 'package:smart_asset_inventory/core/theme/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_page.dart';
import '../settings/settings_page.dart';

import '../assets/assets_list_page.dart';
import '../categories/categories_page.dart';
import '../custody/transfers_page.dart';
import '../locations/locations_page.dart';
import '../maintenance/templates_page.dart';
import '../maintenance/work_orders_page.dart';
import '../procurement/procurement_overview_page.dart';
import '../retirement/retirements_page.dart';
import '../risk/risk_queue_page.dart';
import 'dashboard_risk_section.dart';
import 'dashboard_sections.dart';
import 'dashboard_stats.dart';

class DashboardPage extends StatefulWidget {
  /// User from login — skips a sequential /auth/me round-trip.
  /// null (e.g. tests) = fetch via AuthService as before.
  final UserModel? user;
  const DashboardPage({super.key, this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  UserModel? _user;

  /// Single shared dashboard load — stats + sections + risk all reuse it.
  /// Was 3 independent loads (~11 requests); now 1 parallel batch.
  Future<DashboardData>? _dataFuture;

  /// One shared batch for this role — custodian adds custody records.
  Future<DashboardData> _batch(UserModel? u) => loadDashboardData(
        userId: u?.id,
        scopeLocationId:
            u?.role == UserRole.custodian ? u?.collegeScope : null,
        includeCustody: u?.role == UserRole.custodian,
      );

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // No waiting: data requests fire immediately alongside login-warm API.
      _user = widget.user;
      _dataFuture = _batch(_user);
      _refreshUser();
    } else {
      _loadUser();
    }
  }

  /// Background refresh of the cached user — never blocks data load.
  Future<void> _refreshUser() async {
    final u = await AuthService().currentUser();
    if (!mounted) return;
    if (u != null &&
        (u.id != _user?.id ||
            u.role != _user?.role ||
            u.collegeScope != _user?.collegeScope)) {
      setState(() {
        _user = u;
        _dataFuture = _batch(u);
      });
    }
  }

  Future<void> _loadUser() async {
    final u = await AuthService().currentUser();
    if (mounted) {
      setState(() {
        _user = u;
        _dataFuture = _batch(u);
      });
    }
  }

  Future<void> _reload() async {
    final u = _user;
    setState(() {
      _dataFuture = _batch(u);
    });
    await _dataFuture;
  }

  /// دور المستخدم الحقيقي بعد تسجيل الدخول AST-FR-08.
  UserRole get _role => _user?.role ?? UserRole.unknown;

  /// Quick actions حسب الدور AST-FR-08.
  List<({String title, IconData icon, Widget page})> _actions(
    BuildContext context,
  ) {
    final assets = (
      title: tr(context, 'assets'),
      icon: Icons.inventory_2_outlined,
      page: const AssetsListPage(),
    );
    final custodianAssets = (
      title: tr(context, 'assets'),
      icon: Icons.inventory_2_outlined,
      page: AssetsListPage(scopeLocationId: _user?.collegeScope)
    );
    final maint = (
      title: tr(context, 'maintenance'),
      icon: Icons.build_outlined,
      page: const WorkOrdersPage(),
    );
    final transfer = (
      title: tr(context, 'transfer'),
      icon: Icons.swap_horiz,
      page: _role == UserRole.custodian
          ? TransfersPage(scopeLocationId: _user?.collegeScope)
          : const TransfersPage(),
    );
    final risk = (
      title: tr(context, 'risk'),
      icon: Icons.warning_amber_outlined,
      page: const RiskQueuePage(),
    );
    final locations = (
      title: tr(context, 'locations'),
      icon: Icons.location_city_outlined,
      page: const LocationsPage(),
    );

    switch (_role) {
      case UserRole.procurement:
        return [assets, transfer, locations, risk];
      case UserRole.custodian:
        return [custodianAssets, transfer, risk, locations];
      case UserRole.technician:
        return [maint, assets, transfer, locations];
      case UserRole.auditor:
        return [assets, risk, transfer, locations];
      case UserRole.admin:
      case UserRole.unknown:
        return [assets, maint, transfer, locations];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'dashboard'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            itemBuilder: (BuildContext context) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              List<String> notes = [];
              switch (_role) {
                case UserRole.admin:
                  notes = isAr 
                    ? ['تنبيه: ٣ أصول عالية المخاطر تتطلب مراجعة', 'طلب نقل عهدة جديد معلق بانتظار الاعتماد'] 
                    : ['Alert: 3 high-risk assets need review', 'New custody transfer pending approval'];
                  break;
                case UserRole.procurement:
                  notes = isAr
                    ? ['تنبيه: فترة ضمان أحد الخوادم تنتهي خلال ٣٠ يوماً', 'تقرير فواتير المشتريات الربع سنوي جاهز']
                    : ['Alert: Server warranty expiring in 30 days', 'Quarterly procurement report ready'];
                  break;
                case UserRole.technician:
                  notes = isAr
                    ? ['لديك أمر شغل مستحق الصيانة اليوم', 'تم تحديث خطة الصيانة الوقائية السنوية']
                    : ['You have a work order due for service today', 'Annual preventive plan updated'];
                  break;
                case UserRole.custodian:
                  notes = isAr
                    ? ['يرجى تأكيد استلام العهدة الجديدة المسجلة', 'موعد الصيانة الدورية لجهازك اقترب']
                    : ['Please confirm receipt of new assigned asset', 'Periodic maintenance schedule approaching'];
                  break;
                case UserRole.auditor:
                case UserRole.unknown:
                  notes = isAr
                    ? ['سجل التدقيق والمراجعة الأسبوعي جاهز', 'تم رصد فروقات طفيفة في جرد العهد السابقة']
                    : ['Weekly audit inspection logs are ready', 'Minor stocktake discrepancies recorded'];
                  break;
              }
              return notes.map((text) {
                return PopupMenuItem<String>(
                  value: text,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.blue,
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 38, color: AppColors.blue),
              ),
              accountName: Text(
                _user?.name.trim().isEmpty ?? true
                    ? (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'مستخدم'
                          : 'User')
                    : _user!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                '${_user?.email ?? ''} • ${tr(context, _role.name)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(tr(context, 'dashboard')),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(tr(context, 'assets')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssetsListPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(tr(context, 'custodyTransfers')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransfersPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: Text(tr(context, 'workOrders')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkOrdersPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(tr(context, 'riskQueue')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiskQueuePage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: Text(tr(context, 'locations')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.event_repeat_outlined),
              title: Text(tr(context, 'templates')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplatesPage()),
                );
              },
            ),

            if (_role == UserRole.admin ||
                _role == UserRole.procurement ||
                _role == UserRole.auditor)
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(tr(context, 'procurementTitle')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProcurementOverviewPage()),
                  );
                },
              ),

            if (_role == UserRole.admin)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(tr(context, 'category')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CategoriesPage()),
                  );
                },
              ),

            if (_role == UserRole.admin || _role == UserRole.auditor)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(tr(context, 'retireRequests')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RetirementsPage()),
                  );
                },
              ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(tr(context, 'settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.red),
              title: Text(
                tr(context, 'logout'),
                style: const TextStyle(color: AppColors.red),
              ),
              onTap: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),


      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                welcomeUser(context, _user?.name.trim()),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                tr(context, 'overview'),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              DashboardStats(user: _user, future: _dataFuture, onRetry: _reload),

              const SizedBox(height: 24),

              if (_role != UserRole.procurement) ...[
                Text(
                  tr(context, 'maintRisk'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DashboardRiskSection(future: _dataFuture),
                const SizedBox(height: 24),
              ],

              // =========================
              // Role sections AST-FR-08
              // =========================
              DashboardSections(user: _user, future: _dataFuture, onRetry: _reload),

              // =========================
              // Quick Actions - حسب الدور AST-FR-08
              // =========================
              Text(
                tr(context, 'quickActions'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Builder(
                builder: (context) {
                  final acts = _actions(context);
                  return Column(
                    children: [
                      for (var i = 0; i < acts.length; i += 2)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i + 2 < acts.length ? 12 : 0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _QuickAction(
                                  title: acts[i].title,
                                  icon: acts[i].icon,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => acts[i].page,
                                    ),
                                  ),
                                ),
                              ),
                              if (i + 1 < acts.length) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickAction(
                                    title: acts[i + 1].title,
                                    icon: acts[i + 1].icon,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => acts[i + 1].page,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Quick Action Widget
// =====================================================

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 30, color: AppColors.blue),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
