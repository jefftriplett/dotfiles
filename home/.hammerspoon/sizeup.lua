-- === sizeup ===
--
-- SizeUp emulation for hammerspoon
--
-- To use, you can tweak the key bindings and the margins

require 'keys'

local sizeup = { }
-- local hyper = {"ctrl", "alt", "cmd"}

--------------
-- Bindings --
--------------

--- Split Screen Actions ---
-- Send Window Left
hs.hotkey.bind(hyper, "Left", function()
  sizeup.send_window_left()
end)
-- Send Window Right
hs.hotkey.bind(hyper, "Right", function()
  sizeup.send_window_right()
end)
-- Send Window Up
hs.hotkey.bind(hyper, "Up", function()
  sizeup.send_window_up()
end)
-- Send Window Down
hs.hotkey.bind(hyper, "Down", function()
  sizeup.send_window_down()
end)

--- Quarter Screen Actions ---
-- Send Window Upper Left
hs.hotkey.bind({"ctrl", "alt", "shift"}, "Left", function()
  sizeup.send_window_upper_left()
end)
-- Send Window Upper Right
hs.hotkey.bind({"ctrl", "alt", "shift"}, "Up", function()
  sizeup.send_window_upper_right()
end)
-- Send Window Lower Left
hs.hotkey.bind({"ctrl", "alt", "shift"}, "Down", function()
  sizeup.send_window_lower_left()
end)
-- Send Window Lower Right
hs.hotkey.bind({"ctrl", "alt", "shift"}, "Right", function()
  sizeup.send_window_lower_right()
end)

--- Multiple Monitor Actions ---
-- Send Window Prev Monitor
hs.hotkey.bind({ "ctrl", "alt" }, "Left", function()
  sizeup.send_window_prev_monitor()
end)
-- Send Window Next Monitor
hs.hotkey.bind({ "ctrl", "alt" }, "Right", function()
  sizeup.send_window_next_monitor()
end)

--- Spaces Actions ---

-- Apple no longer provides any reliable API access to spaces.
-- As such, this feature no longer works in SizeUp on Yosemite and
-- Hammerspoon currently has no solution that isn't a complete hack.
-- If you have any ideas, please visit the ticket

--- Snapback Action ---
hs.hotkey.bind(hyper, "Z", function()
  sizeup.snapback()
end)

--- Other Actions ---

-- Make Window Full Screen
hs.hotkey.bind(hyper, "M", function()
  sizeup.maximize()
end)

-- Send Window Center
hs.hotkey.bind(hyper, "C", function()
  sizeup.move_to_center_relative({w=0.60, h=0.60})
end)


-------------------
-- Configuration --
-------------------

-- Margins --
sizeup.screen_edge_margins = {
  top = 0, -- px
  left = 0,
  right = 0,
  bottom = 0
}
sizeup.partition_margins = {
  x = 0, -- px
  y = 0
}

-- Partitions --
sizeup.split_screen_partitions = {
  x = 0.5, -- %
  y = 0.5
}
sizeup.quarter_screen_partitions = {
  x = 0.5, -- %
  y = 0.5
}


----------------
-- Public API --
----------------

function sizeup.send_window_left()
  local s = sizeup.screen()
  local ssp = sizeup.split_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Left", {
    x = s.x,
    y = s.y,
    w = (s.w * ssp.x) - sizeup.gutter().x,
    h = s.h
  })
end

function sizeup.send_window_right()
  local s = sizeup.screen()
  local ssp = sizeup.split_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Right", {
    x = s.x + (s.w * ssp.x) + g.x,
    y = s.y,
    w = (s.w * (1 - ssp.x)) - g.x,
    h = s.h
  })
end

function sizeup.send_window_up()
  local s = sizeup.screen()
  local ssp = sizeup.split_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Up", {
    x = s.x,
    y = s.y,
    w = s.w,
    h = (s.h * ssp.y) - g.y
  })
end

function sizeup.send_window_down()
  local s = sizeup.screen()
  local ssp = sizeup.split_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Down", {
    x = s.x,
    y = s.y + (s.h * ssp.y) + g.y,
    w = s.w,
    h = (s.h * (1 - ssp.y)) - g.y
  })
end

function sizeup.send_window_upper_left()
  local s = sizeup.screen()
  local qsp = sizeup.quarter_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Upper Left", {
    x = s.x,
    y = s.y,
    w = (s.w * qsp.x) - g.x,
    h = (s.h * qsp.y) - g.y
  })
end

function sizeup.send_window_upper_right()
  local s = sizeup.screen()
  local qsp = sizeup.quarter_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Upper Right", {
    x = s.x + (s.w * qsp.x) + g.x,
    y = s.y,
    w = (s.w * (1 - qsp.x)) - g.x,
    h = (s.h * (qsp.y)) - g.y
  })
end

function sizeup.send_window_lower_left()
  local s = sizeup.screen()
  local qsp = sizeup.quarter_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Lower Left", {
    x = s.x,
    y = s.y + (s.h * qsp.y) + g.y,
    w = (s.w * qsp.x) - g.x,
    h = (s.h * (1 - qsp.y)) - g.y
  })
end

function sizeup.send_window_lower_right()
  local s = sizeup.screen()
  local qsp = sizeup.quarter_screen_partitions
  local g = sizeup.gutter()
  sizeup.set_frame("Lower Right", {
    x = s.x + (s.w * qsp.x) + g.x,
    y = s.y + (s.h * qsp.y) + g.y,
    w = (s.w * (1 - qsp.x)) - g.x,
    h = (s.h * (1 - qsp.y)) - g.y
  })
