-- terminal.lua
local json = require "lib/json"  -- ensure you have a json module
local filesystem = require("filesystem")
local TerminalCommands = require("terminal_commands")

local Terminal = {}
Terminal.__index = Terminal

-- Helper functions
local function getPath(node)
    return filesystem.getPath(node)
end

local function generateTree(node, prefix)
    return filesystem.generateTree(node, prefix)
end

local function wrapText(text, width, font)
    local lines = {}
    local currentLine = ""
    local currentWidth = 0

    for i = 1, #text do
        local char = text:sub(i, i)
        local newLine = currentLine .. char
        local newWidth = font:getWidth(newLine)

        if newWidth > width then
            table.insert(lines, currentLine)
            currentLine = char
        else
            currentLine = newLine
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end


local function getWrappedLines(self)
    local wrapped = {}
    for i, line in ipairs(self.rawLines) do
        local linesWrapped = wrapText(line, self.wrapWidth, self.font)
        for _, wline in ipairs(linesWrapped) do
            table.insert(wrapped, wline)
        end
    end
    return wrapped
end

-- Terminal Module Methods
function Terminal.new()
    local self = setmetatable({}, Terminal)
    self.rawLines = {}           -- raw (unwrapped) lines
    self.inputBuffer = ""
    self.prompt = "$ "
    self.font = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 12)
    love.graphics.setFont(self.font)
    self.cursorBlinkTimer = 0
    self.cursorVisible = true
    self.cursorBlinkInterval = 0.5
    self.scrollOffset = 0        -- 0 means bottom (newest lines)
    self.wrapWidth = 400 - 40
    self.autoScroll = true
    self.maxVisibleLines = math.floor((300 - 20) / self.font:getHeight()) - 2
    table.insert(self.rawLines, "Welcome to the 2DPrototype & CORNTOOZ's Terminal!")
    table.insert(self.rawLines, "Type 'help' for available commands.")
    
    -- Use the shared file system.
    self.filesystem = filesystem.getFS()
    self.cwd = self.filesystem
	
    return self
end

function Terminal:update(dt)
    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
    if self.cursorBlinkTimer >= self.cursorBlinkInterval then
        self.cursorBlinkTimer = self.cursorBlinkTimer - self.cursorBlinkInterval
        self.cursorVisible = not self.cursorVisible
    end
end

function Terminal:draw(x, y, width, height)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 1, 0)  -- green text
    
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local termHeight = visibleLines * self.font:getHeight()
    local startIndex = math.max(1, totalWrapped - visibleLines + 1 - self.scrollOffset)
    local endIndex = math.min(totalWrapped, startIndex + visibleLines - 1)
    
    local yPos = 10
    for i = startIndex, endIndex do
        love.graphics.print(wrapped[i], 10, yPos)
        yPos = yPos + self.font:getHeight()
    end

    local inputDisplay = self.prompt .. self.inputBuffer
    love.graphics.print(inputDisplay, 10, yPos)
    if self.cursorVisible then
        local cursorX = 10 + self.font:getWidth(inputDisplay)
        love.graphics.rectangle("fill", cursorX, yPos, 10, self.font:getHeight())
    end
    love.graphics.pop()
    
    -- Draw scrollbar if needed.
    if totalWrapped > visibleLines then
        local scrollbarWidth = 10
        local scrollbarX = x + width - scrollbarWidth - 10
        local scrollbarY = y + 10
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, termHeight)
        local maxScroll = totalWrapped - visibleLines
        local thumbHeight = (visibleLines / totalWrapped) * termHeight
        local thumbY = scrollbarY + ((maxScroll - self.scrollOffset) / maxScroll) * (termHeight - thumbHeight)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight)
    end
end

function Terminal:textinput(text)
    self.inputBuffer = self.inputBuffer .. text
end

function Terminal:keypressed(key)
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local maxScroll = math.max(totalWrapped - visibleLines, 0)
    
    if key == "backspace" then
        self.inputBuffer = self.inputBuffer:sub(1, -2)
    elseif key == "return" then
        self:processCommand(self.inputBuffer)
        self.inputBuffer = ""
        self.autoScroll = true
        self.scrollOffset = 0
    elseif key == "up" then
        self.scrollOffset = math.min(self.scrollOffset + 1, maxScroll)
        self.autoScroll = false
    elseif key == "down" then
        self.scrollOffset = math.max(self.scrollOffset - 1, 0)
        self.autoScroll = (self.scrollOffset == 0)
    end
end

function Terminal:wheelmoved(x, y)
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local maxScroll = math.max(totalWrapped - visibleLines, 0)
    if y > 0 then
        self.scrollOffset = math.min(self.scrollOffset + 1, maxScroll)
        self.autoScroll = false
    elseif y < 0 then
        self.scrollOffset = math.max(self.scrollOffset - 1, 0)
        self.autoScroll = (self.scrollOffset == 0)
    end
end

function Terminal:resize(width, height)
    self.wrapWidth = width - 40
    self.maxVisibleLines = math.floor(height / self.font:getHeight()) - 2
end

-- Delegate command processing to terminal_commands.lua
function Terminal:processCommand(command)
    table.insert(self.rawLines, self.prompt .. command)
    TerminalCommands.process(self, command)
end


function Terminal:print(str)
    -- Split the string by newline characters
    for line in str:gmatch("([^\n]+)") do
        local wrappedLines = wrapText(line, self.wrapWidth, self.font)
        for _, wline in ipairs(wrappedLines) do
            table.insert(self.rawLines, wline)
        end
    end
    if self.autoScroll then
        self.scrollOffset = 0
    end
end



return Terminal
