-- Test data for CI: inserts sample rows into raw.earthquakes so dbt models
-- and tests can run without calling the real USGS API.
-- This file is used by the GitHub Actions dbt-test workflow.
INSERT INTO raw.earthquakes (id, magnitude, place, time_epoch, updated_epoch,
    longitude, latitude, depth_km, mag_type, event_type, tsunami, significance,
    alert, status, net, nst, dmin, rms, gap, title)
VALUES
    ('us7000abcd', 6.2, '15km NW of Parkfield, California',  1704067200000, 1704070800000, -120.4312, 35.9145,  8.2, 'mw', 'earthquake', 0, 612, NULL,    'reviewed', 'us', 45, 0.123, 0.45, 132, 'M 6.2 - 15km NW of Parkfield, California'),
    ('us7000abce', 4.5, '23km SSE of Hilo, Hawaii',          1704153600000, 1704157200000, -154.9201, 19.5833, 35.0, 'ml', 'earthquake', 0, 312, NULL,    'reviewed', 'hv', 22, 0.089, 0.31, 156, 'M 4.5 - 23km SSE of Hilo, Hawaii'),
    ('us7000abcf', 5.8, '80km W of Unalaska, Alaska',        1704240000000, 1704243600000, -167.2341, 53.8901, 50.4, 'mw', 'earthquake', 0, 520, NULL,    'reviewed', 'ak', 38, 0.245, 0.52,  98, 'M 5.8 - 80km W of Unalaska, Alaska'),
    ('us7000abcg', 3.1, '4km E of Morgan Hill, California',  1704326400000, 1704330000000, -121.6012, 37.1302, 12.1, 'md', 'earthquake', 0, 148, NULL,    'reviewed', 'nc', 18, 0.034, 0.22, 245, 'M 3.1 - 4km E of Morgan Hill, California'),
    ('us7000abch', 7.1, '150km SE of Apia, Samoa',           1704412800000, 1704416400000, -170.1234,-14.5678, 35.0, 'mw', 'earthquake', 1, 800, 'green', 'reviewed', 'us', 62, 1.234, 0.61,  45, 'M 7.1 - 150km SE of Apia, Samoa'),
    ('us7000abci', 2.8, '12km NE of Ridgecrest, California', 1704499200000, 1704502800000, -117.6234, 35.7891,  6.3, 'ml', 'earthquake', 0, 112, NULL,    'reviewed', 'ci', 14, 0.056, 0.19, 312, 'M 2.8 - 12km NE of Ridgecrest, California'),
    ('us7000abcj', 5.1, '35km NE of Kathmandu, Nepal',       1704585600000, 1704589200000,   85.4512, 27.9234, 20.0, 'mw', 'earthquake', 0, 433, NULL,    'reviewed', 'us', 55, 0.678, 0.48,  88, 'M 5.1 - 35km NE of Kathmandu, Nepal'),
    ('us7000abck', 6.8, 'Off the coast of Oregon',           1704672000000, 1704675600000, -126.7890, 44.2345, 15.0, 'mw', 'earthquake', 0, 710, NULL,    'reviewed', 'us', 71, 0.892, 0.57,  62, 'M 6.8 - Off the coast of Oregon'),
    ('us7000abcl', 4.2, '8km SW of Mammoth Lakes, California',1704758400000, 1704762000000,-119.0234, 37.6012,  7.8, 'md', 'earthquake', 0, 276, NULL,    'reviewed', 'mb', 25, 0.067, 0.28, 198, 'M 4.2 - 8km SW of Mammoth Lakes, California'),
    ('us7000abcm', 3.7, '20km W of Anchorage, Alaska',       1704844800000, 1704848400000, -150.4567, 61.2123, 55.2, 'ml', 'earthquake', 0, 212, NULL,    'reviewed', 'ak', 31, 0.412, 0.35, 178, 'M 3.7 - 20km W of Anchorage, Alaska')
ON CONFLICT (id) DO NOTHING;
