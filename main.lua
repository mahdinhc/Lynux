-- main.lua
local moonshine = require 'lib/moonshine'
local EmailApp = require("email")
local BrowserApp = require("browser")
local FilesApp = require("files")
local TerminalApp = require("terminal") 
local RouletteApp = require("roulette")
local TextEditor = require("texteditor")
local DinoApp = require("dino")
local TessarectApp = require("tessarect")
local ImageViewer = require("imageviewer")
local ObjViewer = require("objviewer")
local NexusAI = require("nexusai")
local filesystemModule = require("filesystem")
-- local Demoji = require("demoji")  -- require Demoji module

effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt)
effect.scanlines.opacity = 0.6

focusedWindow = nil  -- global variable tracking the focused window

-- Constants for window resizing.
local MIN_WINDOW_WIDTH = 300
local MIN_WINDOW_HEIGHT = 200
local MAX_WINDOW_WIDTH = 1000
local MAX_WINDOW_HEIGHT = 800

local draggingWindow = nil
local dragOffsetX = 0
local dragOffsetY = 0

local resizingWindow = nil
local resizeOffsetX = 0
local resizeOffsetY = 0
local effectEnabled = false
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

desktopHomeIcons = {}
desktopLayout = {}
draggingIcon = nil
dragIconOffsetX = 0
dragIconOffsetY = 0
startMenuOpen = false
ellipsisMenuOpen = false
visibleApps = {}
hiddenApps = {}

-- Start menu scroll variables
local startMenuScroll = 0
local startMenuMaxScroll = 0
local scrollBarHeight = 0
local scrollBarDragging = false
local scrollBarDragOffset = 0

-- Utility function to set focus on a window.
local function setFocus(window)
    for i, win in ipairs(openApps) do
        if win == window then
            table.remove(openApps, i)
            break
        end
    end
    table.insert(openApps, window)
    focusedWindow = window
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Desktop")
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    
    font = love.graphics.newFont("font/Nunito-Regular.ttf", 13)
    topBarHeight = 30
    bottomBarHeight = 40

    -- Load PNG icons.
	home_folderIcon = love.graphics.newImage("assets/folder.png")
	home_fileIcon   = love.graphics.newImage("assets/file.png")
	home_shortcutIcon = love.graphics.newImage("assets/shortcut.png")
    emailIcon = love.graphics.newImage("assets/email.png")
    browserIcon = love.graphics.newImage("assets/browser.png")
    filesIcon = love.graphics.newImage("assets/files.png")
    terminalIcon = love.graphics.newImage("assets/terminal.png")
    rouletteIcon = love.graphics.newImage("assets/roulette.png")
    texteditorIcon = love.graphics.newImage("assets/file.png")
    tessarectIcon = love.graphics.newImage("assets/cube.png")
    dinoIcon = love.graphics.newImage("assets/dino.png")
    chatIcon = love.graphics.newImage("assets/chat.png")
    imageviewerIcon = love.graphics.newImage("assets/image.png")
    startIcon = love.graphics.newImage("assets/layers.png")
    ellipsisIcon = love.graphics.newImage("assets/option.png")
    
    local sharedFS = filesystemModule.getFS()
    -- Ensure there is a "/home" folder in the root.
    if not sharedFS.children["home"] then
        sharedFS.children["home"] = { 
            name = "home", 
            type = "directory", 
            parent = sharedFS, 
            children = {} 
        }
    end
    desktopHome = sharedFS.children["home"]
    
    -- Load desktop layout
    if love.filesystem.getInfo("desktop_layout.json") then
        local data = love.filesystem.read("desktop_layout.json")
        desktopLayout = json.decode(data) or {}
    end

    apps = {
        { name = "Email", module = EmailApp, instance = nil, icon = emailIcon },
        { name = "Browser", module = BrowserApp, instance = nil, icon = browserIcon },
        { name = "Files", module = FilesApp, instance = nil, icon = filesIcon },
        { name = "Terminal", module = TerminalApp, instance = nil, icon = terminalIcon },
        { name = "Roulette", module = RouletteApp, instance = nil, icon = rouletteIcon },
        { name = "TextEditor", module = TextEditor, instance = nil, icon = texteditorIcon },
        { name = "Tessarect", module = TessarectApp, instance = nil, icon = tessarectIcon },
        { name = "Dino", module = DinoApp, instance = nil, icon = dinoIcon },
		{ name = "ImageViewer", module = ImageViewer, instance = nil, icon = imageviewerIcon },
		{ name = "ObjViewer", module = ObjViewer, instance = nil, icon = tessarectIcon },
		{ name = "NexusAI", module = NexusAI, instance = nil, icon = chatIcon },
    }

    iconWidth = 40
    iconHeight = 40
    iconSpacing = 8
    local startX = iconSpacing + 40  -- Space for start button
    for i, app in ipairs(apps) do
        app.x = startX
        app.y = love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - iconHeight) / 2
        app.width = iconWidth
        app.height = iconHeight
        startX = startX + iconWidth + iconSpacing
    end

    openApps = {}  -- List of open windows
    -- Instantiate Demoji.
    -- demojiInstance = Demoji.new()
    
    -- Calculate visible apps for ellipsis menu
    updateVisibleApps()
