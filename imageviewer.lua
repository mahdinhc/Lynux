-- imageviewer.lua
local ImageViewer = {}
ImageViewer.__index = ImageViewer

function ImageViewer.new(__filepath, fileNode)
    local self = setmetatable({}, ImageViewer)
    self.fileNode = fileNode
    self.image = nil
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    self.dragging = false
    self.lastX, self.lastY = 0, 0
    
	print(__filepath, fileNode)
    -- Try to load image from virtual filesystem path
    local success, err = pcall(function()
		filepath = "data/files/" .. __filepath 
        if filepath then
            self.image = love.graphics.newImage(filepath)
        else
            -- Fallback to virtual path
            local path = filesystem.getPath(fileNode):gsub("^/", "")
            self.image = love.graphics.newImage("data/" .. path)
        end
    end)
    
    if not success then
        self.error = "Failed to load image: " .. filepath
    end
    
    return self
end

function ImageViewer:update(dt)
    -- No continuous updates needed
end

function ImageViewer:draw(x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
        return
    end
    
    if self.image then
        local imgW, imgH = self.image:getDimensions()
        local scale = math.min(width/imgW, height/imgH) * self.scale
        
        local drawX = x + width/2 - (imgW * scale)/2 + self.offsetX
        local drawY = y + height/2 - (imgH * scale)/2 + self.offsetY
        
		love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.image, drawX, drawY, 0, scale, scale)
    end
end

function ImageViewer:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
        self.lastX, self.lastY = mx, my
    end
end

function ImageViewer:mousemoved(mx, my)
    if self.dragging then
        self.offsetX = self.offsetX + (mx - self.lastX)
        self.offsetY = self.offsetY + (my - self.lastY)
        self.lastX, self.lastY = mx, my
    end
end

function ImageViewer:mousereleased()
    self.dragging = false
end

function ImageViewer:wheelmoved(x, y)
    local zoomFactor = 1.1
    if y > 0 then
        self.scale = self.scale * zoomFactor
    elseif y < 0 then
        self.scale = self.scale / zoomFactor
    end
    
    -- Limit zoom
    self.scale = math.max(0.1, math.min(self.scale, 10))
end

function ImageViewer:keypressed(key)
    if key == "r" then  -- Reset view
        self.scale = 1.0
        self.offsetX = 0
        self.offsetY = 0
    end
end

return ImageViewer