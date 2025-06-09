#!/usr/bin/env python3

import requests
import json
from decimal import Decimal, ROUND_HALF_UP
import cgi
import cgitb

cgitb.enable()  # Show traceback in browser if error occurs

def convert_meter_per_second_to_knots(mps):
    knots = Decimal(mps) * Decimal('1.94384449')
    return float(knots.quantize(Decimal('0.1'), rounding=ROUND_HALF_UP))

def get_wind_data(station_code):
    uri = "https://actuelewind.nl/getActualSpotData6.php"

    try:
        response = requests.get(uri)
        response.raise_for_status()

        data = response.json()
        spot_data = data['wind'][station_code]

        station_name = spot_data['windspot']['stationnaam']
        windrichting_van = spot_data['windspot']['windrichtingVan']
        windrichting_tot = spot_data['windspot']['windrichtingTot']
        latest = spot_data['winddata'][0]

        windsnelheid_knots = convert_meter_per_second_to_knots(latest['windsnelheidMS'])
        windrichting_gr = latest['windrichtingGR']

        result = {
            "locatie": station_name,
            "windrichtingVan": windrichting_van,
            "windrichtingTot": windrichting_tot,
            "Windsnelheid": windsnelheid_knots,
            "windrichtingGR": windrichting_gr
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