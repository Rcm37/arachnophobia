-- Run from arachnophobia: lua tests/crawlers_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local enabled, colour = true, 0x202830FF
package.loaded.settings = { get = function(name)
    if name == "coverUICrawlers" then return enabled end
    if name == "defaultBoxColour" then return colour end
    error("unexpected setting " .. name)
end }
local components, rectangles = {}, {}
id = { Component = { TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM = 96796734,
    SB_OVERLAY__SMALL_SPIDER = 99287050, SB_OVERLAY__BIG_SPIDER = 99287051 } }
ui = { Interfaces = { GetComponent = function(_, target) return components[target] end } }
local function component(parent)
    local cover = { parent = parent, children = {} }
    function cover:SetPos(x, y) self.x, self.y = x, y end
    function cover:SetSize(width, height) self.width, self.height = width, height end
    function cover:MoveToFront() self.raised = true end
    function cover:Destroy()
        self.destroyed = true
        for _, child in ipairs(self.children) do child:Destroy() end
    end
    if parent.children then parent.children[#parent.children + 1] = cover end
    return cover
end
ui.Layer = { new = component }
ui.Rectangle = { new = function(parent)
    local cover = component(parent)
    rectangles[#rectangles + 1] = cover
    return cover
end }
local host = { interfaceID = 1515, staticID = 0, width = 800, height = 600,
    xyGlobal = { x = 100, y = 50 } }
components[96796734] = host
function host:MoveToFront() error("must preserve the shared plugin layer's render order") end
local branch = { parent = host, interfaceID = 1515, staticID = 14,
    width = 300, height = 200, xyGlobal = { x = 150, y = 100 } }
local small = { parent = branch, width = 30, height = 20, visibleGlobal = true,
    xyGlobal = { x = 200, y = 150 } }
local big = { parent = host, width = 90, height = 80, visibleGlobal = true,
    xyGlobal = { x = 400, y = 250 } }
components[id.Component.SB_OVERLAY__SMALL_SPIDER], components[id.Component.SB_OVERLAY__BIG_SPIDER] = small, big
local Crawlers = require("crawlers")
Crawlers.Draw()
expect(#rectangles, 2, "both crawlers covered")
local first = rectangles[1]
expect(first.parent.parent, components[96796734], "covers attach to plugin bottom layer")
expect(first.parent.raised, true, "overlay layer raised above game interface")
expect(first.parent.clickthrough, true, "overlay layer passes clicks through")
expect(first.parent.enabled, false, "overlay layer ignores input")
expect(first.x, 92, "global x converted with margin")
expect(first.y, 92, "global y converted with margin")
expect(first.width, 46, "width includes margin")
expect(first.height, 36, "height includes margin")
expect(first.clickthrough, true, "cover passes input through")
expect(first.enabled, false, "cover ignores input")
expect(first.alpha, 1, "fully opaque")
expect(first.rgba, colour, "uses default box colour")
expect(first.raised, true, "cover raised above crawler")
small.xyGlobal.x, small.xyGlobal.y, small.width = 250, 200, 40
colour = 0x334455FF
Crawlers.Draw()
expect(#rectangles, 2, "moving covers reused")
expect(first.x, 142, "cover follows horizontal motion")
expect(first.y, 142, "cover follows vertical motion")
expect(first.width, 56, "cover follows resize")
expect(first.rgba, colour, "colour changes applied")
-- Fresh API proxies for the same parent should not recreate covers.
small.parent = { interfaceID = 1515, staticID = 0, width = 800, height = 600,
    xyGlobal = { x = 100, y = 50 } }
Crawlers.Draw()
expect(#rectangles, 2, "fresh parent proxy reuses cover")
small.xyGlobal.x, small.xyGlobal.y = 95, 45
Crawlers.Draw()
expect(first.x, 0, "left edge clipped to parent")
expect(first.y, 0, "top edge clipped to parent")
small.xyGlobal.x = 1000
Crawlers.Draw()
expect(first.destroyed, true, "offscreen cover removed")
small.xyGlobal.x = 200
Crawlers.Draw()
local replacement = rectangles[#rectangles]
small.visibleGlobal = false
Crawlers.Draw()
expect(replacement.destroyed, true, "hidden crawler cover removed")
small.visibleGlobal = true
Crawlers.Draw()
replacement = rectangles[#rectangles]
small.parent.staticID = 9
Crawlers.Draw()
expect(replacement.destroyed, nil, "reparented crawler stays in plugin bottom layer")
components[id.Component.SB_OVERLAY__SMALL_SPIDER] = nil
Crawlers.Draw()
expect(rectangles[#rectangles].destroyed, true, "unloaded crawler cover removed")
-- A loaded layout box is not necessarily drawing a spider.
components[id.Component.SB_OVERLAY__SMALL_SPIDER] = small
local function disappears(change, restore, label)
    Crawlers.Draw()
    local cover = rectangles[#rectangles]
    expect(cover.destroyed, nil, label .. " starts covered")
    change()
    Crawlers.Draw()
    expect(cover.destroyed, true, label)
    restore()
end
disappears(function() small.alpha = 0 end, function() small.alpha = 1 end,
    "fully transparent spider removes cover")
disappears(function() small.parent.alpha = 0 end, function() small.parent.alpha = 1 end,
    "faded parent removes cover")
disappears(function() small.parent.visible = false end, function() small.parent.visible = true end,
    "hidden ancestor removes cover")
ui.ComponentType, ui.ModelType = { MODEL = 6 }, { NONE = "NONE", MODEL = "MODEL" }
small.type, small.modelType, small.modelID1 = 6, "MODEL", 123
disappears(function() small.modelType = "NONE" end, function() small.modelType = "MODEL" end,
    "cleared model removes cover")
disappears(function() small.modelID1 = -1 end, function() small.modelID1 = 123 end,
    "invalid model removes cover")
local previousX, previousY = small.xyGlobal.x, small.xyGlobal.y
disappears(function() small.xyGlobal.x = 100 - small.width end,
    function() small.xyGlobal.x = previousX end,
    "left exit leaves no margin strip")
disappears(function() small.xyGlobal.y = 650 end,
    function() small.xyGlobal.y = previousY end,
    "bottom exit leaves no margin strip")
local previousParent = small.parent
small.parent = branch
small.xyGlobal.x, small.xyGlobal.y = 200, 150
disappears(function() small.xyGlobal.x = 451 end,
    function() small.xyGlobal.x = 200 end,
    "leaving original container removes raised cover")
small.parent = previousParent
components[id.Component.SB_OVERLAY__SMALL_SPIDER] = nil
Crawlers.Draw()
enabled = false
Crawlers.Draw()
expect(rectangles[2].destroyed, true, "disabling removes remaining cover")
enabled = true
Crawlers.Draw()
replacement = rectangles[#rectangles]
components[96796734] = nil
Crawlers.Draw()
expect(replacement.destroyed, true, "missing plugin bottom layer removes covers")
local count = #rectangles
Crawlers.Draw()
expect(#rectangles, count, "missing plugin bottom layer does not fall back above game UI")
components[96796734] = { interfaceID = 1477, staticID = 62, width = 800, height = 600,
    xyGlobal = { x = 120, y = 70 } }
Crawlers.Draw()
replacement = rectangles[#rectangles]
expect(replacement.parent.parent, components[96796734], "covers recover in rebuilt plugin layer")
expect(replacement.x, 248, "big cover x includes extra leg clearance")
expect(replacement.y, 148, "big cover y includes extra leg clearance")
Crawlers.Clear()
expect(replacement.destroyed, true, "shutdown cleanup removes covers")
Crawlers.Clear()
print("Passed " .. checks .. " crawler checks")
