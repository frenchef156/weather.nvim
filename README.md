# weather.nvim
##### Get a weather forecast directly in Neovim
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

### This plugin was written using ChatGPT (model: o3-mini-high)

https://github.com/user-attachments/assets/087f5aa2-c58a-445a-80b0-9f64d7ce7867

## ChatGPT in his own words

Hey there, Neovim adventurers! I'm ChatGPT, and let me tell you—this weather plugin is a game-changer. Imagine checking the weather forecast directly from your favorite text editor, without having to flip open a browser or another app. Whether you're deep in code or just need to know if you should grab an umbrella before heading out, this plugin has got you covered—literally!

With just a couple of simple commands, you can get a detailed hourly forecast for today and a six-day outlook that keeps you informed about what's coming next. It's like having your very own mini meteorologist right at your fingertips. Now you can stay in the zone, without the distraction of switching windows or scrolling through weather apps.

So why wait? Bring the weather to your workflow, stay prepared, and add a little extra charm (and clarity) to your Neovim experience. Happy coding—and may your skies be ever in your favor!

## Installation and Usage

### Installation with lazy.nvim

To install this plugin using lazy.nvim, add the following entry to your lazy configuration:

```lua
{
  "frenchef156/weather.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("weather").setup({
      latitude = 40.7128,    -- Default fallback latitude (e.g., New York City)
      longitude = -74.0060,  -- Default fallback longitude
    })
  end,
}
```

### Usage

Once installed, you can use the plugin with these two commands:

- **`:WeatherForecast`**  
  Uses the configured coordinates (set during setup) to display the weather forecast. This command shows today’s hourly weather details along with a summary for the next 6 days in a floating window.

- **`:WeatherForecastAuto`**  
  Automatically infers your approximate location based on your internet connection (using an IP-based geolocation service) and then displays the weather forecast for that location. This is ideal if you prefer not to set a fixed location manually.

#### Setup Parameters

- **`latitude`**  
  The default latitude to use if auto-detection isn’t required.  
  _Example:_ `40.7128` (for New York City)

- **`longitude`**  
  The default longitude to use if auto-detection isn’t required.  
  _Example:_ `-74.0060` (for New York City)

- **`highlightColors`**  
  The hightlight color to use for the current hour.
  _Example:_ `highlightColors = { bg = "#ffcc00", fg = "#000000", }`

