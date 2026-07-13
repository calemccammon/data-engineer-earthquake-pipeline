"""
Unit tests for scripts/fetch_earthquakes.py

Tests cover parse_feature() edge cases and upsert SQL generation.
No database or network connections required — all external calls are mocked.
"""
import sys
import os
import pytest
from unittest.mock import MagicMock, patch, call

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))
from fetch_earthquakes import parse_feature, upsert_earthquakes, fetch_earthquakes


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def make_feature(
    id="us7000abcd",
    mag=4.5,
    place="15km NW of Parkfield, California",
    time=1704067200000,
    updated=1704070800000,
    coords=[-120.43, 35.91, 8.2],
    mag_type="mw",
    event_type="earthquake",
    tsunami=0,
    sig=312,
    alert=None,
    status="reviewed",
    net="us",
    nst=22,
    dmin=0.089,
    rms=0.31,
    gap=156,
    title="M 4.5 - 15km NW of Parkfield, California",
):
    return {
        "id": id,
        "properties": {
            "mag": mag,
            "place": place,
            "time": time,
            "updated": updated,
            "magType": mag_type,
            "type": event_type,
            "tsunami": tsunami,
            "sig": sig,
            "alert": alert,
            "status": status,
            "net": net,
            "nst": nst,
            "dmin": dmin,
            "rms": rms,
            "gap": gap,
            "title": title,
        },
        "geometry": {"type": "Point", "coordinates": coords},
    }


# ---------------------------------------------------------------------------
# parse_feature tests
# ---------------------------------------------------------------------------

class TestParseFeature:

    def test_full_feature_maps_all_fields(self):
        row = parse_feature(make_feature())
        assert row["id"] == "us7000abcd"
        assert row["magnitude"] == 4.5
        assert row["place"] == "15km NW of Parkfield, California"
        assert row["time_epoch"] == 1704067200000
        assert row["updated_epoch"] == 1704070800000
        assert row["longitude"] == -120.43
        assert row["latitude"] == 35.91
        assert row["depth_km"] == 8.2
        assert row["mag_type"] == "mw"
        assert row["event_type"] == "earthquake"
        assert row["tsunami"] == 0
        assert row["significance"] == 312
        assert row["alert"] is None
        assert row["status"] == "reviewed"
        assert row["net"] == "us"

    def test_null_magnitude_is_preserved(self):
        row = parse_feature(make_feature(mag=None))
        assert row["magnitude"] is None

    def test_null_coordinates_produce_none_fields(self):
        feature = make_feature()
        feature["geometry"]["coordinates"] = []
        row = parse_feature(feature)
        assert row["longitude"] is None
        assert row["latitude"] is None
        assert row["depth_km"] is None

    def test_tsunami_flag_1_is_preserved(self):
        row = parse_feature(make_feature(tsunami=1))
        assert row["tsunami"] == 1

    def test_alert_green_is_preserved(self):
        row = parse_feature(make_feature(alert="green"))
        assert row["alert"] == "green"

    def test_missing_optional_fields_default_to_none(self):
        feature = make_feature()
        del feature["properties"]["nst"]
        del feature["properties"]["dmin"]
        del feature["properties"]["gap"]
        row = parse_feature(feature)
        assert row["nst"] is None
        assert row["dmin"] is None
        assert row["gap"] is None

    def test_quarry_blast_event_type_is_passed_through(self):
        """parse_feature does not filter — filtering is handled in dbt staging."""
        row = parse_feature(make_feature(event_type="quarry blast"))
        assert row["event_type"] == "quarry blast"

    def test_negative_magnitude_allowed(self):
        """Very small local events can have negative magnitudes."""
        row = parse_feature(make_feature(mag=-0.5))
        assert row["magnitude"] == -0.5

    def test_large_magnitude_allowed(self):
        row = parse_feature(make_feature(mag=9.1))
        assert row["magnitude"] == 9.1

    def test_deep_earthquake_depth_preserved(self):
        row = parse_feature(make_feature(coords=[139.7, 35.7, 600.0]))
        assert row["depth_km"] == 600.0

    def test_southern_hemisphere_coords(self):
        row = parse_feature(make_feature(coords=[170.1, -14.6, 35.0]))
        assert row["latitude"] == -14.6
        assert row["longitude"] == 170.1


# ---------------------------------------------------------------------------
# fetch_earthquakes tests (mocked HTTP)
# ---------------------------------------------------------------------------

class TestFetchEarthquakes:

    def test_returns_features_list(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "type": "FeatureCollection",
            "features": [make_feature(), make_feature(id="us7000abce")],
        }
        with patch("fetch_earthquakes.requests.get", return_value=mock_response):
            result = fetch_earthquakes("2024-01-01", "2024-01-02")
        assert len(result) == 2

    def test_empty_response_returns_empty_list(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"type": "FeatureCollection", "features": []}
        with patch("fetch_earthquakes.requests.get", return_value=mock_response):
            result = fetch_earthquakes("2024-01-01", "2024-01-02")
        assert result == []

    def test_passes_correct_params_to_usgs_api(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"features": []}
        with patch("fetch_earthquakes.requests.get", return_value=mock_response) as mock_get:
            fetch_earthquakes("2024-06-01", "2024-06-02")
        _, kwargs = mock_get.call_args
        params = kwargs["params"]
        assert params["starttime"] == "2024-06-01"
        assert params["endtime"] == "2024-06-02"
        assert params["format"] == "geojson"
        assert params["minmagnitude"] == 2.5

    def test_raises_on_http_error(self):
        mock_response = MagicMock()
        mock_response.raise_for_status.side_effect = Exception("HTTP 503")
        with patch("fetch_earthquakes.requests.get", return_value=mock_response):
            with pytest.raises(Exception, match="HTTP 503"):
                fetch_earthquakes("2024-01-01", "2024-01-02")


# ---------------------------------------------------------------------------
# upsert_earthquakes tests (mocked DB)
# ---------------------------------------------------------------------------

class TestUpsertEarthquakes:

    def test_empty_rows_returns_zero(self):
        conn = MagicMock()
        result = upsert_earthquakes(conn, [])
        assert result == 0
        conn.commit.assert_not_called()

    def test_returns_row_count(self):
        conn = MagicMock()
        conn.cursor.return_value.__enter__ = MagicMock(return_value=MagicMock())
        conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
        rows = [parse_feature(make_feature()), parse_feature(make_feature(id="us7000abce"))]
        with patch("fetch_earthquakes.execute_values"):
            result = upsert_earthquakes(conn, rows)
        assert result == 2

    def test_commits_after_upsert(self):
        conn = MagicMock()
        conn.cursor.return_value.__enter__ = MagicMock(return_value=MagicMock())
        conn.cursor.return_value.__exit__ = MagicMock(return_value=False)
        with patch("fetch_earthquakes.execute_values"):
            upsert_earthquakes(conn, [parse_feature(make_feature())])
        conn.commit.assert_called_once()
