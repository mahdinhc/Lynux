local xml2lua = require("lib/xml2lua")
local handler = require("lib/xmlhandler.tree")
local pprint = require("lib/pprint")

local websiteDatabase = {}

-- Recursively walk through a node and modify it in place.
local function processNode(node)
  if type(node) ~= "table" then
    return node
  end

  local attr = node._attr
  local texts = {}
  for k, v in pairs(node) do
    if type(k) == "number" then
      if type(v) == "string" then
        table.insert(texts, v)
      elseif type(v) == "table" and v._text then
        table.insert(texts, v._text)
      end
      node[k] = nil  -- Remove numeric key after processing
    end
  end
  if #texts > 0 then
    node._text = table.concat(texts, " ")
  end


  for key, value in pairs(node) do
    if key ~= "_attr" and key ~= "_text" then
      if type(value) == "table" then
        -- Check if this child is an array (multiple elements with the same tag)
        local isArray = false
        for subKey, _ in pairs(value) do
          if type(subKey) == "number" then
            isArray = true
            break
          end
        end
        if isArray then
          -- Process each child in the array
          for i, child in ipairs(value) do
			-- child._attr = node._attr
            processNode(child)
          end
          -- If there's only one element in the array, flatten it.
          if #value == 1 then
            node[key] = {}
            node[key]._text = value[1]
            node[key]._attr = value._attr
          end
        else
          processNode(value)
        end
      end
    end
  end
  node._attr = attr
  return node
end

-- Load and parse an XML (or HTML) file for a given URL.
local function loadWebsiteXML(url, filename)
  local filepath = "websites/" .. filename

  if love.filesystem.getInfo(filepath) then
    local content = love.filesystem.read(filepath)

    -- Create a fresh handler and parser.
    local xmlHandler = handler:new()
    local parser = xml2lua.parser(xmlHandler)
    parser:parse(content)
    
    -- Process the parsed tree in place.
    processNode(xmlHandler.root)
    websiteDatabase[url] = xmlHandler.root
  else
    websiteDatabase[url] = {
      div = {
        p = "404 Page Not Found: " .. url
      }
    }
  end
end

-- Mapping from URL to XML/HTML filename.
local mapping = {
  [""]                   = "home.html",
  ["http://example.com"] = "example.com.html",
}

for url, filename in pairs(mapping) do
  loadWebsiteXML(url, filename)
end


return websiteDatabase
