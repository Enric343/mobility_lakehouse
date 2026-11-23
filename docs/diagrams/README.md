# Lakehouse diagrams

Diagrams are split into two folders by what they show:
- [`schemas/`](schemas/) — editable Draw.io schemas of the tables (one per layer, plus the overview and the Bronze→Silver lineage).
- [`flows/`](flows/) — Graphviz `.dot` sources and their rendered `.svg` showing storage, lineage and transformations, embedded in the lakehouse map and the Silver guide.

| View | Rendered diagram | Editable source |
|---|---|---|
| **All tables at a glance (Bronze / Silver / Gold)** | | [Draw.io](schemas/tables_overview.drawio) |
| Bronze schema — tables, columns, types | | [Draw.io](schemas/bronze.drawio) |
| Silver schema — star schema, keys, relations | | [Draw.io](schemas/silver.drawio) |
| Gold schema — tables grouped by business question (BQ1/BQ2/BQ3), columns, types | | [Draw.io](schemas/gold.drawio) |
| Bronze to Silver detailed lineage | | [Draw.io](schemas/bronze_to_silver.drawio) |
| Physical storage and query execution | [SVG](flows/lakehouse-storage.svg) | [Graphviz](flows/lakehouse-storage.dot) |
| A MITMA trips file from Bronze to Gold | [SVG](flows/trip-lineage.svg) | [Graphviz](flows/trip-lineage.dot) |
| Daily fact transformations and commit | [SVG](flows/silver-facts.svg) | [Graphviz](flows/silver-facts.dot) |
| Reference data transformations | [SVG](flows/silver-reference.svg) | [Graphviz](flows/silver-reference.dot) |

From the `flows/` directory, use `dot -Tsvg silver-facts.dot -o silver-facts.svg`
to refresh a Graphviz diagram after editing its source.

[Lakehouse map](../lakehouse.md) · [Bronze to Silver guide](../bronze-to-silver.md)
