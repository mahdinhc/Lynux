-- terminal_commands.lua
local filesystem = require("filesystem")
local TerminalCommands = {}

-- Helper function for printing output (if not already defined in self)
function TerminalCommands.print(self, text)
    table.insert(self.rawLines, text)
end

-- Helper: recursively remove a directory from parent's children.
local function removeDirectoryRecursively(parent, name)
    parent.children[name] = nil
end

-- Process a command string. 'self' is the Terminal instance.
function TerminalCommands.process(self, command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    if #args == 0 then return end
    local cmd = args[1]
    
    if cmd == "help" then
        self:print("Available commands:")
        self:print("  help, clear/cls, echo <text>")
        self:print("  ls, pwd, cd <dir>, mkdir <dir>")
        self:print("  touch <file>, rm <file|dir>, rmall <dir>, mv <src> <dst>")
        self:print("  cat <file>, tree, date, time, version, uname")
    elseif cmd == "clear" or cmd == "cls" then
        self.rawLines = {}
        self.scrollOffset = 0
    elseif cmd == "echo" then
        local text = command:match("echo%s+(.+)")
        if text then
            self:print(text)
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
            if target == ".." then
                if self.cwd.parent then
                    self.cwd = self.cwd.parent
                else
                    self:print("Already at root directory.")
                end
            else
                local node = self.cwd.children[target]
                if node and node.type == "directory" then
                    self.cwd = node
                else
                    self:print("Directory not found: " .. target)
                end
            end
        end
    elseif cmd == "mkdir" then
        if #args < 2 then
            self:print("Usage: mkdir <directory>")
        else
            local dirname = args[2]
            if self.cwd.children[dirname] then
                self:print("Already exists: " .. dirname)
            else
                local newdir = { name = dirname, type = "directory", parent = self.cwd, children = {} }
                self.cwd.children[dirname] = newdir
                filesystem.save(self.filesystem)
            end
        end
    elseif cmd == "touch" then
        if #args < 2 then
            self:print("Usage: touch <filename>")
        else
            local filename = args[2]
            if self.cwd.children[filename] then
                self:print("Already exists: " .. filename)
            else
                local newfile = { name = filename, type = "file", content = "" }
                self.cwd.children[filename] = newfile
                filesystem.save(self.filesystem)
            end
        end
    elseif cmd == "rm" then
        if #args < 2 then
            self:print("Usage: rm <file|directory>")
        else
            local name = args[2]
            local node = self.cwd.children[name]
            if not node then
                self:print("Not found: " .. name)
            else
                if node.type == "directory" then
                    if next(node.children or {}) ~= nil then
                        self:print("Directory not empty: " .. name)
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
    elseif cmd == "rmall" then
        if #args < 2 then
            self:print("Usage: rmall <directory>")
        else
            local name = args[2]
            local node = self.cwd.children[name]
            if not node then
                self:print("Not found: " .. name)
            else
                if node.type == "directory" then
                    -- Remove directory recursively (ignoring children)
                    self.cwd.children[name] = nil
                    filesystem.save(self.filesystem)
                    self:print("Removed directory recursively: " .. name)
                else
                    self.cwd.children[name] = nil
                    filesystem.save(self.filesystem)
                    self:print("Removed file: " .. name)
                end
            end
        end
    elseif cmd == "mv" then
        if #args < 3 then
            self:print("Usage: mv <source> <destination>")
        else
            local src = args[2]
            local dst = args[3]
            local node = self.cwd.children[src]
            if not node then
                self:print("Source not found: " .. src)
            else
                -- Check if destination exists in current directory.
                if self.cwd.children[dst] then
                    self:print("Destination already exists: " .. dst)
                else
                    -- Rename or move the node by updating its key in the parent's children table.
                    self.cwd.children[src] = nil
                    node.name = dst
                    self.cwd.children[dst] = node
                    filesystem.save(self.filesystem)
                    self:print("Moved/Renamed " .. src .. " to " .. dst)
                end
            end
        end
    elseif cmd == "cat" then
        if #args < 2 then
            self:print("Usage: cat <filename>")
        else
            local filename = args[2]
            local node = self.cwd.children[filename]
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
        self:print(os.date("Current Date: %Y-%m-%d"))
    elseif cmd == "time" then
        self:print(os.date("Current Time: %H:%M:%S"))
    elseif cmd == "version" then
        self:print("Terminal version 1.0")
    elseif cmd == "uname" then
        self:print("Simulated OS: 2DPrototype OS")
    else
        self:print("Unknown command: " .. command)
    end

    if self.autoScroll then
        self.scrollOffset = 0
    end
end

return TerminalCommands
