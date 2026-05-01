-- Enforce a deterministic 2x2 display grid using screen UUIDs.

local log = require('logger')

local displayGrid = {
    A = "B43E3352-ACB7-4163-A25B-2DDAE0174571",  -- WQX DP (2) - top-left
    B = "B32F530C-62CF-4F0D-9997-80BF2B812AC8",  -- WQX DP (1) - top-right
    C = "C9240C8E-A9D2-418A-89AC-28D3B5DEE5FC",  -- PM161Q B1 (1) - bottom-left
    D = "F4AB0D6C-8E85-4E84-B5AB-C5B388536E3D",  -- PM161Q B1 (2) - bottom-right
}

local function resolveScreens()
    local screens = {
        A = hs.screen.find(displayGrid.A),
        B = hs.screen.find(displayGrid.B),
        C = hs.screen.find(displayGrid.C),
        D = hs.screen.find(displayGrid.D),
    }

    for key, screen in pairs(screens) do
        if not screen then
            log.w("Display grid missing screen:", key)
            return nil
        end
    end

    return screens
end

function fix2x2Grid()
    local screens = resolveScreens()
    if not screens then
        return
    end

    local frameA = screens.A:fullFrame()
    local frameB = screens.B:fullFrame()
    local frameC = screens.C:fullFrame()

    local function applyPositions()
        -- D (bottom-right) is anchor at origin
        screens.D:setOrigin(0, 0)
        -- A (top-left) above C — set before B so B doesn't get shoved
        screens.A:setOrigin(-frameA.w, -frameA.h)
        -- C (bottom-left) is left of D
        screens.C:setOrigin(-frameC.w, 0)
        -- B (top-right) is above D
        screens.B:setOrigin(0, -frameB.h)
    end

    applyPositions()
    -- Second pass: macOS sometimes shoves displays during the first pass
    -- before all positions are known. Re-applying locks things in place.
    hs.timer.doAfter(0.4, applyPositions)

    log.i("Applied 2x2 display grid")
end

local function scheduleGridFix(delaySeconds)
    hs.timer.doAfter(delaySeconds, fix2x2Grid)
end

local displayGridScreenWatcher = hs.screen.watcher.new(function()
    scheduleGridFix(1.5)
end)

local displayGridCaffeinateWatcher = hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.systemDidWake then
        scheduleGridFix(2.5)
    end
end)

-- displayGridScreenWatcher:start()
-- displayGridCaffeinateWatcher:start()

hs.hotkey.bind(hyper, "f", fix2x2Grid)

-- Dump current display configuration to console
function dumpDisplayGrid()
    local screens = hs.screen.allScreens()

    -- Sort screens by position (top-left to bottom-right)
    table.sort(screens, function(a, b)
        local frameA = a:fullFrame()
        local frameB = b:fullFrame()
        if frameA.y ~= frameB.y then
            return frameA.y < frameB.y
        end
        return frameA.x < frameB.x
    end)

    log.i("-- Current display configuration:")
    log.i("local displayGrid = {")

    local labels = {"A", "B", "C", "D"}
    for i, screen in ipairs(screens) do
        local frame = screen:fullFrame()
        local label = labels[i] or tostring(i)
        log.i(string.format('    %s = "%s",  -- %s (%dx%d @ %d,%d)',
            label,
            screen:getUUID(),
            screen:name(),
            frame.w, frame.h,
            frame.x, frame.y
        ))
    end

    log.i("}")
    log.i("")
    log.i("-- Grid layout (based on current positions):")

    for i, screen in ipairs(screens) do
        local frame = screen:fullFrame()
        local label = labels[i] or tostring(i)
        log.i(string.format("%s: %s (%dx%d @ %d,%d)",
            label, screen:name(), frame.w, frame.h, frame.x, frame.y))
    end

    hs.alert.show("Display config dumped to console")
end

hs.hotkey.bind(hyper, "9", dumpDisplayGrid)
