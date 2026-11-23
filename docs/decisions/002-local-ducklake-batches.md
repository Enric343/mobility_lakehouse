# 002. Commit validated daily mobility partitions in local DuckLake

## Context

Sprint 2 needs a persistent catalog for the 2023 inputs. A mobility file covers
one date, one zoning level and one dataset. A year can contain multiple missing
files and is too large to treat as one retry unit.

## Decision

Use a local DuckDB-backed DuckLake catalog and Parquet storage. Validate each
daily input and its Silver output before committing both layers and a load record
in one transaction. Store the geography, 2023 metrics and holidays as a reference
snapshot per catalog. Use the existing Silver DDL for column names and types and
check design keys with SQL during the load.

## Alternatives considered

- Load the full year in one transaction. This makes partial results invisible but
  increases the cost of retries and delays discovering bad partitions.
- Let the notebooks write the persistent catalog. This keeps the exploration easy
  to follow but mixes production writes with experiments and limits repeatability.

## Consequences

Later runs can append new dates or recover from a failed batch using `mobility_loads`.
Completed source files are treated as immutable within a catalog. A separate
catalog lets us evaluate revised source files and reference mappings without
changing already validated facts. Published aggregates can differ across zoning
levels. Each batch is checked against its own source.
