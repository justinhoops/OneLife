# OneLife Performance Phases

## Phase 1 - Instrumentation and Safe Runtime Improvements
- [x] Add runtime marker for derived-state refresh (`derivedStateRefresh`).
- [x] Add runtime marker for world snapshot builds (`worldSnapshotBuild`).
- [x] Instrument `GameViewModel.refreshDerivedState(...)` with timed measurement.
- [x] Instrument `LifeSimulationOrchestrator.rebuildWorldSnapshot(...)` for cache-miss build cost.
- [x] Add unit tests validating both new markers are emitted.

## Phase 2 - Main-Path Cost Reduction
- [ ] Reduce world snapshot rebuild frequency during yearly resolution by batching stale sections.
- [ ] Separate essential and non-essential derived cache rebuild work across frame boundaries.
- [ ] Add threshold-triggered debug summaries for worst marker spikes over a rolling window.

## Phase 3 - Verification and Hard Budgets
- [ ] Capture Instruments baselines for key markers and update budget constants.
- [ ] Promote marker regressions to test-time assertions in performance-focused tests.
- [ ] Run 30+ year soak profiles and document p95/p99 marker timing outcomes.
