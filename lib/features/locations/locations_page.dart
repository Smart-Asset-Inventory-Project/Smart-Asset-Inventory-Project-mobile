import 'package:flutter/material.dart';
import '../../core/l10n/strings.dart';
import '../../core/services/location_service.dart';
import '../../models/asset_model.dart';
import '../assets/assets_list_page.dart';

/// AST-FR-01: تصفح هرم Locations وفتح أصول كل مستوى.
class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  late Future<List<LocationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocationService().fetchLocations();
  }

  IconData _icon(String level) {
    switch (level) {
      case 'campus':
        return Icons.landscape_outlined;
      case 'building':
        return Icons.business_outlined;
      case 'floor':
        return Icons.layers_outlined;
      case 'room':
        return Icons.meeting_room_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'locations'))),
      body: FutureBuilder<List<LocationModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${tr(context, 'error')}: ${snap.error}'));
          }
          final all = snap.data ?? [];
          if (all.isEmpty) return Center(child: Text(tr(context, 'noLocations')));
          final roots = all.where((l) => l.parentId == null).toList();
          return ListView(
            children: roots
                .map((r) => _node(context, all, r, 0))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _node(BuildContext context, List<LocationModel> all,
      LocationModel loc, int depth) {
    final children =
        all.where((l) => l.parentId == loc.id).toList();
    final tile = ListTile(
      contentPadding:
          EdgeInsets.only(left: 16 + depth * 20.0, right: 16),
      leading: Icon(_icon(loc.level), color: Colors.blue),
      title: Text(loc.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(tr(context, loc.level)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssetsListPage(
            locationId: loc.id,
            locationName: loc.name,
          ),
        ),
      ),
    );
    if (children.isEmpty) return tile;
    return ExpansionTile(
      tilePadding:
          EdgeInsets.only(left: 16 + depth * 20.0, right: 16),
      leading: Icon(_icon(loc.level), color: Colors.blue),
      title: Text(loc.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(tr(context, loc.level)),
      children: [
        ListTile(
          contentPadding:
              EdgeInsets.only(left: 32 + depth * 20.0, right: 16),
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text('${tr(context, 'allAssetsIn')} ${loc.name}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetsListPage(
                locationId: loc.id,
                locationName: loc.name,
              ),
            ),
          ),
        ),
        ...children.map((c) => _node(context, all, c, depth + 1)),
      ],
    );
  }
}