end

function sizeup.send_window_prev_monitor()
  hs.alert.show("Prev Monitor")
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():previous()
  win:moveToScreen(nextScreen)
end

function sizeup.send_window_next_monitor()
  hs.alert.show("Next Monitor")
  local win = hs.window.focusedWindow()
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end

-- snapback return the window to its last position. calling snapback twice returns the window to its original position.
-- snapback holds state for each window, and will remember previous state even when focus is changed to another window.
function sizeup.snapback()
  local win = sizeup.win()
  local id = win:id()
  local state = win:frame()
  local prev_state = sizeup.snapback_window_state[id]
  if prev_state then
    win:setFrame(prev_state)
  end
  sizeup.snapback_window_state[id] = state
end

function sizeup.maximize()
  -- sizeup.set_frame("Full Screen", sizeup.screen())
  local win = sizeup.win()
  win:maximize()

  -- print('window:maximize:', hs.layout.maximized)
  -- win:move(hs.layout.maximized)
  -- return win:maximize()
end

--- move_to_center_relative(size)
--- Method
--- Centers and resizes the window to the the fit on the given portion of the screen.
--- The argument is a size with each key being between 0.0 and 1.0.
--- Example: win:move_to_center_relative(w=0.5, h=0.5) -- window is now centered and is half the width and half the height of screen
function sizeup.move_to_center_relative(unit)
  local screen = sizeup.screen()

  -- local win = sizeup.win()
  -- local winFrame = sizeup.frame()

  print('unit.h', unit.h)
  print('unit.w', unit.w)
  print('unit.x', unit.x)
  print('unit.y', unit.y)

  print('screen.h', screen.h)
  print('screen.w', screen.w)
  print('screen.x', screen.x)
  print('screen.y', screen.y)

  sizeup.set_frame("Center", {
    x = screen.x + (screen.w * ((1 - unit.w) / 2)),
    y = screen.y + (screen.h * ((1 - unit.h) / 2)),
    w = screen.w * unit.w,
    h = screen.h * unit.h
  })
    -- local win = hs.window.focusedWindow()
    -- if win then
    --     local screen = win:screen()
    --     local screenFrame = screen:frame()
    --     local winFrame = win:frame()

    --     winFrame.x = (screenFrame.w - winFrame.w) / 2 + screenFrame.x
    --     winFrame.y = (screenFrame.h - winFrame.h) / 2 + screenFrame.y

    --     win:setFrame(winFrame)
    -- end
end

--- move_to_center_absolute(size)
--- Method
--- Centers and resizes the window to the the fit on the given portion of the screen given in pixels.
--- Example: win:move_to_center_relative(w=800, h=600) -- window is now centered and is 800px wide and 600px high
function sizeup.move_to_center_absolute(unit)
  local s = sizeup.screen()
  sizeup.set_frame("Center", {
    x = (s.w - unit.w) / 2,
    y = (s.h - unit.h) / 2,
    w = unit.w,
    h = unit.h
  })
end


------------------
-- Internal API --
------------------

-- SizeUp uses no animations
-- hs.window.animation_duration = 0.0
hs.window.animationDuration = 0.0

-- Initialize Snapback state
sizeup.snapback_window_state = { }

-- return currently focused window
function sizeup.win()
  return hs.window.focusedWindow()
end

-- display title, save state and move win to unit
function sizeup.set_frame(title, unit)
  -- hs.alert.show(title)
  local win = sizeup.win()
  sizeup.snapback_window_state[win:id()] = win:frame()
  return win:setFrame(unit)
  -- return win:setFrameWithWorkarounds(unit)
end

-- screen is the available rect inside the screen edge margins
function sizeup.screen()
  local screen = sizeup.win():screen():frame()
  local sem = sizeup.screen_edge_margins

  print('screen.x', screen.x)
  print('screen.y', screen.y)
  print('screen.w', screen.w)
  print('screen.h', screen.h)
  print('---')

  print('sem.bottom', sem.bottom)
  print('sem.left', sem.left)
  print('sem.right', sem.right)
  print('sem.top', sem.top)
  print('---')

  return {
    x = screen.x + sem.left,
    y = screen.y + sem.top,
    w = screen.w - (sem.left + sem.right),
    h = screen.h - (sem.top + sem.bottom)
  }
end

-- gutter is the adjustment required to accomidate partition
-- margins between windows
function sizeup.gutter()
  local pm = sizeup.partition_margins
  return {
    x = pm.x / 2,
    y = pm.y / 2
  }
end

--- hs.window:moveToScreen(screen)
--- Method
--- move window to the the given screen, keeping the relative proportion and position window to the original screen.
--- Example: win:moveToScreen(win:screen():next()) -- move window to next screen
function hs.window:moveToScreen(nextScreen)
  local currentFrame = self:frame()
  local screenFrame = self:screen():frame()
  local nextScreenFrame = nextScreen:frame()
  self:setFrame({
    x = ((((currentFrame.x - screenFrame.x) / screenFrame.w) * nextScreenFrame.w) + nextScreenFrame.x),
    y = ((((currentFrame.y - screenFrame.y) / screenFrame.h) * nextScreenFrame.h) + nextScreenFrame.y),
    h = ((currentFrame.h / screenFrame.h) * nextScreenFrame.h),
    w = ((currentFrame.w / screenFrame.w) * nextScreenFrame.w)
  })
end
