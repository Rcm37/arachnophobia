local Settings = require("settings")
local Box = {}
local settingsByName = {
    ["mirrorback spider"] = "mirrorbackColour",
    ["pulsing spider"] = "pulsingColour",
    -- The instant-kill add is "Acidic spider". "Highly acidic spider"
    -- is a different add and must not receive the same danger colour.
    ["acidic spider"] = "acidicColour",
}

local function colourForName(name)
    name = (name or ""):lower()
    if name:find("araxxor", 1, true) then return Settings.get("araxxorColour") end
    if name:find("araxxi", 1, true) then return Settings.get("araxxiColour") end
    return Settings.get(settingsByName[name] or "defaultBoxColour")
end

-- Eight vertices, six filled faces. Include both windings so the mask also
-- covers the model if the camera clips inside the box.
local faces = {
    0, 2, 3, 0, 3, 1, -- near
    4, 5, 7, 4, 7, 6, -- far
    0, 4, 6, 0, 6, 2, -- left
    1, 3, 7, 1, 7, 5, -- right
    0, 1, 5, 0, 5, 4, -- bottom
    2, 6, 7, 2, 7, 3, -- top
}
local triangles = {}
for i = 1, #faces, 3 do
    local a, b, c = faces[i], faces[i + 1], faces[i + 2]
    triangles[#triangles + 1] = a
    triangles[#triangles + 1] = b
    triangles[#triangles + 1] = c
    triangles[#triangles + 1] = c
    triangles[#triangles + 1] = b
    triangles[#triangles + 1] = a
end

function Box.Draw(bounds, name, colour)
    if bounds == nil then return end
    -- Small margin to cover edges of the animated model without z-fighting.
    local padding = 16
    local x0, y0, z0 = bounds.minX - padding, bounds.minY - padding, bounds.minZ - padding
    local x1, y1, z1 = bounds.maxX + padding, bounds.maxY + padding, bounds.maxZ + padding
    ShapeList.Draw({
        shapePositions = {
            Vector3.new(x0, y0, z0), Vector3.new(x1, y0, z0),
            Vector3.new(x0, y1, z0), Vector3.new(x1, y1, z0),
            Vector3.new(x0, y0, z1), Vector3.new(x1, y0, z1),
            Vector3.new(x0, y1, z1), Vector3.new(x1, y1, z1),
        },
        shapeTris = triangles,
        colour = colour or colourForName(name),
        ignoreDepth = true,
    })
end

return Box
