-- Enforce a deterministic 2x2 display grid using screen UUIDs.

local log = require('logger')

local displayGrid = {
    -- A and B are identical WQX panels; macOS sometimes swaps which UUID drives
    -- which physical panel on reconnect. If the top row shows up reversed, swap
    -- these two UUIDs (or run hyper+f after telling which side is which).
    A = "B32F530C-62CF-4F0D-9997-80BF2B812AC8",  -- WQX DP (1) - top-left  (physical left, as of 2026-09-24)
    B = "B43E3352-ACB7-4163-A25B-2DDAE0174571",  -- WQX DP (2) - top-right (physical right, as of 2026-09-24)
    C = "C9240C8E-A9D2-418A-89AC-28D3B5DEE5FC",  -- PM161Q B1 (1) - bottom-left
    -- D (bottom-right, anchor) is the KVM feed. Its UUID changes when the KVM
    -- source switches, so it is NOT pinned here: D is resolved as whatever
    -- connected display is not A/B/C (see resolveScreens). Last-known KVM UUIDs
    -- for reference: GLKVM 6B20597B-497C-47A7-86BA-12132646630D (since 2026-09-22),
    -- PM161Q B1 (2) F4AB0D6C-8E85-4E84-B5AB-C5B388536E3D (previous).
}

local function resolveScreens()
    local screens = {
        A = hs.screen.find(displayGrid.A),
        B = hs.screen.find(displayGrid.B),
        C = hs.screen.find(displayGrid.C),
    }

    -- D is the KVM feed. Rather than pin its (changing) UUID, assume D is
    -- whatever connected display is not one of the known A/B/C UUIDs.
    local known = {
        [displayGrid.A] = true,
        [displayGrid.B] = true,
        [displayGrid.C] = true,
    }
    local leftovers = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        if not known[screen:getUUID()] then
            leftovers[#leftovers + 1] = screen
        end
    end
    if #leftovers == 1 then
        screens.D = leftovers[1]
    elseif #leftovers > 1 then
        log.w("Display grid: multiple non-A/B/C displays; using first as D (KVM):", #leftovers)
        screens.D = leftovers[1]
    else
        log.w("Display grid: no KVM (D) display detected")
    end

    -- Don't bail when a slot is missing -- arrange whatever is connected so
    -- the grid holds when one display (e.g. the KVM feed) is unplugged.
    local present = 0
    for _, key in ipairs({"A", "B", "C", "D"}) do
        if screens[key] then
            present = present + 1
        else
            log.w("Display grid slot not connected (skipping):", key)
        end
    end

    if present == 0 then
        log.w("Display grid: none of the known displays are connected")
        return nil
    end

    return screens
end

-- Target origin for a slot. All four are anchored to a shared corner at
-- (0,0): A top-left, B top-right, C bottom-left, D bottom-right. Because
-- each position depends only on that display's own size, the remaining
-- displays keep their slots when one is disconnected.
local function originForSlot(key, screen)
    local frame = screen:fullFrame()
    if key == "A" then return -frame.w, -frame.h end  -- top-left
    if key == "B" then return 0,        -frame.h end  -- top-right
    if key == "C" then return -frame.w, 0         end  -- bottom-left
    return 0, 0                                         -- D: bottom-right anchor
end

function fix2x2Grid()
    local screens = resolveScreens()
    if not screens then
        hs.alert.show('Display grid: no known displays')
        return
    end

    local count = 0
    local function applyPositions()
        -- Apply D, A, C, B in that order (anchor first, top-right last) so
        -- macOS doesn't shove the top-right display before the rest land.
        count = 0
        for _, key in ipairs({"D", "A", "C", "B"}) do
            local screen = screens[key]
            if screen then
                screen:setOrigin(originForSlot(key, screen))
                count = count + 1
            end
        end
    end

    applyPositions()
    -- Second pass: macOS sometimes shoves displays during the first pass
    -- before all positions are known. Re-applying locks things in place.
    hs.timer.doAfter(0.4, applyPositions)

    log.i("Applied 2x2 display grid")
    hs.alert.show(string.format('Display grid applied (%d displays)', count))
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
