#!/usr/bin/env python3
"""
Fetch earthquake data from the USGS Earthquake Catalog API and upsert into PostgreSQL.

Usage:
    python fetch_earthquakes.py <start_time> <end_time>
    e.g.: python fetch_earthquakes.py 2024-01-01 2024-01-02

Called by Airflow's fetch_and_load task with the DAG execution interval dates.
"""
import logging
import os
import sys

import psycopg2
import requests
from psycopg2.extras import execute_values

logger = logging.getLogger(__name__)

USGS_API_URL = "https://earthquake.usgs.gov/fdsnws/event/1/query"
MIN_MAGNITUDE = 2.5
MAX_RESULTS = 20000  # USGS hard limit per request


def get_db_connection() -> psycopg2.extensions.connection:
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "localhost"),
        port=int(os.environ.get("POSTGRES_PORT", "5432")),
        dbname=os.environ.get("POSTGRES_DB", "earthquake_dw"),
        user=os.environ.get("POSTGRES_USER", "postgres"),
        password=os.environ.get("POSTGRES_PASSWORD", "postgres"),
    )


def fetch_earthquakes(start_time: str, end_time: str) -> list[dict]:
    """Fetch earthquakes from the USGS API for a given time range (ISO 8601 strings)."""
    params = {
        "format": "geojson",
        "starttime": start_time,
        "endtime": end_time,
        "minmagnitude": MIN_MAGNITUDE,
        "orderby": "time",
        "limit": MAX_RESULTS,
    }

    logger.info("Fetching earthquakes from %s to %s", start_time, end_time)
    response = requests.get(USGS_API_URL, params=params, timeout=60)
    response.raise_for_status()

    features = response.json().get("features", [])
    logger.info("Fetched %d earthquakes", len(features))
    return features


def parse_feature(feature: dict) -> dict:
    """Parse a single GeoJSON feature into a flat dict matching raw.earthquakes columns."""
    props = feature["properties"]
    coords = feature["geometry"]["coordinates"]  # [longitude, latitude, depth_km]

    return {
        "id": feature["id"],
        "magnitude": props.get("mag"),
        "place": props.get("place"),
        "time_epoch": props.get("time"),
        "updated_epoch": props.get("updated"),
        "longitude": coords[0] if coords else None,
        "latitude": coords[1] if coords else None,
        "depth_km": coords[2] if coords else None,
        "mag_type": props.get("magType"),
        "event_type": props.get("type"),
        "tsunami": props.get("tsunami", 0),
        "significance": props.get("sig"),
        "alert": props.get("alert"),
        "status": props.get("status"),
        "net": props.get("net"),
        "nst": props.get("nst"),
        "dmin": props.get("dmin"),
        "rms": props.get("rms"),
        "gap": props.get("gap"),
        "title": props.get("title"),
    }


def upsert_earthquakes(conn: psycopg2.extensions.connection, rows: list[dict]) -> int:
    """Batch upsert earthquake rows into raw.earthquakes (INSERT ... ON CONFLICT UPDATE)."""
    if not rows:
        return 0

    columns = list(rows[0].keys())
    values = [[row[col] for col in columns] for row in rows]
    update_cols = [c for c in columns if c != "id"]
    update_set = ", ".join(f"{c} = EXCLUDED.{c}" for c in update_cols)

    sql = f"""
        INSERT INTO raw.earthquakes ({', '.join(columns)})
        VALUES %s
        ON CONFLICT (id) DO UPDATE SET
            {update_set},
            loaded_at = NOW()
    """

    with conn.cursor() as cur:
        execute_values(cur, sql, values)
    conn.commit()
    return len(rows)


def run(start_time: str, end_time: str) -> int:
    """End-to-end: fetch from USGS, parse, upsert to Postgres. Returns row count."""
    features = fetch_earthquakes(start_time, end_time)
    rows = [parse_feature(f) for f in features]

    # psycopg2's connection context manager ends the transaction but leaves the
    # connection open, so close it explicitly.
    conn = get_db_connection()
    try:
        count = upsert_earthquakes(conn, rows)
    finally:
        conn.close()

    logger.info("Upserted %d rows", count)
    return count


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    if len(sys.argv) != 3:
        print("Usage: fetch_earthquakes.py <start_time> <end_time>")
        print("  e.g.: fetch_earthquakes.py 2024-01-01 2024-01-02")
        sys.exit(1)
    run(sys.argv[1], sys.argv[2])
