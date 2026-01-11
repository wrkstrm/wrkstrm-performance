# TODO — WrkstrmPerformance: PerfRunner Roadmaps

### Recorder Injection
<!-- id:wperf-recorder-injection owner:perf priority:P1 labels:perf,metrics,status:planned epic:perf-runner estimate:4x7.5m -->
- Add optional recorder to `PerfRunner` to capture RSS deltas and CPU timing per iteration.
- Keep return tuple stable; recorder enriches metrics out‑of‑band.

### Pacing Modes
<!-- id:wperf-pacing-modes owner:perf priority:P2 labels:perf,timing,status:planned epic:perf-runner estimate:4x7.5m -->
- Add `fixedDelay` vs `fixedPeriod` pacing; document trade‑offs (latency vs throughput).

### Warmup Helper
<!-- id:wperf-warmup-helper owner:perf priority:P3 labels:perf,bench,status:planned epic:perf-runner estimate:2x7.5m -->
- Provide `warmup + measure` convenience for micro‑benchmarks.
