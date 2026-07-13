-- CI-only Postgres setup: creates the raw schema and earthquakes table.
-- The full init.sh also creates the Airflow database, which is not needed in CI.
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.earthquakes (
    id              TEXT PRIMARY KEY,
    magnitude       NUMERIC(4, 2),
    place           TEXT,
    time_epoch      BIGINT,
    updated_epoch   BIGINT,
    longitude       NUMERIC(10, 6),
    latitude        NUMERIC(9, 6),
    depth_km        NUMERIC(8, 3),
    mag_type        TEXT,
    event_type      TEXT,
    tsunami         INTEGER DEFAULT 0,
    significance    INTEGER,
    alert           TEXT,
    status          TEXT,
    net             TEXT,
    nst             INTEGER,
    dmin            NUMERIC(10, 4),
    rms             NUMERIC(6, 3),
    gap             NUMERIC(6, 2),
    title           TEXT,
    loaded_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_earthquakes_time_epoch
    ON raw.earthquakes (time_epoch DESC);
CREATE INDEX IF NOT EXISTS idx_earthquakes_magnitude
    ON raw.earthquakes (magnitude DESC);
