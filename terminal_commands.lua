-- terminal_commands.lua
local filesystem = require("filesystem")
local TerminalCommands = {}

-- Custom argument parser that supports quoted strings.
local function parseArgs(input)
    local args = {}
    local current = ""
    local inQuotes = false
    local i = 1
    while i <= #input do
        local c = input:sub(i, i)
        if c == '"' then
            inQuotes = not inQuotes
        elseif c:match("%s") and not inQuotes then
            if #current > 0 then
                table.insert(args, current)
                current = ""
            end
        else
            current = current .. c
        end
        i = i + 1
    end
    if #current > 0 then
        table.insert(args, current)
    end
    return args
end

-- Helper: print output to the terminal.
function TerminalCommands.print(self, text)
    table.insert(self.rawLines, text)
end

-- Helper: resolve a path into its parts.
local function resolvePathParts(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Given a cwd and a path, return the node at that path.
local function navigatePath(cwd, path)
    local node
    if path:sub(1,1) == "/" then
        node = filesystem.getFS()
        path = path:sub(2)
    else
        node = cwd
    end
    local parts = resolvePathParts(path)
    for _, part in ipairs(parts) do
        if part == ".." then
            if node.parent then
                node = node.parent
            else
                return nil, "Already at root"
            end
        else
            if node.children and node.children[part] then
                node = node.children[part]
            else
                return nil, "Not found: " .. part
            end
        end
    end
    return node
end

-- For commands like touch/mv, resolve the parent directory and file name.
local function resolveParentAndName(cwd, path)
    local node
    if path:sub(1,1) == "/" then
        node = filesystem.getFS()
        path = path:sub(2)
    else
        node = cwd
    end
    local parts = resolvePathParts(path)
    if #parts == 0 then return nil, "Invalid path" end
    local name = table.remove(parts)
    for _, part in ipairs(parts) do
        if part == ".." then
            if node.parent then
                node = node.parent
            else
                return nil, "Invalid path (above root)"
            end
        else
            if node.children and node.children[part] then
                node = node.children[part]
            else
                return nil, "Directory not found: " .. part
            end
        end
    end
    return node, name
end

-- Inline substitutions table: all built-in command functions.
local inlineSubstitutions = {
    help = function(self, ...)
        self:print("Available commands:")
        self:print("  help, clear, echo, set, vars, ls, pwd, cd, mkdir, touch, rm, rmall, mv, cat, tree, date, time, version, uname")
    end,
    clear = function(self, ...)
        self.rawLines = {}
        self.scrollOffset = 0
    end,
    echo = function(self, ...)
        return table.concat({...}, " ")
    end,
    set = function(self, varName, ...)
        local data = table.concat({...}, " ")
        self.variables = self.variables or {}
        self.variables[varName] = data
    end,
    vars = function(self, ...)
        for k, v in pairs(self.variables or {}) do
            self:print("  " .. k .. " = " .. v)
        end
    end,
    ls = function(self, ...)
        local list = {}
        for name, node in pairs(self.cwd.children or {}) do
            if node.type == "directory" then
                table.insert(list, name .. "/")
            else
                table.insert(list, name)
            end
        end
        if #list == 0 then return "Directory is empty." end
        return table.concat(list, " ")
    end,
    pwd = function(self, ...)
        return filesystem.getPath(self.cwd)
    end,
    cd = function(self, target)
        if not target then return "Usage: cd <directory>" end
        local node, err = navigatePath(self.cwd, target)
        if node then
            if node.type == "directory" then
                self.cwd = node
            else
                return "Not a directory: " .. target
            end
        else
            return err
        end
    end,
    mkdir = function(self, dirname)
        if not dirname then return "Usage: mkdir <directory>" end
        local parent, name = resolveParentAndName(self.cwd, dirname)
        if not parent then return name end
        if parent.children[name] then
            return "Already exists: " .. dirname
        else
            local newdir = { name = name, type = "directory", parent = parent, children = {} }
            parent.children[name] = newdir
            filesystem.save(self.filesystem)
        end
    end,
    touch = function(self, filename, ...)
        if not filename then return "Usage: touch <file> [data]" end
        local parent, name = resolveParentAndName(self.cwd, filename)
        if not parent then return name end
        if parent.children[name] then
            return "Already exists: " .. filename
        else
            local content = table.concat({...}, " ")
            local newfile = { name = name, type = "file", content = content }
            parent.children[name] = newfile
            filesystem.save(self.filesystem)
        end
    end,
    rm = function(self, path)
        if not path then return "Usage: rm <file|directory>" end
        local parent, name = resolveParentAndName(self.cwd, path)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "Not found: " .. path end
        if node.type == "directory" then
            if next(node.children or {}) ~= nil then
                return "Directory not empty: " .. path
            else
                parent.children[name] = nil
                filesystem.save(self.filesystem)
            end
        else
            parent.children[name] = nil
            filesystem.save(self.filesystem)
        end
    end,
    rmall = function(self, path)
        if not path then return "Usage: rmall <directory>" end
        local parent, name = resolveParentAndName(self.cwd, path)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "Not found: " .. path end
        parent.children[name] = nil
        filesystem.save(self.filesystem)
        return "Removed " .. path
    end,
    mv = function(self, src, dst)
        if not src or not dst then return "Usage: mv <source> <destination>" end
        local srcParent, srcName = resolveParentAndName(self.cwd, src)
        if not srcParent then return srcName end
        local node = srcParent.children[srcName]
        if not node then return "Source not found: " .. src end
        local dstParent, dstName = resolveParentAndName(self.cwd, dst)
        if not dstParent then return dstName end
        if dstParent.children[dstName] then return "Destination already exists: " .. dst end
        srcParent.children[srcName] = nil
        node.name = dstName
        node.parent = dstParent
        dstParent.children[dstName] = node
        filesystem.save(self.filesystem)
        return "Moved/Renamed " .. src .. " to " .. dst
    end,
    cat = function(self, filename)
        if not filename then return "Usage: cat <file>" end
        local parent, name = resolveParentAndName(self.cwd, filename)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "No such file: " .. filename end
        if node.type ~= "file" then return filename .. " is not a file." end
        if node.content == "" then return "File is empty." end
        return node.content
    end,
    tree = function(self, ...)
        local treeLines = filesystem.generateTree(self.cwd, "")
        if #treeLines == 0 then return "Directory is empty." end
        return table.concat(treeLines, "\n")
    end,
    date = function(self, ...)
        return os.date("%Y-%m-%d")
    end,
    time = function(self, ...)
        return os.date("%H:%M:%S")
    end,
    version = function(self, ...)
        return "Terminal version 1.0"
    end,
    uname = function(self, ...)
        return "user@root"
    end,
}

-- Process a command string. 'self' is the Terminal instance.
function TerminalCommands.process(self, command)
    local args = parseArgs(command)
    if #args == 0 then return end

    self.variables = self.variables or {}

    -- First, substitute inline function calls and variable references.
    for i, arg in ipairs(args) do
        local funcName, funcArgs = arg:match("^%$(%w+)%((.*)%)$")
        if funcName then
            if inlineSubstitutions[funcName] then
                local parsedArgs = {}
                for token in funcArgs:gmatch("[^,]+") do
                    token = token:gsub("^%s*(.-)%s*$", "%1")
                    token = token:gsub('^"(.*)"$', "%1")
                    table.insert(parsedArgs, token)
                end
                args[i] = inlineSubstitutions[funcName](self, unpack(parsedArgs))
            else
                args[i] = ""
            end
        elseif arg:sub(1,1) == "$" then
            local varName = arg:sub(2)
            if self.variables[varName] then
                args[i] = self.variables[varName]
            elseif inlineSubstitutions[varName] then
                args[i] = inlineSubstitutions[varName](self)
            else
                args[i] = ""
            end
        end
    end

    local cmd = args[1]
    if inlineSubstitutions[cmd] then
        local result = inlineSubstitutions[cmd](self, unpack(args, 2))
        if result then self:print(result) end
    else
        if command:sub(-3) == ".sh" then
            local parent, name = resolveParentAndName(self.cwd, command)
            if parent and parent.children[name] and parent.children[name].type == "file" then
                local content = parent.children[name].content
                for line in content:gmatch("([^\n]+)") do
                    TerminalCommands.process(self, line)
                end
            else
                self:print("Script file not found: " .. command)
            end
        else 
            self:print("Unknown command: " .. command)
        end
    end

    if self.autoScroll then
        self.scrollOffset = 0
    end
end

return TerminalCommands
