pragma Singleton

import QtQuick
import Quickshell

// Weather for the dashboard, from Open-Meteo (free, no API key — the same source DMS uses).
// The city is the one in Settings → Bar → Weather city. Refreshes every 15 minutes.
Singleton {
    id: root

    readonly property string city: Config.bar.weatherCity
    readonly property bool imperial: Config.dashboard.units === "imperial"
    readonly property string tempUnit: imperial ? "°F" : "°C"
    readonly property string windUnit: imperial ? "mph" : "km/h"

    property bool loading: false
    property string error: ""
    property string place: ""           // "Bari, Italy"
    property var current: null          // { temp, feels, humidity, code, isDay, wind, windDir, pressure, uv, visibility, clouds, precip }
    property var hourly: []             // next 24 hours: [{ time: Date, temp, code, isDay, rain }]
    property var daily: []              // 7 days: [{ date: Date, max, min, code, rain, sunrise: Date, sunset: Date, uv }]
    property date updated

    readonly property bool ready: current !== null

    // ── WMO weather codes ──
    function describe(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mainly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 55) return "Drizzle";
        if (code === 56 || code === 57) return "Freezing drizzle";
        if (code === 61) return "Light rain";
        if (code === 63) return "Rain";
        if (code === 65) return "Heavy rain";
        if (code === 66 || code === 67) return "Freezing rain";
        if (code === 71) return "Light snow";
        if (code === 73) return "Snow";
        if (code === 75) return "Heavy snow";
        if (code === 77) return "Snow grains";
        if (code >= 80 && code <= 82) return "Showers";
        if (code === 85 || code === 86) return "Snow showers";
        if (code === 95) return "Thunderstorm";
        if (code === 96 || code === 99) return "Thunderstorm, hail";
        return "Unknown";
    }

    // Material Symbols weather icon name
    function icon(code, isDay) {
        const day = isDay !== false;
        if (code === 0 || code === 1) return day ? "sunny" : "clear_night";
        if (code === 2) return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3) return "cloud";
        if (code === 45 || code === 48) return "foggy";
        if (code >= 51 && code <= 57) return "rainy";
        if (code === 61 || code === 80) return "rainy";
        if (code === 63 || code === 65 || code === 81 || code === 82) return "rainy_heavy";
        if (code === 66 || code === 67) return "weather_mix";
        if (code === 71 || code === 77 || code === 85) return "weather_snowy";
        if (code === 73 || code === 75 || code === 86) return "snowing_heavy";
        if (code === 95) return "thunderstorm";
        if (code === 96 || code === 99) return "thunderstorm";
        return "cloud";
    }

    function temp(v) { return v === undefined || v === null ? "--" : Math.round(v) + "°"; }

    // Compass direction for wind (degrees → "NE")
    function compass(deg) {
        return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(((deg % 360) / 45)) % 8];
    }

    // ── Fetching ──
    property var coords: null           // { lat, lon, name } for `city`
    onCityChanged: { coords = null; refresh(); }
    onImperialChanged: refresh()

    function get(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) { fail(`No connection (${xhr.status || "offline"})`); return; }
            try { done(JSON.parse(xhr.responseText)); }
            catch (e) { fail("Couldn't read the forecast"); }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fail(msg) {
        loading = false;
        error = msg;
    }

    function refresh() {
        if (!city) { fail("Set a city in Settings → Bar"); return; }
        loading = true;
        if (coords) { fetchForecast(); return; }
        get(`https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&name=${encodeURIComponent(city)}`, data => {
            const r = data.results?.[0];
            if (!r) { fail(`City "${city}" not found`); return; }
            coords = { lat: r.latitude, lon: r.longitude };
            place = r.country ? `${r.name}, ${r.country}` : r.name;
            fetchForecast();
        });
    }

    function fetchForecast() {
        const units = imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch" : "";
        const url = "https://api.open-meteo.com/v1/forecast"
            + `?latitude=${coords.lat}&longitude=${coords.lon}&timezone=auto&forecast_days=7${units}`
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,"
            + "wind_speed_10m,wind_direction_10m,pressure_msl,uv_index,visibility,cloud_cover,precipitation"
            + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,"
            + "precipitation_probability_max,uv_index_max";
        get(url, data => {
            const c = data.current;
            current = {
                temp: c.temperature_2m, feels: c.apparent_temperature, humidity: c.relative_humidity_2m,
                code: c.weather_code, isDay: c.is_day === 1, wind: c.wind_speed_10m, windDir: c.wind_direction_10m,
                pressure: c.pressure_msl, uv: c.uv_index, visibility: c.visibility, clouds: c.cloud_cover,
                precip: c.precipitation
            };
            // Hourly: from the current hour, 24 entries
            const h = data.hourly;
            const now = new Date();
            now.setMinutes(0, 0, 0);
            const hours = [];
            for (let i = 0; i < h.time.length && hours.length < 24; i++) {
                const t = new Date(h.time[i]);
                if (t < now) continue;
                hours.push({ time: t, temp: h.temperature_2m[i], code: h.weather_code[i],
                             isDay: h.is_day[i] === 1, rain: h.precipitation_probability[i] ?? 0 });
            }
            hourly = hours;
            const d = data.daily;
            daily = d.time.map((t, i) => ({
                date: new Date(t + "T12:00"), max: d.temperature_2m_max[i], min: d.temperature_2m_min[i],
                code: d.weather_code[i], rain: d.precipitation_probability_max[i] ?? 0,
                sunrise: new Date(d.sunrise[i]), sunset: new Date(d.sunset[i]), uv: d.uv_index_max[i]
            }));
            updated = new Date();
            error = "";
            loading = false;
        });
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
