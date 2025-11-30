-- objviewer.lua
local ObjViewer = {}
ObjViewer.__index = ObjViewer

function ObjViewer.new(__filepath, fileNode)
    local self = setmetatable({}, ObjViewer)
    self.fileNode = fileNode
    self.engine = nil
    self.scene = nil
    self.models = {}
    self.timer = 0
    self.paused = false
    self.error = nil
    self.dragging = false
    self.lastX, self.lastY = 0, 0
    
    -- Try to load the OBJ file
    local success, err = pcall(function()
        local path = "data/files/" .. __filepath
        self.engine = require("ss3d")
        self.scene = self.engine.newScene(800, 600)  -- Initial size, will be updated in draw

        local modelData = self.engine.loadObj(path)
        local texture = love.graphics.newImage("assets/texture.png")  -- Default texture

        local model = self.engine.newModel(modelData, texture)
        self.scene:addModel(model)
        table.insert(self.models, model)

        self.scene.camera.pos.z = 5
    end)
    
    if not success then
        self.error = "Failed to load model: " .. tostring(err)
		print(err)
    end
    
    return self
end

function ObjViewer:update(dt)
    if self.paused or not self.scene or self.error then return end
    
    self.timer = self.timer + dt/4
    
    -- Rotate the main model
    if self.models[1] then
        self.models[1]:setTransform(
            {0, -1.5, 0}, 
            {self.timer, cpml.vec3.unit_y, self.timer, cpml.vec3.unit_z, self.timer, cpml.vec3.unit_x}
        )
    end
end

function ObjViewer:draw(x, y, width, height)
    -- Store window dimensions for input handling
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
	
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw error message if any
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
        return
    end

    if not self.scene then return end

    -- Update scene dimensions to match window
    self.scene.width = width
    self.scene.height = height
    
    -- Set scissor to constrain rendering to window bounds
    love.graphics.setScissor(x, y, width, height)
    
    -- Render the scene
    self.scene:render()
    
    -- Reset scissor
    love.graphics.setScissor()

    -- Draw UI overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, width, 25)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ObjViewer: " .. self.fileNode.name, x + 10, y + 5)
    love.graphics.print("FPS: " .. love.timer.getFPS(), x + width - 80, y + 5)
    
    if self.paused then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("PAUSED", x + width/2 - 25, y + 5)
    end
    
    -- Draw controls hint
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y + height - 40, width, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Controls: Drag to rotate • Space: Pause • R: Reset", x + 10, y + height - 30)
end

function ObjViewer:mousepressed(mx, my, button, wx, wy)
    -- Convert to window-relative coordinates
    local relX, relY = mx - self.windowX, my - self.windowY
    
    -- Only handle dragging if click is within the 3D view area (excluding UI bars)
    if button == 1 and relY > 25 and relY < self.windowHeight - 40 then
        self.dragging = true
        self.lastX, self.lastY = mx, my
        return true  -- Consume the event
    end
    return false
end

function ObjViewer:mousemoved(mx, my, dx, dy, wx, wy)
    if self.dragging and not self.paused and self.scene then
        -- Calculate relative movement
        local relDx = mx - self.lastX
        local relDy = my - self.lastY
        
        self.scene:mouseLook(mx, my, relDx, relDy) -- Rotate camera with mouse movement
        
        self.lastX, self.lastY = mx, my
        return true  -- Consume the event
    end
    return false
end

function ObjViewer:mousereleased(mx, my, button, wx, wy)
    if button == 1 then
        self.dragging = false
        return true  -- Consume the event
    end
    return false
end

function ObjViewer:keypressed(key)
    if key == "space" then
        self.paused = not self.paused
        return true
    elseif key == "r" and self.scene then
        -- Reset camera position
        self.scene.camera.pos = {x = 0, y = 0, z = 5}
        self.scene.camera.angle = {x = 0, y = 0, z = 0}
        return true
    end
    return false
end

function ObjViewer:keyreleased(key)
    -- Handle key releases if needed
    return false
end

function ObjViewer:resize(w, h)
    -- Handle window resize if needed
    if self.scene then
        self.scene.width = self.windowWidth
        self.scene.height = self.windowHeight
    end
end

return ObjViewer