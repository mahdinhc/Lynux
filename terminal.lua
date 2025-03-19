-- terminal.lua
local json = require "lib/json"  -- ensure you have a json module
local filesystem = require("filesystem")

local Terminal = {}
Terminal.__index = Terminal

-- Helper functions remain the same but you can now call filesystem functions directly.
local function getPath(node)
    return filesystem.getPath(node)
end

local function generateTree(node, prefix)
    return filesystem.generateTree(node, prefix)
end

local function wrapText(text, width, font)
    local lines = {}
    local currentLine = ""
    for word in text:gmatch("%S+") do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if font:getWidth(testLine) > width then
            if currentLine == "" then
                table.insert(lines, word)
            else
                table.insert(lines, currentLine)
                currentLine = word
            end
        else
            currentLine = testLine
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

function Terminal:processCommand(command)
    table.insert(self.rawLines, self.prompt .. command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    if #args == 0 then return end
    local cmd = args[1]
    
    if cmd == "help" then
        table.insert(self.rawLines, "Available commands:")
        table.insert(self.rawLines, "  help, clear, echo <text>")
        table.insert(self.rawLines, "  ls, pwd, cd <dir>, mkdir <dir>")
        table.insert(self.rawLines, "  touch <file>, rm <file|dir>, cat <file>")
        table.insert(self.rawLines, "  tree")
    elseif cmd == "clear" then
        self.rawLines = {}
        self.scrollOffset = 0
    elseif cmd == "echo" then
        local text = command:match("echo%s+(.+)")
        if text then
            table.insert(self.rawLines, text)
        end
    elseif cmd == "ls" then
        local list = {}
        for name, node in pairs(self.cwd.children or {}) do
            if node.type == "directory" then
                table.insert(list, name .. "/")
            else
                table.insert(list, name)
            end
        end
        if #list == 0 then
            table.insert(self.rawLines, "Directory is empty.")
        else
            table.insert(self.rawLines, table.concat(list, "   "))
        end
    elseif cmd == "pwd" then
        table.insert(self.rawLines, getPath(self.cwd))
    elseif cmd == "cd" then
        if #args < 2 then
            table.insert(self.rawLines, "Usage: cd <directory>")
        else
            local target = args[2]
            if target == ".." then
                if self.cwd.parent then
                    self.cwd = self.cwd.parent
                else
                    table.insert(self.rawLines, "Already at root directory.")
                end
            else
                local node = self.cwd.children[target]
                if node and node.type == "directory" then
                    self.cwd = node
                else
                    table.insert(self.rawLines, "Directory not found: " .. target)
                end
            end
        end
    elseif cmd == "mkdir" then
        if #args < 2 then
            table.insert(self.rawLines, "Usage: mkdir <directory>")
        else
            local dirname = args[2]
            if self.cwd.children[dirname] then
                table.insert(self.rawLines, "Already exists: " .. dirname)
            else
                local newdir = { name = dirname, type = "directory", parent = self.cwd, children = {} }
                self.cwd.children[dirname] = newdir
                filesystem.save(self.filesystem)
            end
        end
    elseif cmd == "touch" then
        if #args < 2 then
            table.insert(self.rawLines, "Usage: touch <filename>")
        else
            local filename = args[2]
            if self.cwd.children[filename] then
                table.insert(self.rawLines, "Already exists: " .. filename)
            else
                local newfile = { name = filename, type = "file", content = "" }
                self.cwd.children[filename] = newfile
                filesystem.save(self.filesystem)
            end
        end
    elseif cmd == "rm" then
        if #args < 2 then
            table.insert(self.rawLines, "Usage: rm <file|directory>")
        else
            local name = args[2]
            local node = self.cwd.children[name]
            if not node then
                table.insert(self.rawLines, "Not found: " .. name)
            else
                if node.type == "directory" then
                    if next(node.children or {}) ~= nil then
                        table.insert(self.rawLines, "Directory not empty: " .. name)
                    else
                        self.cwd.children[name] = nil
                        filesystem.save(self.filesystem)
                    end
                else
                    self.cwd.children[name] = nil
                    filesystem.save(self.filesystem)
                end
            end
        end
    elseif cmd == "cat" then
        if #args < 2 then
            table.insert(self.rawLines, "Usage: cat <filename>")
        else
            local filename = args[2]
            local node = self.cwd.children[filename]
            if not node then
                table.insert(self.rawLines, "No such file: " .. filename)
            elseif node.type ~= "file" then
                table.insert(self.rawLines, filename .. " is not a file.")
            else
                if node.content == "" then
                    table.insert(self.rawLines, "File is empty.")
                else
                    table.insert(self.rawLines, node.content)
                end
            end
        end
    elseif cmd == "tree" then
        local treeLines = generateTree(self.cwd, "")
        if #treeLines == 0 then
            table.insert(self.rawLines, "Directory is empty.")
        else
            for _, line in ipairs(treeLines) do
                table.insert(self.rawLines, line)
            end
        end
    else
        table.insert(self.rawLines, "Unknown command: " .. command)
    end

    if self.autoScroll then
        self.scrollOffset = 0
    end
end

return Terminal
