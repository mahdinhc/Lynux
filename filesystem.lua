-- filesystem.lua
local json = require "lib/json"  -- make sure you have a JSON module available

local filesystem = {}

-- The shared file system instance (lazy loaded)
local sharedFS = nil

-- Recursively “sanitize” a node so it can be saved (remove parent pointers, etc.)
function filesystem.sanitize(node)
    local t = { name = node.name, type = node.type }
    if node.type == "directory" then
        t.children = {}
        for k, child in pairs(node.children or {}) do
            t.children[k] = filesystem.sanitize(child)
        end
    elseif node.type == "file" then
        t.content = node.content
    end
    return t
end

-- Recursively restore parent pointers (after loading from file)
function filesystem.restore(node, parent)
    node.parent = parent
    if node.type == "directory" and node.children then
        for k, child in pairs(node.children) do
            filesystem.restore(child, node)
        end
    end
end

-- Save the file system to disk.
function filesystem.save(fs)
    local fsSanitized = filesystem.sanitize(fs)
    local data = json.encode(fsSanitized, { indent = true })
    love.filesystem.write("filesystem.json", data)
end

-- Load the file system from disk (or load default from "data/filesystem.json" if it does not exist).
function filesystem.load()
    local fs = { name = "/", type = "directory", parent = nil, children = {} }
    local data, fsLoaded

    if love.filesystem.getInfo("filesystem.json") then
        data = love.filesystem.read("filesystem.json")
        fsLoaded = json.decode(data)
        if fsLoaded then
            fs = fsLoaded
            filesystem.restore(fs, nil)
        end
    elseif love.filesystem.getInfo("data/filesystem.json") then
        -- Load default file system data if no saved filesystem exists.
        data = love.filesystem.read("data/filesystem.json")
        fsLoaded = json.decode(data)
        if fsLoaded then
            fs = fsLoaded
            filesystem.restore(fs, nil)
        end
    end

    return fs
end

-- Returns the shared file system; load it only once.
function filesystem.getFS()
    if not sharedFS then
        sharedFS = filesystem.load()
    end
    return sharedFS
end

function filesystem.getPath(node)
    local parts = {}
    while node do
        parts[#parts + 1] = node.name
        node = node.parent
    end
    -- Reverse the parts table.
    for i = 1, math.floor(#parts / 2) do
        parts[i], parts[#parts - i + 1] = parts[#parts - i + 1], parts[i]
    end
    -- If the first element is "/" or empty, remove it and prepend a single slash.
    if parts[1] == "/" or parts[1] == "" then
        table.remove(parts, 1)
        return "/" .. table.concat(parts, "/")
    else
        return table.concat(parts, "/")
    end
end

-- Generate a tree view (array of strings) for a directory.
function filesystem.generateTree(node, prefix)
    prefix = prefix or ""
    local lines = {}
    local keys = {}
    for name, _ in pairs(node.children or {}) do
        table.insert(keys, name)
    end
    table.sort(keys)
    for _, name in ipairs(keys) do
        local child = node.children[name]
        if child.type == "directory" then
            table.insert(lines, prefix .. name .. "/")
            local subLines = filesystem.generateTree(child, prefix .. "  ")
            for _, subline in ipairs(subLines) do
                table.insert(lines, subline)
            end
        else
            table.insert(lines, prefix .. name)
        end
    end
    return lines
end

return filesystem
