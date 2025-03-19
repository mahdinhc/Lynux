-- local moonshine = require 'moonshine'
local json = require "json"

-- effect = moonshine(moonshine.effects.scanlines)
-- effect.scanlines.opacity=0.6


terminal = {
    rawLines = {},           -- store raw (unwrapped) lines
    inputBuffer = "",
    prompt = "$ ",
    font = nil,
    cursorBlinkTimer = 0,
    cursorVisible = true,
    cursorBlinkInterval = 0.5,
    scrollOffset = 0,        -- 0 means bottom (newest lines)
    wrapWidth = 200,         -- default width (updated dynamically)
    autoScroll = true,
    maxVisibleLines = 100    -- number of visible wrapped lines (computed dynamically)
}

-- Simulated file system: a root directory and a pointer to the current working directory.
filesystem = { name = "/", type = "directory", parent = nil, children = {} }
cwd = filesystem

-- =================== JSON Save/Load Functions ===================
-- Remove circular parent references by creating a sanitized copy.
function sanitizeFS(node)
    local t = { name = node.name, type = node.type }
    if node.type == "directory" then
        t.children = {}
        for key, child in pairs(node.children) do
            t.children[key] = sanitizeFS(child)
        end
    elseif node.type == "file" then
        t.content = node.content
    end
    return t
end

-- Restore parent pointers recursively.
function restoreParents(node, parent)
    node.parent = parent
    if node.type == "directory" and node.children then
        for key, child in pairs(node.children) do
            restoreParents(child, node)
        end
    end
end

-- Save the current file system state to a JSON file.
function saveFileSystem()
    local fsSanitized = sanitizeFS(filesystem)
    local data = json.encode(fsSanitized, { indent = true })
    love.filesystem.write("filesystem.json", data)
end

-- Load the file system state from JSON if the file exists.
function loadFileSystem()
    if love.filesystem.getInfo("filesystem.json") then
        local data = love.filesystem.read("filesystem.json")
        local fsLoaded = json.decode(data)
        if fsLoaded then
            filesystem = fsLoaded
            restoreParents(filesystem, nil)
            cwd = filesystem  -- Set current working directory to root
        end
    end
end
-- =================================================================

function love.load()
    terminal.font = love.graphics.newFont("x14y24pxHeadUpDaisy.ttf", 13)
    love.graphics.setFont(terminal.font)
    love.keyboard.setKeyRepeat(true)
    table.insert(terminal.rawLines, "Welcome to the 2DPrototye & CORNTOOZ's Terminal!")
    table.insert(terminal.rawLines, "Type 'help' for available commands.")
    
    updateTerminalBounds()
    loadFileSystem()  -- Reload file system state if it exists
end

function love.resize(w, h)
    updateTerminalBounds()
end

-- Update dimensions based on window size; reserve space for scrollbar.
function updateTerminalBounds()
    terminal.wrapWidth = love.graphics.getWidth() - 40  -- leave padding for scrollbar
    terminal.maxVisibleLines = math.floor(love.graphics.getHeight() / terminal.font:getHeight()) - 2
end

-- Dynamically wrap all raw lines using the current wrap width.
function getWrappedLines()
    local wrapped = {}
    for i, line in ipairs(terminal.rawLines) do
        local linesWrapped = wrapText(line, terminal.wrapWidth)
        for _, wline in ipairs(linesWrapped) do
            table.insert(wrapped, wline)
        end
    end
    return wrapped
end

