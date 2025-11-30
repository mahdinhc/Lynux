-- TessarectApp.lua - HYPER-ENHANCED 4D VISUALIZATION MASTERPIECE
local TessarectApp = {}
TessarectApp.__index = TessarectApp

function TessarectApp.new()
    local self = setmetatable({}, TessarectApp)
    
    -- Enhanced visualization parameters
    self.angle = 0
    self.rotationSpeed = 0.3
    self.time = 0
    
    -- Multiple rotation planes for complex motion
    self.rotations = {
        {plane1 = 1, plane2 = 4, speed = 0.3, enabled = true},
        {plane1 = 2, plane3 = 4, speed = 0.2, enabled = true},
        {plane1 = 3, plane2 = 4, speed = 0.4, enabled = true},
        {plane1 = 1, plane2 = 2, speed = 0.25, enabled = false},
        {plane1 = 1, plane2 = 3, speed = 0.35, enabled = false}
    }
    
    -- Color schemes
    self.colorSchemes = {
        neon = {
            edge = {0, 1, 0.5, 1},
            vertex = {0.8, 0.2, 1, 1},
            highlight = {1, 1, 0, 1}
        },
        fire = {
            edge = {1, 0.3, 0, 1},
            vertex = {1, 0.8, 0, 1},
            highlight = {1, 1, 1, 1}
        },
        ice = {
            edge = {0, 0.8, 1, 1},
            vertex = {0.6, 0.9, 1, 1},
            highlight = {1, 1, 1, 1}
        },
        matrix = {
            edge = {0, 1, 0, 1},
            vertex = {0, 0.7, 0, 1},
            highlight = {1, 1, 1, 1}
        }
    }
    self.currentScheme = "matrix"
    
    -- Visualization modes
    self.modes = {"wireframe", "solid", "particles"}
    self.currentMode = "wireframe"
    
    -- Enhanced vertex system with additional properties
    self.vertices = {}
    local vertexCount = 0
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                for w = -1, 1, 2 do
                    vertexCount = vertexCount + 1
                    table.insert(self.vertices, {
                        x = x, y = y, z = z, w = w,
                        original = {x = x, y = y, z = z, w = w},
                        id = vertexCount,
                        size = 4,
                        pulsePhase = math.random() * math.pi * 2
                    })
                end
            end
        end
    end

    -- Enhanced edge system with depth and groups
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
            if differsByOne(self.vertices[i].original, self.vertices[j].original) then
                table.insert(self.edges, {
                    v1 = i, v2 = j,
                    originalLength = math.sqrt(
                        (self.vertices[i].x - self.vertices[j].x)^2 +
                        (self.vertices[i].y - self.vertices[j].y)^2 +
                        (self.vertices[i].z - self.vertices[j].z)^2 +
                        (self.vertices[i].w - self.vertices[j].w)^2
                    ),
                    group = math.random(1, 4), -- For animation effects
                    pulsePhase = math.random() * math.pi * 2
                })
            end
        end
    end

    -- Particle system for enhanced visualization
    self.particles = {}
    self.particleTimer = 0
    
    -- Camera and projection controls
    self.camera = {
        distance = 5,
        fov = 2,
        projectionType = "perspective", -- "perspective" or "orthographic"
        autoRotate = true
    }
    
    -- User interaction state
    self.mouse = {
        x = 0, y = 0,
        dragging = false,
        lastX = 0, lastY = 0
    }
    
    -- Animation states
    self.animations = {
        pulse = 0,
        morph = 0,
        twist = 0
    }
    
    -- UI state
    self.showUI = true
    self.showAxes = true
    
    self.transformed = {}
    return self
end

-- Enhanced 4D rotation with multiple planes
local function rotate4D(v, angle, plane1, plane2)
    local coords = {v.x, v.y, v.z, v.w}
    local a = coords[plane1]
    local b = coords[plane2]
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    coords[plane1] = a * cos - b * sin
    coords[plane2] = a * sin + b * cos
    return {x = coords[1], y = coords[2], z = coords[3], w = coords[4]}
end

-- Advanced projection system
function TessarectApp:project4Dto3D(v)
    if self.camera.projectionType == "orthographic" then
        return {x = v.x, y = v.y, z = v.z, w = v.w}
    else
        local distance = self.camera.distance
        local factor = distance / (distance - v.w * self.camera.fov)
        return {
            x = v.x * factor,
            y = v.y * factor, 
            z = v.z * factor,
            w = v.w
        }
    end
end

function TessarectApp:project3Dto2D(v)
    local distance = 3
    local factor = distance / (distance - v.z * 0.5)
    return {
        x = v.x * factor,
        y = v.y * factor,
        z = v.z,
        depth = v.z + v.w * 0.3  -- Combined depth for sorting
    }
end

