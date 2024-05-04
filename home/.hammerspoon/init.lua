----------------------
-- Define hyper key --
----------------------

require 'hs.ipc'
require 'keys'
require 'sizeup'
require 'tabletools'

--------------------------------------------------
-- Reload at the top in case we break something --
--------------------------------------------------

-- reload script --
hs.hotkey.bind(hyper, 'r', function()
    hs.reload()
end)

-----------------------
-- Initialize Logger --
-----------------------

hs.logger = require('hs.logger')
hs.logger.historySize(200)

---------------------
-- Initialize Grid --
---------------------

-- Monitor names
local display_1200x1920 = '1200x1920'
local display_1366x1024 = '1366x1024@2x'
local display_1440x900 = '1440x900@2x'
local display_1600x2560 = '1600x2560'
local display_1680x1050 = '1680x1050'
local display_1792x1120 = '1792x1120@2x'
local display_1920x1080 = '1920x1080@2x'
local display_1920x1200 = '1920x1200'
local display_2048x1152 = '2048x1152@2x'
local display_2048x1280 = '2048x1280'
local display_2560x1440 = '2560x1440'
local display_2560x1440x1 = '2560x1440@1x'
local display_2560x1600 = '2560x1600'

-- Monitor grids
local display_1200x1920_grid = '2x6'
local display_1366x1024_grid = '6x4'
local display_1440x900_grid = '3x2'
local display_1600x2560_grid = '1x3'
local display_1680x1050_grid = '2x4'
local display_1792x1120_grid = '6x4'
local display_1920x1080_grid = '6x4'
local display_1920x1200_grid = '6x2'
local display_2048x1152_grid = '6x4'
local display_2048x1280_grid = '6x4'
local display_2560x1440_grid = '6x4'
local display_2560x1440x1_grid = '6x4'
local display_2560x1600_grid = '6x4'

-- Watchers and other useful objects
local app_watcher = nil
local battery_watcher = nil
local caffeinate_watcher = nil
local config_file_watcher = nil
local screen_watcher = nil
local usb_watcher = nil
local wifi_watcher = nil

------------
-- Config --
------------

hs.window.animationDuration = 0.1;

------------------------
-- Setup Default Grid --
------------------------

function setup_grid()
    print('setup_grid()')

    -- MacBook Pro (default) --
    if hs.screen.find(display_1680x1050) then
        print('found', display_1680x1050)
        hs.grid.setGrid(display_1680x1050_grid, display_1680x1050)
    end

    -- Home Display --
    if hs.screen.find(display_2560x1440) then
        print('found', display_2560x1440)
        hs.grid.setGrid(display_2560x1440_grid, display_2560x1440)
    end

    -- Home Display 4K --
    if hs.screen.find(display_2560x1440x1) then
        print('found', display_2560x1440x1)
        hs.grid.setGrid(display_2560x1440x1_grid, display_2560x1440x1)
    end

    -- Home Display 4K Dual --
    if hs.screen.find(display_1920x1080) then
        print('found', display_1920x1080)
        hs.grid.setGrid(display_1920x1080_grid, display_1920x1080)
    end

    -- Home Display 4K Low(er) --
    if hs.screen.find(display_2048x1152) then
        print('found', display_2048x1152)
        hs.grid.setGrid(display_2048x1152_grid, display_2048x1152)
    end

    -- iMac --
    if hs.screen.find(display_1920x1200) then
        print('found', display_1920x1200)
        hs.grid.setGrid(display_1920x1200_grid, display_1920x1200)
    end

    -- Work Display(s) --
    if hs.screen.find(display_1440x900) then
        print('found', display_1440x900)
        hs.grid.setGrid(display_1440x900_grid, display_1440x900)
    end

    if hs.screen.find(display_1792x1120) then
        print('found', display_1792x1120)
        hs.grid.setGrid(display_1792x1120_grid, display_1792x1120)
    end

    if hs.screen.find(display_1366x1024) then
        print('found', display_1366x1024)
        hs.grid.setGrid(display_1366x1024_grid, display_1366x1024)
    end

    if hs.screen.find(display_2048x1280) then
        print('found', display_2048x1280)
        hs.grid.setGrid(display_2048x1280_grid, display_2048x1280)
    end

    if hs.screen.find(display_2560x1600) then
        print('found', display_2560x1600)
        hs.grid.setGrid(display_2560x1600_grid, display_2560x1600)
    end

    if hs.screen.find(display_1200x1920) then
        print('found', display_1200x1920)
        hs.grid.setGrid(display_1200x1920_grid, display_1200x1920)
    end

    if hs.screen.find(display_1600x2560) then
        print('found', display_1600x2560)
        hs.grid.setGrid(display_1600x2560_grid, display_1600x2560)
    end
end

