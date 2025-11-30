-- settings.lua
local SettingsApp = {}
SettingsApp.__index = SettingsApp

function SettingsApp.new(availableWallpapers, currentWallpaper, onWallpaperChange)
    local self = setmetatable({}, SettingsApp)
    self.availableWallpapers = availableWallpapers or {}
    self.currentWallpaper = currentWallpaper or {}
    self.onWallpaperChange = onWallpaperChange or function() end
    self.tabs = {"Wallpaper", "Display", "System"}
    self.selectedTab = 1
    self.wallpaperPreviewSize = 120
    self.wallpaperGridColumns = 3
    self.wallpaperScroll = 0
    
    -- Mouse state tracking
    self.mouseX = 0
    self.mouseY = 0
    self.mousePressed = false
    
    -- Tab button dimensions
    self.tabHeight = 30
    self.tabWidth = 0  -- Will be set in draw
    
    -- Display settings
    self.resolutions = {
        {800, 600},
        {1024, 768},
        {1280, 720},
        {1366, 768},
        {1600, 900},
        {1920, 1080}
    }
    self.currentResolution = 1
    
    return self
end

function SettingsApp:setWallpaperTab()
    self.selectedTab = 1
end

function SettingsApp:draw(x, y, width, height)
    -- Draw background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Calculate tab dimensions
    self.tabWidth = width / #self.tabs
    
    -- Draw tabs
    for i, tab in ipairs(self.tabs) do
        if i == self.selectedTab then
            love.graphics.setColor(0.7, 0.7, 0.8)
        else
            love.graphics.setColor(0.8, 0.8, 0.9)
        end
        love.graphics.rectangle("fill", x + (i-1) * self.tabWidth, y, self.tabWidth, self.tabHeight)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(tab, x + (i-1) * self.tabWidth, y + 8, self.tabWidth, "center")
    end
    
    -- Draw tab content
    local contentY = y + self.tabHeight + 10
    local contentHeight = height - self.tabHeight - 10
    
    if self.selectedTab == 1 then
        self:drawWallpaperTab(x, contentY, width, contentHeight)
    elseif self.selectedTab == 2 then
        self:drawDisplayTab(x, contentY, width, contentHeight)
    elseif self.selectedTab == 3 then
        self:drawSystemTab(x, contentY, width, contentHeight)
    end
end