end

function updateVisibleApps()
    local availableWidth = love.graphics.getWidth() - 120  -- Space for start button and ellipsis
    local currentX = 80  -- Start after start button
    visibleApps = {}
    hiddenApps = {}
    
    for i, app in ipairs(apps) do
        if currentX + app.width <= availableWidth then
            table.insert(visibleApps, app)
            currentX = currentX + app.width + iconSpacing
        else
            table.insert(hiddenApps, app)
        end
    end
end

function love.update(dt)
    for _, window in ipairs(openApps) do
        if window.instance and window.instance.update then
            window.instance:update(dt)
        end
    end
    -- demojiInstance:update(dt)
end

function love.draw()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
    
    if effectEnabled then
        effect(function()
            drawDesktop()
        end)
    else
        drawDesktop()
    end
end

-- Draw the desktop and also draw the home folder icons.
function drawDesktop()
    love.graphics.clear(0.15, 0.25, 0.35)  -- Darker blue background
    love.graphics.setFont(font)
    
    -- Draw top bar (date/time).
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), topBarHeight)
    love.graphics.setColor(0.7, 0.8, 1.0)
    local currentTime = os.date("%H:%M:%S")
    local currentDate = os.date("%Y-%m-%d")
    love.graphics.print(currentDate .. " " .. currentTime, 10, 8)
    
    -- Draw the desktop "home" area.
    drawDesktopHome()
    
    -- Draw bottom bar (app icons).
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, love.graphics.getWidth(), bottomBarHeight)
    
    -- Draw start button
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, 40, bottomBarHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(startIcon, 10, love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - 30) / 2, 0, 30/startIcon:getWidth(), 30/startIcon:getHeight())
    
    -- Draw visible app icons
    for _, app in ipairs(visibleApps) do
        local state = "closed"
        for _, window in ipairs(openApps) do
            if window.app == app then
                if window.minimized then
                    state = "minimized"
                else
                    state = "maximized"
                end
                break
            end
        end
        
        local iconMargin = 1
        local targetIconHeight = app.height - iconMargin * 2
        local scale = targetIconHeight / app.icon:getHeight()
        local iconSize = targetIconHeight  -- this will be the square size

        -- draw background square
        if state == "maximized" then
            love.graphics.setColor(0.3, 0.4, 0.5)
			love.graphics.rectangle("fill", app.x, app.y, iconSize + iconMargin * 2, iconSize + iconMargin * 2)
        elseif state == "minimized" then
			love.graphics.setColor(0.2, 0.3, 0.4)
			love.graphics.rectangle("fill", app.x, app.y, iconSize + iconMargin * 2, iconSize + iconMargin * 2)
        end

		-- draw the icon
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(app.icon, app.x + iconMargin, app.y + iconMargin, 0, scale, scale)
    end
    
    -- Draw ellipsis button if there are hidden apps
    if #hiddenApps > 0 then
        local ellipsisX = love.graphics.getWidth() - 40
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", ellipsisX, love.graphics.getHeight() - bottomBarHeight, 40, bottomBarHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(ellipsisIcon, ellipsisX + 10, love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - 30) / 2, 0, 30/ellipsisIcon:getWidth(), 30/ellipsisIcon:getHeight())
    end

    -- Draw ellipsis menu if open
    if ellipsisMenuOpen then
        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
        local menuX = love.graphics.getWidth() - 160
        local menuY = love.graphics.getHeight() - bottomBarHeight - #hiddenApps * 40 - 10
        local menuWidth = 150
        local menuHeight = #hiddenApps * 40 + 10
        love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
        love.graphics.setColor(0.7, 0.8, 1.0)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        for i, app in ipairs(hiddenApps) do
            local appY = menuY + 5 + (i-1)*40
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", menuX + 5, appY, 140, 35)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(app.icon, menuX + 10, appY + 5, 0, 25/app.icon:getWidth(), 25/app.icon:getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(app.name, menuX + 40, appY + 10)
        end
    end
    
    -- Draw start menu if open
    if startMenuOpen then
        local menuX = 5
        local menuY = love.graphics.getHeight() - bottomBarHeight - 300
        local menuWidth = 300
        local menuHeight = 300
        
        -- Calculate content height
        local headerHeight = 40
        local cols = 3
        local iconSize = 80
        local padding = 10
        local rows = math.ceil(#apps / cols)
        local contentHeight = headerHeight + rows * (iconSize + padding) + padding
        
        -- Update max scroll
        startMenuMaxScroll = math.max(0, contentHeight - menuHeight)
        
        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
        love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
        love.graphics.setColor(0.7, 0.8, 1.0)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        -- Set scissor for content area
        love.graphics.setScissor(menuX, menuY + headerHeight, menuWidth - 15, menuHeight - headerHeight)
        
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(0.7, 0.8, 1.0)
        love.graphics.print("Applications", menuX + 10, menuY + 10 - startMenuScroll)
        love.graphics.setFont(font)
        
        -- Draw apps in grid with scroll offset
        for i, app in ipairs(apps) do
            local col = (i-1) % cols
            local row = math.floor((i-1) / cols)
            local x = menuX + 15 + col * (iconSize + padding)
            local y = menuY + headerHeight + 5 + row * (iconSize + padding) - startMenuScroll
            
            love.graphics.setColor(0.3, 0.4, 0.5, 0.8)
            love.graphics.rectangle("fill", x, y, iconSize, iconSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(app.icon, x + (iconSize - 40)/2, y + 10, 0, 40/app.icon:getWidth(), 40/app.icon:getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(app.name, x, y + 55, iconSize, "center")
        end
        
        love.graphics.setScissor()
        
        -- Draw scrollbar if needed
        if startMenuMaxScroll > 0 then
            local scrollBarWidth = 10
            local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
            local scrollTrackHeight = menuHeight - headerHeight
            scrollBarHeight = (menuHeight / contentHeight) * scrollTrackHeight
            
            -- Scroll track
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", scrollBarX, menuY + headerHeight, scrollBarWidth, scrollTrackHeight)
            
            -- Scroll thumb
            local scrollThumbY = menuY + headerHeight + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
            love.graphics.setColor(0.5, 0.6, 0.7, 0.8)
            love.graphics.rectangle("fill", scrollBarX, scrollThumbY, scrollBarWidth, scrollBarHeight)
        end
    end

    -- Draw open app windows (existing code unchanged).
    for _, window in ipairs(openApps) do
        if not window.minimized then
            love.graphics.setFont(font)
            love.graphics.setColor(0.9, 0.9, 0.95)
            love.graphics.rectangle("fill", window.x, window.y, window.width, window.height)
            
            if window == focusedWindow then
                love.graphics.setColor(0.0, 0.5, 1.0)
            else
                love.graphics.setColor(0.2, 0.3, 0.4)
            end
            love.graphics.rectangle("fill", window.x, window.y, window.width, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(window.app.name, window.x + 5, window.y + 2)
            
            local btnSize = 20
            local closeX = window.x + window.width - btnSize
            local minX = window.x + window.width - 2 * btnSize
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.rectangle("fill", closeX, window.y, btnSize, btnSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("x", closeX + 5, window.y + 2)
            
            love.graphics.setColor(0.7, 0.8, 1.0)
            love.graphics.rectangle("fill", minX, window.y, btnSize, btnSize)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print("-", minX + 5, window.y + 2)
            
            if window.instance and window.instance.draw then
                love.graphics.setScissor(window.x, window.y+20, window.width, window.height-20)
				love.graphics.push()
                window.instance:draw(window.x, window.y + 20, window.width, window.height - 20)
				love.graphics.pop()
                love.graphics.setScissor()
            else
                love.graphics.setColor(0, 0, 0)
                love.graphics.print("Content of " .. window.app.name, window.x + 10, window.y + 30)
            end
            
            local handleSize = 10
            love.graphics.setColor(0.5, 0.6, 0.7)
            love.graphics.rectangle("fill", window.x + window.width - handleSize, window.y + window.height - handleSize, handleSize, handleSize)
        end
    end
end

-- Draw desktop home icons (children of /home) using saved layout.
function drawDesktopHome()
    desktopHomeIcons = {}  -- reset icons table
    local startX = 10
    local startY = topBarHeight + 10
    local iconSize = 40
    local padding = 20
    local index = 0
    if desktopHome and desktopHome.children then
        -- Iterate through children in /home.
        for name, node in pairs(desktopHome.children) do
            index = index + 1
            local x, y
            if desktopLayout[name] then
                x = desktopLayout[name].x
                y = desktopLayout[name].y
            else
                local col = (index - 1) % 4
                local row = math.floor((index - 1) / 4)
                x = startX + col * (iconSize + padding)
                y = startY + row * (iconSize + padding)
                desktopLayout[name] = {x = x, y = y}
            end
            local icon = home_fileIcon  -- default to file icon
            if node.type == "directory" then
                icon = home_folderIcon
            elseif node.name:match("%.lnk$") then
                icon = home_shortcutIcon
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            love.graphics.setColor(0.9, 0.95, 1.0)
            love.graphics.printf(name, x, y + iconSize + 2, iconSize, "center")
            -- Save icon's bounding box and node for click detection.
            table.insert(desktopHomeIcons, {x = x, y = y, width = iconSize, height = iconSize, node = node, name = name})
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check start button
        if x >= 0 and x <= 40 and y >= love.graphics.getHeight() - bottomBarHeight then
            startMenuOpen = not startMenuOpen
            ellipsisMenuOpen = false
            return
        end
        
        -- Check ellipsis button
        if #hiddenApps > 0 and x >= love.graphics.getWidth() - 40 and x <= love.graphics.getWidth() and y >= love.graphics.getHeight() - bottomBarHeight then
            ellipsisMenuOpen = not ellipsisMenuOpen
            startMenuOpen = false
            return
        end
        
        -- Check ellipsis menu
        if ellipsisMenuOpen then
            local menuX = love.graphics.getWidth() - 160
            local menuY = love.graphics.getHeight() - bottomBarHeight - #hiddenApps * 40 - 10
            for i, app in ipairs(hiddenApps) do
                local appY = menuY + 5 + (i-1)*40
                if x >= menuX + 5 and x <= menuX + 145 and y >= appY and y <= appY + 35 then
                    toggleApp(app)
                    ellipsisMenuOpen = false
                    return
                end
            end
            -- Clicked outside menu, close it
            ellipsisMenuOpen = false
        end
        
        -- Check start menu
        if startMenuOpen then
            local menuX = 5
            local menuY = love.graphics.getHeight() - bottomBarHeight - 300
            local menuWidth = 300
            local headerHeight = 40
            
            -- Check scrollbar
            if startMenuMaxScroll > 0 then
                local scrollBarWidth = 10
                local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
                local scrollTrackHeight = 300 - headerHeight
                local scrollThumbY = menuY + headerHeight + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
                
                if x >= scrollBarX and x <= scrollBarX + scrollBarWidth and 
                   y >= scrollThumbY and y <= scrollThumbY + scrollBarHeight then
                    scrollBarDragging = true
                    scrollBarDragOffset = y - scrollThumbY
                    return
                end
            end
            
            -- Check app icons
            local cols = 3
            local iconSize = 80
            local padding = 10
            for i, app in ipairs(apps) do
                local col = (i-1) % cols
                local row = math.floor((i-1) / cols)
                local appX = menuX + 15 + col * (iconSize + padding)
                local appY = menuY + headerHeight + 5 + row * (iconSize + padding) - startMenuScroll
                
                if x >= appX and x <= appX + iconSize and y >= appY and y <= appY + iconSize then
                    toggleApp(app)
                    startMenuOpen = false
                    return
                end
            end
            -- Clicked outside menu, close it
            startMenuOpen = false
        end
        
        -- Check if the click is in the desktop home area.
        for _, icon in ipairs(desktopHomeIcons) do
            if x >= icon.x and x <= icon.x + icon.width and y >= icon.y and y <= icon.y + icon.height then
                -- Found a desktop icon click. 
                if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                    -- Start dragging the icon
                    draggingIcon = icon
                    dragIconOffsetX = x - icon.x
                    dragIconOffsetY = y - icon.y
                    return
                else
                    -- Open FilesApp at icon.node.
                    local FilesApp = require("files")
                    local fileExplorer = FilesApp.new(apps, toggleApp)
                    fileExplorer.cwd = icon.node  -- set explorer to this folder or file's parent.
                    fileExplorer:updateFileList()
                    -- Toggle FilesApp.
                    for i, app in ipairs(apps) do
                        if app.name == "Files" then
                            app.instance = fileExplorer
                            toggleApp(app)
                            break
                        end
                    end
                    return  -- consume the click.
                end
            end
        end
        -- First, dispatch to Demoji.
        -- if demojiInstance:mousepressed(x, y, button) then
            -- return  -- if Demoji consumed the click, don't process further.
        -- end

        local resizeHandleSize = 20
        for _, window in ipairs(openApps) do
            if not window.minimized then
                if x >= window.x + window.width - resizeHandleSize and x <= window.x + window.width and
                   y >= window.y + window.height - resizeHandleSize and y <= window.y + window.height then
                    resizingWindow = window
                    resizeOffsetX = window.x + window.width - x
                    resizeOffsetY = window.y + window.height - y
                    return
                end
            end
        end

        if focusedWindow and not focusedWindow.minimized then
            if x >= focusedWindow.x and x <= focusedWindow.x + focusedWindow.width and
               y >= focusedWindow.y and y <= focusedWindow.y + focusedWindow.height then
                local btnSize = 20
                local closeX = focusedWindow.x + focusedWindow.width - btnSize
                local minX = focusedWindow.x + focusedWindow.width - 2 * btnSize
                if x >= closeX and x <= closeX + btnSize and y >= focusedWindow.y and y <= focusedWindow.y + btnSize then
                    for i, win in ipairs(openApps) do
                        if win == focusedWindow then
                            table.remove(openApps, i)
                            focusedWindow.app.instance = nil
                            focusedWindow = nil
                            break
                        end
                    end
                    return
                elseif x >= minX and x <= minX + btnSize and y >= focusedWindow.y and y <= focusedWindow.y + btnSize then
                    focusedWindow.minimized = not focusedWindow.minimized
                    setFocus(focusedWindow)
                    return
                end
                if x >= focusedWindow.x and x <= focusedWindow.x + focusedWindow.width and
                   y >= focusedWindow.y and y <= focusedWindow.y + 20 then
                    if x < focusedWindow.x + focusedWindow.width - 2 * btnSize then
                        setFocus(focusedWindow)
                        draggingWindow = focusedWindow
                        dragOffsetX = x - focusedWindow.x
                        dragOffsetY = y - focusedWindow.y
                        return
                    end
                end
                if x >= focusedWindow.x and x <= focusedWindow.x + focusedWindow.width and
                   y >= focusedWindow.y + 20 and y <= focusedWindow.y + focusedWindow.height then
                    if focusedWindow.instance and focusedWindow.instance.mousepressed then
                        focusedWindow.instance:mousepressed(x - focusedWindow.x, y - focusedWindow.y - 20, button, x, y)
                    end
                end
                return
            end
        end

        for _, window in ipairs(openApps) do
            local btnSize = 20
            local closeX = window.x + window.width - btnSize
            local minX = window.x + window.width - 2 * btnSize
            if x >= closeX and x <= closeX + btnSize and y >= window.y and y <= window.y + btnSize then
                if focusedWindow == window then focusedWindow = nil end
                for i2, win in ipairs(openApps) do
                    if win == window then
                        table.remove(openApps, i2)
                        window.app.instance = nil
                        break
                    end
                end
                return
            elseif x >= minX and x <= minX + btnSize and y >= window.y and y <= window.y + btnSize then
                window.minimized = not window.minimized
                setFocus(window)
                return
            end
        end

        for _, window in ipairs(openApps) do
            if x >= window.x and x <= window.x + window.width and
               y >= window.y and y <= window.y + 20 then
                local btnSize = 20
                if x < window.x + window.width - 2 * btnSize then
                    setFocus(window)
                    draggingWindow = window
                    dragOffsetX = x - window.x
                    dragOffsetY = y - window.y
                    return
                end
            end
        end

        for _, window in ipairs(openApps) do
            if not window.minimized then
                if x >= window.x and x <= window.x + window.width and
                   y >= window.y + 20 and y <= window.y + window.height then
                    setFocus(window)
                    if window.instance and window.instance.mousepressed then
                        window.instance:mousepressed(x - window.x, y - window.y - 20, button, x, y)
                        return
                    end
                end
            end
        end

        for _, app in ipairs(visibleApps) do
            if x >= app.x and x <= app.x + app.width and
               y >= app.y and y <= app.y + app.height then
                toggleApp(app)
                return
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if resizingWindow then
        local newWidth = x + resizeOffsetX - resizingWindow.x
        local newHeight = y + resizeOffsetY - resizingWindow.y
        newWidth = math.max(MIN_WINDOW_WIDTH, math.min(newWidth, MAX_WINDOW_WIDTH))
        newHeight = math.max(MIN_WINDOW_HEIGHT, math.min(newHeight, MAX_WINDOW_HEIGHT))
        resizingWindow.width = newWidth
        resizingWindow.height = newHeight
    elseif draggingWindow then
        draggingWindow.x = x - dragOffsetX
        draggingWindow.y = y - dragOffsetY
    elseif draggingIcon then
        desktopLayout[draggingIcon.name].x = x - dragIconOffsetX
        desktopLayout[draggingIcon.name].y = y - dragIconOffsetY
    elseif scrollBarDragging then
        local menuY = love.graphics.getHeight() - bottomBarHeight - 300
        local headerHeight = 40
        local scrollTrackHeight = 300 - headerHeight
        local relativeY = y - menuY - headerHeight - scrollBarDragOffset
        startMenuScroll = (relativeY / (scrollTrackHeight - scrollBarHeight)) * startMenuMaxScroll
        startMenuScroll = math.max(0, math.min(startMenuScroll, startMenuMaxScroll))
    end
	
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousemoved then
        focusedWindow.instance:mousemoved(x, y, dx, dy)
    end
    -- Pass mouse movement to Demoji.
    -- demojiInstance:mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    if button == 1 then
        draggingWindow = nil
        resizingWindow = nil
        scrollBarDragging = false
        if draggingIcon then
            draggingIcon = nil
            -- Save desktop layout
            local data = json.encode(desktopLayout)
            love.filesystem.write("desktop_layout.json", data)
        end
        -- demojiInstance:mousereleased(x, y, button)
    end
	
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousereleased then
        focusedWindow.instance:mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if startMenuOpen then
        startMenuScroll = startMenuScroll - y * 20
        startMenuScroll = math.max(0, math.min(startMenuScroll, startMenuMaxScroll))
        return
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.wheelmoved then
        focusedWindow.instance:wheelmoved(x, y)
    end
end

function love.textinput(text)
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.textinput then
        focusedWindow.instance:textinput(text)
    end
end

function love.keypressed(key)
    if key == "g" then
        effectEnabled = not effectEnabled
    end
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.keypressed then
        focusedWindow.instance:keypressed(key)
    end
end

function love.resize(w, h)
    for _, window in ipairs(openApps) do
        if window.instance and window.instance.resize then
            window.instance:resize(w, h)
        end
    end
    updateVisibleApps()
end

function toggleApp(app)
    local found = nil
    for _, window in ipairs(openApps) do
        if window.app == app then
            found = window
            break
        end
    end

    if found then
        found.minimized = not found.minimized
        setFocus(found)
    else
        -- For TextEditor, check if an instance already exists:
        if (app.name == "TextEditor" or app.name == "ImageViewer" or app.name == "ObjViewer" ) and app.instance then
            -- Do not create a new instance; just open the existing one.
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local windowWidth = 500
            local windowHeight = 300
            local x = (screenWidth - windowWidth) / 2
            local y = topBarHeight + ((screenHeight - topBarHeight - bottomBarHeight) - windowHeight) / 2
            local newWindow = { app = app, instance = app.instance, x = x, y = y, width = windowWidth, height = windowHeight, minimized = false }
            table.insert(openApps, newWindow)
            setFocus(newWindow)
        else
            app.instance = app.module.new()
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local windowWidth = 500
            local windowHeight = 300
            local x = (screenWidth - windowWidth) / 2
            local y = topBarHeight + ((screenHeight - topBarHeight - bottomBarHeight) - windowHeight) / 2
            local newWindow = { app = app, instance = app.instance, x = x, y = y, width = windowWidth, height = windowHeight, minimized = false }
            table.insert(openApps, newWindow)
            setFocus(newWindow)
        end
    end
end