function love.draw()
    love.graphics.clear(0, 0, 0)
	-- effect(function()
		love.graphics.push()
		love.graphics.setColor(0, 1, 0) -- green text

		local wrapped = getWrappedLines()
		local totalWrapped = #wrapped
		local visibleLines = terminal.maxVisibleLines
		local termHeight = visibleLines * terminal.font:getHeight()

		-- Calculate starting index so that 0 scrollOffset shows the bottom (newest wrapped lines)
		local startIndex = math.max(1, totalWrapped - visibleLines + 1 - terminal.scrollOffset)
		local endIndex = math.min(totalWrapped, startIndex + visibleLines - 1)

		local y = 10
		for i = startIndex, endIndex do
			love.graphics.print(wrapped[i], 10, y)
			y = y + terminal.font:getHeight()
		end

		-- Draw input prompt and blinking cursor
		local inputDisplay = terminal.prompt .. terminal.inputBuffer
		love.graphics.print(inputDisplay, 10, y)
		if terminal.cursorVisible then
			local cursorX = 10 + terminal.font:getWidth(inputDisplay)
			love.graphics.rectangle("fill", cursorX, y, 10, terminal.font:getHeight())
		end
		love.graphics.pop()

		-- Draw scrollbar if there are more wrapped lines than can be shown
		if totalWrapped > visibleLines then
			local scrollbarWidth = 10
			local scrollbarX = love.graphics.getWidth() - scrollbarWidth - 10
			local scrollbarY = 10
			love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
			love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, termHeight)

			local maxScroll = totalWrapped - visibleLines
			local thumbHeight = (visibleLines / totalWrapped) * termHeight
			local thumbY = scrollbarY + ((maxScroll - terminal.scrollOffset) / maxScroll) * (termHeight - thumbHeight)
			love.graphics.setColor(0.8, 0.8, 0.8)
			love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight)
		end
	-- end)
end

function love.textinput(text)
    terminal.inputBuffer = terminal.inputBuffer .. text
end

function love.keypressed(key)
    local wrapped = getWrappedLines()
    local totalWrapped = #wrapped
    local visibleLines = terminal.maxVisibleLines
    local maxScroll = math.max(totalWrapped - visibleLines, 0)
    
    if key == "backspace" then
        terminal.inputBuffer = terminal.inputBuffer:sub(1, -2)
    elseif key == "return" then
        processCommand(terminal.inputBuffer)
        terminal.inputBuffer = ""
        terminal.autoScroll = true
        terminal.scrollOffset = 0  -- always reset scroll on new command
    elseif key == "up" then
        terminal.scrollOffset = math.min(terminal.scrollOffset + 1, maxScroll)
        terminal.autoScroll = false
    elseif key == "down" then
        terminal.scrollOffset = math.max(terminal.scrollOffset - 1, 0)
        terminal.autoScroll = (terminal.scrollOffset == 0)
    end
end

function love.wheelmoved(x, y)
    local wrapped = getWrappedLines()
    local totalWrapped = #wrapped
    local visibleLines = terminal.maxVisibleLines
    local maxScroll = math.max(totalWrapped - visibleLines, 0)
    
    if y > 0 then
        terminal.scrollOffset = math.min(terminal.scrollOffset + 1, maxScroll)
        terminal.autoScroll = false
    elseif y < 0 then
        terminal.scrollOffset = math.max(terminal.scrollOffset - 1, 0)
        terminal.autoScroll = (terminal.scrollOffset == 0)
    end
end

