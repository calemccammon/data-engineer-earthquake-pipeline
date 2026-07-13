-- Singular test: assert all magnitude values fall within a physically plausible range.
-- The smallest instrumentally recorded earthquakes are around -2; the largest ever
-- recorded was ~9.5. A value outside [-2, 10] indicates a data ingestion error.
select id, magnitude
from {{ ref('stg_earthquakes') }}
where magnitude < -2 or magnitude > 10
