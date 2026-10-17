local Settings = {}
local listeners, cache = {}, {}
local definitions = {
    enabled = { default = true, type = "boolean" },
    showNames = { default = true, type = "boolean" },
    coverAraxxorFight = { default = false, type = "boolean" },
    customNPCs = { default = "", type = "string" },
}
local PREFIX = "arachnophobia_"

local function definition(name)
    assert(definitions[name], "Unknown setting: " .. tostring(name))
    return definitions[name]
end

local function write(name, value, kind)
    if kind == "boolean" then
        PersistentDB:SetBool(PREFIX .. name, value)
    else
        PersistentDB:SetString(PREFIX .. name, value)
    end
end

function Settings.get(name)
    local spec = definition(name)
    if cache[name] ~= nil then return cache[name] end
    local value
    if spec.type == "boolean" then
        value = PersistentDB:GetBool(PREFIX .. name)
    else
        value = PersistentDB:GetString(PREFIX .. name)
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
    write(name, value, spec.type)
    cache[name] = value
    for _, callback in pairs(listeners) do callback(name, value) end
end

function Settings.Subscribe(key, callback) listeners[key] = callback end
function Settings.Unsubscribe(key) listeners[key] = nil end

return Settings
