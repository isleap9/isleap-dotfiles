#!/usr/bin/env python3

import json
import urllib.request

CITY = "Bari"
UNIT = "m"

url = f"https://wttr.in/{CITY}?format=j1"

try:
    with urllib.request.urlopen(url, timeout=10) as response:
        data = json.loads(response.read().decode())

    current = data["current_condition"][0]

    temp = current["temp_C"] if UNIT == "m" else current["temp_F"]
    feels_like = current["FeelsLikeC"] if UNIT == "m" else current["FeelsLikeF"]
    humidity = current["humidity"]
    wind_speed = current["windspeedKmph"] if UNIT == "m" else current["windspeedMiles"]
    wind_unit = "km/h" if UNIT == "m" else "mph"
    description = current["weatherDesc"][0]["value"]
    visibility = current["visibility"]

    weather_icons = {
        "sunny": "☀️",
        "clear": "🌙",
        "cloud": "☁️",
        "overcast": "☁️",
        "mist": "🌫️",
        "fog": "🌫️",
        "rain": "🌧️",
        "drizzle": "🌦️",
        "snow": "❄️",
        "sleet": "🌨️",
        "thunder": "⛈️",
        "blizzard": "❄️",
    }

    def get_icon(desc):
        desc_lower = desc.lower()
        for key, val in weather_icons.items():
            if key in desc_lower:
                return val
        return "🌡️"

    icon = get_icon(description)

    # Build weekly forecast
    days = ["Today", "Tomorrow", "Day 3"]
    forecast_lines = []
    for i, weather in enumerate(data["weather"][:3]):
        day_desc = weather["hourly"][4]["weatherDesc"][0]["value"]
        day_icon = get_icon(day_desc)
        max_c = weather["maxtempC"] if UNIT == "m" else weather["maxtempF"]
        min_c = weather["mintempC"] if UNIT == "m" else weather["mintempF"]
        rain = weather["hourly"][4]["chanceofrain"]
        forecast_lines.append(
            f"{days[i]:<10} {day_icon} {day_desc:<20} ↑{max_c}° ↓{min_c}°  🌧️{rain}%"
        )

    forecast = "\n".join(forecast_lines)
    unit_sym = "C" if UNIT == "m" else "F"

    tooltip = (
        f"{description}\n"
        f"🌡️ Feels like {feels_like}°{unit_sym}\n"
        f"💧 Humidity {humidity}%\n"
        f"💨 Wind {wind_speed} {wind_unit}\n"
        f"👁️ Visibility {visibility} km\n"
        f"\n──────────────────────\n"
        f"{forecast}"
    )

    out = {
        "text": f"{icon} {temp}°{unit_sym}",
        "alt": description,
        "tooltip": tooltip,
        "class": "weather",
    }
    print(json.dumps(out))

except Exception as e:
    print(json.dumps({"text": "⚠️ N/A", "alt": str(e), "tooltip": str(e), "class": "error"}))
