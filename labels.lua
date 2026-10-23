local Settings = require("settings")
local Labels = {}
local entries = {}
local parent, interfaceID
local HEIGHT = 26

function Labels.Clear()
    if parent and ui.Interfaces:GetInterface(interfaceID) ~= nil then
        for _, entry in pairs(entries) do entry.root:Destroy() end
    end
    entries, parent, interfaceID = {}, nil, nil
end

function Labels.BeginFrame()
    local current = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__ROOT)
    if current == nil or current.width <= 0 or current.height <= 0
        or current.visibleGlobal == false then
        current = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    end
    if current ~= parent then
        Labels.Clear()
        parent = current
        interfaceID = current and current.interfaceID
    end
    for _, entry in pairs(entries) do entry.seen = false end
end

function Labels.Draw(npc, bounds)
    if parent == nil or bounds == nil or parent.width <= 0 or parent.height <= 0 then return end
    local position = ScreenConvert.Vector3ToScreen(Vector3.new(
        (bounds.minX + bounds.maxX) / 2, bounds.maxY + 32, (bounds.minZ + bounds.maxZ) / 2
    ))
    if position == nil then return end
    -- Projections use screen coordinates; UI positions are relative to the
    -- parent, which may be an inset game area rather than the full window.
    local origin = parent.xyGlobal
    local x = position.x - (origin and origin.x or 0)
    local y = position.y - (origin and origin.y or 0)
    if x < 0 or y < 0 or x > parent.width or y > parent.height then return end

    local entry = entries[npc.uid]
    if not entry then
        local root = ui.Layer.new(parent)
        root.clickthrough = true
        root.enabled = false
        root.hidden = false
        root.alpha = 1
        local background = ui.Rectangle.new(root)
        background:SetSize(0, 0, 1, 1)
        background.fill = true
        background.alpha = 1
        background.clickthrough = true
        background.enabled = false
        local text = ui.Text.new(root)
        text:SetSize(0, 0, 1, 1)
        text.font = id.Font.MUSEO_SANS_15PT_REGULAR
        text.alpha = 1
        text.isShadowed = true
        text.alignHorizontal = ui.AlignMode.CENTRE
        text.alignVertical = ui.AlignMode.CENTRE
        text.maxLines = 1
        text.clickthrough = true
        text.enabled = false
        entry = { root = root, text = text, background = background }
        entries[npc.uid] = entry
    end
    entry.background.hidden = not Settings.get("showNameBackground")
    entry.background.rgba = Settings.get("nameBackgroundColour")
    entry.text.rgba = Settings.get("nameTextColour")
    if entry.name ~= npc.displayName then
        entry.name = npc.displayName
        entry.text.content = npc.displayName
        entry.width = config.Font.MUSEO_SANS_15PT_REGULAR:GetStringWidth(npc.displayName, false) + 16
    end
    local width = math.min(entry.width, parent.width)
    entry.root:SetSize(width, HEIGHT)
    entry.root:SetPos(
        math.floor(math.max(0, math.min(x - width / 2, parent.width - width))),
        math.floor(math.max(0, math.min(y - HEIGHT, parent.height - HEIGHT)))
    )
    -- Sending these to the back puts them behind the game-area component.
    -- Bring them above the viewport; all children remain clickthrough.
    entry.root:MoveToFront()
    entry.seen = true
end

function Labels.EndFrame()
    for uid, entry in pairs(entries) do
        if not entry.seen then
            entry.root:Destroy()
            entries[uid] = nil
        end
    end
end

return Labels
