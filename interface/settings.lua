local Settings = require("settings")
local SettingsPane = {}
local EVENT_ID = "arachnophobia-settings"
local views = {}
local colourOptions = {
    { setting = "defaultBoxColour", label = "Default Box" },
    { setting = "araxxorColour", label = "Araxxor" },
    { setting = "araxxiColour", label = "Araxxi" },
    { setting = "mirrorbackColour", label = "Mirrorback Spider" },
    { setting = "pulsingColour", label = "Pulsing Spider" },
    { setting = "acidicColour", label = "Acidic Spider (Instant-kill)" },
}

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
        { text = "Cover Araxxor Previews", value = "coverAraxxorPreviews", selected = Settings.get("coverAraxxorPreviews") },
        { text = "Cover UI Crawlers", value = "coverUICrawlers", selected = Settings.get("coverUICrawlers") },
    }, {
        onChange = function(_, _, name, selected) Settings.update(name, selected) end,
    })
    if key == "settings" then
        view:AddText("Covers spiders with opaque boxes. Click through boxes and labels to interact normally.")
        view:AddText("Cover Araxxor Fight is off by default. Enable it to cover Araxxor, Araxxi, araxytes, and all seven fight-specific spider types. When off, these NPCs stay visible, even if listed under Additional NPCs.")
        view:AddText("Default colours: mirrorback white, pulsing orange, and acidic (instant-kill) bright red. Customise box colours below.")
        view:AddText("Cover Araxxor Previews hides the Araxxor/Araxxi portraits in instance creation and Beasts, and covers the attuned Araxxor portal at War's Retreat. This works independently of fight coverage.")
        view:AddText("Cover UI Crawlers follows the small and big spider overlay components with clickthrough boxes. This is on by default and independent of fight and preview coverage.")
    end
    local field, nameToggles
    local pickers = {}
    local function addColourPickers(options)
        for _, option in ipairs(options) do
            local setting = option.setting
            view:AddText(option.label)
            pickers[setting] = view:AddColourPicker({
                value = Settings.get(setting),
                alphaSlider = false,
                onChange = function(_, colour) Settings.update(setting, colour) end,
            })
        end
    end
    if key == "settings" then
        view:AddDivider()
        view:AddTitle("Additional NPCs")
        view:AddText("Add exact NPC or pet names, separated by commas, to cover creatures with other names.")
        field = view:AddTextField({
            placeholder = "Eek, Rax",
            text = Settings.get("customNPCs"),
            onChange = function(_, _, text) Settings.update("customNPCs", text) end,
        })
        view:AddDivider()
        view:AddTitle("Box Colours")
        addColourPickers(colourOptions)
        view:AddDivider()
        view:AddTitle("Name Labels")
        nameToggles = view:AddCheckboxButton({
            { text = "Show Name Background", value = "showNameBackground",
                selected = Settings.get("showNameBackground") },
        }, {
            onChange = function(_, _, name, selected) Settings.update(name, selected) end,
        })
        addColourPickers({
            { setting = "nameBackgroundColour", label = "Name Background Colour" },
            { setting = "nameTextColour", label = "Name Text Colour" },
        })
        view:AddDivider()
        view:AddText("Restore all options and colours to defaults and clear Additional NPCs.")
        view:AddSimpleButton("Reset to Defaults", function() Settings.ResetDefaults() end)
    end
    if key == "content" then
        view:AddDivider()
        view:AddText("Manage Arachnophobia settings via Plugin Hub for option details and custom configurations!")
    end
    Settings.Subscribe(EVENT_ID .. key, function(name, value)
        if name == "customNPCs" then
            if field and field:GetText() ~= value then field:SetText(value) end
        elseif pickers[name] then
            pickers[name]:SetValue(value, false)
        elseif name == "showNameBackground" then
            if nameToggles then nameToggles:SetSelected(name, value, false) end
        elseif type(value) == "boolean" then
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
