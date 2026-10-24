-- Run from arachnophobia: lua tests/arachnophobia_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local saved = {}
PersistentDB = {
    GetBool = function(_, key) return saved[key] end,
    GetString = function(_, key) return saved[key] end,
    SetBool = function(_, key, value) saved[key] = value end,
    SetString = function(_, key, value) saved[key] = value end,
}
local function subscription()
    return {
        callbacks = {},
        Subscribe = function(key, callback) Event.Draw.callbacks[key] = callback end,
        Unsubscribe = function(key) Event.Draw.callbacks[key] = nil end,
    }
end
Event = { Draw = subscription() }
Vector3 = { new = function(x, y, z) return { x = x, y = y, z = z } end }
local draws = {}
ShapeList = { Draw = function(shape) draws[#draws + 1] = shape end }
local root = { width = 1000, height = 800, interfaceID = 1 }
local gameArea
local interfaceLoaded = true
local components = {}
local function component(parent)
    local c = { parent = parent, children = {}, interfaceID = parent.interfaceID }
    function c:SetPos(x, y) self.x, self.y = x, y end
    function c:SetSize(w, h) self.width, self.height = w, h end
    function c:MoveToBack() error("labels must not be drawn behind the viewport") end
    function c:MoveToFront() self.frontMoves = (self.frontMoves or 0) + 1 end
    function c:Destroy()
        self.destroyed = true
        for _, child in ipairs(self.children) do child:Destroy() end
    end
    if parent.children then parent.children[#parent.children + 1] = c end
    components[#components + 1] = c
    return c
end
ui = {
    Interfaces = {
        GetComponent = function(_, componentID)
            if componentID == id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM then return root end
            if componentID == id.Component.TOPLEVEL_V2__ROOT then return root end
            if componentID == id.Component.TOPLEVEL_V2__GAME_AREA then return gameArea end
        end,
        GetInterface = function() return interfaceLoaded and {} or nil end,
    },
    Layer = { new = component }, Rectangle = { new = component }, Text = { new = component },
    AlignMode = { CENTRE = 1 },
}
id = { Component = { TOPLEVEL_V2__ROOT = 1, TOPLEVEL_V2__GAME_AREA = 2,
        TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM = 96796734,
        SB_OVERLAY__SMALL_SPIDER = 99287050, SB_OVERLAY__BIG_SPIDER = 99287051 },
    Font = { MUSEO_SANS_15PT_REGULAR = 2 } }
config = { Font = { MUSEO_SANS_15PT_REGULAR = {
    GetStringWidth = function(_, name) return #name * 8 end,
} } }
local projected = { x = 500, y = 400 }
ScreenConvert = { Vector3ToScreen = function() return projected end }
local bounds = { minX = 100, minY = 200, minZ = 300, maxX = 400, maxY = 500, maxZ = 600 }
local function npc(uid, name)
    return { uid = uid, displayName = name, isValid = true, aabb = bounds }
end
local spider, guard = npc(1, "Giant Spider"), npc(2, "Guard")
local npcs = { spider, guard }
NPCList = { All = function() return npcs end }
LocList = { ByConfigID = function() return {} end }

local Matcher = require("matcher")
expect(Matcher.Matches("SPIDER", ""), true, "case-insensitive spiders")
expect(Matcher.Matches("Araxxor", "", true), true, "boss without spider in its name")
expect(Matcher.Matches("Araxxi", "", true), true, "second boss form")
expect(Matcher.Matches("Araxyte", "", true), true, "araxytes")
for _, name in ipairs({ "Araxxor", "Araxxi", "Araxyte", "Bladed spider", "Imbued spider",
    "Spitting spider", "Mirrorback spider", "Pulsing spider", "Acidic spider", "Highly acidic spider" }) do
    expect(Matcher.Matches(name, ""), false, name .. " visible by default")
    expect(Matcher.Matches(name, name, false), false, name .. " cannot bypass fight toggle via custom names")
    expect(Matcher.Matches(name:upper(), "", true), true, name .. " covered when fight toggle on")
end
expect(Matcher.Matches(nil, ""), false, "missing name")
expect(Matcher.Matches("Rax", " Eek, RAX, ,"), true, "custom names trimmed and folded")
expect(Matcher.Matches("Rax pet", "Rax"), false, "custom names are exact")
expect(Matcher.Matches("Rax", ""), false, "changing list clears cached matches")

local Settings = require("settings")
expect(Settings.get("enabled"), true, "enabled by default")
expect(Settings.get("showNames"), true, "names on by default")
expect(Settings.get("coverAraxxorFight"), false, "fight coverage off by default")
expect(Settings.get("coverUICrawlers"), true, "UI crawlers covered by default")
expect(pcall(Settings.update, "enabled", "false"), false, "setting types checked")
expect(pcall(Settings.get, "spiders"), false, "unknown settings rejected")

local Plugin = require("arachnophobia")
Plugin.Start()
Plugin.Start()
local function frame()
    draws = {}
    for _, callback in pairs(Event.Draw.callbacks) do callback() end
end
local function liveLabels()
    local found = {}
    for _, c in ipairs(components) do
        if c.content and not c.destroyed then found[#found + 1] = c end
    end
    return found
end
frame()
expect(#draws, 1, "only matching NPCs masked")
expect(#draws[1].shapePositions, 8, "box has eight corners")
expect(#draws[1].shapeTris, 72, "all six faces filled in both directions")
expect(draws[1].ignoreDepth, true, "mask always overlays the model")
expect(draws[1].colour & 0xFF, 0xFF, "mask fully opaque")
expect(draws[1].shapePositions[1].x < bounds.minX, true, "padding covers model edges")
expect(draws[1].shapePositions[8].z > bounds.maxZ, true, "padding covers far edges")
for _, index in ipairs(draws[1].shapeTris) do
    assert(index >= 0 and index <= 7, "triangle indices must use zero-based corners")
end
expect(#liveLabels(), 1, "one name label")
expect(liveLabels()[1].content, "Giant Spider", "label contains NPC name")
for _, c in ipairs(components) do
    expect(c.clickthrough, true, "every label component passes clicks through")
    expect(c.enabled, false, "every label component ignores input")
end
local firstLabel = liveLabels()[1]
expect(firstLabel.parent.frontMoves, 1, "label brought above the game viewport")
expect(firstLabel.parent.hidden, false, "label explicitly visible")
expect(firstLabel.parent.alpha, 1, "label fully opaque")
frame()
expect(liveLabels()[1], firstLabel, "reuse label between frames")
local nameBackground = firstLabel.parent.children[1]
expect(nameBackground.hidden, false, "name background shown by default")
expect(nameBackground.rgba, 0x202830FF, "default name background colour")
expect(firstLabel.rgba, 0xFFFFFFFF, "default name text colour")
Settings.update("nameBackgroundColour", 0x334455FF)
Settings.update("nameTextColour", 0xFFEEDDFF)
Settings.update("showNameBackground", false)
frame()
expect(liveLabels()[1], firstLabel, "name styling updates existing labels")
expect(nameBackground.hidden, true, "background can be removed independently of names")
expect(nameBackground.rgba, 0x334455FF, "chosen background colour applied")
expect(firstLabel.rgba, 0xFFEEDDFF, "chosen text colour applied")
expect(firstLabel.parent.hidden, false, "text remains visible without background")
local savedNameSettings = dofile("settings.lua")
expect(savedNameSettings.get("showNameBackground"), false, "background toggle persists")
expect(savedNameSettings.get("nameBackgroundColour"), 0x334455FF, "background colour persists")
expect(savedNameSettings.get("nameTextColour"), 0xFFEEDDFF, "text colour persists")
Settings.update("showNameBackground", true)
frame()
expect(nameBackground.hidden, false, "background can be restored")
expect(nameBackground.rgba, 0x334455FF, "restored background retains chosen colour")
Settings.update("nameBackgroundColour", 0x202830FF)
Settings.update("nameTextColour", 0xFFFFFFFF)
spider.displayName = "Spiderling"
frame()
expect(firstLabel.content, "Spiderling", "transformed NPC label refreshed")
spider.aabb = { minX = 0, minY = 0, minZ = 0, maxX = 1000, maxY = 2000, maxZ = 3000 }
frame()
expect(draws[1].shapePositions[8].z, 3016, "moving and resized AABB read every frame")
do
    local previousNPCs = npcs
    npcs = {
        npc(3, "Mirrorback spider"), npc(4, "Pulsing spider"),
        npc(5, "Acidic spider"), npc(6, "Highly acidic spider"),
        npc(7, "MIRRORBACK SPIDER"), npc(8, "Araxxor"), npc(9, "Araxxi"), spider,
    }
    frame()
    expect(#draws, 1, "fight NPCs visible by default while ordinary spiders stay covered")
    expect(#liveLabels(), 1, "fight NPCs have no covering labels by default")
    Settings.update("coverAraxxorFight", true)
    expect(saved.arachnophobia_coverAraxxorFight, true, "fight toggle persisted")
    frame()
    expect(#draws, 8, "bosses and Araxxor adds masked when enabled")
    expect(draws[1].colour, 0xFFFFFFFF, "mirrorbacks are white")
    expect(draws[2].colour, 0xFF8800FF, "pulsing spiders are orange")
    expect(draws[3].colour, 0xFF0000FF, "instant-kill acidic spiders are bright red")
    expect(draws[4].colour, 0x202830FF, "highly acidic spiders do not get instant-kill warning")
    expect(draws[5].colour, 0xFFFFFFFF, "colour matching ignores name case")
    local customColours = {
        defaultBoxColour = 0x123456FF,
        araxxorColour = 0x224466FF,
        araxxiColour = 0x446688FF,
        mirrorbackColour = 0x6688AAFF,
        pulsingColour = 0x88AACCFF,
        acidicColour = 0xAACCEEFF,
    }
    for name, colour in pairs(customColours) do Settings.update(name, colour) end
    frame()
    expect(draws[1].colour, customColours.mirrorbackColour, "mirrorback colour updates live")
    expect(draws[2].colour, customColours.pulsingColour, "pulsing colour updates live")
    expect(draws[3].colour, customColours.acidicColour, "acidic colour updates live")
    expect(draws[4].colour, customColours.defaultBoxColour, "other adds use default colour")
    expect(draws[6].colour, customColours.araxxorColour, "Araxxor has independent colour")
    expect(draws[7].colour, customColours.araxxiColour, "Araxxi has independent colour")
    expect(draws[8].colour, customColours.defaultBoxColour, "ordinary spiders use default colour")
    local reloadedSettings = dofile("settings.lua")
    for name, colour in pairs(customColours) do
        expect(reloadedSettings.get(name), colour, name .. " persists between loads")
    end
    expect(pcall(Settings.update, "defaultBoxColour", -1), false, "negative colour rejected")
    expect(pcall(Settings.update, "defaultBoxColour", 0x100000000), false, "out-of-range colour rejected")
    expect(pcall(Settings.update, "defaultBoxColour", 1.5), false, "fractional colour rejected")
    Settings.update("defaultBoxColour", 0x12345600)
    expect(Settings.get("defaultBoxColour"), 0x123456FF, "colour stays opaque")
    Settings.update("defaultBoxColour", 0x202830FF)
    Settings.update("araxxorColour", 0x202830FF)
    Settings.update("araxxiColour", 0x202830FF)
    Settings.update("mirrorbackColour", 0xFFFFFFFF)
    Settings.update("pulsingColour", 0xFF8800FF)
    Settings.update("acidicColour", 0xFF0000FF)
    Settings.update("coverAraxxorFight", false)
    frame()
    expect(#draws, 1, "disabling fight coverage restores bosses and minions")
    expect(#liveLabels(), 1, "disabling fight coverage removes fight labels")
    npcs = previousNPCs
    frame()
end
Settings.update("customNPCs", "Guard")
frame()
expect(#draws, 2, "custom names mask additional NPCs")
expect(#liveLabels(), 2, "custom NPCs also labelled")
Settings.update("showNames", false)
expect(#liveLabels(), 0, "turning labels off cleans up immediately")
frame()
expect(#draws, 2, "turning labels off preserves boxes")
Settings.update("showNames", true)
frame()
expect(#liveLabels(), 2, "turning labels back on recreates them")
projected = nil
frame()
expect(#draws, 2, "projection failure does not prevent boxes")
expect(#liveLabels(), 0, "unprojectable labels removed")
projected = { x = 500, y = 400 }
spider.isValid = false
frame()
expect(#draws, 1, "invalid NPC skipped")
expect(#liveLabels(), 1, "invalid NPC label removed")
guard.aabb = nil
frame()
expect(#draws, 0, "missing bounds skipped")
expect(#liveLabels(), 0, "missing bounds leave no label")
guard.aabb = bounds
frame()
Settings.update("enabled", false)
expect(next(Event.Draw.callbacks), nil, "disabled plugin unsubscribes drawing")
expect(#liveLabels(), 0, "disabled plugin clears labels")
expect(saved.arachnophobia_enabled, false, "disabled state persisted")
Settings.update("enabled", true)
frame()
expect(#draws, 1, "reenabling resumes masks")
npcs = {}
frame()
expect(#liveLabels(), 0, "despawn clears labels")
npcs = { guard }
frame()
-- Some layouts expose the game area without a usable top-level root.
local originalRoot = root
root = nil
gameArea = { width = 800, height = 600, interfaceID = 1, xyGlobal = { x = 100, y = 50 } }
frame()
local fallbackLabel = liveLabels()[1]
expect(fallbackLabel.parent.parent, gameArea, "fallback uses game area when root unavailable")
expect(fallbackLabel.parent.x, math.floor(400 - fallbackLabel.parent.width / 2),
    "label converts screen x to parent coordinates")
expect(fallbackLabel.parent.y, 324, "label converts screen y to parent coordinates")
root = { width = 0, height = 0, interfaceID = 1 }
frame()
expect(liveLabels()[1], fallbackLabel, "zero-size root does not displace visible game-area label")
root = originalRoot
root.visibleGlobal = false
frame()
expect(liveLabels()[1], fallbackLabel, "hidden root falls back to game area")
root.visibleGlobal = true
gameArea = nil
frame()
expect(fallbackLabel.destroyed, true, "old fallback labels cleaned up when parent changes")
-- Simulate top-level interface teardown and rebuilding after logout.
interfaceLoaded, root = false, nil
frame()
expect(#draws, 1, "missing UI does not interrupt masks")
root = { width = 1000, height = 800, interfaceID = 2 }
interfaceLoaded = true
frame()
local newest = components[#components]
expect(newest.content, "Guard", "labels recover after interface reload")
local originalGetComponent = ui.Interfaces.GetComponent
ui.Interfaces.GetComponent = function(self, target)
    if target == id.Component.SB_OVERLAY__SMALL_SPIDER then
        return { parent = root, visibleGlobal = true, width = 50, height = 40,
            xyGlobal = { x = 100, y = 100 } }
    end
    return originalGetComponent(self, target)
end
Settings.update("coverAraxxorPreviews", false)
frame()
local crawlerCover = components[#components]
expect(crawlerCover.fill, true, "crawler covered with fight and previews off")
Settings.update("coverUICrawlers", false)
expect(crawlerCover.destroyed, true, "crawler toggle clears cover immediately")
Settings.update("coverUICrawlers", true)
frame()
crawlerCover = components[#components]
Settings.update("enabled", false)
expect(crawlerCover.destroyed, true, "disabling plugin clears crawler cover")
Settings.update("enabled", true)
frame()
crawlerCover = components[#components]
Plugin.Shutdown()
expect(crawlerCover.destroyed, true, "shutdown clears crawler cover")
expect(newest.destroyed, true, "shutdown destroys current interface label")
expect(next(Event.Draw.callbacks), nil, "shutdown unsubscribes")
Plugin.Shutdown()
Settings.update("enabled", false)
Settings.update("coverAraxxorFight", true)
Settings.update("coverUICrawlers", false)
Settings.update("showNameBackground", false)
Settings.update("customNPCs", "Guard")
Settings.update("acidicColour", 0x112233FF)
Settings.update("nameTextColour", 0x445566FF)
local resetNotifications = {}
Settings.Subscribe("reset-test", function(name, value) resetNotifications[name] = value end)
Settings.ResetDefaults()
local resetSettings = dofile("settings.lua")
expect(resetSettings.get("enabled"), true, "reset restores enabled default")
expect(resetSettings.get("coverAraxxorFight"), false, "reset leaves fight coverage off")
expect(resetSettings.get("coverUICrawlers"), true, "reset restores UI crawler coverage")
expect(resetSettings.get("showNameBackground"), true, "reset restores name backgrounds")
expect(resetSettings.get("customNPCs"), "", "reset clears additional NPCs")
expect(resetSettings.get("acidicColour"), 0xFF0000FF, "reset restores special colour")
expect(resetSettings.get("nameTextColour"), 0xFFFFFFFF, "reset restores name text colour")
expect(resetNotifications.customNPCs, "", "reset notifies text field listeners")
expect(resetNotifications.acidicColour, 0xFF0000FF, "reset notifies colour picker listeners")
expect(resetNotifications.coverAraxxorFight, false, "reset notifies toggle listeners")
Settings.Unsubscribe("reset-test")
