enum UserRole {
  admin,
  procurement,
  custodian,
  technician,
  auditor,
  unknown;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
      case 'asset_administrator':
        return UserRole.admin;
      case 'procurement':
      case 'procurement_finance':
        return UserRole.procurement;
      case 'custodian':
      case 'department_manager':
        return UserRole.custodian;
      case 'technician':
      case 'maintenance_technician':
        return UserRole.technician;
      case 'auditor':
        return UserRole.auditor;
      default:
        return UserRole.unknown;
    }
  }
}

enum AssetStatus { active, inMaintenance, retired, unknown }

enum TransferStatus { pending, approved, rejected, unknown }

enum WorkOrderStatus { open, inProgress, closed, cancelled, unknown }
// عملت lib/core/constants/app_enums.dart للادوار admin/procurement/custodian/technician/auditor.