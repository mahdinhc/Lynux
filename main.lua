local moonshine = require 'lib/moonshine'
local EmailApp = require("email")
local BrowserApp = require("browser")
local FilesApp = require("files")
local TerminalApp = require("terminal") 
local RouletteApp = require("roulette")
local TextEditor = require("texteditor")
local DinoApp = require("dino")
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
    emailIcon = love.graphics.newImage("assets/email.png")
    browserIcon = love.graphics.newImage("assets/browser.png")
    filesIcon = love.graphics.newImage("assets/files.png")
    terminalIcon = love.graphics.newImage("assets/terminal.png")
    rouletteIcon = love.graphics.newImage("assets/roulette.png")
    texteditorIcon = love.graphics.newImage("assets/file.png")
    dinoIcon = love.graphics.newImage("assets/dino.png")
    
    local sharedFS = filesystemModule.load()
    
    apps = {
        { name = "Email", module = EmailApp, instance = nil, icon = emailIcon },
        { name = "Browser", module = BrowserApp, instance = nil, icon = browserIcon },
        { name = "Files", module = FilesApp, instance = nil, icon = filesIcon },
        { name = "Terminal", module = TerminalApp, instance = nil, icon = terminalIcon },
        { name = "Roulette", module = RouletteApp, instance = nil, icon = rouletteIcon },
        { name = "TextEditor", module = TextEditor, instance = nil, icon = texteditorIcon },
        { name = "Dino", module = DinoApp, instance = nil, icon = dinoIcon },
    }

    iconWidth = 40
    iconHeight = 40
    iconSpacing = 8
    local startX = iconSpacing
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
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
	-- effect(function()
    love.graphics.setFont(font)
    love.graphics.clear(0.2, 0.3, 0.4)
    
    -- Draw top bar (date/time).
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, topBarHeight)
    love.graphics.setColor(1, 1, 1)
    local currentTime = os.date("%H:%M:%S")
    local currentDate = os.date("%Y-%m-%d")
    love.graphics.print(currentDate .. " " .. currentTime, 10, 8)

    -- Draw bottom bar (app icons).
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, screenHeight - bottomBarHeight, screenWidth, bottomBarHeight)
    for _, app in ipairs(apps) do
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
        
        if state == "closed" then
            love.graphics.setColor(1, 1, 1)
        elseif state == "maximized" then
            love.graphics.setColor(0, 1, 0)
        elseif state == "minimized" then
            love.graphics.setColor(0, 0.7, 0)
        end
        
        local iconMargin = 2
        local targetIconHeight = app.height - iconMargin * 2
        local scale = targetIconHeight / app.icon:getHeight()
        love.graphics.draw(app.icon, app.x + iconMargin, app.y + iconMargin, 0, scale, scale)
    end

    -- Draw open app windows.
    for _, window in ipairs(openApps) do
        if not window.minimized then
			love.graphics.setFont(font)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", window.x, window.y, window.width, window.height)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", window.x, window.y, window.width, window.height)
            
            if window == focusedWindow then
                love.graphics.setColor(0.0, 0.5, 1.0)
            else
                love.graphics.setColor(0.2, 0.2, 0.2)
            end
            love.graphics.rectangle("fill", window.x, window.y, window.width, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(window.app.name, window.x + 5, window.y + 2)
            
            local btnSize = 20
            local closeX = window.x + window.width - btnSize
            local minX = window.x + window.width - 2 * btnSize
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", closeX, window.y, btnSize, btnSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("x", closeX + 5, window.y + 2)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", minX, window.y, btnSize, btnSize)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print("-", minX + 5, window.y + 2)
            
            if window.instance and window.instance.draw then
                window.instance:draw(window.x, window.y + 20, window.width, window.height - 20)
            else
                love.graphics.setColor(0, 0, 0)
                love.graphics.print("Content of " .. window.app.name, window.x + 10, window.y + 30)
            end
            
            local handleSize = 20
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", window.x + window.width - handleSize, window.y + window.height - handleSize, handleSize, handleSize)
        end
    end

    -- Draw Demoji on top.
    -- demojiInstance:draw()
	-- end)
end

function love.mousepressed(x, y, button)
    if button == 1 then
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

        for _, app in ipairs(apps) do
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
    end
    -- Pass mouse movement to Demoji.
    -- demojiInstance:mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    if button == 1 then
        draggingWindow = nil
        resizingWindow = nil
        -- demojiInstance:mousereleased(x, y, button)
    end
end

function love.textinput(text)
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.textinput then
        focusedWindow.instance:textinput(text)
    end
end

function love.keypressed(key)
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.keypressed then
        focusedWindow.instance:keypressed(key)
    end
end

function love.wheelmoved(x, y)
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.wheelmoved then
        focusedWindow.instance:wheelmoved(x, y)
    end
end

function love.resize(w, h)
    for _, window in ipairs(openApps) do
        if window.instance and window.instance.resize then
            window.instance:resize(w, h)
        end
    end
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
        if app.name == "TextEditor" and app.instance then
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


-- function toggleApp(app)
    -- local found = nil
    -- for _, window in ipairs(openApps) do
        -- if window.app == app then
            -- found = window
            -- break
        -- end
    -- end

    -- if found then
        -- found.minimized = not found.minimized
        -- setFocus(found)
    -- else
        -- app.instance = app.module.new()
        -- local screenWidth = love.graphics.getWidth()
        -- local screenHeight = love.graphics.getHeight()
        -- local windowWidth = 500
        -- local windowHeight = 300
        -- local x = (screenWidth - windowWidth) / 2
        -- local y = topBarHeight + ((screenHeight - topBarHeight - bottomBarHeight) - windowHeight) / 2
        -- local newWindow = { app = app, instance = app.instance, x = x, y = y, width = windowWidth, height = windowHeight, minimized = false }
        -- table.insert(openApps, newWindow)
        -- setFocus(newWindow)
    -- end
-- end
