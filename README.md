# 🌍 data-engineer-earthquake-pipeline

> A batch ELT pipeline using **Apache Airflow + dbt + PostgreSQL** — ingesting live seismic data
> from the USGS Earthquake Catalog API, transforming it through layered dbt models, validating
> data quality with dbt tests, and publishing auto-generated lineage documentation to GitHub Pages.

📖 **[dbt Docs (Model Lineage)](https://calemccammon.github.io/data-engineer-earthquake-pipeline/)**

---

## Why This Project

| Concept | This project | Prior projects |
|---|---|---|
| **Orchestration** | Airflow DAGs (scheduling, retries, task graph) | None |
| **Transformation** | dbt (SQL-first, lineage, docs, tests) | Raw SQL / Python |
| **Warehouse** | PostgreSQL (local, relational) | BigQuery (cloud), DuckDB (embedded) |
| **Data quality** | dbt generic + singular tests | None |
| **BI / Visualization** | Metabase (connected to marts schema) | Custom dashboards |
| **Documentation** | Auto-generated dbt docs site | Hand-written / OpenAPI |

---

## Architecture

```
USGS Earthquake Catalog API  (free, no auth, ~150 events/day ≥ M2.5)
         │
         │  Airflow DAG: earthquake_pipeline (runs @daily)
         ▼
┌─────────────────────┐
│  fetch_and_load     │  PythonOperator — calls USGS GeoJSON API for the execution
│  (PythonOperator)   │  interval, parses features, upserts into raw.earthquakes
└────────┬────────────┘
         ▼
┌─────────────────────┐
│  PostgreSQL         │  raw.earthquakes — one row per event, loaded by Airflow
│  raw schema         │
└────────┬────────────┘
         │
         │  dbt run
         ▼
┌───────────────────────────────────────────────────┐
│  dbt Transformation Layers                        │
│                                                   │
│  staging/                                         │
│    stg_earthquakes          (view)                │
│      └─ cast types, filter event_type, rename     │
│                                                   │
│  intermediate/                                    │
│    int_earthquakes_classified  (view)             │
│      └─ magnitude_class, depth_class, region      │
│                                                   │
│  marts/                                           │
│    fact_earthquakes         (table)               │
│    mart_daily_counts        (table)               │
│    mart_regional_stats      (table)               │
└────────┬──────────────────────────────────────────┘
         │
         │  dbt test
         ▼
┌─────────────────────────────────┐
│  Data Quality Tests             │
│  • not_null / unique (generic)  │
│  • accepted_values (generic)    │
│  • no future timestamps (custom)│
│  • valid magnitude range (custom│
└────────┬────────────────────────┘
     │
     ▼
┌─────────────────────┐
│  Metabase           │  BI dashboards querying marts schema directly
│  localhost:3000     │  fact_earthquakes, mart_daily_counts, mart_regional_stats
└─────────────────────┘
```

---

## Tech Stack

| Layer | Tool | Version |
|---|---|---|
| Language | Python + SQL | Python 3.12 |
| Orchestration | Apache Airflow | 2.10 |
| Transformation | dbt-postgres | 1.9 |
| Warehouse | PostgreSQL | 16 |
| BI / Dashboards | Metabase | latest |
| Infrastructure | Docker Compose | – |
| Data source | USGS Earthquake Catalog API | GeoJSON |
| CI | GitHub Actions | – |
| Docs | dbt docs → GitHub Pages | – |

---

## dbt Model Lineage

```
Source: raw.earthquakes
    └── stg_earthquakes            (staging — clean, typed, filtered)
            └── int_earthquakes_classified  (intermediate — magnitude/depth/region classes)
                    ├── fact_earthquakes       (mart — full fact table for analysis)
                    ├── mart_daily_counts      (mart — daily counts by magnitude class)
                    └── mart_regional_stats    (mart — per-region aggregated stats)
```

**Schemas:**
- `raw` — loaded by Airflow; never queried by downstream tools directly
- `staging` — cleaned source views; internal to dbt
- `intermediate` — derived/enriched views; internal to dbt
- `marts` — public-facing materialised tables for BI / analysis

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

## Quick Start

```bash
# 1. Clone and configure
git clone https://github.com/calemccammon/data-engineer-earthquake-pipeline.git
cd data-engineer-earthquake-pipeline
cp .env.example .env        # optionally change passwords

# 2. Build and start all services
docker compose up --build -d

# 3. Wait ~60 seconds for Airflow to initialise, then open:
#    Airflow UI   →  http://localhost:8080  (admin / admin)
#    Metabase     →  http://localhost:3000  (setup wizard on first visit)
#    pgAdmin      →  connect to localhost:5432 (postgres / postgres)
```

### Trigger a pipeline run

In the Airflow UI at `http://localhost:8080`:
1. Find the **earthquake_pipeline** DAG
2. Click the ▶ (trigger) button to run it for today
3. Watch the task graph: `fetch_and_load → dbt_run → dbt_test`

To backfill historical data, use the **Trigger DAG w/ config** button and set a custom logical date, or use the Airflow CLI:

```bash
docker compose exec airflow airflow dags backfill earthquake_pipeline \
  --start-date 2024-01-01 --end-date 2024-01-31 --reset-dagruns
```

### Query the marts

```bash
# Connect with psql
docker compose exec postgres psql -U postgres -d earthquake_dw

-- Which regions have the most earthquakes?
SELECT region, total_earthquakes, avg_magnitude, major_plus_count
FROM marts.mart_regional_stats
LIMIT 20;

-- Daily strong+ earthquake counts
SELECT occurred_date, earthquake_count
FROM marts.mart_daily_counts
WHERE magnitude_class IN ('strong', 'major', 'great')
ORDER BY occurred_date DESC;
```

---

## dbt Docs

The dbt docs site (with interactive lineage graph) is deployed to GitHub Pages automatically on every push to `main`:

📖 **[https://calemccammon.github.io/data-engineer-earthquake-pipeline/](https://calemccammon.github.io/data-engineer-earthquake-pipeline/)**

To generate docs locally:

```bash
cd earthquake_dbt
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .   # opens browser at localhost:8080
```

## Screenshots

**Metabase — Live Earthquake Data**

![Metabase earthquake data browser](docs/metabase-earthquakes.png)

---

To enable GitHub Pages for your fork:
> **Settings → Pages → Source → GitHub Actions**

---

## Project Structure

```
data-engineer-earthquake-pipeline/
├── Dockerfile                        # Custom Airflow image with dbt + psycopg2
├── docker-compose.yml                # Postgres + Airflow (LocalExecutor)
├── requirements-airflow.txt          # Python deps baked into Docker image
├── requirements.txt                  # Local dev deps
├── .env.example                      # Environment variable template
│
├── dags/
│   └── earthquake_pipeline.py        # Airflow DAG definition
│
├── scripts/
│   ├── init.sh                       # Postgres init: creates airflow DB + raw schema
│   ├── init_ci.sql                   # CI-only Postgres setup (no airflow DB)
│   ├── fetch_earthquakes.py          # USGS API fetch + upsert logic
│   └── seed_test_data.sql            # Sample rows for CI testing
│
├── earthquake_dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml                  # DB connection (reads from env vars)
│   ├── macros/
│   │   └── generate_schema_name.sql  # Use clean schema names (not analytics_staging)
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml
│   │   │   ├── stg_earthquakes.sql
│   │   │   └── schema.yml
│   │   ├── intermediate/
│   │   │   ├── int_earthquakes_classified.sql
│   │   │   └── schema.yml
│   │   └── marts/
│   │       ├── fact_earthquakes.sql
│   │       ├── mart_daily_counts.sql
│   │       ├── mart_regional_stats.sql
│   │       └── schema.yml
│   └── tests/
│       ├── assert_no_future_timestamps.sql
│       └── assert_valid_magnitude_range.sql
│
├── docs/
│   └── index.html                    # GitHub Pages landing (replaced by dbt docs on deploy)
│
└── .github/workflows/
    ├── dbt-test.yml                  # Run dbt tests on every push/PR
    └── dbt-docs.yml                  # Generate + deploy dbt docs to GitHub Pages
```

---

## Data Source

[USGS Earthquake Catalog API](https://earthquake.usgs.gov/fdsnws/event/1/) — completely free, no API key, real-time global seismic data.

The pipeline fetches events with **M ≥ 2.5** (roughly 150–300 events per day globally).

**Key fields ingested:**

| Field | Description |
|---|---|
| `id` | Unique USGS event ID |
| `magnitude` | Event magnitude |
| `place` | Human-readable location (e.g. "15km NW of Parkfield, California") |
| `time_epoch` | Origin time as Unix ms |
| `longitude / latitude / depth_km` | Epicenter coordinates |
| `mag_type` | Magnitude scale used (mw, ml, md, mb…) |
| `tsunami` | 1 if a tsunami message was issued |
| `significance` | USGS significance score (0–1000+) |
| `alert` | PAGER alert level (green/yellow/orange/red) |
