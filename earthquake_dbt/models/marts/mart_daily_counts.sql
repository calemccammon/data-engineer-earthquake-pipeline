-- Daily earthquake counts broken down by magnitude class.
-- Useful for spotting active periods and tracking distribution of event severity over time.
with facts as (

    select * from {{ ref('fact_earthquakes') }}

)

select
    occurred_date,
    magnitude_class,
    count(*)                                                    as earthquake_count,
    round(avg(magnitude)::numeric, 2)                          as avg_magnitude,
    max(magnitude)                                             as max_magnitude,
    min(magnitude)                                             as min_magnitude,
    round(avg(depth_km)::numeric, 1)                          as avg_depth_km,
    sum(case when is_tsunami_related then 1 else 0 end)        as tsunami_count
from facts
group by occurred_date, magnitude_class
