#!/usr/bin/env python3

import requests
import json
from decimal import Decimal, ROUND_HALF_UP
import cgi
import cgitb

cgitb.enable()  # Show traceback in browser if error occurs

WATERINFO_BASE_URL = "https://waterinfo.rws.nl"
WIND_MAP_TYPE = "wind"
WIND_DIRECTION_PARAMETER = "Windrichting___20in___20Lucht___20t.o.v.___20ware___20Noorden___20in___20graad"
STATION_CODE_MAP = {
    "6225": "ijmuiden.buitenhaven",
}

def convert_meter_per_second_to_knots(mps):
    knots = Decimal(mps) * Decimal('1.94384449')
    return float(knots.quantize(Decimal('0.1'), rounding=ROUND_HALF_UP))

def resolve_location_code(station_code):
    station_code = str(station_code).strip()
    return STATION_CODE_MAP.get(station_code, station_code)

def get_direction_measurement(location_code, headers):
    uri = f"{WATERINFO_BASE_URL}/api/point/latestmeasurement"
    response = requests.get(
        uri,
        params={"parameterId": WIND_MAP_TYPE},
        headers=headers,
        timeout=10,
    )
    response.raise_for_status()

    for feature in response.json().get("features", []):
        properties = feature.get("properties", {})
        if properties.get("locationCode") != location_code:
            continue

        for measurement in properties.get("measurements", []):
            if measurement.get("parameterId") == WIND_DIRECTION_PARAMETER:
                return measurement

    return None

def get_wind_data(station_code):
    location_code = resolve_location_code(station_code)
    headers = {'User-Agent': 'ActueleWind-Script/1.0'}
    uri = f"{WATERINFO_BASE_URL}/api/detail/get"

    try:
        response = requests.get(
            uri,
            params={"locationCode": location_code, "mapType": WIND_MAP_TYPE},
            headers=headers,
            timeout=10,
        )
        response.raise_for_status()

        data = response.json()
        latest = data.get('latest')
        if not latest:
            raise ValueError(f"No current wind speed found for location '{location_code}'")

        direction = get_direction_measurement(location_code, headers)

        station_name = data['location']
        windsnelheid_knots = convert_meter_per_second_to_knots(latest['data'])
        windrichting_gr = direction.get('latestValue') if direction else None

        result = {
            "locatie": station_name,
            "windrichtingVan": None,
            "windrichtingTot": None,
            "Windsnelheid": windsnelheid_knots,
            "windrichtingGR": windrichting_gr,
            "bron": "Rijkswaterstaat Waterinfo",
            "refreshSeconds": int(data.get("refreshSpeedInMs", 0) / 1000)
        }

        return {
            "statusCode": 200,
            "body": json.dumps(result, ensure_ascii=False)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error fetching/parsing wind data: {str(e)}"
        }

# Handle CGI parameters
form = cgi.FieldStorage()
station_code = form.getfirst("station", "6225")  # Default changed to 6225
result = get_wind_data(station_code)

# Output response
print("Content-Type: application/json\n")
print(result["body"])
