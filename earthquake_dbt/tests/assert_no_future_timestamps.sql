-- Singular test: assert no earthquake events have future timestamps.
-- A future occurred_at indicates a corrupted time_epoch value or a clock/timezone bug.
-- Allows a 1-hour buffer to account for any minor clock skew between data source and pipeline.
select id, occurred_at
from {{ ref('stg_earthquakes') }}
where occurred_at > now() + interval '1 hour'
