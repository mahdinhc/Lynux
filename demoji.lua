local Demoji = {}
Demoji.__index = Demoji

function Demoji.new()
    local self = setmetatable({}, Demoji)
    self.dialogue = "Hello! I'm Demoji, your guide.\nClick on an app to explore the desktop!"
    
    -- Load static image and scale to 80x80.
    self.image = love.graphics.newImage("assets/demoji.png")
    self.width = 80
    self.height = 80
    self.scaleX = self.width / self.image:getWidth()
    self.scaleY = self.height / self.image:getHeight()
    
    -- Initial position.
    self.x = 20
    self.y = love.graphics.getHeight() - self.height - 80

    -- Draggable state.
    self.visible = true
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    return self
end

function Demoji:update(dt)
    -- Static image: no animation.
end

function Demoji:draw()
    if not self.visible then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, self.scaleX, self.scaleY)
    
    -- Draw close button (20x20) at top-right of the image.
    local btnSize = 20
    local closeX = self.x + self.width - btnSize
    local closeY = self.y
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", closeX, closeY, btnSize, btnSize)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("X", closeX, closeY + 2, btnSize, "center")
    
    -- Draw dialogue box to the right of Demoji.
    local dialogueX = self.x + self.width + 10
    local dialogueY = self.y
    local dialogueWidth = 300
    local dialogueHeight = 60
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", dialogueX, dialogueY, dialogueWidth, dialogueHeight, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.dialogue, dialogueX + 10, dialogueY + 10, dialogueWidth - 20, "left")
end

function Demoji:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    -- Check close button region.
    local btnSize = 20
    local closeX = self.x + self.width - btnSize
    local closeY = self.y
    if x >= closeX and x <= closeX + btnSize and y >= closeY and y <= closeY + btnSize then
        self.visible = false
        return true
    end
    -- Define overall draggable region covering Demoji and its dialogue box.
    local regionX = self.x
    local regionY = self.y
    local regionWidth = self.width + 10 + 300
    local regionHeight = math.max(self.height, 60)
    if x >= regionX and x <= regionX + regionWidth and y >= regionY and y <= regionY + regionHeight then
        self.dragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end
    return false
end

function Demoji:mousemoved(x, y, dx, dy)
    if self.dragging then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
    end
end

function Demoji:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

return Demoji
