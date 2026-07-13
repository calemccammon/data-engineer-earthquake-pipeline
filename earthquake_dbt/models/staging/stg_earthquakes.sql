with source as (

    select * from {{ source('raw', 'earthquakes') }}

),

cleaned as (

    select
        id,
        magnitude,
        place,
        time_epoch,
        -- Convert USGS epoch-milliseconds to a proper UTC timestamp
        to_timestamp(time_epoch / 1000.0) at time zone 'UTC'    as occurred_at,
        to_timestamp(updated_epoch / 1000.0) at time zone 'UTC' as updated_at,
        longitude,
        latitude,
        depth_km,
        lower(mag_type)                                          as mag_type,
        lower(event_type)                                        as event_type,
        coalesce(tsunami, 0) = 1                                 as is_tsunami_related,
        significance,
        alert,
        lower(status)                                            as status,
        net,
        nst                                                      as num_stations,
        dmin                                                     as distance_to_station_deg,
        rms,
        gap                                                      as azimuthal_gap,
        title,
        loaded_at
    from source
    -- Only retain genuine earthquake events; exclude quarry blasts, explosions, etc.
    where lower(event_type) = 'earthquake'
      and magnitude is not null
      and time_epoch is not null

)

select * from cleaned
