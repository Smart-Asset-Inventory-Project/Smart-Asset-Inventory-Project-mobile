// import 'package:flutter/material.dart';
// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

//
// import 'package:flutter/material.dart';
//
// import '../assets/assets_list_page.dart';
// import '../custody/transfers_page.dart';
// import '../maintenance/work_orders_page.dart';
// import '../risk/risk_queue_page.dart';
// import '../stocktake/stocktake_page.dart';
// import 'dashboard_stats.dart';
//
// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//
//         appBar: AppBar(
//           title: const Text(
//             'Dashboard',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           actions: [
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(Icons.notifications_none),
//             ),
//             const SizedBox(width: 8),
//           ],
//         ),
//         drawer: Drawer(
//           child: ListView(
//             padding: EdgeInsets.zero, // لإلغاء أي Padding افتراضي من الأعلى
//             children: [
//               // 1. الهيدر الخاص بالقائمة (User Info / Header)
//               UserAccountsDrawerHeader(
//                 accountName: const Text('أحمد محمد'),
//                 accountEmail: const Text('ahmed@example.com'),
//                 currentAccountPicture: const CircleAvatar(
//                   backgroundColor: Colors.white,
//                   child: Icon(Icons.person, size: 40, color: Colors.blue),
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade700,
//                 ),
//               ),
//
//               // 2. عناصر القائمة (ListTiles)
//               ListTile(
//                 leading: const Icon(Icons.dashboard_outlined),
//                 title: const Text('Dashboard'),
//                 onTap: () {
//                   Navigator.pop(context); // إغلاق الـ Drawer
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.inventory_2_outlined),
//                 title: const Text('Assets'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const AssetsListPage()),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.qr_code_scanner),
//                 title: const Text('Stocktake'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const StocktakePage()),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.warning_amber_outlined),
//                 title: const Text('Risk Queue'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const RiskQueuePage()),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.settings_outlined),
//                 title: const Text('Settings'),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.logout, color: Colors.red),
//                 title: const Text(
//                   'Logout',
//                   style: TextStyle(color: Colors.red),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         ),
//
//       // appBar: AppBar(
//       //   title: const Text(
//       //     'Dashboard',
//       //     style: TextStyle(
//       //       fontWeight: FontWeight.bold,
//       //     ),
//       //   ),
//       //   actions: [
//       //     IconButton(
//       //       onPressed: () {},
//       //       icon: const Icon(Icons.notifications_none),
//       //     ),
//       //     const SizedBox(width: 8),
//       //   ],
//       // ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//
//             // Welcome section
//             const Text(
//               'Welcome back 👋',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 4),
//
//             const Text(
//               'Here is an overview of your assets',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey,
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Statistics - AST-FR-08 real data
//             const DashboardStats(),
//
//             const SizedBox(height: 28),
//
//             // Maintenance Risk
//             const Text(
//               'Maintenance Risk',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             Card(
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(12),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) => const RiskQueuePage()),
//                   );
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: const [
//
//                     _RiskRow(
//                       title: 'High Risk',
//                       value: '8 Assets',
//                       icon: Icons.warning_amber_outlined,
//                     ),
//
//                     Divider(),
//
//                     _RiskRow(
//                       title: 'Medium Risk',
//                       value: '15 Assets',
//                       icon: Icons.error_outline,
//                     ),
//
//                     Divider(),
//
//                     _RiskRow(
//                       title: 'Low Risk',
//                       value: '42 Assets',
//                       icon: Icons.check_circle_outline,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//             const SizedBox(height: 28),
//
//             // Quick Actions
//             const Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             Row(
//               children: [
//
//                 Expanded(
//                   child: _QuickAction(
//                     title: 'Assets',
//                     icon: Icons.inventory_2_outlined,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (_) => const AssetsListPage()),
//                       );
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 Expanded(
//                   child: _QuickAction(
//                     title: 'Scan',
//                     icon: Icons.qr_code_scanner,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (_) => const StocktakePage()),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             Row(
//               children: [
//
//                 Expanded(
//                   child: _QuickAction(
//                     title: 'Maintenance',
//                     icon: Icons.build_outlined,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (_) => const WorkOrdersPage()),
//                       );
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(width: 12),
//
//                 Expanded(
//                   child: _QuickAction(
//                     title: 'Transfer',
//                     icon: Icons.swap_horiz,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (_) => const TransfersPage()),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// /// Maintenance risk row
// class _RiskRow extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//
//   const _RiskRow({
//     required this.title,
//     required this.value,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//
//         Icon(
//           icon,
//           size: 26,
//         ),
//
//         const SizedBox(width: 12),
//
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//
//         Text(
//           value,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
// /// Quick action button
// class _QuickAction extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final VoidCallback onTap;
//
//   const _QuickAction({
//     required this.title,
//     required this.icon,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           vertical: 18,
//         ),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: Colors.grey.shade300,
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//
//             Icon(
//               icon,
//               size: 28,
//               color: Colors.blue,
//             ),
//
//             const SizedBox(height: 8),
//
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:smart_asset_inventory/core/theme/app_colors.dart';

import '../assets/assets_list_page.dart';
import '../custody/transfers_page.dart';
import '../maintenance/work_orders_page.dart';
import '../risk/risk_queue_page.dart';
import '../stocktake/stocktake_page.dart';
import 'dashboard_risk_section.dart';
import 'dashboard_stats.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      // =========================
      // Drawer
      // =========================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Ahmed Mohamed'),
              accountEmail: Text('ahmed@example.com'),
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, size: 35),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Assets'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssetsListPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Stocktake'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StocktakePage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text('Risk Queue'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiskQueuePage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {},
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {},
            ),
          ],
        ),
      ),

      // =========================
      // Body
      // =========================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              const Text(
                'Welcome back 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Here is an overview of your assets',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // =========================
              // Dashboard Statistics
              // =========================
              const DashboardStats(),

              const SizedBox(height: 24),

              // =========================
              // Maintenance Risk
              // =========================
              const Text(
                'Maintenance Risk',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const DashboardRiskSection(),

              const SizedBox(height: 24),

              // =========================
              // Quick Actions
              // =========================
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      title: 'Assets',
                      icon: Icons.inventory_2_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssetsListPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      title: 'Scan',
                      icon: Icons.qr_code_scanner,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StocktakePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      title: 'Maintenance',
                      icon: Icons.build_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkOrdersPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      title: 'Transfer',
                      icon: Icons.swap_horiz,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransfersPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
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
