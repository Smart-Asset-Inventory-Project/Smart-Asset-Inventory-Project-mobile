# AST-FR-09 — Maintenance Risk Baseline (deterministic)

Date: 2026-09-22. Source: live backend `https://assethub-backend.vercel.app/api`.
No `/risk-queue` endpoint exists, so the app computes risk locally with
explainable rules only. Output is a review queue; it never changes
asset or work-order state (human confirmation required).

## Dataset snapshot (limit=200)

- Assets: 100 — ACTIVE=80, MAINTENANCE=10, RETIRED=5, LOST=5
- Condition: GOOD=80, FAIR=20
- Work orders: OPEN=20, IN_PROGRESS=10, COMPLETED=16, CANCELLED=5
- Overdue open/in-progress work orders: 11
- Warranties: 30 tracked, 10 expiring within 30d

## Baseline rules (v1, deterministic)

For each non-retired asset, score in [0,1]:

| Signal | Points |
|---|---|
| Each open/in-progress work order on the asset | +0.30 |
| Any overdue open/in-progress work order | +0.40 |
| Condition != GOOD | +0.25 |
| Status MAINTENANCE/in-repair | +0.20 |

Bands: score >= 0.60 → high; >= 0.35 → medium; else low (only listed if it
has at least one reason). Sorted by score desc. Implementation:
`InsightsService.computeLocalRisk()` in
`lib/core/services/insights_service.dart`.

## Known limitations

- No labeled failure history yet, so precision/recall vs a failure window
  cannot be measured; the rules above ARE the documented baseline.
- No runtime/condition sensor data (MVP excludes per-device IoT).
- Warranty expiry is not yet an input (asset detail lacks warranty dates);
  add when backend exposes per-asset warranty.
- When a classifier is trained later, it must beat this baseline on
  precision/recall + median lead time, with a dataset split and model log,
  before replacing it. A non-beating model is a valid reported result.
