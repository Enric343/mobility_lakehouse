# Code map

How the code is organized and how a run flows through it. For the data
architecture, the star schema and the design decisions, see the
[lakehouse map](lakehouse.md); this page is about the files, not the tables.

## The big picture

Two layers of code, split by language and responsibility:

- **`scripts/` (Python)** orchestrates: it stages inputs, runs the SQL, checks
  the results and commits. It holds no business rules beyond the K-means step.
- **`sql/`** holds the actual definitions and transformations. DuckDB executes
  it; DuckLake stores the committed result.

So `scripts/` decides *when and over what*, `sql/` decides *what the data
becomes*. Changing a calculation means editing `sql/` (and maybe `gold.py`),
not the orchestration.

## `scripts/` at a glance

```text
scripts/
├─ run_sprint2.py          entry point · local DuckLake load
├─ run_sprint1.py          entry point · Sprint 1 proof of concept
├─ build_gold.py           entry point · build the Gold snapshot
├─ download_data.py        entry point · fetch raw MITMA/INE/BOE files
├─ render_sprint3.py       entry point · render the HTML report
│
├─ lakehouse/              ── build & populate the lakehouse (writes) ──
│  ├─ catalog.py           open DuckLake, load extensions, transactions
│  ├─ sources.py           raw file paths + reference inventory
│  ├─ reference.py         load fixed 2023 geography, economics, holidays
│  ├─ mobility.py          load daily trips & overnight facts
│  ├─ validation.py        run SQL checks, stop a failed batch
│  ├─ gold.py              build & publish the Gold snapshot
│  └─ clustering.py        K-means on daily profiles (only non-SQL step)
│
└─ reporting/              ── read Gold, make figures & report (read-only) ──
   ├─ charts.py            plots & choropleths from Gold rows
   └─ sprint3.py           read Gold, write the offline HTML report
```

The top-level `run_*` / `build_*` files are the commands you launch; the Sprint 3
DAG in `dags/` calls the same `lakehouse/` code. See the [runbook](runbook.md).

## `sql/` at a glance

The folders follow the pipeline, in order:

```text
sql/
├─ schema/            ① define the tables (no data)
├─ ingestion/         ② raw files → Bronze
├─ bronze_to_silver/  ③ clean & type → Silver
├─ silver_to_gold/    ④ aggregate → Gold (the analytical questions)
├─ validation/        ⑤ quality checks, run before every commit
└─ reporting/         ⑥ read-only views for the report
```

The fact SQL reads a staged Bronze table through `$source_table`. The daily-OD
SQL uses the same parameter to read Silver trips. Each query serves every
zoning level and date. The [Bronze to Silver rules](bronze-to-silver.md)
explain the fact transformations in detail.

## How it all fits together

A full run (the Sprint 3 DAG, or Sprint 2 up to the load) has two phases: it
**builds** the lakehouse (writing, in transactions) and then **queries** it
(read-only) for the report. In the diagram the main path runs straight down;
each decision branches to the right, where finished work is skipped and a failed
check aborts before anything is committed.

```text
═══ BUILD the lakehouse · writes, one transaction per commit ═══

  download_data.py  ──►  raw files in data/raw/
        │
        ▼
  reference already loaded? ──── yes ───►  skip
        │ no
        ▼
  reference.py: stage → check → commit        (geography, economics, holidays)
        │
        ▼
  for each daily mobility file:
     │
     ├─ already loaded? ──────────── yes ───►  skip this file
     │     │ no
     │     ▼
     │  stage Bronze → run checks
     │     │
     │     ├─ checks fail? ───────── yes ───►  QualityError: no commit,
     │     │     │ no                           retry on the next run
     │     │     ▼
     │     └─ transform Silver → commit Bronze + Silver + load record
     ▼
  gold.py: build Gold from Silver → run Gold checks
        │
        ├─ checks fail? ──────────── yes ───►  abort: no Gold commit
        │ no
        ▼
  commit Gold snapshot

═══ QUERY the lakehouse · read-only, no writes ═══

  read one validated Gold snapshot  ──►  charts  ──►  HTML report
  ad-hoc SQL for inspection             (see the runbook)
```

Every commit in the build phase groups its data with its tracking record in one
transaction, so a run that stops midway leaves no half-finished state. The next
run reads the tracking tables (`reference_load`, `mobility_loads`, `gold_runs`)
and resumes from the first unfinished step. The query phase never writes, so it
can run any time after Gold without touching the data.

## Zoom in: how a daily load flows through the code

A single daily mobility file, end to end, shows how the two layers interact:

```text
pending_files()                 what is not yet in mobility_loads
      │
      ▼
ingestion/mobility_day.sql      stage the CSV into a Bronze temp table
      │
      ▼
validation/bronze_trips.sql     issue counts; non-zero → QualityError, stop
      │
      ▼
bronze_to_silver/fact_trips.sql transform staged rows into Silver
      │
      ▼
catalog.transaction()           commit Bronze + Silver + mobility_loads together
```

An invalid batch leaves no load record, so a retry resumes where it stopped. The
reference snapshot and the Gold build follow the same shape: stage, check,
transform, commit as one transaction. Reporting runs only after Gold and opens
the catalog read-only.

[Lakehouse map](lakehouse.md) · [Bronze to Silver](bronze-to-silver.md) · [Runbook](runbook.md) · [Table catalog](tables/README.md)
