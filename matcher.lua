local Matcher = {}
local cachedInput, customNames
local fightFragments = { "araxxor", "araxxi", "araxyte" }
local fightNames = {
    ["bladed spider"] = true,
    ["imbued spider"] = true,
    ["spitting spider"] = true,
    ["mirrorback spider"] = true,
    ["pulsing spider"] = true,
    ["acidic spider"] = true,
    ["highly acidic spider"] = true,
}

local function normalize(name)
    return (name:lower():gsub("^%s+", ""):gsub("%s+$", ""))
end

function Matcher.Matches(name, customInput, coverAraxxorFight)
    if type(name) ~= "string" then return false end
    name = normalize(name)
    -- Check encounter NPCs before generic spider matching and custom lists so
    -- disabling fight coverage always leaves the bosses and their adds visible.
    if fightNames[name] then return coverAraxxorFight == true end
    for _, fragment in ipairs(fightFragments) do
        if name:find(fragment, 1, true) then return coverAraxxorFight == true end
    end
    if name:find("spider", 1, true) then return true end
    customInput = customInput or ""
    if cachedInput ~= customInput then
        customNames = {}
        for entry in customInput:gmatch("[^,]+") do
            entry = normalize(entry)
            if entry ~= "" then customNames[entry] = true end
        end
        cachedInput = customInput
    end
    return customNames[name] == true
end

return Matcher