---------------------
-- Initialize Grid --
---------------------

setup_grid()

----------------------
-- System Callbacks --
----------------------

function app_changed_callback(app_name, event_type, app_object)
    print('app_changed_callback()')
    print(app_name, event_type, app_object)
end

function battery_changed_callback()
    print('battery_changed_callback()')
    print('timeRemaining:', hs.battery.timeRemaining())
    print('percentage:', hs.battery.percentage())
end

function caffeinate_changed_callback(event_type)
    print('caffeinate_changed_callback()')
    print(event_type)
    print(table.show(event_type, 'event_type'))
    if (event_type == hs.caffeinate.watcher.screensDidSleep) then
        print('screensDidSleep')
    elseif (event_type == hs.caffeinate.watcher.screensDidWake) then
        print('screensDidWake')
    end
end

function config_changed_callback(paths)
    print('config_changed_callback()')
    print(table.show(paths, 'paths'))

    setup_grid()
end

function screens_changed_callback()
    print('screens_changed_callback()')
    number_of_screens = #hs.screen.allScreens()
    print('number_of_screens:', number_of_screens)
    print(table.show(hs.screen.allScreens(), 'allScreens'))
    for _, screen in pairs(hs.screen.allScreens()) do
        print(table.show(screen:currentMode(), 'currentMode'))
    end

    -- restructure the grid --
    setup_grid()

    -- arrange apps for work --
    local vertical = hs.screen.find(display_1200x1920)
    local main = hs.screen.find(display_1792x1120)

    if not main then
        main = hs.screen.find(display_1440x900)
    end

    print('main:', main)

    if (vertical) then
        hs.layout.apply({
            -- macbook pro display --
            {"iTerm2", nil, main, hs.layout.maximized, nil, nil},

            -- top 1/2 of vertical monitor --
            {"Slack", nil, vertical, {x=0, y=0, w=1, h=0.5}, nil, nil},

            -- bottom 1/2 of vertical monitor --
            {"Caprine", nil, vertical, {x=0, y=0.5, w=1, h=0.5}, nil, nil},
            {"Messages", nil, vertical, {x=0, y=0.5, w=1, h=0.5}, nil, nil},
            {"Telegram", nil, vertical, {x=0, y=0.5, w=1, h=0.5}, nil, nil},
        })
    else
        hs.layout.apply({
            -- macbook pro display --
            {"iTerm2", nil, main, hs.layout.maximized, nil, nil},
        })
    end
end

function wifi_changed_callback()
    print('wifi_changed_callback()')
    ssid = hs.wifi.currentNetwork()
    print('ssid:', ssid)
end

function usb_changed_callback(data)
    print('usb_changed_callback()')
    print(table.show(data, 'data'))
end

---------------------
-- System Watchers --
---------------------

-- app_watcher = hs.application.watcher.new(app_changed_callback):start()
battery_watcher = hs.battery.watcher.new(battery_changed_callback):start()
caffeinate_watcher = hs.caffeinate.watcher.new(caffeinate_changed_callback):start()
config_file_watcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', config_changed_callback):start()
-- screen_watcher = hs.screen.watcher.new(screens_changed_callback):start()
usb_watcher = hs.usb.watcher.new(usb_changed_callback):start()
wifi_watcher = hs.wifi.watcher.new(wifi_changed_callback):start()

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
    local app = hs.appfinder.appFromName(_app)
    if not app then
        -- FIXME: This should really launch _app
        return
    end
    local mainwin = app:mainWindow()
    if mainwin then
        if mainwin == hs.window.focusedWindow() then
            mainwin:application():hide()
        else
            mainwin:application():activate(true)
            mainwin:application():unhide()
            mainwin:focus()
        end
    end
end

-------------------------
-- Application Hotkeys --
-------------------------

-- show grid --
hs.hotkey.bind(hyper, 'g', hs.grid.show)

-- debug watcher statuses
hs.hotkey.bind(hyper, '0', function()
    print('app_watcher:', app_watcher)
    print('battery_watcher:', battery_watcher)
    print('caffeinate_watcher:', caffeinate_watcher)
    print('config_file_watcher:', config_file_watcher)
    print('screen_watcher:', screen_watcher)
    print('usb_watcher:', usb_watcher)
    print('wifi_watcher:', wifi_watcher)
end)

hs.hotkey.bind(hyper, 'Q', function()
    toggle_application('iTerm')
end)

hs.hotkey.bind(hyper, 'W', function()
    toggle_application('Sublime Text')
end)

hs.hotkey.bind(hyper, '.', function()
    hs.hints.windowHints(hs.window.focusedWindow():application():allWindows())
end)

hs.hotkey.bind(hyper, ',', function()
    battery_changed_callback()
    screens_changed_callback()
end)

hs.alert.show('Config loaded')
