local Settings = require("settings")
local Crawlers = {}
local covers = {}
local targets = { id.Component.SB_OVERLAY__SMALL_SPIDER, id.Component.SB_OVERLAY__BIG_SPIDER }
local PADDING = 8
local BIG_SPIDER_PADDING = 32

local function isDrawn(spider)
    if not spider then return false end
    -- Layout components can remain loaded after the game fades their contents
    -- out or clears a model. visibleGlobal alone does not catch those states.
    if ui.ComponentType and spider.type == ui.ComponentType.MODEL then
        if ui.ModelType and spider.modelType == ui.ModelType.NONE then return false end
        if spider.modelID1 and spider.modelID1 < 0 then return false end
    end
    local current = spider
    while current do
        if current.visibleGlobal == false or current.visible == false or current.hidden == true
            or (current.alpha and current.alpha <= 0) then return false end
        current = current.parent
    end
    return true
end

local function overlayHost()
    -- Keep the client's ordering relative to the minimap and other built-in UI.
    -- Only our children are raised; never raise the shared plugin layer itself.
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM)
end

local function key(component)
    return table.concat({ component.interfaceID or -1, component.staticID or -1,
        component.categoryID or -1, component.dynamicID or -1 }, ":")
end

local function remove(target)
    local entry = covers[target]
    if entry then pcall(function() entry.layer:Destroy() end) end
    covers[target] = nil
end

function Crawlers.Clear()
    for target in pairs(covers) do remove(target) end
end

function Crawlers.Draw()
    if not Settings.get("coverUICrawlers") then
        Crawlers.Clear()
        return
    end
    for _, target in ipairs(targets) do
        local spider = ui.Interfaces:GetComponent(target)
        local host = overlayHost()
        local position = spider and spider.xyGlobal
        if not isDrawn(spider) or not position
            or spider.width <= 0 or spider.height <= 0
            or not host or host.visibleGlobal == false or host.width <= 0 or host.height <= 0 then
            remove(target)
        else
            local origin = host.xyGlobal
            local x = position.x - (origin and origin.x or 0)
            local y = position.y - (origin and origin.y or 0)
            local padding = target == id.Component.SB_OVERLAY__BIG_SPIDER and BIG_SPIDER_PADDING or PADDING
            local left, top = math.max(0, x - padding), math.max(0, y - padding)
            local right = math.min(host.width, x + spider.width + padding)
            local bottom = math.min(host.height, y + spider.height + padding)
            -- Padding must not keep a cover alive once the actual target has
            -- left the screen. Also respect containers we moved the cover out of.
            local visibleLeft, visibleTop = math.max(0, x), math.max(0, y)
            local visibleRight = math.min(host.width, x + spider.width)
            local visibleBottom = math.min(host.height, y + spider.height)
            local ancestor = spider.parent
            while ancestor and ancestor ~= host do
                local bounds = ancestor.xyGlobal
                if bounds and ancestor.width > 0 and ancestor.height > 0 then
                    local ax = bounds.x - (origin and origin.x or 0)
                    local ay = bounds.y - (origin and origin.y or 0)
                    visibleLeft, visibleTop = math.max(visibleLeft, ax), math.max(visibleTop, ay)
                    visibleRight = math.min(visibleRight, ax + ancestor.width)
                    visibleBottom = math.min(visibleBottom, ay + ancestor.height)
                    left, top = math.max(left, ax), math.max(top, ay)
                    right = math.min(right, ax + ancestor.width)
                    bottom = math.min(bottom, ay + ancestor.height)
                end
                ancestor = ancestor.parent
            end
            if visibleRight <= visibleLeft or visibleBottom <= visibleTop
                or right <= left or bottom <= top then
                remove(target)
            else
                local hostKey = key(host)
                local entry = covers[target]
                if entry and entry.hostKey ~= hostKey then
                    remove(target)
                    entry = nil
                end
                if not entry then
                    local layer = ui.Layer.new(host)
                    layer:SetPos(0, 0)
                    layer:SetSize(0, 0, 1, 1)
                    layer.clickthrough = true
                    layer.enabled = false
                    layer.hidden = false
                    layer.alpha = 1
                    local cover = ui.Rectangle.new(layer)
                    cover.fill = true
                    cover.clickthrough = true
                    cover.enabled = false
                    cover.hidden = false
                    cover.alpha = 1
                    entry = { layer = layer, cover = cover, hostKey = hostKey }
                    covers[target] = entry
                end
                local cover = entry.cover
                cover.rgba = Settings.get("defaultBoxColour")
                cover:SetPos(left, top)
                cover:SetSize(right - left, bottom - top)
                cover:MoveToFront()
                entry.layer:MoveToFront()
            end
        end
    end
end

return Crawlers
