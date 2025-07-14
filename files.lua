-- files.lua
local filesystem = require("filesystem")
local TextEditor = require("texteditor")
local ImageViewer = require("imageviewer")
local loveTimer = love.timer  -- alias for convenience

local FilesApp = {}
FilesApp.__index = FilesApp

function FilesApp.new()
   local self = setmetatable({}, FilesApp)
   -- Get the shared file system.
   self.fs = filesystem.getFS()
   -- Start at the root directory.
   self.cwd = self.fs
   -- Build an ordered list of filenames from the current working directory.
   self:updateFileList()
   self.selected = 1
   self.scrollOffset = 0  -- new: scroll offset for file list
   -- For detecting double-clicks
   self.lastClickTime = 0
   self.lastClickIndex = 0

   -- Load icons (ensure these files exist in your project folder)
   self.folderIcon = love.graphics.newImage("assets/folder.png")
   self.fileIcon   = love.graphics.newImage("assets/file.png")

   return self
end

-- Update the file list array based on the current working directory.
-- If we're not at the root, add a special ".." entry at the top for going back.
function FilesApp:updateFileList()
   self.fileNames = {}
   if self.cwd.parent then
      table.insert(self.fileNames, "..")
   end
   for name, node in pairs(self.cwd.children or {}) do
      table.insert(self.fileNames, name)
   end
   table.sort(self.fileNames, function(a, b)
      -- Ensure ".." always stays at the top.
      if a == ".." then return true end
      if b == ".." then return false end
      return a < b
   end)
   -- Reset scroll offset and selection if needed.
   self.scrollOffset = 0
   self.selected = 1
end

function FilesApp:draw(x, y, width, height)
   -- Draw background
   love.graphics.setColor(1, 1, 1)
   love.graphics.rectangle("fill", x, y, width, height)
   -- Draw current path at the top
   love.graphics.setColor(0, 0, 0)
   love.graphics.printf(filesystem.getPath(self.cwd) .. ":", x + 10, y + 10, width - 20, "left")
   
   local iconSize = 16  -- Desired size for the icons
   local margin = 5     -- Spacing between icon and text
   local listYStart = y + 30
   local lineHeight = 20

   -- Determine how many items can be displayed in the available space.
   local availableHeight = height - 30
   local visibleItems = math.floor(availableHeight / lineHeight)
   local totalItems = #self.fileNames

   -- Clamp scrollOffset in case fileNames changed.
   self.scrollOffset = math.min(self.scrollOffset, math.max(totalItems - visibleItems, 0))

   -- Draw only visible file items.
   for i = 1, visibleItems do
       local fileIndex = self.scrollOffset + i
       if fileIndex > totalItems then break end
       local file = self.fileNames[fileIndex]
       local posY = listYStart + (i - 1) * lineHeight
       
       -- Determine the icon:
       local icon = self.fileIcon  -- default to file icon
       if file == ".." then
          icon = self.folderIcon
       else
          local node = self.cwd.children[file]
          if node and node.type == "directory" then
             icon = self.folderIcon
          end
       end
       
       -- Draw background highlight for the selected row.
       if fileIndex == self.selected then
           love.graphics.setColor(0.8, 0.8, 1)  -- Highlight color
           love.graphics.rectangle("fill", x + 10, posY, width - 20, lineHeight)
           love.graphics.setColor(0, 0, 0)
       else
           love.graphics.setColor(1, 1, 1)
       end
       
       -- Draw the icon scaled to iconSize.
       local scaleX = iconSize / icon:getWidth()
       local scaleY = iconSize / icon:getHeight()
       love.graphics.draw(icon, x + 15, posY + 2, 0, scaleX, scaleY)
       
       -- Draw the text offset by the icon width plus margin.
       love.graphics.setColor(0, 0, 0)
       love.graphics.print(file, x + 15 + iconSize + margin, posY + 2)
   end

   -- Draw scrollbar if needed.
   if totalItems > visibleItems then
       local scrollbarWidth = 10
       local scrollbarX = x + width - scrollbarWidth - 10
       local scrollbarY = listYStart
       local listAreaHeight = visibleItems * lineHeight
       love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
       love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, listAreaHeight)
       local maxScroll = totalItems - visibleItems
       local thumbHeight = (visibleItems / totalItems) * listAreaHeight
       local thumbY = scrollbarY + (self.scrollOffset / maxScroll) * (listAreaHeight - thumbHeight)
       love.graphics.setColor(0.8, 0.8, 0.8)
       love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight)
   end
