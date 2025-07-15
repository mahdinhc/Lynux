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
    -- draw window background
    -- love.graphics.setColor(0.1, 0.1, 0.1)
    -- love.graphics.rectangle("fill", x, y, width, height)

    -- draw error message if any
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
        return
    end

    -- self.scene.width  = width
    -- self.scene.height = height
	-- self.scene.resize()
	self.scene:render()
	-- self.scene:render(x, y, width, height)


    -- -- draw UI overlay (title bar, FPS, pause)
    -- love.graphics.setColor(0, 0, 0, 0.7)
    -- love.graphics.rectangle("fill", x, y, width, 30)
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.print("ObjViewer: " .. self.fileNode.name, x + 10, y + 8)
    -- love.graphics.print("FPS: " .. love.timer.getFPS(), x + width - 100, y + 8)
    -- if self.paused then
        -- love.graphics.setColor(1, 0, 0)
        -- love.graphics.print("PAUSED", x + width/2 - 30, y + 8)
    -- end
end


function ObjViewer:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
        self.lastX, self.lastY = mx, my
    end
end

function ObjViewer:mousemoved(mx, my, dx, dy)
    if self.dragging and not self.paused and self.scene then
        self.scene:mouseLook(mx, my, dx, dy) -- Rotate camera with mouse movement
    end
end

function ObjViewer:mousereleased()
    self.dragging = false
end

function ObjViewer:keypressed(key)
    if key == "space" then
        self.paused = not self.paused
    elseif key == "r" then
        -- Reset camera position
        self.scene.camera.pos = {x = 0, y = 0, z = 5}
        self.scene.camera.angle = {x = 0, y = 0, z = 0}
    end
    
    -- Camera movement
    -- if not self.paused and self.scene then
        -- if key == "w" then self.movingForward = true end
        -- if key == "s" then self.movingBack = true end
        -- if key == "a" then self.movingLeft = true end
        -- if key == "d" then self.movingRight = true end
    -- end
end

function ObjViewer:keyreleased(key)
    -- if key == "w" then self.movingForward = false end
    -- if key == "s" then self.movingBack = false end
    -- if key == "a" then self.movingLeft = false end
    -- if key == "d" then self.movingRight = false end
end

return ObjViewer