local Settings = require("settings")
local SettingsPane = {}
local EVENT_ID = "arachnophobia-settings"
local views = {}

local function closeView(key)
    if views[key] then views[key]:Destroy() end
    views[key] = nil
    Settings.Unsubscribe(EVENT_ID .. key)
end

local function onLayerReady(key, event)
    closeView(key)
    local parent = event.component
    local view = prettyui.SimpleView.new(parent, { width = parent.width, height = parent.height })
    views[key] = view
    view:AddTitle("Arachnophobia")
    local toggles = view:AddCheckboxButton({
        { text = "Enable Plugin", value = "enabled", selected = Settings.get("enabled") },
        { text = "Show NPC Names", value = "showNames", selected = Settings.get("showNames") },
        { text = "Cover Araxxor Fight", value = "coverAraxxorFight", selected = Settings.get("coverAraxxorFight") },
    }, {
        onChange = function(_, _, name, selected) Settings.update(name, selected) end,
    })
    view:AddText("Covers spiders with opaque boxes. Click through boxes and labels to interact normally.")
    view:AddText("Cover Araxxor Fight is off by default. Enable it to cover Araxxor, Araxxi, araxytes, and all seven fight-specific spider types. When off, these NPCs stay visible, even if listed under Additional NPCs.")
    view:AddText("Mirrorback: white. Pulsing: orange. Acidic (instant-kill): bright red. Other spiders: dark grey.")
    view:AddDivider()
    view:AddTitle("Additional NPCs")
    view:AddText("Add exact NPC or pet names, separated by commas, to cover creatures with other names.")
    local field = view:AddTextField({
        placeholder = "Eek, Rax",
        text = Settings.get("customNPCs"),
        onChange = function(_, _, text) Settings.update("customNPCs", text) end,
    })
    Settings.Subscribe(EVENT_ID .. key, function(name, value)
        if name == "customNPCs" then
            if field:GetText() ~= value then field:SetText(value) end
        else
            toggles:SetSelected(name, value, false)
        end
    end)
end

function SettingsPane.Start()
    Event.ContentLayerReady.Subscribe(EVENT_ID, function(event) onLayerReady("content", event) end)
    Event.SettingsLayerReady.Subscribe(EVENT_ID, function(event) onLayerReady("settings", event) end)
end

function SettingsPane.Shutdown()
    Event.ContentLayerReady.Unsubscribe(EVENT_ID)
    Event.SettingsLayerReady.Unsubscribe(EVENT_ID)
    closeView("content")
    closeView("settings")
end

return SettingsPane
