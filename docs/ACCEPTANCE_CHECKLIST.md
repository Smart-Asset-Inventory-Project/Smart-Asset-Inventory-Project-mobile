# Acceptance Checklist — field run on real phones (live backend)

Base: `https://assethub-backend.vercel.app/api`. Login: `admin@assethub.local` / `Admin@123`.
Role accounts (custodian/technician/procurement/auditor) still pending from backend.

## S1 — Import 100 assets + duplicate report
- [ ] Assets → upload icon → Load sample → Import → success report shows.
- [ ] Re-import same CSV → every row fails with CONFLICT (verified API-side 2026-09-22).
- [ ] Upload the 100-asset file across 2 buildings → 100 success, errors listed per row.

## S2 — Transfer + history
- [ ] Asset detail → Transfer → pick room → submit → record `completed` (verified API-side with restore).
- [ ] Transfers list shows location names + user names, newest first, with reason.
- [ ] transfer → back to original room to leave seed data clean.

## S3 — Procurement visibility + denial
- [ ] Admin sees Procurement overview (POs/invoices/warranties/suppliers) and per-asset page.
- [ ] No-token API calls return 401 (verified).
- [ ] Unauthorized-role denial needs role accounts from backend.

## S4 — Template → work order → completion
- [ ] Templates shows last completion + next due per category (verified API-side cycle).
- [ ] Create WO with title → complete with notes → status COMPLETED + completedAt.

## S5 — Dashboard reconciliation
- [ ] Admin totals match `/dashboard/summary` (120/100/5, value 157050).
- [ ] Category breakdown taps open filtered lists; View All opens everything.
- [ ] Risk queue shows local-rule reasons; never auto-creates orders.

## Regression
- [ ] `flutter analyze lib test` clean, `flutter test` green.
- [ ] Login validator accepts `.local` domains.
- [ ] Commits carry `AST:` prefix.