-- Enhanced update with multiple animations
function TessarectApp:update(dt)
    self.time = self.time + dt
    self.angle = self.angle + self.rotationSpeed * dt
    
    -- Update animations
    self.animations.pulse = math.sin(self.time * 2) * 0.5 + 0.5
    self.animations.morph = math.sin(self.time * 0.7) * 0.3
    self.animations.twist = math.sin(self.time * 1.3) * 0.5
    
    -- Apply multiple rotations
    self.transformed = {}
    for i, vertex in ipairs(self.vertices) do
        local vt = {x = vertex.x, y = vertex.y, z = vertex.z, w = vertex.w}
        
        -- Apply morphing animation
        vt.x = vt.x + math.sin(self.time + i * 0.1) * self.animations.morph * 0.1
        vt.y = vt.y + math.cos(self.time + i * 0.2) * self.animations.morph * 0.1
        
        -- Apply multiple rotation planes
        for _, rotation in ipairs(self.rotations) do
            if rotation.enabled then
                vt = rotate4D(vt, self.angle * rotation.speed, rotation.plane1, rotation.plane2 or rotation.plane1 + 1)
            end
        end
        
        -- Apply twist animation
        local twistAngle = self.animations.twist * (vt.w + 1) * 0.5
        vt = rotate4D(vt, twistAngle, 1, 3)
        
        table.insert(self.transformed, vt)
    end
    
    -- Update particles
    self.particleTimer = self.particleTimer + dt
    if self.particleTimer > 0.05 and self.currentMode == "particles" then
        self.particleTimer = 0
        for i = 1, 3 do
            local edge = self.edges[math.random(1, #self.edges)]
            local progress = math.random()
            table.insert(self.particles, {
                x = 0, y = 0, z = 0,
                life = 2,
                maxLife = 2,
                size = math.random(2, 5),
                speed = math.random(10, 30),
                edge = edge,
                progress = progress,
                direction = math.random() > 0.5 and 1 or -1
            })
        end
    end
    
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        p.progress = p.progress + (p.direction * p.speed * dt / p.edge.originalLength)
        
        if p.life <= 0 or p.progress < 0 or p.progress > 1 then
            table.remove(self.particles, i)
        end
    end
end

-- Enhanced drawing with multiple visualization modes
function TessarectApp:draw(x, y, width, height)
    
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    
    local projected = {}
    for i, v in ipairs(self.transformed) do
        local v3d = self:project4Dto3D(v)
        local v2d = self:project3Dto2D(v3d)
        local scale = math.min(width, height) / 6
        projected[i] = {
            x = x + width/2 + v2d.x * scale,
            y = y + height/2 + v2d.y * scale,
            depth = v2d.depth,
            original = self.vertices[i]
        }
    end
    
    -- Sort edges by depth for proper rendering
    local sortedEdges = {}
    for i, edge in ipairs(self.edges) do
        local depth = (projected[edge.v1].depth + projected[edge.v2].depth) * 0.5
        table.insert(sortedEdges, {edge = edge, depth = depth})
    end
    
    table.sort(sortedEdges, function(a, b) return a.depth < b.depth end)
    
    local scheme = self.colorSchemes[self.currentScheme]
    
    -- Draw edges based on current mode
    if self.currentMode == "wireframe" then
        for _, sortedEdge in ipairs(sortedEdges) do
            local edge = sortedEdge.edge
            local a = projected[edge.v1]
            local b = projected[edge.v2]
            
            if a and b then
                local pulse = math.sin(self.time * 3 + edge.pulsePhase) * 0.3 + 0.7
                local alpha = 0.3 + pulse * 0.7
                
                love.graphics.setColor(scheme.edge[1], scheme.edge[2], scheme.edge[3], alpha)
                love.graphics.setLineWidth(1 + pulse * 0.5)
                love.graphics.line(a.x, a.y, b.x, b.y)
            end
        end
    end
    
    -- Draw particles
    if self.currentMode == "particles" then
        for _, particle in ipairs(self.particles) do
            local a = projected[particle.edge.v1]
            local b = projected[particle.edge.v2]
            
            if a and b then
                local px = a.x + (b.x - a.x) * particle.progress
                local py = a.y + (b.y - a.y) * particle.progress
                local alpha = particle.life / particle.maxLife
                
                love.graphics.setColor(scheme.highlight[1], scheme.highlight[2], scheme.highlight[3], alpha)
                love.graphics.circle("fill", px, py, particle.size * alpha)
            end
        end
    end
    
    -- Draw vertices
    for i, proj in ipairs(projected) do
        local pulse = math.sin(self.time * 2 + proj.original.pulsePhase) * 0.5 + 1
        local size = proj.original.size * pulse * self.animations.pulse
        
        love.graphics.setColor(scheme.vertex[1], scheme.vertex[2], scheme.vertex[3], 0.8)
        love.graphics.circle("fill", proj.x, proj.y, size)
        
        love.graphics.setColor(scheme.highlight[1], scheme.highlight[2], scheme.highlight[3], 0.9)
        love.graphics.circle("fill", proj.x, proj.y, size * 0.3)
    end

    
    -- Draw coordinate axes
    if self.showAxes then
        self:drawAxes(x, y, width, height)
    end
    
    -- Draw UI
    if self.showUI then
        self:drawUI(x, y, width, height)
    end
end

-- Draw coordinate axes for reference
function TessarectApp:drawAxes(x, y, width, height)
    local centerX = x + width/2
    local centerY = y + height/2
    local axisLength = math.min(width, height) / 4
    
    love.graphics.setLineWidth(1)
    
    -- X axis (red)
    love.graphics.setColor(1, 0, 0, 0.6)
    love.graphics.line(centerX, centerY, centerX + axisLength, centerY)
    love.graphics.print("X", centerX + axisLength + 5, centerY - 10)
    
    -- Y axis (green)
    love.graphics.setColor(0, 1, 0, 0.6)
    love.graphics.line(centerX, centerY, centerX, centerY - axisLength)
    love.graphics.print("Y", centerX + 5, centerY - axisLength - 15)
    
    -- Z axis (blue) - simulated perspective
    love.graphics.setColor(0, 0.5, 1, 0.6)
    love.graphics.line(centerX, centerY, centerX + axisLength * 0.7, centerY + axisLength * 0.7)
    love.graphics.print("Z", centerX + axisLength * 0.7 + 5, centerY + axisLength * 0.7 + 5)
    
    love.graphics.setLineWidth(1)
end

-- Enhanced UI with controls
function TessarectApp:drawUI(x, y, width, height)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x + 10, y + 10, 250, 180)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("4D TESSERACT VISUALIZER", x + 20, y + 20)
    love.graphics.print("Mode: " .. self.currentMode, x + 20, y + 40)
    love.graphics.print("Scheme: " .. self.currentScheme, x + 20, y + 60)
    love.graphics.print("Speed: " .. string.format("%.2f", self.rotationSpeed), x + 20, y + 80)
    love.graphics.print("Projection: " .. self.camera.projectionType, x + 20, y + 100)
    love.graphics.print("Active Rotations: " .. self:countActiveRotations(), x + 20, y + 120)
    
    love.graphics.print("Controls:", x + 20, y + 140)
    love.graphics.print("M - Mode | C - Scheme | R - Reset", x + 20, y + 155)
    love.graphics.print("P - Projection | SPACE - Auto Rotate", x + 20, y + 170)
end

function TessarectApp:countActiveRotations()
    local count = 0
    for _, rotation in ipairs(self.rotations) do
        if rotation.enabled then count = count + 1 end
    end
    return count
end

-- Input handlers for interactive control
function TessarectApp:mousepressed(mx, my, button)
    if button == 1 then
        self.mouse.dragging = true
        self.mouse.lastX = mx
        self.mouse.lastY = my
    end
end

function TessarectApp:mousemoved(mx, my)
    if self.mouse.dragging then
        local dx = mx - self.mouse.lastX
        local dy = my - self.mouse.lastY
        
        -- Rotate based on mouse movement
        for _, rotation in ipairs(self.rotations) do
            if rotation.enabled then
                rotation.speed = rotation.speed + dx * 0.001
            end
        end
        
        self.camera.fov = math.max(0.5, math.min(3, self.camera.fov + dy * 0.01))
        
        self.mouse.lastX = mx
        self.mouse.lastY = my
    end
end

function TessarectApp:mousereleased()
    self.mouse.dragging = false
end

function TessarectApp:keypressed(key)
    if key == "m" then
        local currentIndex = 1
        for i, mode in ipairs(self.modes) do
            if mode == self.currentMode then
                currentIndex = i
                break
            end
        end
        self.currentMode = self.modes[(currentIndex % #self.modes) + 1]
        
    elseif key == "c" then
        local schemes = {"neon", "fire", "ice", "matrix"}
        local currentIndex = 1
        for i, scheme in ipairs(schemes) do
            if scheme == self.currentScheme then
                currentIndex = i
                break
            end
        end
        self.currentScheme = schemes[(currentIndex % #schemes) + 1]
        
    elseif key == "r" then
        -- Reset to initial state
        self.rotationSpeed = 0.3
        self.camera.fov = 2
        for _, rotation in ipairs(self.rotations) do
            rotation.speed = rotation.speed > 0 and 0.3 or -0.3
        end
        
    elseif key == "p" then
        self.camera.projectionType = self.camera.projectionType == "perspective" and "orthographic" or "perspective"
        
    elseif key == "space" then
        self.camera.autoRotate = not self.camera.autoRotate
        if self.camera.autoRotate then
            self.rotationSpeed = math.abs(self.rotationSpeed)
        end
        
    elseif key == "u" then
        self.showUI = not self.showUI
    elseif key == "a" then
        self.showAxes = not self.showAxes
    end
end

function TessarectApp:wheelmoved(x, y)
    self.rotationSpeed = self.rotationSpeed + y * 0.1
    self.rotationSpeed = math.max(-2, math.min(2, self.rotationSpeed))
end

return TessarectApp