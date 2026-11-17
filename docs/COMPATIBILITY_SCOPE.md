# Initial compatibility scope — frozen before implementation

Baseline: Unleash/client-specification `9ef6efa01feabeb699857192ad8106fd7d990235`.

Phase A mandatory suites: 01, 02, 03, 04, 05, 07, 09, 10, 11, 12, 18. All boolean cases in these suites are required; no expected output will be changed. Phase A is an internal milestone, not a complete SDK release. If a mandatory case fails, fix it rather than relabel it unsupported.

Phase B planned: global variants (08), general and version constraints (13, 14), global segments (15), strategy variants (16), feature dependencies (17). The initial plan allows staged support; these are not currently declared implemented.

Implementation update (2026-11-17): Phase A suite 12 required parsing global variants. Global variant selection was implemented, suite 08 was added to required coverage, and all variantTests in the included suites are executed. This expands the scope without removing any initial required case.

Deferred: remote-address semantics (06), delta updates (19, 20), regex (21), CIDR constraints (22). Exact inventory and machine-readable results will be generated from every file in the pinned index, including deferred files. No omitted suite is counted as passed.

Whole-snapshot validation is strict: unknown strategies/operators and nonempty unsupported semantic fields reject installation. This intentionally differs from broad upstream compatibility for unknown constructs; it will be documented prominently.
