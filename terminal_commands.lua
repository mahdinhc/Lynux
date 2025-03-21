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

-- Helper function for printing output.
function TerminalCommands.print(self, text)
    table.insert(self.rawLines, text)
end

-- Helper function: resolve a path into its parts.
local function resolvePathParts(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Given a cwd and a path string, return the node at that path.
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

-- For commands like touch/mv, resolve the parent directory and the new name.
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
    local name = table.remove(parts)  -- last part is the file/directory name.
    for _, part in ipairs(parts) do
        if part == ".." then
            if node.parent then
                node = node.parent
            else
                return nil, "Invalid path (attempt to traverse above root)"
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

-- Process a command string. 'self' is the Terminal instance.
function TerminalCommands.process(self, command)
    local args = parseArgs(command)
    if #args == 0 then return end

    -- Ensure the terminal instance has a variables table.
    self.variables = self.variables or {}

    -- Inline substitutions: map built-in names to functions.
    local inlineSubstitutions = {
        pwd = function() return filesystem.getPath(self.cwd) end,
        date = function() return os.date("%Y-%m-%d") end,
        time = function() return os.date("%H:%M:%S") end,
        version = function() return "Terminal version 1.0" end,
        uname = function() return "Simulated OS: 2DPrototype OS" end,
    }

    -- Substitute any argument that starts with '$'
    for i, arg in ipairs(args) do
        if arg:sub(1,1) == "$" then
            local varName = arg:sub(2)
            if self.variables[varName] then
                args[i] = self.variables[varName]
            elseif inlineSubstitutions[varName] then
                args[i] = inlineSubstitutions[varName]()
            else
                args[i] = ""  -- or leave as-is if you prefer
            end
        end
    end

    local cmd = args[1]
    
    if cmd == "help" then
        self:print("Available commands:")
        self:print("  help, clear/cls, echo <text>")
        self:print("  ls, pwd, cd <dir>, mkdir <dir>")
        self:print("  touch <file>, rm <file|dir>, rmall <dir>, mv <src> <dst>")
        self:print("  cat <file>, tree, date, time, version, uname")
        self:print("  set <variable> <data>")
        self:print("  vars")
    elseif cmd == "clear" or cmd == "cls" then
        self.rawLines = {}
        self.scrollOffset = 0
    elseif cmd == "echo" then
        if #args >= 2 then
            local text = table.concat(args, " ", 2)
            self:print(text)
        else
            self:print("Usage: echo <text>")
        end
    elseif cmd == "set" then
        if #args < 3 then
            self:print("Usage: set <variable> <data>")
        else
            local varName = args[2]
            local data = table.concat(args, " ", 3)
            self.variables[varName] = data
        end
    elseif cmd == "vars" then
        for k, v in pairs(self.variables) do
            self:print("  " .. k .. " = " .. v)
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
            self:print("Directory is empty.")
        else
            self:print(table.concat(list, "   "))
        end
    elseif cmd == "pwd" then
        self:print(filesystem.getPath(self.cwd))
    elseif cmd == "cd" then
        if #args < 2 then
            self:print("Usage: cd <directory>")
        else
            local target = args[2]
            local node, err = navigatePath(self.cwd, target)
            if node then
                if node.type == "directory" then
                    self.cwd = node
                else
                    self:print("Not a directory: " .. target)
                end
            else
                self:print(err)
            end
        end
    elseif cmd == "mkdir" then
        if #args < 2 then
            self:print("Usage: mkdir <directory>")
        else
            local dirname = args[2]
            local parent, name = resolveParentAndName(self.cwd, dirname)
            if not parent then
                self:print(name)
            elseif parent.children[name] then
                self:print("Already exists: " .. dirname)
            else
                local newdir = { name = name, type = "directory", parent = parent, children = {} }
                parent.children[name] = newdir
                filesystem.save(self.filesystem)
            end
        end
	elseif cmd == "touch" then
		if #args < 2 then
			self:print("Usage: touch <file> [data]")
		else
			local filename = args[2]
			local parent, name = resolveParentAndName(self.cwd, filename)
			if not parent then
				self:print(name)
			elseif parent.children[name] then
				self:print("Already exists: " .. filename)
			else
				local content = ""
				if #args >= 3 then
					content = table.concat(args, " ", 3)
				end
				local newfile = { name = name, type = "file", content = content }
				parent.children[name] = newfile
				filesystem.save(self.filesystem)
			end
		end
    elseif cmd == "rm" then
        if #args < 2 then
            self:print("Usage: rm <file|directory>")
        else
            local path = args[2]
            local parent, name = resolveParentAndName(self.cwd, path)
            if not parent then
                self:print(name)
            else
                local node = parent.children[name]
                if not node then
                    self:print("Not found: " .. path)
                else
                    if node.type == "directory" then
                        if next(node.children or {}) ~= nil then
                            self:print("Directory not empty: " .. path)
                        else
                            parent.children[name] = nil
                            filesystem.save(self.filesystem)
                        end
                    else
                        parent.children[name] = nil
                        filesystem.save(self.filesystem)
                    end
                end
            end
        end
    elseif cmd == "rmall" then
        if #args < 2 then
            self:print("Usage: rmall <directory>")
        else
            local path = args[2]
            local parent, name = resolveParentAndName(self.cwd, path)
            if not parent then
                self:print(name)
            else
                local node = parent.children[name]
                if not node then
                    self:print("Not found: " .. path)
                else
                    parent.children[name] = nil
                    filesystem.save(self.filesystem)
                    self:print("Removed " .. path)
                end
            end
        end
    elseif cmd == "mv" then
        if #args < 3 then
            self:print("Usage: mv <source> <destination>")
        else
            local srcPath = args[2]
            local dstPath = args[3]
            local srcParent, srcName = resolveParentAndName(self.cwd, srcPath)
            if not srcParent then
                self:print(srcName)
            else
                local node = srcParent.children[srcName]
                if not node then
                    self:print("Source not found: " .. srcPath)
                else
                    local dstParent, dstName = resolveParentAndName(self.cwd, dstPath)
                    if not dstParent then
                        self:print(dstName)
                    elseif dstParent.children[dstName] then
                        self:print("Destination already exists: " .. dstPath)
                    else
                        srcParent.children[srcName] = nil
                        node.name = dstName
                        node.parent = dstParent
                        dstParent.children[dstName] = node
                        filesystem.save(self.filesystem)
                        self:print("Moved/Renamed " .. srcPath .. " to " .. dstPath)
                    end
                end
            end
        end
    elseif cmd == "cat" then
        if #args < 2 then
            self:print("Usage: cat <filename>")
        else
            local filename = args[2]
            local parent, name = resolveParentAndName(self.cwd, filename)
            if not parent then
                self:print(name)
            else
                local node = parent.children[name]
                if not node then
                    self:print("No such file: " .. filename)
                elseif node.type ~= "file" then
                    self:print(filename .. " is not a file.")
                else
                    if node.content == "" then
                        self:print("File is empty.")
                    else
                        self:print(node.content)
                    end
                end
            end
        end
    elseif cmd == "tree" then
        local treeLines = filesystem.generateTree(self.cwd, "")
        if #treeLines == 0 then
            self:print("Directory is empty.")
        else
            for _, line in ipairs(treeLines) do
                self:print(line)
            end
        end
    elseif cmd == "date" then
        self:print(inlineSubstitutions.date())
    elseif cmd == "time" then
        self:print(inlineSubstitutions.time())
    elseif cmd == "version" then
        self:print(inlineSubstitutions.version())
    elseif cmd == "uname" then
        self:print(inlineSubstitutions.uname())
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