function SettingsApp:drawWallpaperTab(x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Select Wallpaper", x + 10, y)
    
    -- Calculate grid layout
    local padding = 10
    local availableWidth = width - 20
    local cols = self.wallpaperGridColumns
    local itemWidth = (availableWidth - (cols - 1) * padding) / cols
    local itemHeight = self.wallpaperPreviewSize + 30  -- Preview + label
    
    -- Calculate how many rows we have
    local rows = math.ceil(#self.availableWallpapers / cols)
    local totalContentHeight = rows * (itemHeight + padding)
    local maxScroll = math.max(0, totalContentHeight - height + 20)
    
    -- Apply scroll
    self.wallpaperScroll = math.min(self.wallpaperScroll, maxScroll)
    self.wallpaperScroll = math.max(0, self.wallpaperScroll)
    
    -- Set scissor for scrollable area
    love.graphics.setScissor(x, y + 30, width, height - 40)
    
    -- Draw wallpaper grid
    for i, wallpaper in ipairs(self.availableWallpapers) do
		-- print(i)
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        
        local itemX = x + 10 + col * (itemWidth + padding)
        local itemY = y + 30 + row * (itemHeight + padding) - self.wallpaperScroll
        
        -- Check if this is the current wallpaper
        local isCurrent = false
        if wallpaper.type == self.currentWallpaper.type then
            if wallpaper.type == "color" then
                isCurrent = self:colorsEqual(wallpaper.color, self.currentWallpaper.color)
            elseif wallpaper.type == "gradient" then
                isCurrent = self:colorsEqual(wallpaper.gradient.top, self.currentWallpaper.gradient.top) and
                           self:colorsEqual(wallpaper.gradient.bottom, self.currentWallpaper.gradient.bottom)
            elseif wallpaper.type == "image" then
                isCurrent = wallpaper.filename == self.currentWallpaper.filename
            end
        end
        
        -- Draw selection border
        if isCurrent then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.rectangle("fill", itemX - 2, itemY - 2, itemWidth + 4, itemHeight + 4)
        end
        
        -- Draw preview background
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
        
        -- Draw wallpaper preview
        if wallpaper.type == "color" then
            love.graphics.setColor(wallpaper.color)
            love.graphics.rectangle("fill", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
        elseif wallpaper.type == "gradient" then
            -- Simple gradient preview
            for py = 0, self.wallpaperPreviewSize do
                local ratio = py / self.wallpaperPreviewSize
                local r = wallpaper.gradient.top[1] * (1 - ratio) + wallpaper.gradient.bottom[1] * ratio
                local g = wallpaper.gradient.top[2] * (1 - ratio) + wallpaper.gradient.bottom[2] * ratio
                local b = wallpaper.gradient.top[3] * (1 - ratio) + wallpaper.gradient.bottom[3] * ratio
                love.graphics.setColor(r, g, b)
                love.graphics.line(itemX, itemY + py, itemX + itemWidth, itemY + py)
            end
        elseif wallpaper.type == "image" and wallpaper.image then
            love.graphics.setColor(1, 1, 1)
            local scale = math.min(
                itemWidth / wallpaper.image:getWidth(),
                self.wallpaperPreviewSize / wallpaper.image:getHeight()
            )
            local drawWidth = wallpaper.image:getWidth() * scale
            local drawHeight = wallpaper.image:getHeight() * scale
            local offsetX = (itemWidth - drawWidth) / 2
            local offsetY = (self.wallpaperPreviewSize - drawHeight) / 2
            love.graphics.draw(wallpaper.image, itemX + offsetX, itemY + offsetY, 0, scale, scale)
        end
        
        -- Draw border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
        
        -- Draw label
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(wallpaper.name, itemX, itemY + self.wallpaperPreviewSize + 5, itemWidth, "center")
    end
    
    love.graphics.setScissor()
    
    -- Draw scrollbar if needed
    if maxScroll > 0 then
        local scrollbarWidth = 10
        local scrollbarX = x + width - scrollbarWidth - 5
        local scrollTrackHeight = height - 40
        local thumbHeight = (height / totalContentHeight) * scrollTrackHeight
        local thumbY = y + 30 + (self.wallpaperScroll / maxScroll) * (scrollTrackHeight - thumbHeight)
        
        -- Scroll track
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", scrollbarX, y + 30, scrollbarWidth, scrollTrackHeight)
        
        -- Scroll thumb
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight)
    end
    
    -- Draw current wallpaper info
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Current Wallpaper: " .. self:getCurrentWallpaperName(), x + 10, y + height - 20)
end

function SettingsApp:drawDisplayTab(x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Display Settings", x + 10, y)
    
    -- Current resolution
    local res = self.resolutions[self.currentResolution]
    love.graphics.print("Resolution: " .. res[1] .. "x" .. res[2], x + 20, y + 40)
    
    -- Resolution buttons
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 20, y + 70, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Previous", x + 40, y + 78)
    
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 150, y + 70, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Next", x + 185, y + 78)
    
    -- Fullscreen status
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Fullscreen: " .. (love.window.getFullscreen() and "Yes" or "No"), x + 20, y + 120)
    
    -- Fullscreen toggle button
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 20, y + 150, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Toggle Fullscreen", x + 30, y + 158)
    
    -- VSync setting
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("VSync: " .. (love.window.getVSync() and "Enabled" or "Disabled"), x + 20, y + 200)
    
    -- VSync toggle button
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 20, y + 230, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Toggle VSync", x + 40, y + 238)
end

function SettingsApp:drawSystemTab(x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("System Information", x + 10, y)
    
    -- System info
    love.graphics.print("OS: " .. love.system.getOS(), x + 20, y + 40)
    love.graphics.print("Love2D Version: " .. love.getVersion(), x + 20, y + 70)
    
    -- Performance info
    love.graphics.print(string.format("FPS: %.0f", love.timer.getFPS()), x + 20, y + 100)
    love.graphics.print(string.format("Memory: %.2f MB", collectgarbage("count") / 1024), x + 20, y + 130)
    
    -- GPU info
    local stats = love.graphics.getStats()
    love.graphics.print(string.format("Draw Calls: %d", stats.drawcalls), x + 20, y + 160)
    love.graphics.print(string.format("Texture Memory: %.2f MB", stats.texturememory / 1024 / 1024), x + 20, y + 190)
    
    -- Garbage collection buttons
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 20, y + 230, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Run GC", x + 50, y + 238)
    
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("fill", x + 150, y + 230, 120, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Reset Stats", x + 165, y + 238)
end

function SettingsApp:getCurrentWallpaperName()
    for _, wallpaper in ipairs(self.availableWallpapers) do
        if wallpaper.type == self.currentWallpaper.type then
            if wallpaper.type == "color" and self:colorsEqual(wallpaper.color, self.currentWallpaper.color) then
                return wallpaper.name
            elseif wallpaper.type == "gradient" and 
                   self:colorsEqual(wallpaper.gradient.top, self.currentWallpaper.gradient.top) and
                   self:colorsEqual(wallpaper.gradient.bottom, self.currentWallpaper.gradient.bottom) then
                return wallpaper.name
            elseif wallpaper.type == "image" and wallpaper.filename == self.currentWallpaper.filename then
                return wallpaper.name
            end
        end
    end
    return "Custom"
end

function SettingsApp:colorsEqual(c1, c2)
    return c1[1] == c2[1] and c1[2] == c2[2] and c1[3] == c2[3]
end

function SettingsApp:mousepressed(mx, my, button, wx, wy)
    self.mousePressed = true
    
    -- Handle tab clicks
    if my <= self.tabHeight then
        for i = 1, #self.tabs do
            if mx >= (i-1) * self.tabWidth and mx <= i * self.tabWidth then
                self.selectedTab = i
                return
            end
        end
    end
    
    -- Handle tab-specific clicks
    if self.selectedTab == 1 then
        self:handleWallpaperTabClick(mx, my, wx, wy)
    elseif self.selectedTab == 2 then
        self:handleDisplayTabClick(mx, my, wx, wy)
    elseif self.selectedTab == 3 then
        self:handleSystemTabClick(mx, my, wx, wy)
    end
end

function SettingsApp:mousemoved(mx, my, dx, dy)
    self.mouseX = mx
    self.mouseY = my
end

function SettingsApp:mousereleased(mx, my, button)
    self.mousePressed = false
end

function SettingsApp:handleWallpaperTabClick(mx, my, wx, wy)
    local padding = 10
    local availableWidth = wx - 20
    local cols = self.wallpaperGridColumns
    local itemWidth = (availableWidth - (cols - 1) * padding) / cols
    local itemHeight = self.wallpaperPreviewSize + 30
    
    for i, wallpaper in ipairs(self.availableWallpapers) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        
        local itemX = 10 + col * (itemWidth + padding)
        local itemY = 70 + row * (itemHeight + padding) - self.wallpaperScroll
        
        if mx >= itemX and mx <= itemX + itemWidth and
           my >= itemY and my <= itemY + itemHeight then
            self.currentWallpaper = {
                type = wallpaper.type,
                color = wallpaper.color,
                gradient = wallpaper.gradient,
                image = wallpaper.image,
                filename = wallpaper.filename
            }
            self.onWallpaperChange(self.currentWallpaper)
            break
        end
    end
end

function SettingsApp:handleDisplayTabClick(mx, my, wx, wy)
    -- Previous resolution button
    if mx >= 20 and mx <= 140 and my >= 70 and my <= 100 then
        self.currentResolution = self.currentResolution - 1
        if self.currentResolution < 1 then
            self.currentResolution = #self.resolutions
        end
        local res = self.resolutions[self.currentResolution]
        love.window.setMode(res[1], res[2])
    end
    
    -- Next resolution button
    if mx >= 150 and mx <= 270 and my >= 70 and my <= 100 then
        self.currentResolution = self.currentResolution + 1
        if self.currentResolution > #self.resolutions then
            self.currentResolution = 1
        end
        local res = self.resolutions[self.currentResolution]
        love.window.setMode(res[1], res[2])
    end
    
    -- Fullscreen toggle button
    if mx >= 20 and mx <= 140 and my >= 150 and my <= 180 then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    
    -- VSync toggle button
    if mx >= 20 and mx <= 140 and my >= 230 and my <= 260 then
        love.window.setVSync(love.window.getVSync() == 1 and 0 or 1)
    end
end

function SettingsApp:handleSystemTabClick(mx, my, wx, wy)
    -- Run GC button
    if mx >= 20 and mx <= 140 and my >= 230 and my <= 260 then
        collectgarbage("collect")
    end
    
    -- Reset Stats button (placeholder - would need custom implementation)
    if mx >= 150 and mx <= 270 and my >= 230 and my <= 260 then
        -- This would reset custom performance tracking if implemented
    end
end

function SettingsApp:wheelmoved(x, y)
    if self.selectedTab == 1 then
        self.wallpaperScroll = self.wallpaperScroll - y * 20
        local totalContentHeight = math.ceil(#self.availableWallpapers / self.wallpaperGridColumns) * (self.wallpaperPreviewSize + 40)
        local maxScroll = math.max(0, totalContentHeight - (love.graphics.getHeight() - 150))
        self.wallpaperScroll = math.max(0, math.min(self.wallpaperScroll, maxScroll))
    end
end

function SettingsApp:keypressed(key)
    -- Tab navigation with keyboard
    if key == "tab" then
        self.selectedTab = self.selectedTab + 1
        if self.selectedTab > #self.tabs then
            self.selectedTab = 1
        end
    elseif key == "left" then
        if self.selectedTab > 1 then
            self.selectedTab = self.selectedTab - 1
        end
    elseif key == "right" then
        if self.selectedTab < #self.tabs then
            self.selectedTab = self.selectedTab + 1
        end
    end
    
    -- Wallpaper tab shortcuts
    if self.selectedTab == 1 then
        if key == "up" then
            self.wallpaperScroll = math.max(0, self.wallpaperScroll - 50)
        elseif key == "down" then
            local totalContentHeight = math.ceil(#self.availableWallpapers / self.wallpaperGridColumns) * (self.wallpaperPreviewSize + 40)
            local maxScroll = math.max(0, totalContentHeight - (love.graphics.getHeight() - 150))
            self.wallpaperScroll = math.min(maxScroll, self.wallpaperScroll + 50)
        elseif key == "home" then
            self.wallpaperScroll = 0
        elseif key == "end" then
            local totalContentHeight = math.ceil(#self.availableWallpapers / self.wallpaperGridColumns) * (self.wallpaperPreviewSize + 40)
            local maxScroll = math.max(0, totalContentHeight - (love.graphics.getHeight() - 150))
            self.wallpaperScroll = maxScroll
        end
    end
    
    -- Display tab shortcuts
    if self.selectedTab == 2 then
        if key == "f" then
            love.window.setFullscreen(not love.window.getFullscreen())
        elseif key == "v" then
            love.window.setVSync(love.window.getVSync() == 1 and 0 or 1)
        end
    end
    
    -- System tab shortcuts
    if self.selectedTab == 3 then
        if key == "g" then
            collectgarbage("collect")
        end
    end
    
    -- Escape to close settings (this would need to be handled by main.lua)
    if key == "escape" then
        -- This would need to communicate with main.lua to close the window
    end
end

function SettingsApp:textinput(text)
    -- Handle text input if needed for any settings
end

function SettingsApp:update(dt)
    -- Update any animations or real-time info
end

function SettingsApp:resize(w, h)
    -- Handle window resize if needed
end

return SettingsApp