local Settings = require("settings")
local Matcher = require("matcher")
local Box = require("box")
local Labels = require("labels")
local Previews = require("previews")
local Crawlers = require("crawlers")
local Arachnophobia = {}
local EVENT_ID = "arachnophobia-draw"
local active = false

local function onDraw()
    Previews.Draw()
    Crawlers.Draw()
    Labels.BeginFrame()
    local customNames = Settings.get("customNPCs")
    local showNames = Settings.get("showNames")
    local coverAraxxorFight = Settings.get("coverAraxxorFight")
    for _, npc in ipairs(NPCList.All()) do
        if npc.isValid and Matcher.Matches(npc.displayName, customNames, coverAraxxorFight) then
            local bounds = npc.aabb
            Box.Draw(bounds, npc.displayName)
            if showNames then Labels.Draw(npc, bounds) end
        end
    end
    Labels.EndFrame()
end

local function setEnabled(enabled)
    if active == enabled then return end
    if enabled then
        Event.Draw.Subscribe(EVENT_ID, onDraw)
    else
        Event.Draw.Unsubscribe(EVENT_ID)
        Labels.Clear()
        Previews.Clear()
        Crawlers.Clear()
    end
    active = enabled
end

function Arachnophobia.Start()
    Settings.Subscribe(EVENT_ID, function(name, value)
        if name == "enabled" then setEnabled(value) end
        if name == "showNames" and not value then Labels.Clear() end
        if name == "coverAraxxorPreviews" and not value then Previews.Clear() end
        if name == "coverUICrawlers" and not value then Crawlers.Clear() end
    end)
    setEnabled(Settings.get("enabled"))
end

function Arachnophobia.Shutdown()
    Settings.Unsubscribe(EVENT_ID)
    setEnabled(false)
end

return Arachnophobia
