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
    self.minScale = 0.1
    self.maxScale = 10.0
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, 0, 0
    self.uiHeight = 30
    self.controlsHeight = 40
    self.showInfo = true
    self.smoothZoom = true
    self.targetScale = 1.0
    self.zoomSpeed = 0.5
    
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
        self.error = "Failed to load image: " .. tostring(__filepath)
        print("Image loading error:", err)
    else
        -- Initialize scale to fit window
        self:resetView()
    end
    
    return self
end

function ImageViewer:update(dt)
    -- Smooth zoom animation
    if self.smoothZoom and math.abs(self.scale - self.targetScale) > 0.001 then
        self.scale = self.scale + (self.targetScale - self.scale) * self.zoomSpeed * 10 * dt
        -- Apply bounds
        self.scale = math.max(self.minScale, math.min(self.scale, self.maxScale))
    end
end

function ImageViewer:draw(x, y, width, height)
    -- Store window dimensions for calculations
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
    
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    if self.error then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
        return
    end
    
    if not self.image then return end
    
    local imgW, imgH = self.image:getDimensions()
    local viewWidth = width
    local viewHeight = height
    
    -- Adjust view area for UI
    if self.showInfo then
        viewHeight = viewHeight - self.uiHeight - self.controlsHeight
    end
    
    -- Calculate scale and position
    local drawW = imgW * self.scale
    local drawH = imgH * self.scale
    
    -- Calculate center position
    local centerX = x + viewWidth/2
    local centerY = y + viewHeight/2 + (self.showInfo and self.uiHeight or 0)
    
    local drawX = centerX - drawW/2 + self.offsetX
    local drawY = centerY - drawH/2 + self.offsetY
    
    -- Apply bounds checking to prevent excessive dragging
    self:applyDragBounds(drawX, drawY, drawW, drawH, viewWidth, viewHeight)
    
    -- Set scissor for image area only
    local imageAreaY = y + (self.showInfo and self.uiHeight or 0)
    love.graphics.setScissor(x, imageAreaY, viewWidth, viewHeight)
    
    -- Draw image with border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", drawX - 1, drawY - 1, drawW + 2, drawH + 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, drawX, drawY, 0, self.scale, self.scale)
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw UI overlay
    if self.showInfo then
        self:drawUI(x, y, width, height, imgW, imgH)
    end
end

function ImageViewer:applyDragBounds(drawX, drawY, drawW, drawH, viewWidth, viewHeight)
    local viewX = self.windowX
    local viewY = self.windowY + (self.showInfo and self.uiHeight or 0)
    
    -- Calculate maximum allowed offsets
    local maxOffsetX = 0
    local maxOffsetY = 0
    local minOffsetX = 0
    local minOffsetY = 0
    
    if drawW > viewWidth then
        -- Image is wider than view - can drag horizontally
        maxOffsetX = (drawW - viewWidth) / 2
        minOffsetX = -maxOffsetX
    else
        -- Image fits in view - center it
        self.offsetX = 0
    end
    
    if drawH > viewHeight then
        -- Image is taller than view - can drag vertically
        maxOffsetY = (drawH - viewHeight) / 2
        minOffsetY = -maxOffsetY
    else
        -- Image fits in view - center it
        self.offsetY = 0
    end
    
    -- Apply bounds
    self.offsetX = math.max(minOffsetX, math.min(self.offsetX, maxOffsetX))
    self.offsetY = math.max(minOffsetY, math.min(self.offsetY, maxOffsetY))
end

function ImageViewer:drawUI(x, y, width, height, imgW, imgH)
    -- Top info bar
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, width, self.uiHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.fileNode.name, x + 10, y + 8)
    love.graphics.print(string.format("%dx%d | Zoom: %.1fx", imgW, imgH, self.scale), x + width - 200, y + 8)
    
    -- Bottom controls bar
    local controlsY = y + height - self.controlsHeight
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, controlsY, width, self.controlsHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Drag: Move | Wheel: Zoom | R: Reset | F: Fit | 1:1 | I: Toggle Info", x + 10, controlsY + 12)
    
    -- Zoom level indicator
    local zoomBarWidth = 100
    local zoomBarX = x + width - zoomBarWidth - 10
    local zoomBarY = controlsY + 10
    local zoomBarHeight = 20
    
    -- Zoom bar background
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", zoomBarX, zoomBarY, zoomBarWidth, zoomBarHeight)
    
    -- Zoom level indicator
    local zoomRatio = (self.scale - self.minScale) / (self.maxScale - self.minScale)
    local indicatorWidth = 10
    local indicatorX = zoomBarX + (zoomRatio * (zoomBarWidth - indicatorWidth))
    love.graphics.setColor(0.2, 0.6, 1.0)
    love.graphics.rectangle("fill", indicatorX, zoomBarY, indicatorWidth, zoomBarHeight)
    
    -- Zoom bar border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", zoomBarX, zoomBarY, zoomBarWidth, zoomBarHeight)
