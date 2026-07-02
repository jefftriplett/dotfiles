-- config.lua: Centralized configuration for Hammerspoon

local config = {}

-- Debugging configuration
config.debug = false

-- Define display configurations
config.displays = {
    -- Display names (used by screens_changed_callback in init.lua)
    names = {
        display_1200x1920 = '1200x1920',    -- vertical monitor
        display_1440x900 = '1440x900@2x',   -- built-in fallback
        display_1792x1120 = '1792x1120@2x', -- main
    },

    -- Monitor grid configurations (keyed by screen name)
    grids = {
        ['WQX DP (1)']    = '6x4',  -- 2048x1280
        ['WQX DP (2)']    = '6x4',  -- 2048x1280
        ['PM161Q B1 (1)'] = '3x2',  -- 1920x1080
        ['PM161Q B1 (2)'] = '3x2',  -- 1920x1080
        ['XREAL One']     = '3x2',  -- 1920x1080 @1x (glasses)
    }
}

-- Application layout configurations
config.layouts = {
    -- Vertical monitor setup
    vertical = {
        {"Ghostty", nil, "main", hs.layout.maximized, nil, nil},
        {"Slack", nil, "vertical", {x=0, y=0, w=1, h=0.5}, nil, nil},
        {"Caprine", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
        {"Messages", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
        {"Telegram", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
    },

    -- Default layout (no vertical monitor)
    default = {
        {"Ghostty", nil, "main", hs.layout.maximized, nil, nil},
    }
}

-- Window management animation duration
config.animationDuration = 0.1

return config
