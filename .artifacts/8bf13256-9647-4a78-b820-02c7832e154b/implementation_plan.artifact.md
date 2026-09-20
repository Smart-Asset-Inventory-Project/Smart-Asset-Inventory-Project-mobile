# Smart Asset Inventory (AST) - Final Phase Plan

This plan addresses the missing "Must" and "Should" requirements from the AST project brief to reach a full MVP.

## User Review Required

> [!IMPORTANT]
> The current tech stack is **Flutter**, while the brief initially mentioned React. We will continue with Flutter as the project is already well-advanced in it.

> [!NOTE]
> We will implement a client-side **Rules Engine** for AI Risk (AST-FR-09) to meet the "Explainable Rules" requirement before moving to any ML models.

## Proposed Changes

### 1. Maintenance Templates & Automation (AST-FR-05/06)
Currently, we only have Work Orders. We need Templates to auto-generate due dates.

#### [NEW] [maintenance_template_model.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/models/maintenance_template_model.dart)
Define triggers (interval-based, runtime, or condition).

#### [NEW] [maintenance_templates_page.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/features/maintenance/maintenance_templates_page.dart)
UI for administrators to configure these templates.

#### [MODIFY] [work_order_service.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/core/services/work_order_service.dart)
Logic to generate the next due date when a work order is closed.

---

### 2. Procurement & Audit Linking (AST-FR-03/04)
Enhance the asset detail to show full lifecycle and financial evidence.

#### [MODIFY] [asset_detail_page.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/features/assets/asset_detail_page.dart)
- Add "Procurement" tab to show Supplier, Invoice, and Warranty.
- Add "History" tab to show custody transfers and audit trail.

---

### 3. AI Risk Rules Engine (AST-FR-09)
Replace mock data with explainable logic.

#### [MODIFY] [insights_service.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/core/services/insights_service.dart)
Implement logic:
- **High Risk:** Asset age > useful life OR warranty expired > 6 months.
- **Medium Risk:** Maintenance overdue OR repeated failures (3+ in 90 days).

---

### 4. Role-Based Access Control (AST-FR-08)
Ensure users only see what they are authorized to see.

#### [MODIFY] [asset_service.dart](file:///C:/Users/PC/StudioProjects/smart_asset_inventory/lib/core/services/asset_service.dart)
Pass organizational scope/college ID to filters based on current user profile.

## Verification Plan

### Automated Tests
- Unit tests for the `Risk Rules Engine` to ensure correct banding.
- Validation tests for `Maintenance Template` next-date calculation.

### Manual Verification
1. Create a "Computer" template (every 6 months).
2. Register a computer, link it to the template.
3. Close a work order and verify the new "Next Due Date" is generated.
4. Verify that a user assigned to "College of Engineering" cannot see assets in "College of Medicine".
