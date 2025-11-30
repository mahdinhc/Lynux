-- texteditor.lua
local filesystem = require("filesystem")

local TextEditor = {}
TextEditor.__index = TextEditor

function TextEditor.new(filename, fileNode)
    print(filename, fileNode)
    local self = setmetatable({}, TextEditor)
    self.lines = {""}               -- Starting content: one empty line.
    self.cursorX = 1                -- Position in current line (character index)
    self.cursorY = 1                -- Current line number
    self.font = love.graphics.newFont("font/consola.ttf", 12)
    self.blinkTimer = 0
    self.cursorVisible = true
    self.scrollOffsetY = 0
    self.scrollOffsetX = 0
    self.lineHeight = self.font:getHeight()
    self.charWidth = self.font:getWidth(" ")
    self.filename = filename or "untitled.txt"
    self.fileNode = fileNode or nil -- Reference to the file node in the file system.
    self.editorHeight = 300         -- For scrolling calculations.
    self.editorWidth = 500          -- For horizontal scrolling.
    self.dirty = false              -- Tracks if there are unsaved changes.
    self.lineNumbers = true         -- Show line numbers
    self.lineNumberWidth = 40       -- Width for line numbers area
    self.selection = {startX = nil, startY = nil, endX = nil, endY = nil}
    self.selecting = false
    self.tabSize = 4                -- Tab width in spaces
    self.undoStack = {}             -- Undo history
    self.redoStack = {}             -- Redo history
    self.maxUndoSteps = 100
    self.wordWrap = false           -- Word wrap mode
    self.showWhitespace = false     -- Show whitespace characters
    
    -- Load file content if fileNode exists
    if fileNode and fileNode.content then
        self:loadContent(fileNode.content)
        self.dirty = false
    end
    
    -- Save initial state for undo
    self:saveState()
    
    return self
end

function TextEditor:loadContent(content)
    self.lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(self.lines, line)
    end
    if #self.lines == 0 then
        self.lines = {""}
    end
    self.cursorX = 1
    self.cursorY = 1
end

function TextEditor:saveState()
    -- Save current state to undo stack
    local state = {
        lines = {},
        cursorX = self.cursorX,
        cursorY = self.cursorY
    }
    
    for i, line in ipairs(self.lines) do
        state.lines[i] = line
    end
    
    table.insert(self.undoStack, state)
    
    -- Limit undo stack size
    if #self.undoStack > self.maxUndoSteps then
        table.remove(self.undoStack, 1)
    end
    
    -- Clear redo stack when new change is made
    self.redoStack = {}
end

