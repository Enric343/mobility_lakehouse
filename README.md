# Mobility Lakehouse

A 3-tier data lakehouse (Bronze → Silver → Gold) for mobility analysis in Spain,
built on **DuckLake** for ACID storage and versioning and **DuckDB** for SQL
analytics. It integrates MITMA mobility, INE demographics and economics, and BOE
holidays. The working sample covers **6–12 March 2023**; the design scales to the
full 2023 reference year. Airflow runs the load and publishes Gold analyses of
the typical mobility day and gravity-model infrastructure gaps.

## Documentation

This README is the index. Follow the goal that matches what you need.

| If you want to… | Start here |
|---|---|
| Understand the architecture, the schema and the design decisions | [Lakehouse map](docs/lakehouse.md) |
| Understand how the code is organized (scripts and SQL) | [Code map](docs/code-map.md) |
| See how raw data becomes Silver and what is cleaned | [Bronze to Silver](docs/bronze-to-silver.md) |
| Look up one table: columns, source, grain, query | [Table catalog](docs/tables/README.md) |
| Know where each dataset comes from | [Source inventory](docs/data_sources.md) |
| Run the pipeline or query the lakehouse | [Runbook](docs/runbook.md) |
| Interpret the Gold results and maps | [Sprint 3 analysis](docs/sprint3.md) |

Secondary references: [Diagrams](docs/diagrams/README.md) ·
[Design decisions / ADRs](docs/decisions/) · [Project progress](docs/progress.md)

## Layout

| Path | Contents |
|---|---|
| `scripts/lakehouse/` | Ingestion, transformation, validation and Gold build steps |
| `sql/` | Table definitions, transformations and checks, by layer |
| `dags/` | Sprint 3 Airflow DAG |
| `scripts/reporting/` | Gold plotting and the HTML report |
| `docs/` | All documentation (this index points into it) |
| `data/` | Local DuckLake catalog, Parquet warehouse and reports (git-ignored) |

The generated report is at `data/reports/sprint3/index.html` after the sample run.

For what each script module and `sql/` folder does, and how a run flows through
the code, see the [Code map](docs/code-map.md).
