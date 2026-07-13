-- Public-facing fact table: all classified earthquake events.
-- Downstream BI tools and analysis should query this model, not the staging or
-- intermediate models directly.
select * from {{ ref('int_earthquakes_classified') }}
