-- Aggregate earthquake statistics by geographic region.
-- Identifies earthquake hot-spots, average depths, and historical significance.
with facts as (

    select * from {{ ref('fact_earthquakes') }}

)

select
    region,
    count(*)                                                        as total_earthquakes,
    round(avg(magnitude)::numeric, 2)                              as avg_magnitude,
    max(magnitude)                                                 as max_magnitude,
    round(avg(depth_km)::numeric, 1)                              as avg_depth_km,
    sum(case when magnitude_class in ('major', 'great') then 1 else 0 end)
                                                                   as major_plus_count,
    sum(case when is_tsunami_related then 1 else 0 end)            as tsunami_count,
    count(distinct occurred_date)                                  as active_days,
    min(occurred_at)                                               as first_recorded_at,
    max(occurred_at)                                               as latest_recorded_at
from facts
group by region
order by total_earthquakes desc
