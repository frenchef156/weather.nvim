local M = {}

-- Default configuration: San Francisco coordinates (fallback)
M.config = {
  latitude = 37.7749,
  longitude = -122.4194,
}

-- A mapping from weather codes to human-readable descriptions (based on Open-Meteo docs)
local weather_code_map = {
  [0] = "Clear sky",
  [1] = "Mainly clear",
  [2] = "Partly cloudy",
  [3] = "Overcast",
  [45] = "Fog",
  [48] = "Depositing rime fog",
  [51] = "Light drizzle",
  [53] = "Moderate drizzle",
  [55] = "Dense drizzle",
  [56] = "Light freezing drizzle",
  [57] = "Dense freezing drizzle",
  [61] = "Slight rain",
  [63] = "Moderate rain",
  [65] = "Heavy rain",
  [66] = "Light freezing rain",
  [67] = "Heavy freezing rain",
  [71] = "Slight snow fall",
  [73] = "Moderate snow fall",
  [75] = "Heavy snow fall",
  [77] = "Snow grains",
  [80] = "Slight rain showers",
  [81] = "Moderate rain showers",
  [82] = "Violent rain showers",
  [85] = "Slight snow showers",
  [86] = "Heavy snow showers",
  [95] = "Thunderstorm",
  [96] = "Thunderstorm with slight hail",
  [99] = "Thunderstorm with heavy hail",
}

-- Fetch weather forecast from the Open-Meteo API using M.config coordinates
function M.fetch_weather()
  local today = os.date("%Y-%m-%d")
  local six_days = os.date("%Y-%m-%d", os.time() + 6 * 24 * 3600)

  local query_params = {
    latitude = M.config.latitude,
    longitude = M.config.longitude,
    hourly = "temperature_2m,weathercode",
    daily = "weathercode,temperature_2m_max,temperature_2m_min",
    timezone = "auto",
    start_date = today,
    end_date = six_days,
  }

  local curl = require("plenary.curl")
  local url = "https://api.open-meteo.com/v1/forecast"
  local response = curl.get(url, { query = query_params })

  if response.status ~= 200 then
    vim.notify("Failed to fetch weather forecast", vim.log.levels.ERROR)
    return
  end

  local ok, data = pcall(vim.fn.json_decode, response.body)
  if not ok then
    vim.notify("Failed to parse weather data", vim.log.levels.ERROR)
    return
  end

  M.display_weather(data)
end

-- Format and display the weather data in a floating window
function M.display_weather(data)
  local lines = {}

  -- Today's hourly forecast
  table.insert(lines, "Weather Forecast for Today (Hourly):")
  table.insert(lines, "------------------------------------")
  local today = os.date("%Y-%m-%d")
  local hourly = data.hourly or {}
  if hourly.time and hourly.temperature_2m and hourly.weathercode then
    for i, time_str in ipairs(hourly.time) do
      if time_str:sub(1, 10) == today then
        -- Extract the hour (assumes time format "YYYY-MM-DDTHH:MM")
        local hour = time_str:sub(12, 16)
        local temp = hourly.temperature_2m[i]
        local code = hourly.weathercode[i]
        local condition = weather_code_map[code] or ("Code " .. code)
        table.insert(lines, string.format("%s - %s°C, %s", hour, tostring(temp), condition))
      end
    end
  else
    table.insert(lines, "No hourly data available.")
  end

  table.insert(lines, "")
  table.insert(lines, "Weather Forecast for Next 6 Days:")
  table.insert(lines, "--------------------------------")
  local daily = data.daily or {}
  if daily.time and daily.temperature_2m_max and daily.temperature_2m_min and daily.weathercode then
    for i, date_str in ipairs(daily.time) do
      if date_str ~= today then  -- skip today's summary if present
        local high = daily.temperature_2m_max[i]
        local low = daily.temperature_2m_min[i]
        local code = daily.weathercode[i]
        local condition = weather_code_map[code] or ("Code " .. code)
        table.insert(lines, string.format("%s - High: %s°C, Low: %s°C, %s", date_str, tostring(high), tostring(low), condition))
      end
    end
  else
    table.insert(lines, "No daily data available.")
  end

  M.create_floating_window(lines)
end

-- Create and display a floating window with the provided lines
function M.create_floating_window(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local width = 60
  local height = #lines
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  }

  vim.api.nvim_open_win(buf, true, opts)
end

-- Inference of the current location via ip-api.com
function M.fetch_location()
  local curl = require("plenary.curl")
  local url = "http://ip-api.com/json/"
  local response = curl.get(url)

  if response.status ~= 200 then
    vim.notify("Failed to fetch location info", vim.log.levels.ERROR)
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, response.body)
  if not ok or data.status ~= "success" then
    vim.notify("Failed to parse location data", vim.log.levels.ERROR)
    return nil
  end

  return { latitude = data.lat, longitude = data.lon, city = data.city }
end

-- Fetch weather using auto-detected location.
function M.fetch_weather_auto()
  local loc = M.fetch_location()
  if not loc then
    return
  end

  -- Optionally display the inferred location.
  vim.notify(string.format("Detected location: %s (%s, %s)", loc.city, loc.latitude, loc.longitude))

  -- Temporarily override the configuration with the detected coordinates.
  local original_config = { latitude = M.config.latitude, longitude = M.config.longitude }
  M.config.latitude = loc.latitude
  M.config.longitude = loc.longitude

  M.fetch_weather()

  -- Restore original config if desired. Comment out if you wish to keep the auto-detected location.
  M.config.latitude = original_config.latitude
  M.config.longitude = original_config.longitude
end

-- Setup function to configure the plugin and register the commands
function M.setup(config)
  M.config = vim.tbl_extend("force", M.config, config or {})
  vim.api.nvim_create_user_command("WeatherForecast", function()
    M.fetch_weather()
  end, { desc = "Show weather forecast (today by hours and next 6 days) using configured location" })

  vim.api.nvim_create_user_command("WeatherForecastAuto", function()
    M.fetch_weather_auto()
  end, { desc = "Show weather forecast using auto-detected location" })
end

return M
