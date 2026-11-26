<!-- kit: governance v0.1.1 -->
# Amendments — lifehacker.dev

> The append-only log of changes to [the constitution](../constitution.md), one numbered record per amendment.

Process: constitution § 8.

- File name: `NNNN-kebab-slug.md`, next free number, never reused. Copy [0000-template.md](0000-template.md).
- Status: `proposed` → `ratified` (PR merged) | `rejected` | `withdrawn` | `superseded`.
- Validate: `python3 <bamr87/bamr87>/tools/governance_lint.py check .`

| # | Title | Status | Affects |
| --- | --- | --- | --- |
| [0001](0001-ratify-constitution.md) | Ratify the constitution | ratified on merge | whole constitution |
| [0002](0002-reflow-to-one-paragraph-per-line.md) | Reflow the constitution to one paragraph per line (editorial) | proposed | preamble, § 8 (formatting only) |
| [0003](0003-mission-statement.md) | Missions | proposed | constitution §1; PRD §1.1; feature LHD-008 |
| [0004](0004-agencies.md) | Agencies | proposed | constitution § 9 (new); PRD FR6, NFR5; feature LHD-009 |
| [0005](0005-auto-merge.md) | Auto-merge may publish the autopilot's own content | proposed | constitution § 1 mission 3; PRD § 1.1; `auto-merge.yml` |
