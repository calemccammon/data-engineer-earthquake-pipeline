-- Singular test: assert that depth_class is consistent with the depth_km value.
-- Catches any regression in the depth classification logic.
select
    id,
    depth_km,
    depth_class,
    case
        when depth_km < 70  then 'shallow'
        when depth_km < 300 then 'intermediate'
        else                     'deep'
    end as expected_class
from {{ ref('int_earthquakes_classified') }}
where depth_km is not null
  and depth_class != case
    when depth_km < 70  then 'shallow'
    when depth_km < 300 then 'intermediate'
    else                     'deep'
end
