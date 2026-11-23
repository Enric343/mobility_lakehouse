OBJETIVO:
El objetivo del proyecto es completar los sprints que estan dentro del archivo project.pdf siguiendo tambien las especificaciones que se piden ahi, vamos a trabajar segun los sprints especificados ahi por tanto revisalo y analizar por que punto vamos
La arquitectura tiene que ser clara, diviendo bien las responsabilidades y las funcionalidades de cada parte, esto incluye la documentacion


MAINTAINING AGENTS.md:
Keep this file updated when important project conventions, architectural rules, or development workflows change.

Only store information that is useful for future development sessions.

Avoid temporary notes, implementation histories, and redundant information.

Never remove existing instructions without a justified reason and without asking the user first

DOCUMENTATION:
Keep the README as an index. Use `docs/lakehouse.md` for data architecture (layers, schema, design decisions), `docs/code-map.md` for code architecture (how `scripts/` and `sql/` are organized and how a run flows), `docs/bronze-to-silver.md` for transformation rules, `docs/tables/` for table cards, and `docs/runbook.md` for execution.
Record significant technical decisions in docs/decisions/.
Each record should explain:
- Context and problem
- Decision made
- Alternatives considered
- Reasons for the decision
- Trade-offs and consequences
- Do not create ADRs for trivial implementation details.

Preserve historical decisions. If a decision changes, create a new ADR that supersedes the previous one.

PROGRESS TRACKING:
- Maintain docs/progress.md with the current project status, completed milestones, blockers, and next steps.
- Update it after significant tasks, not after every small code change.
- Remove outdated pending tasks when they are completed.

ENGINEERING PRINCIPLES:
- Prefer reusable Python modules and SQL files for production logic.
- Preserve existing working code and documentation.
- Prefer simple, maintainable solutions over unnecessary abstractions.
- Use notebooks primarily for exploration, prototyping and visualization.
- Use `scripts/run_sprint2.py` for the local DuckLake load. Keep the Bronze and Silver steps in `scripts/lakehouse/` and their table definitions, transformations and checks under `sql/`.
- Commit a daily mobility partition and its load record in the same DuckLake transaction. Use the load records to skip completed partitions on retries.
- Keep the Sprint 3 DAG in `dags/`, Gold transformations in `sql/silver_to_gold/`, and plotting in `scripts/reporting/`. Use the original sample week for the DAG and report.
- Never silently change table schemas, grains or business definitions.

DATA QUALITY:
For every relevant transformation, consider:
- Nulls and suppressed observations
- Duplicates
- Invalid identifiers
- Missing dates
- Referential integrity
- Zone mapping consistency
- Unexpected row-count changes
- Conservation of totals when aggregating

GENERAL:
- Keep documentation concise, accurate, and consistent with the code. Not slope, better small lines with clear instructions and decisions, easy to read that long detailed explainations if there are not neccesary
- Do not implement future-sprint infrastructure unless explicitly requested.
- Use the sample week (2023-03-06 to 2023-03-12) for fast local development. Design for incremental ingestion of larger periods, including the complete 2023 reference year.
- Keep documentation in English.
- Each module should have a clear, well-defined responsibility. Separate ingestion, transformation, validation, orchestration, and analytical logic. Avoid duplicating business logic across modules.
- Very important that when you change something in the project the documentation and the code must be in the same page, There can be no inconsistencies between the documentation and the code. Likewise, there can be no inconsistencies between two different documents within the documentation.