end

function FilesApp:mousepressed(x, y, button)
   if button == 1 then
       local listYStart = 30
       local lineHeight = 20
       -- Calculate the relative index based on scrollOffset.
       local visibleIndex = math.floor((y - listYStart) / lineHeight) + 1
       local fileIndex = self.scrollOffset + visibleIndex
       if fileIndex >= 1 and fileIndex <= #self.fileNames then
           local currentTime = loveTimer.getTime()
           -- Check for double-click (within 0.3 seconds on the same index)
           if self.lastClickIndex == fileIndex and (currentTime - self.lastClickTime) < 0.3 then
               self:openSelectedEntry()
           else
               self.selected = fileIndex
           end
           self.lastClickTime = currentTime
           self.lastClickIndex = fileIndex
       end
   end
end

-- Handle key presses: Enter opens the entry; up/down changes the selection.
function FilesApp:keypressed(key)
   if key == "return" then
      self:openSelectedEntry()
   elseif key == "up" then
      if self.selected > 1 then
         self.selected = self.selected - 1
         -- Adjust scrollOffset if necessary.
         if self.selected <= self.scrollOffset then
            self.scrollOffset = self.selected - 1
         end
      end
   elseif key == "down" then
	  local listYStart = 30
	  local lineHeight = 20
	  local availableHeight = 280 - listYStart
	  local visibleItems = math.floor(availableHeight / lineHeight)
	  -- print(visibleIndex, self.selected)
      if self.selected < #self.fileNames then
         self.selected = self.selected + 1
         if self.selected > self.scrollOffset + visibleItems then
            self.scrollOffset = self.selected - visibleItems
         end
      end
   end
end

-- Opens the currently selected entry if it is a directory (or the ".." entry).
function FilesApp:openSelectedEntry()
   local entry = self.fileNames[self.selected]
   if entry == ".." then
      if self.cwd.parent then
         self.cwd = self.cwd.parent
         self:updateFileList()
      end
   else
      local node = self.cwd.children[entry]
      if node and node.type == "directory" then
         self.cwd = node
         self:updateFileList()
      elseif node and node.type == "file" then
		local ext = node.name:match("^.+(%..+)$") or ""
		ext = ext:lower()
	
	  if ext == ".obj" then
        -- Open in ObjViewer
        local ObjViewer = require("objviewer")
        local viewer = ObjViewer.new(filesystem.getPath(node), node)
        for i, app in ipairs(apps) do
            if app.name == "ObjViewer" then
                app.instance = viewer
                toggleApp(app)
                break
            end
        end
		elseif ext == ".png" or ext == ".jpg" or ext == ".jpeg" then
			-- Open in ImageViewer
			local viewer = ImageViewer.new(filesystem.getPath(node), node)
			for i, app in ipairs(apps) do
				if app.name == "ImageViewer" then
					app.instance = viewer
					toggleApp(app)
					break
				end
			end
		else
			 local editor = TextEditor.new(filesystem.getPath(node), node)
			 if node.content and node.content ~= "" then
				editor.lines = {}
				for line in node.content:gmatch("([^\n]*)\n?") do
				   table.insert(editor.lines, line)
				end
			 else
				editor.lines = {""}
			 end
			 editor.filename = entry
			 editor.fileNode = node  -- This should now stick.
			 -- Set the TextEditor app's instance to your custom editor
			 for i, app in ipairs(apps) do
				if app.name == "TextEditor" then
				   app.instance = editor
				   toggleApp(app)
				   break
				end
			 end
		end
      end
   end
end



-- Handle mouse wheel for scrolling the file list.
function FilesApp:wheelmoved(x, y)
   local totalItems = #self.fileNames
   local listYStart = 30
   local lineHeight = 20
   local availableHeight = 280 - listYStart
   local visibleItems = math.floor(availableHeight / lineHeight)
   local maxScroll = math.max(totalItems - visibleItems, 0)
   if y > 0 then
      self.scrollOffset = math.min(self.scrollOffset + 1, maxScroll)
   elseif y < 0 then
      self.scrollOffset = math.max(self.scrollOffset - 1, 0)
   end
end

function FilesApp:update(dt)
   -- For now, no dynamic updates are required.
end

return FilesApp
