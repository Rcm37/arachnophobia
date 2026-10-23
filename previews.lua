local Settings = require("settings")
local Box = require("box")
local Previews = {}
local PREVIEW_COLOUR = 0x202830FF
local covers = {}
local parent, interfaceID
local portraits = {
    { name = 104267785, image = 104267778, area = 104267776, host = 104267788, sidePadding = 20 }, -- BOSS_INSTANCE: portrait background plus leg clearance
    { name = 49348619, image = 49348648 }, -- BSLAY_BOSS_INFO: BOSS_MODEL
}

local function destroyCover(entry)
    if entry.text then pcall(function() entry.text:Destroy() end) end
    pcall(function() entry.cover:Destroy() end)
end

local function isRax(name)
    name = (name or ""):lower()
    return name:find("araxxi", 1, true) ~= nil
end

function Previews.Clear()
    for _, entry in pairs(covers) do destroyCover(entry) end
    covers, parent, interfaceID = {}, nil, nil
end

local function componentKey(component)
    if component.interfaceID == nil or component.staticID == nil then return tostring(component) end
    return table.concat({ component.interfaceID, component.staticID,
        component.categoryID or -1, component.dynamicID or -1 }, ":")
end

local function conceal(component, seen, key, overlayHost, sidePadding)
    if component == nil or component.visibleGlobal == false then return end
    -- Put the cover in the portrait's own container. A top-level rectangle can
    -- sit behind modal interfaces even after MoveToFront() on that rectangle.
    local host = overlayHost or component.parent or parent
    if host == nil then return end
    local position, origin = component.xyGlobal, host.xyGlobal
    if position == nil or component.width <= 0 or component.height <= 0 then return end
    local x = position.x - (origin and origin.x or 0)
    local y = position.y - (origin and origin.y or 0)
    sidePadding = overlayHost and sidePadding or 0
    local left, top = math.max(0, x - sidePadding), math.max(0, y)
    local right = math.min(host.width, x + component.width + sidePadding)
    local bottom = math.min(host.height, y + component.height)
    if right <= left or bottom <= top then return end
    local isPortrait = key ~= nil
    key = key or componentKey(component)
    local hostKey = componentKey(host)
    local entry = covers[key]
    if entry and entry.hostKey ~= hostKey then
        destroyCover(entry)
        covers[key], entry = nil, nil
    end
    local cover = entry and entry.cover
    if cover == nil then
        cover = ui.Rectangle.new(host)
        cover.fill = true
        cover.clickthrough = true
        cover.enabled = false
        cover.hidden = false
        cover.alpha = 1
        covers[key] = { cover = cover, hostKey = hostKey }
        if isPortrait then
            local text = ui.Text.new(host)
            text.content = "Hidden by Arachnophobia plugin"
            text.font = id.Font.MUSEO_SANS_15PT_REGULAR
            text.rgba = 0xFFFFFFFF
            text.alpha = 1
            text.hidden = false
            text.isShadowed = true
            text.alignHorizontal = ui.AlignMode.CENTRE
            text.alignVertical = ui.AlignMode.CENTRE
            text.maxLines = 3
            text.clickthrough = true
            text.enabled = false
            covers[key].text = text
        end
    end
    cover.rgba = PREVIEW_COLOUR
    cover:SetPos(left, top)
    cover:SetSize(right - left, bottom - top)
    cover:MoveToFront()
    local text = covers[key].text
    if text then
        text:SetPos(left + 8, top)
        text:SetSize(math.max(0, right - left - 16), bottom - top)
        text:MoveToFront()
    end
    seen[key] = true
end

local function coverBeastsIcons(component, seen)
    if component == nil then return end
    if component.type == ui.ComponentType.SPRITE then
        -- AIF_BOSS_SLAYER_ARAXXOR: also catches the dynamic Beasts list entry.
        if component.spriteID == 23969 then
            conceal(component, seen, componentKey(component))
        end
        return
    end
    local kind = component.type
    if kind == ui.ComponentType.LAYER or kind == ui.ComponentType.PANEL
        or kind == ui.ComponentType.LIST or kind == ui.ComponentType.GROUP_BOX
        or kind == ui.ComponentType.GRID then
        local function visit(child)
            coverBeastsIcons(child, seen)
            return false
        end
        component:IterateStaticComponents(visit)
        component:IterateDynamicComponents(visit)
    end
end

function Previews.Draw()
    if not Settings.get("coverAraxxorPreviews") then
        Previews.Clear()
        return
    end
    local current = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__ROOT)
    if current == nil or current.width <= 0 or current.height <= 0
        or current.visibleGlobal == false then
        current = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    end
    if (current and componentKey(current)) ~= (parent and componentKey(parent)) then
        Previews.Clear()
        parent = current
        interfaceID = current and current.interfaceID
    end
    local seen = {}
    for _, portrait in ipairs(portraits) do
        local name = ui.Interfaces:GetComponent(portrait.name)
        if name and name.visibleGlobal and isRax(name.content) then
            local image = ui.Interfaces:GetComponent(portrait.image)
            local area = portrait.area and ui.Interfaces:GetComponent(portrait.area)
            -- UI models can render well beyond their layout bounds. Cover the
            -- entire portrait background while keeping adjacent controls clear.
            local target = image
            if image and image.visibleGlobal ~= false and area and area.visibleGlobal ~= false
                and area.width > 0 and area.height > 0 then target = area end
            -- Background bounds determine size, but its container may draw
            -- behind the model. Add the instance cover to the modal itself so
            -- MoveToFront places it above both portrait branches.
            local host = portrait.host and ui.Interfaces:GetComponent(portrait.host)
            conceal(target, seen, portrait.image, host, portrait.sidePadding)
        end
    end
    coverBeastsIcons(ui.Interfaces:GetComponent(49348608), seen)
    for key, entry in pairs(covers) do
        if not seen[key] then
            destroyCover(entry)
            covers[key] = nil
        end
    end
    -- Sprite and model covers can overlap. Raise labels after every cover has
    -- been positioned, so a later Beasts sprite cover cannot obscure the text.
    for _, entry in pairs(covers) do
        if entry.text then entry.text:MoveToFront() end
    end

    -- MultiLoc entities expose their selected destination through configID.
    for _, portal in ipairs(LocList.ByConfigID(114780)) do -- PVM_HUB_PORTAL_ARAXXI
        if portal.isValid and not portal.isHidden then
            local position = portal.position
            -- LocEntity has no world AABB. Conservatively cover the portal's
            -- footprint in both orientations, including its floating preview.
            local radius = math.max(portal.width, portal.length, 1) * 768
            Box.Draw({
                minX = position.x - radius, maxX = position.x + radius,
                minY = position.y - 256, maxY = position.y + 2048,
                minZ = position.z - radius, maxZ = position.z + radius,
            }, nil, PREVIEW_COLOUR)
        end
    end
end

return Previews
