with staged as (

    select * from {{ ref('stg_earthquakes') }}

),

classified as (

    select
        *,

        -- Richter / moment magnitude classification (standard seismology scale)
        case
            when magnitude < 2.5 then 'minor'
            when magnitude < 4.0 then 'light'
            when magnitude < 5.0 then 'moderate'
            when magnitude < 6.0 then 'strong'
            when magnitude < 7.0 then 'major'
            else                      'great'
        end as magnitude_class,

        -- Focal depth classification (USGS / ISC standard)
        case
            when depth_km < 70  then 'shallow'
            when depth_km < 300 then 'intermediate'
            else                     'deep'
        end as depth_class,

        -- Extract the broadest region token from USGS place strings.
        -- USGS format: "X km DIRECTION of Location, Region"
        -- e.g. "15km NW of Parkfield, California" -> "California"
        -- Uses regexp_replace with greedy match to grab everything after the last comma.
        case
            when place ~ '.*,.*'
            then trim(regexp_replace(place, '.*,\s*', ''))
            else trim(place)
        end as region,

        date_trunc('day',  occurred_at)      as occurred_date,
        extract(hour from occurred_at)::int  as occurred_hour

    from staged

)

select * from classified