-- Process a command entered in the terminal.
-- This function handles both general commands and file system commands.
function processCommand(command)
    table.insert(terminal.rawLines, terminal.prompt .. command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    if #args == 0 then return end
    local cmd = args[1]
    
    if cmd == "help" then
        table.insert(terminal.rawLines, "Available commands:")
        table.insert(terminal.rawLines, "  help, clear, echo <text>")
        table.insert(terminal.rawLines, "  ls, pwd, cd <dir>, mkdir <dir>")
        table.insert(terminal.rawLines, "  touch <file>, rm <file|dir>, cat <file>")
        table.insert(terminal.rawLines, "  tree")
    elseif cmd == "clear" then
        terminal.rawLines = {}
        terminal.scrollOffset = 0
    elseif cmd == "echo" then
        local text = command:match("echo%s+(.+)")
        if text then
            table.insert(terminal.rawLines, text)
        end
    elseif cmd == "ls" then
        local list = {}
        for name, node in pairs(cwd.children) do
            if node.type == "directory" then
                table.insert(list, name .. "/")
            else
                table.insert(list, name)
            end
        end
        if #list == 0 then
            table.insert(terminal.rawLines, "Directory is empty.")
        else
            table.insert(terminal.rawLines, table.concat(list, "   "))
        end
    elseif cmd == "pwd" then
        table.insert(terminal.rawLines, getPath(cwd))
    elseif cmd == "cd" then
        if #args < 2 then
            table.insert(terminal.rawLines, "Usage: cd <directory>")
        else
            local target = args[2]
            if target == ".." then
                if cwd.parent then
                    cwd = cwd.parent
                else
                    table.insert(terminal.rawLines, "Already at root directory.")
                end
            else
                local node = cwd.children[target]
                if node and node.type == "directory" then
                    cwd = node
                else
                    table.insert(terminal.rawLines, "Directory not found: " .. target)
                end
            end
        end
    elseif cmd == "mkdir" then
        if #args < 2 then
            table.insert(terminal.rawLines, "Usage: mkdir <directory>")
        else
            local dirname = args[2]
            if cwd.children[dirname] then
                table.insert(terminal.rawLines, "Directory or file already exists: " .. dirname)
            else
                local newdir = { name = dirname, type = "directory", parent = cwd, children = {} }
                cwd.children[dirname] = newdir
                saveFileSystem()  -- Save after modification
            end
        end
    elseif cmd == "touch" then
        if #args < 2 then
            table.insert(terminal.rawLines, "Usage: touch <filename>")
        else
            local filename = args[2]
            if cwd.children[filename] then
                table.insert(terminal.rawLines, "File or directory already exists: " .. filename)
            else
                local newfile = { name = filename, type = "file", content = "" }
                cwd.children[filename] = newfile
                saveFileSystem()  -- Save after modification
            end
        end
    elseif cmd == "rm" then
        if #args < 2 then
            table.insert(terminal.rawLines, "Usage: rm <filename|directory>")
        else
            local name = args[2]
            local node = cwd.children[name]
            if not node then
                table.insert(terminal.rawLines, "No such file or directory: " .. name)
            else
                if node.type == "directory" then
                    if next(node.children) ~= nil then
                        table.insert(terminal.rawLines, "Directory not empty: " .. name)
                    else
                        cwd.children[name] = nil
                        saveFileSystem()  -- Save after modification
                    end
                else
                    cwd.children[name] = nil
                    saveFileSystem()  -- Save after modification
                end
            end
        end
    elseif cmd == "cat" then
        if #args < 2 then
            table.insert(terminal.rawLines, "Usage: cat <filename>")
        else
            local filename = args[2]
            local node = cwd.children[filename]
            if not node then
                table.insert(terminal.rawLines, "No such file: " .. filename)
            elseif node.type ~= "file" then
                table.insert(terminal.rawLines, filename .. " is not a file.")
            else
                if node.content == "" then
                    table.insert(terminal.rawLines, "File is empty.")
                else
                    table.insert(terminal.rawLines, node.content)
                end
            end
        end
    elseif cmd == "tree" then
        -- Generate and print the file tree for the current directory.
        local treeLines = generateTree(cwd, "")
        if #treeLines == 0 then
            table.insert(terminal.rawLines, "Directory is empty.")
        else
            for _, line in ipairs(treeLines) do
                table.insert(terminal.rawLines, line)
            end
        end
    else
        table.insert(terminal.rawLines, "Unknown command: " .. command)
    end

    if terminal.autoScroll then
        terminal.scrollOffset = 0
    end
end

-- Compute the full path of a directory node.
function getPath(node)
    local parts = {}
    while node do
        table.insert(parts, 1, node.name)
        node = node.parent
    end
    local path = table.concat(parts, "/")
    if path == "//" then path = "/" end
    return path
end

-- Recursively generate a table of lines representing the file tree starting at the given node.
function generateTree(node, prefix)
    prefix = prefix or ""
    local lines = {}
    -- Collect and sort keys for a consistent order.
    local keys = {}
    for name, _ in pairs(node.children) do
        table.insert(keys, name)
    end
    table.sort(keys)
    for _, name in ipairs(keys) do
        local child = node.children[name]
        if child.type == "directory" then
            table.insert(lines, prefix .. name .. "/")
            local subLines = generateTree(child, prefix .. "+ ")
            for _, subline in ipairs(subLines) do
                table.insert(lines, subline)
            end
        else
            table.insert(lines, prefix .. name)
        end
    end
    return lines
end

-- Wrap a given text so that no line exceeds the specified width.
function wrapText(text, width)
    local lines = {}
    local currentLine = ""
    for word in text:gmatch("%S+") do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if terminal.font:getWidth(testLine) > width then
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
