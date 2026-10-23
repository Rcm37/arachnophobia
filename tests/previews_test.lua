-- Run from arachnophobia: lua tests/previews_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local enabled = true
package.loaded.settings = { get = function(name)
    if name == "araxxorColour" then error("previews must not read the entity colour") end
    return enabled
end }
local draws = {}
package.loaded.box = { Draw = function(bounds, name, colour)
    draws[#draws + 1] = { bounds = bounds, name = name, colour = colour }
end }
ui = { ComponentType = { SPRITE = 3, LAYER = 20 }, Interfaces = {} }
local components = {}
function ui.Interfaces:GetComponent(key) return components[key] end
function ui.Interfaces:GetInterface() return {} end
id = { Component = { TOPLEVEL_V2__ROOT = 1, TOPLEVEL_V2__GAME_AREA = 2 } }
id.Font = { MUSEO_SANS_15PT_REGULAR = 1 }
ui.AlignMode = { CENTRE = 1 }
components[1] = { width = 1000, height = 800, interfaceID = 1, xyGlobal = { x = 10, y = 20 } }
local rectangles = {}
ui.Rectangle = { new = function(parent)
    local rectangle = { parent = parent }
    function rectangle:SetPos(x, y) self.x, self.y = x, y end
    function rectangle:SetSize(width, height) self.width, self.height = width, height end
    function rectangle:MoveToFront() self.front = true end
    function rectangle:Destroy() self.destroyed = true end
    rectangles[#rectangles + 1] = rectangle
    return rectangle
end }
local texts = {}
ui.Text = { new = function(parent)
    local text = { parent = parent }
    function text:SetPos(x, y) self.x, self.y = x, y end
    function text:SetSize(width, height) self.width, self.height = width, height end
    function text:MoveToFront() self.front = true end
    function text:Destroy() self.destroyed = true end
    texts[#texts + 1] = text
    return text
end }
local function portrait()
    return { hidden = false, visibleGlobal = true, width = 200, height = 150,
        xyGlobal = { x = 110, y = 220 } }
end
local instancePortrait, beastsPortrait = portrait(), portrait()
local icon, otherIcon = portrait(), portrait()
icon.type, icon.spriteID = 3, 23969
otherIcon.type, otherIcon.spriteID = 3, 12345
components[104267785] = { content = "<col=ffffff>Araxxi</col>", visibleGlobal = true }
components[104267778] = instancePortrait
components[49348619] = { content = "ARAXXI", visibleGlobal = true }
components[49348648] = beastsPortrait
components[49348608] = {
    type = 20,
    IterateStaticComponents = function(_, callback) callback(otherIcon) end,
    IterateDynamicComponents = function(_, callback) callback(icon) end,
}
local portals = {}
LocList = { ByConfigID = function(configID)
    expect(configID, 114780, "only the Araxxor portal config queried")
    return portals
end }
local Previews = require("previews")
Previews.Draw()
expect(#rectangles, 3, "instance, details and dynamic list portraits covered")
expect(#texts, 3, "instance, Beasts detail and Beasts sprite covers labelled")
expect(texts[1].content, "Hidden by Arachnophobia plugin", "requested cover message")
expect(texts[2].content, texts[1].content, "both portrait covers have same message")
expect(texts[3].content, texts[1].content, "Beasts sprite cover includes message")
expect(texts[1].clickthrough, true, "cover text passes clicks through")
expect(texts[1].front, true, "cover text brought above rectangle")
local first = rectangles[1]
expect(first.x, 100, "cover converts global x to parent coordinates")
expect(first.y, 200, "cover converts global y to parent coordinates")
expect(first.width, 200, "cover fits portrait width")
expect(first.height, 150, "cover fits portrait height")
expect(first.clickthrough, true, "cover passes clicks through")
expect(first.enabled, false, "cover ignores input")
expect(first.rgba, 0x202830FF, "cover uses fixed opaque preview colour")
expect(first.front, true, "cover drawn above interface")
expect(instancePortrait.hidden, false, "game visibility never modified")
-- The game can keep the portrait visible without removing our cover.
instancePortrait.hidden = false
Previews.Draw()
expect(#rectangles, 3, "persistent covers reused across game updates")
expect(first.destroyed, nil, "cover persists while portrait is selected")
instancePortrait.xyGlobal.x = 150
instancePortrait.width = 240
Previews.Draw()
expect(first.x, 140, "cover tracks moved portrait")
expect(first.width, 240, "cover tracks resized portrait")
local portraitContainer = { interfaceID = 1591, staticID = 37,
    width = 300, height = 300, xyGlobal = { x = 100, y = 100 } }
instancePortrait.parent = portraitContainer
Previews.Draw()
local localCover = rectangles[#rectangles]
expect(localCover.parent, portraitContainer, "cover belongs to portrait container above modal")
expect(localCover.x, 50, "cover position relative to portrait container")
expect(localCover.y, 120, "cover y relative to portrait container")
expect(first.destroyed, true, "old top-level cover removed")
-- Each API read may return a fresh proxy for the same native component.
instancePortrait.parent = { interfaceID = 1591, staticID = 37,
    width = 300, height = 300, xyGlobal = { x = 100, y = 100 } }
local rectangleCount = #rectangles
Previews.Draw()
expect(#rectangles, rectangleCount, "fresh parent proxy does not recreate cover")
expect(localCover.destroyed, nil, "cover persists across fresh proxies")
expect(otherIcon.hidden, false, "other boss icon unchanged")
components[104267785].content = "Kerapac"
components[49348619].content = "Solak"
icon.spriteID = 12345
Previews.Draw()
expect(instancePortrait.hidden, false, "switching instance boss restores portrait")
expect(beastsPortrait.hidden, false, "switching Beasts boss restores portrait")
expect(icon.hidden, false, "recycled list entry restored")
expect(first.destroyed, true, "switching boss removes cover")
components[104267785].content = "Araxxi"
instancePortrait.visibleGlobal = false
local count = #rectangles
Previews.Draw()
expect(#rectangles, count, "invisible portrait not covered")
Previews.Clear()
instancePortrait.visibleGlobal = true
Previews.Draw()
local activeCover = rectangles[#rectangles]
portals = {
    { isValid = true, isHidden = false, position = { x = 100, y = 200, z = 300 }, width = 2, length = 3 },
    { isValid = false },
    { isValid = true, isHidden = true },
}
Previews.Draw()
expect(#draws, 1, "only valid visible portal covered")
expect(draws[1].colour, 0x202830FF, "portal uses fixed preview colour")
expect(draws[1].bounds.minX < 100, true, "portal cover extends around position")
expect(draws[1].bounds.maxY, 2248, "portal cover includes floating preview")
enabled = false
Previews.Draw()
expect(instancePortrait.hidden, false, "disabling previews restores portrait immediately")
expect(activeCover.destroyed, true, "disabling previews destroys cover")
expect(#draws, 1, "disabled previews draw no portal cover")
enabled = true
Previews.Draw()
activeCover = rectangles[#rectangles]
components[104267778] = nil
Previews.Draw()
expect(instancePortrait.hidden, false, "removed portrait restored and forgotten")
expect(activeCover.destroyed, true, "unloaded portrait cover removed")
components[104267778] = instancePortrait
components[104267776] = { visibleGlobal = true, width = 300, height = 300,
    xyGlobal = { x = 100, y = 100 }, parent = portraitContainer }
local modal = { interfaceID = 1591, staticID = 12, width = 600, height = 500,
    xyGlobal = { x = 80, y = 60 } }
components[104267788] = modal
Previews.Draw()
local fullCover = rectangles[#rectangles]
expect(fullCover.parent, modal, "instance cover draws on modal above portrait branches")
expect(fullCover.width, 340, "instance cover adds twenty pixels on each side")
expect(fullCover.height, 300, "cover uses full portrait background height")
expect(fullCover.x, 0, "instance cover extends twenty pixels left of background")
expect(fullCover.y, 40, "full cover converts background y to modal coordinates")
Previews.Clear()
Previews.Clear()
