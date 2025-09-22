----------------------
-- Hammerspoon Init --
----------------------

-- Load required modules
local config = require('config')
local log = require('logger')
require('hs.ipc')
require('keys')
require('sizeup')
require('tabletools')

--------------------------------------------------
-- Reload at the top in case we break something --
--------------------------------------------------

-- reload script
hs.hotkey.bind(hyper, 'r', function()
    hs.reload()
end)

-- Initialize animation duration
hs.window.animationDuration = config.animationDuration

---------------------
-- Initialize Grid --
---------------------

-- Initialize display variables
local display = config.displays.names

------------------------
-- Setup Default Grid --
------------------------

function setup_grid()
    log.i('Setting up window grid')
    
    for displayName, gridConfig in pairs(config.displays.grids) do
        log.d(displayName, gridConfig)
        local screen = hs.screen.find(displayName)
        if screen then
            log.d('Found display:', displayName, 'with grid:', gridConfig)
            hs.grid.setGrid(gridConfig, screen)
        end
    end
end

-- Initialize grid
setup_grid()

----------------------
-- System Callbacks --
----------------------

function battery_changed_callback()
    if config.debug then
        log.d('Battery changed')
        log.d('  Time remaining:', hs.battery.timeRemaining())
        log.d('  Percentage:', hs.battery.percentage())
    end
end

function caffeinate_changed_callback(event_type)
    log.d('Caffeinate changed:', event_type)
    
    if (event_type == hs.caffeinate.watcher.screensDidSleep) then
        log.i('Screens went to sleep')
    elseif (event_type == hs.caffeinate.watcher.screensDidWake) then
        log.i('Screens woke up')
    end
end

function config_changed_callback(paths)
    log.i('Config files changed:', table.show(paths, 'paths'))
    setup_grid()
end

function screens_changed_callback()
    log.i('Screen configuration changed')
    log.d('Number of screens:', #hs.screen.allScreens())
    
    -- Restructure the grid
    setup_grid()
    
    -- Arrange apps based on available screens
    local vertical = hs.screen.find(display.display_1200x1920)
    local main = hs.screen.find(display.display_1792x1120)
    
    if not main then
        main = hs.screen.find(display.display_1440x900)
    end
    
    log.d('Main screen:', main)
    
    -- Apply the appropriate layout
    if vertical then
        log.i('Applying vertical monitor layout')
        local layout = config.layouts.vertical
        
        -- Update the screen references in the layout
        for _, item in ipairs(layout) do
            if item[3] == "main" then
                item[3] = main
            elseif item[3] == "vertical" then
                item[3] = vertical
            end
        end
        
        hs.layout.apply(layout)
    else
        log.i('Applying default layout')
        local layout = config.layouts.default
        
        -- Update the screen references in the layout
        for _, item in ipairs(layout) do
            if item[3] == "main" then
                item[3] = main
            end
        end
        
        hs.layout.apply(layout)
    end
end

function usb_changed_callback(data)
    log.d('USB device changed:', table.show(data, 'data'))
end

function wifi_changed_callback()
    log.i('WiFi changed')
    local ssid = hs.wifi.currentNetwork()
    log.d('SSID:', ssid)
end

---------------------
-- System Watchers --
---------------------

battery_watcher = hs.battery.watcher.new(battery_changed_callback):start()
caffeinate_watcher = hs.caffeinate.watcher.new(caffeinate_changed_callback):start()
config_file_watcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', config_changed_callback):start()
usb_watcher = hs.usb.watcher.new(usb_changed_callback):start()
wifi_watcher = hs.wifi.watcher.new(wifi_changed_callback):start()

-- Uncomment to enable app and screen watchers if needed
-- app_watcher = hs.application.watcher.new(app_changed_callback):start()
-- screen_watcher = hs.screen.watcher.new(screens_changed_callback):start()

-- Toggle an application between being the frontmost app, and being hidden
function toggle_application(_app)
    local app = hs.application.find(_app)
    if not app then
        hs.application.launchOrFocus(_app)
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

-- show grid
hs.hotkey.bind(hyper, 'g', hs.grid.show)

-- Display watcher status
hs.hotkey.bind(hyper, '0', function()
    log.i('Watcher Status:')
    log.i('  app_watcher:', app_watcher)
    log.i('  battery_watcher:', battery_watcher)
    log.i('  caffeinate_watcher:', caffeinate_watcher)
    log.i('  config_file_watcher:', config_file_watcher)
    log.i('  screen_watcher:', screen_watcher)
    log.i('  usb_watcher:', usb_watcher)
    log.i('  wifi_watcher:', wifi_watcher)
end)

-- hs.hotkey.bind(hyper, 'Q', function()
--     toggle_application('iTerm')
-- end)

-- hs.hotkey.bind(hyper, 'W', function()
--     toggle_application('Sublime Text')
-- end)

hs.hotkey.bind(hyper, 'I', function()
    toggle_application('iTerm2')
end)

hs.hotkey.bind(hyper, 'D', function()
    toggle_application('Discord')
end)

hs.hotkey.bind(hyper, 'S', function()
    toggle_application('Slack')
end)

hs.hotkey.bind(hyper, 'T', function()
    toggle_application('Telegram')
end)

hs.hotkey.bind(hyper, 'E', function()
    toggle_application('Sublime Text')
end)

hs.hotkey.bind(hyper, 'W', function()
    toggle_application('Tower')
end)

hs.hotkey.bind(hyper, 'X', function()
    toggle_application('Zed')
end)

hs.hotkey.bind(hyper, 'A', function()
    toggle_application('Messages')
end)

hs.hotkey.bind(hyper, 'V', function()
    toggle_application('Vivaldi')
end)

hs.hotkey.bind(hyper, 'O', function()
    toggle_application('Obsidian')
end)

hs.hotkey.bind(hyper, '.', function()
    hs.hints.windowHints(hs.window.focusedWindow():application():allWindows())
end)

hs.hotkey.bind(hyper, ',', function()
    battery_changed_callback()
    screens_changed_callback()
end)

hs.alert.show('Config loaded')
