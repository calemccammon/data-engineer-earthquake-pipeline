{#
  Classification expressions shared by int_earthquakes_classified and the
  singular tests that check their boundaries against literal values.
#}

{% macro magnitude_class(magnitude) -%}
    {#- Conventional magnitude class names: minor below 4, light 4, moderate 5,
        strong 6, major 7, great 8 and above. -#}
    case
        when {{ magnitude }} < 4.0 then 'minor'
        when {{ magnitude }} < 5.0 then 'light'
        when {{ magnitude }} < 6.0 then 'moderate'
        when {{ magnitude }} < 7.0 then 'strong'
        when {{ magnitude }} < 8.0 then 'major'
        else                            'great'
    end
{%- endmacro %}

{% macro depth_class(depth_km) -%}
    {#- Focal depth classes: shallow below 70 km, intermediate below 300 km, deep beyond. -#}
    case
        when {{ depth_km }} < 70  then 'shallow'
        when {{ depth_km }} < 300 then 'intermediate'
        else                           'deep'
    end
{%- endmacro %}

{% macro region_from_place(place) -%}
    {#- USGS place strings look like "15km NW of Parkfield, California". The region is
        the text after the last comma, or the whole string when there is no comma.
        A missing or blank place becomes 'Unknown'. -#}
    coalesce(nullif(trim(regexp_replace({{ place }}, '.*,\s*', '')), ''), 'Unknown')
{%- endmacro %}
