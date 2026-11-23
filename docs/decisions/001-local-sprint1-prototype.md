# 001. Use a local SQL prototype for Sprint 1

## Context

The assignment asks for a three-layer schema and a tested SQL proof of concept
over one week. The existing notebooks contain source observations, transformation
experiments and DuckDB Silver DDL.

## Decision

Keep the notebooks as evidence and extract the Silver fact transformations and
Silver DDL into shared SQL. Run the proof of concept in a disposable DuckDB
session with CSV-backed Bronze views. Exercise municipal trips and district
overnight stays across the seven sample days. The final DuckLake implementation
and incremental writes belong to Sprint 2.

## Alternatives considered

- Run the proof entirely in notebooks. This makes evidence easy to inspect, but
  makes the SQL harder to reuse and the sample harder to run consistently.
- Build the persistent DuckLake catalog now. This would exercise the target storage
  sooner and couple the current schema review to ingestion and storage work.

## Consequences

The runner can start fresh each time and reuse downloaded files. The sample checks
query semantics and conservation of totals. Production partitioning and
incremental ingestion need separate validation in Sprint 2. In the sample, typical
day averages use published OD-hours and report their observed day counts. This
retains source coverage information when privacy suppression or missing
observations prevent interpreting an absent row as zero trips.
