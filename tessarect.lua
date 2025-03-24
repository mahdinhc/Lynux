-- TessarectApp.lua
local TessarectApp = {}
TessarectApp.__index = TessarectApp

-- Create a new TessarectApp instance.
function TessarectApp.new()
    local self = setmetatable({}, TessarectApp)
    self.angle = 0
    self.rotationSpeed = 0.5

    -- Create the 16 vertices of a tesseract: all combinations of -1 and 1.
    self.vertices = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                for w = -1, 1, 2 do
                    table.insert(self.vertices, {x = x, y = y, z = z, w = w})
                end
            end
        end
    end

    -- Generate edges: an edge exists if two vertices differ in exactly one coordinate.
    self.edges = {}
    local function differsByOne(v1, v2)
        local diff = 0
        if v1.x ~= v2.x then diff = diff + 1 end
        if v1.y ~= v2.y then diff = diff + 1 end
        if v1.z ~= v2.z then diff = diff + 1 end
        if v1.w ~= v2.w then diff = diff + 1 end
        return diff == 1
    end

    for i = 1, #self.vertices do
        for j = i + 1, #self.vertices do
            if differsByOne(self.vertices[i], self.vertices[j]) then
                table.insert(self.edges, {i, j})
            end
        end
    end

    self.transformed = {}
    return self
end

-- Rotate a 4D vector v in the plane defined by indices i and j (1=x, 2=y, 3=z, 4=w)
local function rotate4D(v, angle, i, j)
    local coords = {v.x, v.y, v.z, v.w}
    local a = coords[i]
    local b = coords[j]
    coords[i] = a * math.cos(angle) - b * math.sin(angle)
    coords[j] = a * math.sin(angle) + b * math.cos(angle)
    return {x = coords[1], y = coords[2], z = coords[3], w = coords[4]}
end

-- Update: rotate the tesseract over time.
function TessarectApp:update(dt)
    self.angle = self.angle + self.rotationSpeed * dt
    self.transformed = {}  -- Clear transformed vertices.
    for _, v in ipairs(self.vertices) do
        local vt = v
        vt = rotate4D(vt, self.angle, 1, 4)  -- rotate in x-w plane
        vt = rotate4D(vt, self.angle, 2, 4)  -- rotate in y-w plane
        table.insert(self.transformed, vt)
    end
end

-- Project a 4D point into 3D using perspective projection.
function TessarectApp:project4Dto3D(v)
    local distance = 3
    local factor = distance / (distance - v.w)
    return {x = v.x * factor, y = v.y * factor, z = v.z * factor}
end

-- Project a 3D point into 2D.
function TessarectApp:project3Dto2D(v)
    local distance = 3
    local factor = distance / (distance - v.z)
    return {x = v.x * factor, y = v.y * factor}
end

-- Draw the tesseract in the given window rectangle.
function TessarectApp:draw(x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, width, height)
    local projected = {}
    for i, v in ipairs(self.transformed) do
        local v3d = self:project4Dto3D(v)
        local v2d = self:project3Dto2D(v3d)
        local scale = math.min(width, height) / 4
        projected[i] = {
            x = x + width/2 + v2d.x * scale,
            y = y + height/2 + v2d.y * scale
        }
    end

    love.graphics.setColor(0, 1, 0)
    for _, edge in ipairs(self.edges) do
        local a = projected[edge[1]]
        local b = projected[edge[2]]
        if a and b then
            love.graphics.line(a.x, a.y, b.x, b.y)
        end
    end
end

return TessarectApp
