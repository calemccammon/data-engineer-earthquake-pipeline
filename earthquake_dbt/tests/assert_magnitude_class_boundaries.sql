-- Singular test: the magnitude_class macro used by int_earthquakes_classified must
-- return the expected class on each side of every threshold. Returns the cases
-- where it does not.
with cases (magnitude, expected_class) as (

    values
        (2.5,  'minor'),
        (3.99, 'minor'),
        (4.0,  'light'),
        (4.99, 'light'),
        (5.0,  'moderate'),
        (5.99, 'moderate'),
        (6.0,  'strong'),
        (6.99, 'strong'),
        (7.0,  'major'),
        (7.99, 'major'),
        (8.0,  'great'),
        (9.5,  'great')

)

select
    magnitude,
    expected_class,
    {{ magnitude_class('magnitude') }} as actual_class
from cases
where {{ magnitude_class('magnitude') }} != expected_class
