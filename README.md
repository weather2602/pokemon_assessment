# Pokemon Data Ingestion & Consolidated Staging Pipeline

A dbt-core and DuckDB pipeline that ingests two parallel raw JSON sources and produces a consolidated staging dataset.

The implementation is intentionally scoped to the **staging layer**, as requested by the assessment.

## 1. Architecture

```text
[pokemon-source-a.json]        [pokemon-source-b.json]
          │                              │
          ▼                              ▼
 [stg_pokemon_a]                 [stg_pokemon_b]
          │                              │
          └──────────────┬───────────────┘
                         │
                    UNION ALL
                         │
                         ▼
              [stg_pokemon_unified]
                         │
                         ▼
             [staged_pokemon_unified.csv]
```

The two source models normalize their respective schemas into a common structure. The unified staging model then reconciles overlapping records and removes duplicate logical records.

A downstream curated/gold layer is outside the scope of this assessment.

## 2. Project Structure

```text
├── data_profiling.ipynb
├── pokemon-source-a.json
├── pokemon-source-b.json
├── dbt_project.yml
├── profiles.yml
├── run_pipeline.py
├── requirements.txt
├── .pre-commit-config.yaml
├── .gitignore
├── staged_pokemon_unified.csv
├── models/
│   ├── raw/
│   │   └── sources.yml
│   └── staging/
│       ├── stg_pokemon_a.sql
│       ├── stg_pokemon_b.sql
│       ├── stg_pokemon_unified.sql
│       └── schema.yml
└── tests/
    ├── assert_total_stats_match_sum.sql
    └── assert_no_cross_source_conflicts.sql
```

## 3. Source Profiling

The supplied files were profiled before implementing the transformation logic.

Key findings:

- Source A contains 749 records.
- Source B contains 81 records.
- There are 28 Pokémon names present in both sources.
- 721 names are exclusive to Source A.
- 51 names are exclusive to Source B.
- `pokemon_name` is unique within each source and is therefore used as the natural/business key for reconciliation in this exercise.
- IDs are not unique because different forms, such as Mega Evolutions, can share a Pokedex ID.
- Source B contains exact duplicate records for `PumpkabooSmall Size` and `PumpkabooLarge Size`.
- The overlapping records were profiled and their stat values matched.
- The resulting consolidated dataset contains 800 unique Pokémon names.

## 4. Staging Logic

### Source-specific staging

`stg_pokemon_a` and `stg_pokemon_b`:

- Rename source-specific fields to a common snake_case schema.
- Cast numeric and boolean fields to appropriate types.
- Trim string values.
- Normalize Pokémon type values using `lower(trim(...))`.
- Preserve the originating source through `source_file`.
- Add `ingested_at` as pipeline metadata.
- Use `SELECT DISTINCT` to remove exact duplicate payloads within each source.

The type normalization handles representation differences such as:

```text
Source A: Ice
Source B: ice
```

Since casing does not carry meaning for Pokémon types, both are normalized to:

```text
ice
```

This allows the cross-source validation to focus on actual data conflicts rather than differences in string representation.

### Consolidated staging

`stg_pokemon_unified` combines both normalized sources using `UNION ALL`.

Overlapping records are reconciled using `pokemon_name` as the natural/business key. A deterministic `ROW_NUMBER()` ordering is used to select one record when the same Pokémon is present in both sources.

No source authority hierarchy was specified by the assessment. The source ordering therefore acts only as a deterministic fallback. In a production system, source precedence would be defined with the relevant data owners.

## 5. Data Quality Checks

The pipeline includes standard dbt schema tests and custom SQL assertions.

The custom checks validate:

- `total_stats` equals the sum of the six individual stats.
- Overlapping records do not contain conflicting normalized attributes.
- Required fields are not null.
- `pokemon_name` is unique within the staging models and final consolidated dataset.

The cross-source conflict check uses null-safe comparisons (`IS DISTINCT FROM`) so that genuine differences are detected without incorrectly treating two null values as a conflict.

## 6. Running Locally

### Prerequisites

- Python 3.11 or later
- pip

### Setup

Create and activate a virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
```

On Windows, activate it with:

```powershell
.venv\Scripts\activate
```

Install the project dependencies:

```bash
pip install -r requirements.txt
```

Install the Git hooks:

```bash
pre-commit install
```

The pre-commit hooks run the configured checks automatically before each commit. To run them manually across the repository:

```bash
pre-commit run --all-files
```

### Run the pipeline

Execute the pipeline:

```bash
python run_pipeline.py
```

The script performs the following steps:

1. Runs the dbt models to build the staging tables.
2. Executes the dbt schema tests and custom SQL assertions.
3. Exports `stg_pokemon_unified` to `staged_pokemon_unified.csv`.
4. Prints the exported row count and a sample of the resulting dataset.

The expected output contains **800 rows**.

The DuckDB database and CSV export are generated locally. The database path is configured in `profiles.yml`.

### Run dbt commands individually

The models and tests can also be executed directly:

```bash
dbt run --profiles-dir .
dbt test --profiles-dir .
```

The pipeline exports the consolidated dataset only after the dbt tests pass. If a test fails, the script exits with an error instead of exporting the data.

## 7. Production Considerations

For a production implementation, the local JSON files could be replaced by a GCS-based ingestion layer and BigQuery raw tables.

A possible architecture would be:

```text
GCS
 │
 ▼
BigQuery Raw
 │
 ▼
dbt / Dataform
 │
 ▼
BigQuery Staging
 │
 ▼
Downstream Analytics / ML
```

The dbt `source()` abstraction keeps the transformation models independent of the physical source path. When moving from DuckDB to BigQuery, the profile, source configuration, and any warehouse-specific SQL or functions would be adapted as required.

In a production environment, orchestration, CI/CD, monitoring, alerting, and additional data-quality checks would also be added according to the operational requirements.
