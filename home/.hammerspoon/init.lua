----------------------
-- Define hyper key --
----------------------

require 'keys'
require 'tabletools'
require 'sizeup'

--------------------------------------------------
-- Reload at the top in case we break something --
--------------------------------------------------

-- reload script --
hs.hotkey.bind(hyper, 'r', function()
    hs.reload()
end)

---------------------
-- Initialize Grid --
---------------------

-- Monitor names
local display_default = '1680x1050'
local display_home = '2560x1440'
local display_imac = '1920x1200'
local display_retina = '1440x900@2x'
local display_work = '2560x1600'
local display_work_vertical = '1200x1920'

-- Monitor grids
local display_default_grid = '3x2'
local display_home_grid = '3x2'
local display_imac_grid = '6x2'
local display_retina = '3x2'
local display_work_grid = '6x4'
local display_work_vertical_grid = '2x6'

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

hs.window.animationDuration = 0;

------------------------
-- Setup Default Grid --
------------------------

function setup_grid()
    print('setup_grid()')

    -- MacBook Pro (default) --
    if hs.screen.find(display_default) then
        print('found', display_default)
        hs.grid.setGrid(display_default_grid, display_default)
    end

    -- Home Display --
    if hs.screen.find(display_home) then
        print('found', display_home)
        hs.grid.setGrid(display_home_grid, display_home)
    end

    -- iMac --
    if hs.screen.find(display_imac) then
        print('found', display_imac)
        hs.grid.setGrid(display_imac_grid, display_imac)
    end

    -- Work Display(s) --
    if hs.screen.find(display_retina) then
        print('found', display_retina)
        hs.grid.setGrid(display_retina_grid, display_retina)
    end

    if hs.screen.find(display_work) then
        print('found', display_work)
        hs.grid.setGrid(display_work_grid, display_work)
    end

    if hs.screen.find(display_work_vertical) then
        print('found', display_work_vertical)
        hs.grid.setGrid(display_work_vertical_grid, display_work_vertical)
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
screen_watcher = hs.screen.watcher.new(screens_changed_callback):start()
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
