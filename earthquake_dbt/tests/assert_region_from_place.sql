-- Singular test: the region_from_place macro used by int_earthquakes_classified must
-- return the text after the last comma, the whole string when there is no comma,
-- and 'Unknown' for a missing or blank place. Returns the cases where it does not.
with cases (place, expected_region) as (

    values
        ('15km NW of Parkfield, California',   'California'),
        ('5 km S of Town, County, California', 'California'),
        ('Off the coast of Oregon',            'Off the coast of Oregon'),
        ('  South Sandwich Islands region ',   'South Sandwich Islands region'),
        ('',                                   'Unknown'),
        (null,                                 'Unknown')

)

select
    place,
    expected_region,
    {{ region_from_place('place') }} as actual_region
from cases
where {{ region_from_place('place') }} != expected_region
