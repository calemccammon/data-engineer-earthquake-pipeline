-- Singular test: assert that magnitude_class is consistent with the magnitude value.
-- If a row's magnitude is in the 'great' range (≥7.0) but is classified differently,
-- the classification logic in int_earthquakes_classified is broken.
select
    id,
    magnitude,
    magnitude_class,
    case
        when magnitude < 2.5 then 'minor'
        when magnitude < 4.0 then 'light'
        when magnitude < 5.0 then 'moderate'
        when magnitude < 6.0 then 'strong'
        when magnitude < 7.0 then 'major'
        else                      'great'
    end as expected_class
from {{ ref('int_earthquakes_classified') }}
where magnitude_class != case
    when magnitude < 2.5 then 'minor'
    when magnitude < 4.0 then 'light'
    when magnitude < 5.0 then 'moderate'
    when magnitude < 6.0 then 'strong'
    when magnitude < 7.0 then 'major'
    else                      'great'
end
