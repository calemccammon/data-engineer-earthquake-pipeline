with staged as (

    select * from {{ ref('stg_earthquakes') }}

),

classified as (

    select
        *,

        -- The classification expressions live in macros/classify.sql so the
        -- singular tests can check the same code against literal boundary values.
        {{ magnitude_class('magnitude') }}   as magnitude_class,
        {{ depth_class('depth_km') }}        as depth_class,
        {{ region_from_place('place') }}     as region,

        date_trunc('day',  occurred_at)      as occurred_date,
        extract(hour from occurred_at)::int  as occurred_hour

    from staged

)

select * from classified
