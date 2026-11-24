# 004. Keep VARCHAR for Silver categorical and code columns

## Context and problem

Several Silver columns hold a small, fixed set of values: `zone_level`
(`distritos`, `municipios`, `GAU`) and `origin_activity` / `destination_activity`
(`casa`, `trabajo_estudio`, `frecuente`, `no_frecuente`). Administrative codes
(`ccaa_code`, `province_code`) are short, 2-digit strings. A reasonable instinct
is that `VARCHAR` wastes space here and a narrower type would save memory. This
record checks whether that holds for the DuckDB + DuckLake stack.

## Decision

Keep `VARCHAR` for all Silver categorical and code columns. Do not introduce
`ENUM` or `VARCHAR(n)` for these columns.

## Alternatives considered

- **`ENUM` for the categorical columns.** This is the type that would actually
  dictionary-encode the domain in a classic database. Tested against DuckLake
  1.5.6: the project's load pattern
  (`CREATE TABLE lake.main.x AS FROM contract.x LIMIT 0`) fails with
  `Failed to convert DuckDB type to DuckLake - unsupported type ENUM`. ENUM is
  not storable in DuckLake and would break the loader.
- **`VARCHAR(n)` to bound the length.** Tested against DuckLake 1.5.6: the
  length is accepted syntactically but dropped from the catalog (stored as plain
  `VARCHAR`) and not enforced — a 3-character value inserts into `VARCHAR(2)`
  without error. It gives neither storage savings nor a constraint.
- **Integer types for the 2-digit codes.** This would drop the leading zeros
  that identify communities and provinces (`'01'` becomes `1`), corrupting joins.

## Reasons for the decision

- DuckDB does not reserve space by declared string length; a `VARCHAR` and a
  `VARCHAR(2)` store identically in memory.
- DuckLake persists as Parquet, which already dictionary-encodes low-cardinality
  string columns on disk, so the imagined waste is not present.
- The only type that would change the encoding, `ENUM`, is unsupported by
  DuckLake, and `VARCHAR(n)` is a no-op there. Neither delivers the intended
  saving.
- Codes must remain text to preserve leading zeros.

## Trade-offs and consequences

- The schema does not enforce the allowed value set at the type level. The
  domain is instead documented in each table card and the bronze-to-silver
  rules, and non-empty activity and zone references are checked during the load
  (`sql/validation/`). A stricter whitelist check can be added there later
  without a schema change.
- If a future DuckLake version supports `ENUM`, revisit this record with a new
  ADR before adopting it, measuring the gain against Parquet's existing
  dictionary encoding.

Supersedes nothing. Relates to [002](002-local-ducklake-batches.md) (DuckLake
storage) and the leading-zero note in [bronze-to-silver](../bronze-to-silver.md).
