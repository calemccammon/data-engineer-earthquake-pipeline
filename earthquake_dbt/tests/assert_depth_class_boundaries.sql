-- Singular test: the depth_class macro used by int_earthquakes_classified must
-- return the expected class on each side of every threshold. Returns the cases
-- where it does not.
with cases (depth_km, expected_class) as (

    values
        (0.0,   'shallow'),
        (69.9,  'shallow'),
        (70.0,  'intermediate'),
        (299.9, 'intermediate'),
        (300.0, 'deep'),
        (650.0, 'deep')

)

select
    depth_km,
    expected_class,
    {{ depth_class('depth_km') }} as actual_class
from cases
where {{ depth_class('depth_km') }} != expected_class
