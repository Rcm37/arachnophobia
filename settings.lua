local Settings = {}
local listeners, cache = {}, {}
local definitions = {
    enabled = { default = true, type = "boolean" },
    showNames = { default = true, type = "boolean" },
    showNameBackground = { default = true, type = "boolean" },
    nameBackgroundColour = { default = 0x202830FF, type = "number" },
    nameTextColour = { default = 0xFFFFFFFF, type = "number" },
    coverAraxxorFight = { default = false, type = "boolean" },
    coverAraxxorPreviews = { default = true, type = "boolean" },
    customNPCs = { default = "", type = "string" },
    defaultBoxColour = { default = 0x202830FF, type = "number" },
    araxxorColour = { default = 0x202830FF, type = "number" },
    araxxiColour = { default = 0x202830FF, type = "number" },
    mirrorbackColour = { default = 0xFFFFFFFF, type = "number" },
    pulsingColour = { default = 0xFF8800FF, type = "number" },
    acidicColour = { default = 0xFF0000FF, type = "number" },
}
local PREFIX = "arachnophobia_"

local function definition(name)
    assert(definitions[name], "Unknown setting: " .. tostring(name))
    return definitions[name]
end

local function write(name, value, kind)
    if kind == "boolean" then
        PersistentDB:SetBool(PREFIX .. name, value)
    elseif kind == "number" then
        PersistentDB:SetString(PREFIX .. name, tostring(value))
    else
        PersistentDB:SetString(PREFIX .. name, value)
    end
end

local function validColour(value)
    return type(value) == "number" and value >= 0 and value <= 0xFFFFFFFF and value % 1 == 0
end

local function opaqueColour(value)
    return math.floor(value / 256) * 256 + 255
end

function Settings.get(name)
    local spec = definition(name)
    if cache[name] ~= nil then return cache[name] end
    local value
    if spec.type == "boolean" then
        value = PersistentDB:GetBool(PREFIX .. name)
    else
        value = PersistentDB:GetString(PREFIX .. name)
        if spec.type == "number" then
            value = tonumber(value)
            value = validColour(value) and opaqueColour(value) or nil
        end
    end
    if value == nil then
        value = spec.default
        write(name, value, spec.type)
    end
    cache[name] = value
    return value
end

function Settings.update(name, value)
    local spec = definition(name)
    assert(type(value) == spec.type, "Setting " .. name .. " expects " .. spec.type)
    if spec.type == "number" then
        assert(validColour(value), "Setting " .. name .. " expects an RGBA colour")
        value = opaqueColour(value)
    end
    write(name, value, spec.type)
    cache[name] = value
    for _, callback in pairs(listeners) do callback(name, value) end
end

function Settings.Subscribe(key, callback) listeners[key] = callback end
function Settings.Unsubscribe(key) listeners[key] = nil end

function Settings.ResetDefaults()
    for name, spec in pairs(definitions) do
        Settings.update(name, spec.default)
    end
end

return Settings
