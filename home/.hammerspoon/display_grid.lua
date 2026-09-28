-- Enforce a 2x2 display grid, working out which display is which each time.
--
--   top-left     | top-right        two identical WQX DP panels
--   -------------+-------------
--   bottom-left  | bottom-right     PM161Q B1 | the KVM feed (anchor at 0,0)
--
-- The two top panels report identical EDIDs (same vendor, model, and serial
-- number 1), so macOS cannot tell them apart and hands out their two saved
-- UUIDs in whatever order they reconnect after display sleep. Pinning a UUID
-- to a side therefore flips every few wakes. Instead, the displays are polled
-- and classified by name on every run, the tops keep whatever left/right
-- order they have now, and hyper+f swaps them -- one keypress when they
-- come back reversed.

local log = require('logger')

local roles = {
    -- The two top panels, matched by name. macOS appends " (1)" / " (2)"
    -- to identical names, so match the prefix.
    topPattern = "^WQX DP",
    -- Bottom-left. Prefer its UUID (stable, since it reports a real serial);
    -- fall back to the name. The KVM feed has shown up as a "PM161Q B1 (2)"
    -- before, so the UUID keeps the two apart when both are connected.
    bottomLeftUUID = "C9240C8E-A9D2-418A-89AC-28D3B5DEE5FC",
    bottomLeftPattern = "^PM161Q",
    -- Bottom-right is the KVM feed, whose UUID changes with the KVM source:
    -- it is whatever display is left over after the others are classified.
}

-- Poll every connected display and sort them into slots:
-- A top-left, B top-right, C bottom-left, D bottom-right.
local function classifyScreens()
    local tops, bottomLeft, leftovers = {}, nil, {}

    for _, screen in ipairs(hs.screen.allScreens()) do
        local name = screen:name() or ""
        if name:match(roles.topPattern) then
            tops[#tops + 1] = screen
        elseif screen:getUUID() == roles.bottomLeftUUID then
            if bottomLeft then leftovers[#leftovers + 1] = bottomLeft end
            bottomLeft = screen
        elseif not bottomLeft and name:match(roles.bottomLeftPattern) then
            bottomLeft = screen
        else
            leftovers[#leftovers + 1] = screen
        end
    end

    -- The tops keep their current left/right order: whichever is further
    -- left now stays top-left. hyper+f is what changes it.
    table.sort(tops, function(a, b)
        local fa, fb = a:fullFrame(), b:fullFrame()
        if fa.x ~= fb.x then return fa.x < fb.x end
        return a:getUUID() < b:getUUID()
    end)
    if #tops > 2 then
        log.w("Display grid: more than two top panels; using the first two:", #tops)
    end
    for i = 3, #tops do leftovers[#leftovers + 1] = tops[i] end

    if #leftovers > 1 then
        log.w("Display grid: several unclassified displays; using the first as the KVM (D):", #leftovers)
    end

    return { A = tops[1], B = tops[2], C = bottomLeft, D = leftovers[1] }
end

-- Target origin for a slot. All four are anchored to a shared corner at
-- (0,0), and each position depends only on that display's own size, so the
-- rest keep their slots when one is disconnected.
local function originForSlot(key, screen)
    local frame = screen:fullFrame()
    if key == "A" then return -frame.w, -frame.h end  -- top-left
    if key == "B" then return 0,        -frame.h end  -- top-right
    if key == "C" then return -frame.w, 0         end  -- bottom-left
    return 0, 0                                         -- D: bottom-right anchor
end

local function describe(screens)
    local parts = {}
    for _, key in ipairs({"A", "B", "C", "D"}) do
        local screen = screens[key]
        parts[#parts + 1] = key .. "=" .. (screen and screen:name() or "(none)")
    end
    return table.concat(parts, "  ")
end

-- Place the classified displays. With `swapTops`, the two tops trade sides.
local function applyGrid(swapTops)
    local screens = classifyScreens()
    if not (screens.A or screens.B or screens.C or screens.D) then
        hs.alert.show("Display grid: no displays found")
        return
    end

    if swapTops then
        if screens.A and screens.B then
            screens.A, screens.B = screens.B, screens.A
        else
            log.w("Display grid: need both top panels to swap them")
        end
    end

    local function place(order)
        for _, key in ipairs(order) do
            local screen = screens[key]
            if screen then screen:setOrigin(originForSlot(key, screen)) end
        end
    end

    -- Park the tops far apart first: two same-size panels trading places
    -- would otherwise overlap mid-move, and macOS shoves one of them aside.
    -- Then set the final origins anchor-first, and once more after a beat,
    -- because macOS can still nudge displays while the first pass lands.
    if screens.A then screens.A:setOrigin(-10000, -2000) end
    if screens.B then screens.B:setOrigin(10000, -2000) end
    hs.timer.doAfter(0.3, function() place({"D", "B", "C", "A"}) end)
    hs.timer.doAfter(0.8, function() place({"D", "B", "C", "A"}) end)

    local summary = describe(screens)
    log.i((swapTops and "Swapped tops; " or "Applied grid; ") .. summary)
    hs.alert.show(swapTops and "Swapped the top displays" or "Display grid applied")
end

-- Arrange the grid, keeping the tops in their current left/right order.
-- Headless: hs -c "fix2x2Grid()"
function fix2x2Grid()
    applyGrid(false)
end

-- Swap the two top panels and arrange the grid. Bound to hyper+f.
function swapTopDisplays()
    applyGrid(true)
end

hs.hotkey.bind(hyper, "f", swapTopDisplays)

-- Log every display, the slot it was classified into, and where it is now.
function dumpDisplayGrid()
    local screens = classifyScreens()
    local slotFor = {}
    for key, screen in pairs(screens) do slotFor[screen:getUUID()] = key end

    log.i("-- Displays (slot: A top-left, B top-right, C bottom-left, D bottom-right):")
    for _, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:fullFrame()
        log.i(string.format("%s  %-14s %s  %dx%d @ %d,%d",
            slotFor[screen:getUUID()] or "-",
            screen:name() or "?",
            screen:getUUID(),
            frame.w, frame.h, frame.x, frame.y))
    end
    hs.alert.show("Display config dumped to console")
end

hs.hotkey.bind(hyper, "9", dumpDisplayGrid)