end

function ImageViewer:mousepressed(mx, my, button, wx, wy)
    -- Convert to window-relative coordinates
    local relX, relY = mx - self.windowX, my - self.windowY
    
    -- Only handle dragging in the image area (not in UI bars)
    local imageAreaY = self.windowY + (self.showInfo and self.uiHeight or 0)
    local imageAreaHeight = self.windowHeight - (self.showInfo and (self.uiHeight + self.controlsHeight) or 0)
    
    if button == 1 and relY >= (self.showInfo and self.uiHeight or 0) and relY <= imageAreaHeight then
        self.dragging = true
        self.lastX, self.lastY = mx, my
        return true  -- Consume the event
    end
    
    return false
end

function ImageViewer:mousemoved(mx, my, dx, dy, wx, wy)
    if self.dragging then
        self.offsetX = self.offsetX + (mx - self.lastX)
        self.offsetY = self.offsetY + (my - self.lastY)
        self.lastX, self.lastY = mx, my
        return true  -- Consume the event
    end
    return false
end

function ImageViewer:mousereleased(mx, my, button, wx, wy)
    if button == 1 then
        self.dragging = false
        return true  -- Consume the event
    end
    return false
end

function ImageViewer:wheelmoved(x, y)
    if self.image then
        local oldScale = self.scale
        local zoomFactor = 1.2
        
        if y > 0 then
            -- Zoom in
            self.targetScale = self.scale * zoomFactor
        elseif y < 0 then
            -- Zoom out
            self.targetScale = self.scale / zoomFactor
        end
        
        -- Apply bounds
        self.targetScale = math.max(self.minScale, math.min(self.targetScale, self.maxScale))
        
        if not self.smoothZoom then
            self.scale = self.targetScale
        end
        
        return true  -- Consume the event
    end
    return false
end

function ImageViewer:resetView()
    if not self.image then return end
    
    local imgW, imgH = self.image:getDimensions()
    local viewWidth = self.windowWidth
    local viewHeight = self.windowHeight - (self.showInfo and (self.uiHeight + self.controlsHeight) or 0)
    
    -- Calculate scale to fit image in window
    local scaleX = viewWidth / imgW
    local scaleY = viewHeight / imgH
    self.scale = math.min(scaleX, scaleY)
    self.targetScale = self.scale
    
    self.offsetX = 0
    self.offsetY = 0
end

function ImageViewer:setActualSize()
    if self.image then
        self.scale = 1.0
        self.targetScale = 1.0
        self.offsetX = 0
        self.offsetY = 0
    end
end

function ImageViewer:keypressed(key)
    if key == "r" then  -- Reset view to fit window
        self:resetView()
        return true
    elseif key == "f" then  -- Fit to window
        self:resetView()
        return true
    elseif key == "1" then  -- Actual size (100%)
        self:setActualSize()
        return true
    elseif key == "i" then  -- Toggle info overlay
        self.showInfo = not self.showInfo
        -- Adjust view when toggling UI
        if self.showInfo then
            self:resetView()
        end
        return true
    elseif key == "=" or key == "+" then  -- Zoom in
        self.targetScale = math.min(self.scale * 1.2, self.maxScale)
        if not self.smoothZoom then
            self.scale = self.targetScale
        end
        return true
    elseif key == "-" then  -- Zoom out
        self.targetScale = math.max(self.scale / 1.2, self.minScale)
        if not self.smoothZoom then
            self.scale = self.targetScale
        end
        return true
    elseif key == "0" then  -- Reset zoom to 100% but keep position
        self.scale = 1.0
        self.targetScale = 1.0
        return true
    end
    
    return false
end

function ImageViewer:resize(w, h)
    -- Recalculate view when window is resized
    self:resetView()
end

return ImageViewer