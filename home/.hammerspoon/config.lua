-- config.lua: Centralized configuration for Hammerspoon

local config = {}

-- Debugging configuration
config.debug = false

-- Define display configurations
config.displays = {
    -- Display names
    names = {
        display_1200x1920 = '1200x1920',
        display_1366x1024 = '1366x1024@2x',
        display_1440x900 = '1440x900@2x',
        display_1600x2560 = '1600x2560',
        display_1680x1050 = '1680x1050',
        display_1792x1120 = '1792x1120@2x',
        display_1920x1080 = '1920x1080@2x',
        display_1920x1200 = '1920x1200',
        display_2048x1152 = '2048x1152@2x',
        display_2048x1280 = '2048x1280',
        display_2560x1440 = '2560x1440',
        display_2560x1440x1 = '2560x1440@1x',
        display_2560x1600 = '2560x1600',
    },
    
    -- Monitor grid configurations
    grids = {
        ['1200x1920'] = '2x6',
        ['1366x1024@2x'] = '6x4',
        ['1440x900@2x'] = '3x2',
        ['1600x2560'] = '1x3',
        ['1680x1050'] = '2x4',
        ['1792x1120@2x'] = '6x4',
        ['1920x1080@2x'] = '6x4',
        ['1920x1200'] = '6x2',
        ['2048x1152@2x'] = '6x4',
        ['2048x1280'] = '6x4',
        ['2560x1440'] = '6x4',
        ['2560x1440@1x'] = '6x4',
        ['2560x1600'] = '6x4',
    }
}

-- Application layout configurations
config.layouts = {
    -- Vertical monitor setup
    vertical = {
        {"iTerm2", nil, "main", hs.layout.maximized, nil, nil},
        {"Slack", nil, "vertical", {x=0, y=0, w=1, h=0.5}, nil, nil},
        {"Caprine", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
        {"Messages", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
        {"Telegram", nil, "vertical", {x=0, y=0.5, w=1, h=0.5}, nil, nil},
    },
    
    -- Default layout (no vertical monitor)
    default = {
        {"iTerm2", nil, "main", hs.layout.maximized, nil, nil},
    }
}

-- Window management animation duration
config.animationDuration = 0.1

return config