function TextEditor:undo()
    if #self.undoStack > 1 then
        -- Save current state to redo stack
        local currentState = table.remove(self.undoStack)
        table.insert(self.redoStack, currentState)
        
        -- Restore previous state
        local prevState = self.undoStack[#self.undoStack]
        self.lines = {}
        for i, line in ipairs(prevState.lines) do
            self.lines[i] = line
        end
        self.cursorX = prevState.cursorX
        self.cursorY = prevState.cursorY
        
        self.dirty = true
        return true
    end
    return false
end

function TextEditor:redo()
    if #self.redoStack > 0 then
        local state = table.remove(self.redoStack)
        table.insert(self.undoStack, state)
        
        self.lines = {}
        for i, line in ipairs(state.lines) do
            self.lines[i] = line
        end
        self.cursorX = state.cursorX
        self.cursorY = state.cursorY
        
        self.dirty = true
        return true
    end
    return false
end

function TextEditor:update(dt)
    self.blinkTimer = self.blinkTimer + dt
    if self.blinkTimer >= 0.5 then
        self.cursorVisible = not self.cursorVisible
        self.blinkTimer = self.blinkTimer - 0.5
    end
end

function TextEditor:draw(x, y, width, height)
    self.editorHeight = height
    self.editorWidth = width
    
    -- Draw editor background and border.
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", x, y, width, height)

    -- Draw header bar with file info.
    local headerHeight = 25
    local filePath = self.fileNode and filesystem.getPath(self.fileNode) or self.filename
    if self.dirty then
        love.graphics.setColor(1, 0.3, 0.3)  -- Red if unsaved.
    else
        love.graphics.setColor(0.2, 0.5, 0.8)  -- Blue if saved.
    end
    love.graphics.rectangle("fill", x, y, width, headerHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(filePath .. (self.dirty and " •" or ""), x + 5, y + 5, width - 10, "left")
    
    -- Draw info in header
    love.graphics.setColor(1, 1, 1, 0.8)
    local infoText = string.format("Line: %d, Col: %d | %d lines", self.cursorY, self.cursorX, #self.lines)
    love.graphics.printf(infoText, x, y + 5, width - 10, "right")
    
    -- Calculate text area
    local textAreaX = x + (self.lineNumbers and self.lineNumberWidth or 0)
    local textAreaY = y + headerHeight
    local textAreaWidth = width - (self.lineNumbers and self.lineNumberWidth + 5 or 0)
    local textAreaHeight = height - headerHeight
    
    -- Draw line numbers background
    if self.lineNumbers then
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.rectangle("fill", x, textAreaY, self.lineNumberWidth, textAreaHeight)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.line(x + self.lineNumberWidth, textAreaY, x + self.lineNumberWidth, textAreaY + textAreaHeight)
    end
    
    -- Set scissor to restrict drawing to the text area.
    love.graphics.setScissor(textAreaX, textAreaY, textAreaWidth, textAreaHeight)
    
    -- Draw selection highlight
    self:drawSelection(textAreaX, textAreaY)
    
    -- Draw text content
    love.graphics.setFont(self.font)
    local currentY = textAreaY - self.scrollOffsetY
    
    for i, line in ipairs(self.lines) do
        -- Draw line number
        if self.lineNumbers then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf(tostring(i), x + 5, currentY, self.lineNumberWidth - 10, "right")
        end
        
        -- Draw text line
        local displayLine = self.showWhitespace and self:visualizeWhitespace(line) or line
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(displayLine, textAreaX + 5 - self.scrollOffsetX, currentY)
        
        currentY = currentY + self.lineHeight
    end

    -- Draw blinking cursor.
    if self.cursorVisible then
        local lineText = self.lines[self.cursorY] or ""
        local cursorX = textAreaX + 5 + self.font:getWidth(lineText:sub(1, self.cursorX - 1)) - self.scrollOffsetX
        local cursorY = textAreaY + (self.cursorY - 1) * self.lineHeight - self.scrollOffsetY
        
        -- Ensure cursor is visible
        self:ensureCursorVisible(cursorX, cursorY, textAreaX, textAreaWidth)
        
        love.graphics.setColor(0, 0, 1)
        love.graphics.line(cursorX, cursorY, cursorX, cursorY + self.lineHeight)
    end
    
    love.graphics.setScissor()

    -- Draw scrollbars
    self:drawScrollbars(x, y, width, height, headerHeight, textAreaWidth, textAreaHeight)
    
    -- Draw status bar
    self:drawStatusBar(x, y + height - 20, width, 20)
end

function TextEditor:drawSelection(textAreaX, textAreaY)
    if not self.selection.startX then return end
    
    local selStartX, selStartY, selEndX, selEndY = self:getOrderedSelection()
    if selStartY == selEndY then
        -- Single line selection
        local line = self.lines[selStartY] or ""
        local startX = self.font:getWidth(line:sub(1, selStartX - 1))
        local endX = self.font:getWidth(line:sub(1, selEndX - 1))
        local yPos = textAreaY + (selStartY - 1) * self.lineHeight - self.scrollOffsetY
        
        love.graphics.setColor(0.7, 0.8, 1, 0.5)
        love.graphics.rectangle("fill", 
            textAreaX + 5 + startX - self.scrollOffsetX, 
            yPos, 
            endX - startX, 
            self.lineHeight
        )
    else
        -- Multi-line selection
        for y = selStartY, selEndY do
            local line = self.lines[y] or ""
            local startX = (y == selStartY) and self.font:getWidth(line:sub(1, selStartX - 1)) or 0
            local endX = (y == selEndY) and self.font:getWidth(line:sub(1, selEndX - 1)) or self.font:getWidth(line)
            local yPos = textAreaY + (y - 1) * self.lineHeight - self.scrollOffsetY
            
            love.graphics.setColor(0.7, 0.8, 1, 0.5)
            love.graphics.rectangle("fill", 
                textAreaX + 5 + startX - self.scrollOffsetX, 
                yPos, 
                endX - startX, 
                self.lineHeight
            )
        end
    end
end

function TextEditor:getOrderedSelection()
    if not self.selection.startX then return nil end
    
    local startY, endY = self.selection.startY, self.selection.endY
    local startX, endX = self.selection.startX, self.selection.endX
    
    if startY > endY or (startY == endY and startX > endX) then
        return endX, endY, startX, startY
    else
        return startX, startY, endX, endY
    end
end

function TextEditor:ensureCursorVisible(cursorX, cursorY, textAreaX, textAreaWidth)
    -- Horizontal scrolling
    if cursorX < textAreaX + 5 then
        self.scrollOffsetX = self.scrollOffsetX - (textAreaX + 5 - cursorX)
    elseif cursorX > textAreaX + textAreaWidth - 5 then
        self.scrollOffsetX = self.scrollOffsetX + (cursorX - (textAreaX + textAreaWidth - 5))
    end
    
    -- Vertical scrolling
    local visibleTop = textAreaX
    local visibleBottom = textAreaX + self.editorHeight - 50
    
    if cursorY < visibleTop then
        self.scrollOffsetY = self.scrollOffsetY - (visibleTop - cursorY)
    elseif cursorY + self.lineHeight > visibleBottom then
        self.scrollOffsetY = self.scrollOffsetY + (cursorY + self.lineHeight - visibleBottom)
    end
    
    -- Ensure non-negative scroll offsets
    self.scrollOffsetX = math.max(0, self.scrollOffsetX)
    self.scrollOffsetY = math.max(0, self.scrollOffsetY)
end

function TextEditor:drawScrollbars(x, y, width, height, headerHeight, textAreaWidth, textAreaHeight)
    -- Vertical scrollbar
    local totalLines = #self.lines
    local totalHeight = totalLines * self.lineHeight
    if totalHeight > textAreaHeight then
        local thumbHeight = (textAreaHeight / totalHeight) * textAreaHeight
        local maxScrollY = math.max(0, totalHeight - textAreaHeight)
        local thumbY = y + headerHeight + (self.scrollOffsetY / maxScrollY) * (textAreaHeight - thumbHeight)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        love.graphics.rectangle("fill", x + width - 12, thumbY, 8, thumbHeight)
    end
    
    -- Horizontal scrollbar
    local maxLineWidth = 0
    for _, line in ipairs(self.lines) do
        maxLineWidth = math.max(maxLineWidth, self.font:getWidth(line))
    end
    
    if maxLineWidth > textAreaWidth then
        local thumbWidth = (textAreaWidth / maxLineWidth) * textAreaWidth
        local maxScrollX = math.max(0, maxLineWidth - textAreaWidth)
        local thumbX = x + (self.lineNumbers and self.lineNumberWidth or 0) + (self.scrollOffsetX / maxScrollX) * (textAreaWidth - thumbWidth)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        love.graphics.rectangle("fill", thumbX, y + height - 12, thumbWidth, 8)
    end
end

function TextEditor:drawStatusBar(x, y, width, height)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", x, y, width, height)
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    local statusText = string.format("Tab: %d | %s | %s", 
        self.tabSize,
        self.lineNumbers and "LN:On" or "LN:Off",
        self.wordWrap and "Wrap:On" or "Wrap:Off"
    )
    love.graphics.printf(statusText, x + 10, y + 4, width - 20, "left")
    
    love.graphics.printf("Ctrl+S: Save | Ctrl+Z: Undo | Ctrl+Y: Redo", x, y + 4, width - 10, "right")
end

function TextEditor:visualizeWhitespace(text)
    return text:gsub("\t", "→"):gsub(" ", "·")
end

function TextEditor:insertText(text)
    local line = self.lines[self.cursorY] or ""
    local before = line:sub(1, self.cursorX - 1)
    local after = line:sub(self.cursorX)
    self.lines[self.cursorY] = before .. text .. after
    self.cursorX = self.cursorX + #text
    self.dirty = true
end

function TextEditor:deleteSelection()
    if not self.selection.startX then return false end
    
    self:saveState()
    
    local selStartX, selStartY, selEndX, selEndY = self:getOrderedSelection()
    
    if selStartY == selEndY then
        -- Single line deletion
        local line = self.lines[selStartY]
        self.lines[selStartY] = line:sub(1, selStartX - 1) .. line:sub(selEndX)
        self.cursorX = selStartX
        self.cursorY = selStartY
    else
        -- Multi-line deletion
        local firstLine = self.lines[selStartY]:sub(1, selStartX - 1)
        local lastLine = self.lines[selEndY]:sub(selEndX)
        self.lines[selStartY] = firstLine .. lastLine
        
        -- Remove lines in between
        for i = selEndY, selStartY + 1, -1 do
            table.remove(self.lines, i)
        end
        
        self.cursorX = selStartX
        self.cursorY = selStartY
    end
    
    self.selection = {startX = nil, startY = nil, endX = nil, endY = nil}
    self.dirty = true
    return true
end

function TextEditor:getSelectedText()
    if not self.selection.startX then return "" end
    
    local selStartX, selStartY, selEndX, selEndY = self:getOrderedSelection()
    local selected = {}
    
    if selStartY == selEndY then
        local line = self.lines[selStartY] or ""
        table.insert(selected, line:sub(selStartX, selEndX - 1))
    else
        -- First line
        local firstLine = self.lines[selStartY]:sub(selStartX)
        table.insert(selected, firstLine)
        
        -- Middle lines
        for y = selStartY + 1, selEndY - 1 do
            table.insert(selected, self.lines[y])
        end
        
        -- Last line
        local lastLine = self.lines[selEndY]:sub(1, selEndX - 1)
        table.insert(selected, lastLine)
    end
    
    return table.concat(selected, "\n")
end

function TextEditor:textinput(t)
    -- Delete selection if any
    if self:deleteSelection() then
        -- Continue with insertion
    end
    
    self:saveState()
    
    if t == "\t" then
        -- Insert spaces for tab
        self:insertText(string.rep(" ", self.tabSize))
    else
        self:insertText(t)
    end
end

function TextEditor:keypressed(key)
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    
    -- Selection handling with shift
    if shift and not self.selecting then
        self.selection = {startX = self.cursorX, startY = self.cursorY, endX = self.cursorX, endY = self.cursorY}
        self.selecting = true
    elseif not shift then
        self.selection = {startX = nil, startY = nil, endX = nil, endY = nil}
        self.selecting = false
    end
    
    if key == "backspace" then
        if self:deleteSelection() then
            return
        end
        
        self:saveState()
        
        if self.cursorX > 1 then
            local line = self.lines[self.cursorY]
            self.lines[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
            self.cursorX = self.cursorX - 1
            self.dirty = true
        elseif self.cursorY > 1 then
            local currentLine = self.lines[self.cursorY]
            self.cursorX = #self.lines[self.cursorY - 1] + 1
            self.lines[self.cursorY - 1] = self.lines[self.cursorY - 1] .. currentLine
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
            self.dirty = true
        end
    elseif key == "return" then
        if self:deleteSelection() then
            -- Continue with new line
        end
        
        self:saveState()
        
        local line = self.lines[self.cursorY]
        local before = line:sub(1, self.cursorX - 1)
        local after = line:sub(self.cursorX)
        self.lines[self.cursorY] = before
        table.insert(self.lines, self.cursorY + 1, after)
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
        self.dirty = true
    elseif key == "left" then
        if self.cursorX > 1 then
            if ctrl then
                -- Move to previous word
                local line = self.lines[self.cursorY]
                local textBefore = line:sub(1, self.cursorX - 1)
                local prevWord = textBefore:match(".*(%W)%w+%W*$")
                if prevWord then
                    self.cursorX = #textBefore - #prevWord + 2
                else
                    self.cursorX = 1
                end
            else
                self.cursorX = self.cursorX - 1
            end
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = #self.lines[self.cursorY] + 1
        end
    elseif key == "right" then
        local line = self.lines[self.cursorY]
        if self.cursorX <= #line then
            if ctrl then
                -- Move to next word
                local textAfter = line:sub(self.cursorX)
                local nextWord = textAfter:match("^(%w+)")
                if nextWord then
                    self.cursorX = self.cursorX + #nextWord
                else
                    self.cursorX = #line + 1
                end
            else
                self.cursorX = self.cursorX + 1
            end
        elseif self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
        end
    elseif key == "up" then
        if self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            local line = self.lines[self.cursorY]
            self.cursorX = math.min(self.cursorX, #line + 1)
        end
    elseif key == "down" then
        if self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            local line = self.lines[self.cursorY]
            self.cursorX = math.min(self.cursorX, #line + 1)
        end
    elseif key == "home" then
        self.cursorX = 1
    elseif key == "end" then
        self.cursorX = #self.lines[self.cursorY] + 1
    elseif key == "pageup" then
        local visibleLines = math.floor((self.editorHeight - 45) / self.lineHeight)
        self.cursorY = math.max(1, self.cursorY - visibleLines)
        self.scrollOffsetY = math.max(0, self.scrollOffsetY - visibleLines * self.lineHeight)
    elseif key == "pagedown" then
        local visibleLines = math.floor((self.editorHeight - 45) / self.lineHeight)
        self.cursorY = math.min(#self.lines, self.cursorY + visibleLines)
        self.scrollOffsetY = math.min(self.scrollOffsetY + visibleLines * self.lineHeight, 
                                     math.max(0, #self.lines * self.lineHeight - (self.editorHeight - 45)))
    elseif ctrl then
        if key == "s" then
            self:saveFile()
        elseif key == "a" then
            -- Select all
            self.selection = {startX = 1, startY = 1, endX = #self.lines[#self.lines] + 1, endY = #self.lines}
            self.selecting = true
        elseif key == "c" or key == "x" then
            -- Copy or cut
            local selectedText = self:getSelectedText()
            if selectedText ~= "" then
                love.system.setClipboardText(selectedText)
                if key == "x" then
                    self:deleteSelection()
                end
            end
        elseif key == "v" then
            -- Paste
            local clipboard = love.system.getClipboardText()
            if clipboard then
                if self:deleteSelection() then
                    -- Continue with paste
                end
                self:saveState()
                self:insertText(clipboard)
            end
        elseif key == "z" then
            self:undo()
        elseif key == "y" then
            self:redo()
        elseif key == "l" then
            self.lineNumbers = not self.lineNumbers
        elseif key == "w" then
            self.wordWrap = not self.wordWrap
        end
    end
    
    -- Update selection end if selecting
    if self.selecting then
        self.selection.endX = self.cursorX
        self.selection.endY = self.cursorY
    end
end

function TextEditor:wheelmoved(x, y)
    local totalHeight = #self.lines * self.lineHeight
    local visibleHeight = self.editorHeight - 45
    local maxScrollY = math.max(totalHeight - visibleHeight, 0)
    self.scrollOffsetY = math.max(0, math.min(self.scrollOffsetY - y * 20, maxScrollY))
    
    -- Horizontal scrolling with shift
    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
        local maxLineWidth = 0
        for _, line in ipairs(self.lines) do
            maxLineWidth = math.max(maxLineWidth, self.font:getWidth(line))
        end
        local maxScrollX = math.max(maxLineWidth - (self.editorWidth - (self.lineNumbers and self.lineNumberWidth + 5 or 0)), 0)
        self.scrollOffsetX = math.max(0, math.min(self.scrollOffsetX - y * 20, maxScrollX))
    end
end

function TextEditor:mousepressed(mx, my, button)
    if button == 1 then
        local headerHeight = 25
        local textAreaX = self.lineNumbers and self.lineNumberWidth or 0
        local textAreaY = headerHeight
        
        -- Convert mouse coordinates to text position
        local relX = mx - textAreaX - 5 + self.scrollOffsetX
        local relY = my - textAreaY + self.scrollOffsetY
        
        self.cursorY = math.max(1, math.min(#self.lines, math.floor(relY / self.lineHeight) + 1))
        local line = self.lines[self.cursorY] or ""
        
        -- Find character position in line
        self.cursorX = 1
        for i = 1, #line do
            if self.font:getWidth(line:sub(1, i)) > relX then
                break
            end
            self.cursorX = i + 1
        end
        
        -- Start selection
        self.selection = {startX = self.cursorX, startY = self.cursorY, endX = self.cursorX, endY = self.cursorY}
        self.selecting = true
    end
end

function TextEditor:mousemoved(mx, my, dx, dy)
    if self.selecting then
        local headerHeight = 25
        local textAreaX = self.lineNumbers and self.lineNumberWidth or 0
        local textAreaY = headerHeight
        
        -- Convert mouse coordinates to text position
        local relX = mx - textAreaX - 5 + self.scrollOffsetX
        local relY = my - textAreaY + self.scrollOffsetY
        
        local newY = math.max(1, math.min(#self.lines, math.floor(relY / self.lineHeight) + 1))
        local line = self.lines[newY] or ""
        
        -- Find character position in line
        local newX = 1
        for i = 1, #line do
            if self.font:getWidth(line:sub(1, i)) > relX then
                break
            end
            newX = i + 1
        end
        
        self.cursorX = newX
        self.cursorY = newY
        self.selection.endX = newX
        self.selection.endY = newY
    end
end

function TextEditor:mousereleased(mx, my, button)
    if button == 1 then
        self.selecting = false
    end
end

-- Save the current text back to the file system.
function TextEditor:saveFile()
    if self.fileNode then
        self.fileNode.content = table.concat(self.lines, "\n")
        filesystem.save(filesystem.getFS())
        self.dirty = false
    end
end

return TextEditor