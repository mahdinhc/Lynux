-- texteditor.lua
local TextEditor = {}
TextEditor.__index = TextEditor

function TextEditor.new()
    local self = setmetatable({}, TextEditor)
    -- Starting content: one empty line.
    self.lines = {""}
    self.cursorX = 1  -- Position in current line (character index)
    self.cursorY = 1  -- Current line number
    self.font = love.graphics.newFont(14)
    self.blinkTimer = 0
    self.cursorVisible = true
    self.scrollOffset = 0
    self.lineHeight = self.font:getHeight()
    self.filename = "untitled.txt"
    -- We'll store the last drawn editor height (set during draw) for scrolling calculations.
    self.editorHeight = 300
    return self
end

function TextEditor:update(dt)
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= 0.5 then
        self.cursorVisible = not self.cursorVisible
        self.blinkTimer = self.blinkTimer - 0.5
    end
end

function TextEditor:draw(x, y, width, height)
    -- Save the editor height for use in wheelmoved.
    self.editorHeight = height

    -- Draw background and border.
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", x, y, width, height)

    -- Set scissor so text doesn't draw outside the editor.
    love.graphics.setScissor(x, y, width, height)
    local currentY = y - self.scrollOffset

	love.graphics.setFont(self.font)
    -- Draw each line.
    for i, line in ipairs(self.lines) do
        love.graphics.print(line, x + 5, currentY)
        currentY = currentY + self.lineHeight
    end

    -- Draw blinking cursor.
    if self.cursorVisible then
        local lineText = self.lines[self.cursorY] or ""
        local cx = x + 5 + self.font:getWidth(lineText:sub(1, self.cursorX - 1))
        local cy = y + (self.cursorY - 1) * self.lineHeight - self.scrollOffset
        love.graphics.line(cx, cy, cx, cy + self.lineHeight)
    end
    love.graphics.setScissor()

    -- Draw vertical scrollbar if needed.
    local totalLines = #self.lines
    local totalHeight = totalLines * self.lineHeight
    if totalHeight > height then
        local thumbHeight = (height / totalHeight) * height
        local maxScroll = totalHeight - height
        local thumbY = y + (self.scrollOffset / maxScroll) * (height - thumbHeight)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", x + width - 10, thumbY, 5, thumbHeight)
    end
end

function TextEditor:textinput(t)
    local line = self.lines[self.cursorY] or ""
    local before = line:sub(1, self.cursorX - 1)
    local after = line:sub(self.cursorX)
    self.lines[self.cursorY] = before .. t .. after
    self.cursorX = self.cursorX + #t
end

function TextEditor:keypressed(key)
    if key == "backspace" then
        if self.cursorX > 1 then
            local line = self.lines[self.cursorY]
            self.lines[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            local currentLine = self.lines[self.cursorY]
            self.cursorX = #self.lines[self.cursorY - 1] + 1
            self.lines[self.cursorY - 1] = self.lines[self.cursorY - 1] .. currentLine
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
        end
    elseif key == "return" then
        local line = self.lines[self.cursorY]
        local before = line:sub(1, self.cursorX - 1)
        local after = line:sub(self.cursorX)
        self.lines[self.cursorY] = before
        table.insert(self.lines, self.cursorY + 1, after)
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
    elseif key == "left" then
        if self.cursorX > 1 then
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = #self.lines[self.cursorY] + 1
        end
    elseif key == "right" then
        local line = self.lines[self.cursorY]
        if self.cursorX <= #line then
            self.cursorX = self.cursorX + 1
        elseif self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
        end
    elseif key == "up" then
        if self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            local line = self.lines[self.cursorY]
            self.cursorX = math.min(self.cursorX, #line + 1)
            -- Adjust scroll: if new cursorY is above visible area, update scrollOffset.
            local topVisible = math.floor(self.scrollOffset / self.lineHeight) + 1
            if self.cursorY < topVisible then
                self.scrollOffset = (self.cursorY - 1) * self.lineHeight
            end
        end
    elseif key == "down" then
        if self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            local line = self.lines[self.cursorY]
            self.cursorX = math.min(self.cursorX, #line + 1)
            -- Adjust scroll: if new cursorY is below visible area, update scrollOffset.
            local visibleLines = math.floor(self.editorHeight / self.lineHeight)
            if self.cursorY > (math.floor(self.scrollOffset / self.lineHeight) + visibleLines) then
                self.scrollOffset = (self.cursorY - visibleLines) * self.lineHeight
            end
        end
    end
end

function TextEditor:wheelmoved(x, y)
    local totalHeight = #self.lines * self.lineHeight
    local visibleHeight = self.editorHeight
    local maxScroll = math.max(totalHeight - visibleHeight, 0)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset - y * 20, maxScroll))
end

return TextEditor
