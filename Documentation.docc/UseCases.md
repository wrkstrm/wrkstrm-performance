# ``WrkstrmPerformance`` Use Cases

WrkstrmPerformance provides helpers for timing and benchmarking Swift code.

## Use Cases

- **Baseline metrics** – wrap a feature in a temporary measurement to capture before-and-after durations when refactoring or tuning. ``TimeMonitor.recordPreciseMeasurement`` or ``TimeMonitor.measureAverageExecutionTime`` can log baseline numbers for comparison. [Implemented]
- **Instrument critical code paths** – place ``TimeMonitor.markTimestamp`` at the start and ``TimeMonitor.recordPreciseMeasurement`` at the end of high-risk sections to surface hotspots in asynchronous flows. [Implemented]
- **Track execution phases** – log milestones like ``TimeMonitor.applicationDidFinishLaunching()`` and custom markers to generate a boot-time report that highlights slow startup phases. [Implemented]
- **Capture fine-grained measurements** – provide a start uptime and call ``TimeMonitor.recordPreciseMeasurement`` to log nanosecond-level durations for network requests or database queries. [Implemented]
- **Measure average execution time** – use ``TimeMonitor.measureAverageExecutionTime`` in benchmarks or tests to run an operation repeatedly and compute the mean. [Implemented]
- **CLI integration** – envision a wrapper command that spawns a child process, streams its output, and emits aggregated timing metrics for pipeline analysis. [Could be implemented]

## See Also

- Repository guidance in `.wrkstrm/clia/Agents.md`
