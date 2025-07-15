-- nexusai.lua
local NexusAI = {}
NexusAI.__index = NexusAI

-- Modern color palette
local colors = {
    background = {0.98, 0.98, 0.99},
    header = {0.15, 0.15, 0.25},
    inputBg = {0.95, 0.95, 0.97},
    userBubble = {0.18, 0.52, 0.88},
    aiBubble = {0.95, 0.95, 0.97},
    userText = {1, 1, 1},
    aiText = {0.2, 0.2, 0.2},
    border = {0.9, 0.9, 0.92},
    shadow = {0, 0, 0, 0.1}
}

-- Enhanced AI responses with contextual awareness
local responses = {
    greeting = {
        "Hello! I'm NexusAI, your digital assistant. How can I help you today?",
        "Hi there! Ready to assist with anything you need.",
        "Greetings! What can I do for you today?"
    },
    help = {
        "I can help with:\n- System information\n- File operations\n- Application guidance\n- General knowledge\n\nWhat would you like to know?",
        "My capabilities include:\n- Answering questions\n- Explaining features\n- Providing tips\n- Finding information\n\nHow can I assist?",
        "I specialize in:\n- Technical support\n- File management\n- App usage\n- Problem solving\n\nWhat do you need help with?"
    },
    system = {
        function() 
            return "This system runs Lynux OS v"..math.random(3,5).."."..math.random(0,5)..", a lightweight OS designed for efficiency.\n"..
                   "Current time: " .. os.date("%H:%M") .. " | Date: " .. os.date("%Y-%m-%d") 
        end,
        "System status: All operations normal\nAvailable apps: Email, Browser, Files, Terminal, Text Editor, and more!",
        "Hardware report:\n- CPU: Quad-core @ 2.4GHz\n- RAM: 8GB available\n- Storage: 128GB SSD (42GB free)"
    },
    file = {
        "Files are managed through the Files app where you can create, edit, and organize documents.",
        "To access files, open the Files application from the taskbar or press Win+F.",
        "File management tips:\n- Use folders to organize projects\n- Press Ctrl+N to create new files\n- Right-click for file options"
    },
    unknown = {
        "I'm not sure I understand. Could you rephrase that?",
        "I'm still learning about that topic. Could you ask something else?",
        "I don't have information about that yet. Try asking about system features or file management?",
        "Let me think... Actually, I'm better at technical questions. Want to try something else?"
    },
    fun = {
        "Did you know? The first computer bug was an actual moth found in a Harvard Mark II in 1947!",
        "Fun fact: The QWERTY keyboard layout was designed to slow typists down to prevent jamming on old typewriters.",
        "Trivia: The world's first programmer was Ada Lovelace in the 1840s!",
        "Interesting: There are more possible chess games than atoms in the known universe."
    },
    gratitude = {
        "You're welcome! Let me know if you need anything else.",
        "Glad I could help! What else can I assist with?",
        "Happy to help! Is there something else you'd like to know?"
    }
}

function NexusAI.new()
    local self = setmetatable({}, NexusAI)
    self.messages = {
        {text = "System initialized", sender = "system", time = os.date("%H:%M")},
        {text = "Neural network online", sender = "system", time = os.date("%H:%M")},
        {text = "Hello! I'm NexusAI, your virtual assistant. How can I help?", sender = "ai", time = os.date("%H:%M")}
    }
    self.inputText = ""
    -- self.font = love.graphics.newFont("fonts/Roboto-Regular.ttf", 14) or love.graphics.newFont(14)
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont(16)
    self.scrollOffset = 0
    self.cursorVisible = true
    self.cursorTimer = 0
    self.thinking = false
    self.thinkTimer = 0
    self.lastResponseType = nil
    self.typingSpeed = 2 -- Characters per second for typing effect
    self.typingProgress = 0
    self.currentResponse = ""
    return self
end

function NexusAI:update(dt)
    -- Cursor blinking
    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer > 0.5 then
        self.cursorVisible = not self.cursorVisible
        self.cursorTimer = 0
    end
    
    -- Thinking animation
    if self.thinking then
        self.thinkTimer = self.thinkTimer + dt
        
        -- Typing effect
        if self.thinkTimer > 0.8 and #self.currentResponse > 0 then
            self.typingProgress = self.typingProgress + dt * self.typingSpeed
            local chars = math.min(math.floor(self.typingProgress * #self.currentResponse), #self.currentResponse)
            self.messages[#self.messages].text = self.currentResponse:sub(1, chars)
            
            if chars == #self.currentResponse then
                self.thinking = false
            end
        end
    end
end

function NexusAI:draw(x, y, width, height)
    -- Draw background
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw header
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, y, width, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("NexusAI", x, y + 10, width, "center")
    
    -- Draw chat area with shadow effect
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle("fill", x + 5, y + 45, width - 10, height - 100, 8)
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", x, y + 40, width, height - 95, 8)
    
    -- Draw messages
    local messageY = y + height - 95 - 20 - self.scrollOffset
    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        local textWidth = width - 120
        local _, wrapped = self.font:getWrap(msg.text, textWidth)
        local textHeight = #wrapped * (self.font:getHeight() + 2)
        
        messageY = messageY - textHeight - 40
        
        -- Draw message bubble
        if msg.sender == "user" then
            -- User message (right-aligned)
            local bubbleWidth = math.min(textWidth + 30, width - 60)
            love.graphics.setColor(colors.userBubble)
            love.graphics.rectangle("fill", width - bubbleWidth - 20, messageY, bubbleWidth, textHeight + 20, 12)
            love.graphics.setColor(colors.userText)
            love.graphics.printf(msg.text, width - bubbleWidth - 10, messageY + 10, bubbleWidth - 20, "left")
            
            -- Timestamp
            love.graphics.setColor(0.7, 0.8, 1)
            love.graphics.setFont(love.graphics.newFont(10))
            love.graphics.printf(msg.time or os.date("%H:%M"), width - bubbleWidth - 20, messageY + textHeight + 22, bubbleWidth, "right")
        elseif msg.sender == "ai" then
            -- AI message (left-aligned)
            local bubbleWidth = math.min(textWidth + 30, width - 60)
            love.graphics.setColor(colors.aiBubble)
            love.graphics.rectangle("fill", 20, messageY, bubbleWidth, textHeight + 20, 12)
            love.graphics.setColor(colors.aiText)
            love.graphics.printf(msg.text, 30, messageY + 10, bubbleWidth - 20, "left")
            
            -- Timestamp
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setFont(love.graphics.newFont(10))
            love.graphics.printf("NexusAI • " .. (msg.time or os.date("%H:%M")), 20, messageY + textHeight + 22, bubbleWidth, "left")
        else
            -- System message
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.printf(msg.text, x + 20, messageY + 10, width - 40, "center")
        end
        
        love.graphics.setFont(self.font)
        
        if messageY < y + 40 then
            break
        end
    end
    
    -- Draw scrollbar if needed
    self:drawScrollbar(x, y + 40, width, height - 95)
    
    -- Draw input area
    love.graphics.setColor(colors.inputBg)
    love.graphics.rectangle("fill", x, y + height - 50, width, 50, 0, 0, 8, 8)
    love.graphics.setColor(colors.border)
    love.graphics.rectangle("line", x, y + height - 50, width, 50, 0, 0, 8, 8)
    
    -- Draw input text
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.setFont(self.font)
    love.graphics.print("You:", x + 15, y + height - 35)
    
    -- Input text with cursor
    local inputX = x + 60
    love.graphics.printf(self.inputText, inputX, y + height - 35, width - 80, "left")
    
    if self.cursorVisible and not self.thinking then
        local cursorX = inputX + self.font:getWidth(self.inputText)
        love.graphics.setColor(0.2, 0.4, 0.8)
        love.graphics.rectangle("fill", cursorX, y + height - 35, 2, self.font:getHeight())
    end
    
    -- Thinking indicator
    if self.thinking then
        love.graphics.setColor(0.5, 0.5, 0.6)
        local dots = math.floor(self.thinkTimer * 3) % 4
        love.graphics.printf("Thinking" .. string.rep(".", dots), x, y + height - 35, width - 20, "right")
    end
end

function NexusAI:drawScrollbar(x, y, width, height)
    local totalHeight = 0
    for i, msg in ipairs(self.messages) do
        local textWidth = width - 120
        local _, wrapped = self.font:getWrap(msg.text, textWidth)
        totalHeight = totalHeight + #wrapped * (self.font:getHeight() + 2) + 50
    end
    
    if totalHeight > height then
        local visibleRatio = height / totalHeight
        local thumbHeight = math.max(20, height * visibleRatio)
        local trackHeight = height
        local maxScroll = math.max(0, totalHeight - height)
        local thumbPosition = (self.scrollOffset / maxScroll) * (trackHeight - thumbHeight)
        
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.rectangle("fill", x + width - 12, y + thumbPosition, 8, thumbHeight, 4)
    end
end

function NexusAI:textinput(text)
    if not self.thinking then
        self.inputText = self.inputText .. text
    end
end

function NexusAI:keypressed(key)
    if key == "backspace" then
        self.inputText = self.inputText:sub(1, -2)
    elseif key == "return" then
        if love.keyboard.isDown("lshift", "rshift") then
            self.inputText = self.inputText .. "\n"
        elseif self.inputText:len() > 0 and not self.thinking then
            self:sendMessage()
        end
    elseif key == "up" then
        self.scrollOffset = math.min(self.scrollOffset + 30, 1000)
    elseif key == "down" then
        self.scrollOffset = math.max(self.scrollOffset - 30, 0)
    end
end

function NexusAI:sendMessage()
    table.insert(self.messages, {
        text = self.inputText, 
        sender = "user",
        time = os.date("%H:%M")
    })
    
    self.thinking = true
    self.thinkTimer = 0
    self.typingProgress = 0
    self.inputText = ""
    
    -- Auto-scroll to bottom
    self.scrollOffset = 0
    
    -- Start generating response
    self:generateResponse()
end

function NexusAI:generateResponse()
    local input = self.messages[#self.messages].text:lower()
    local responseCategory = "unknown"
    local response
    
    -- Contextual response logic
    if input:find("hello") or input:find("hi") or input:find("hey") then
        responseCategory = "greeting"
    elseif input:find("help") or input:find("what can you do") then
        responseCategory = "help"
    elseif input:find("system") or input:find("os") or input:find("about") or input:find("spec") then
        responseCategory = "system"
    elseif input:find("file") or input:find("document") or input:find("folder") or input:find("save") then
        responseCategory = "file"
    elseif input:find("joke") or input:find("fun") or input:find("interesting") or input:find("fact") then
        responseCategory = "fun"
    elseif input:find("thank") or input:find("appreciate") or input:find("thanks") then
        responseCategory = "gratitude"
    end
    
    -- Follow-up conversations
    if self.lastResponseType == "help" and input:find("file") then
        responseCategory = "file"
    elseif self.lastResponseType == "system" and (input:find("app") or input:find("program")) then
        responseCategory = "help"
    end
    
    -- Get response
    local category = responses[responseCategory]
    if type(category) == "table" then
        response = category[math.random(#category)]
    elseif type(category) == "function" then
        response = category()
    else
        response = responses.unknown[math.random(#responses.unknown)]
    end
    
    -- Add contextual awareness
    if responseCategory ~= "unknown" then
        self.lastResponseType = responseCategory
    end
    
    -- Add to messages with typing effect
    self.currentResponse = response
    table.insert(self.messages, {
        text = "", 
        sender = "ai",
        time = os.date("%H:%M")
    })
end

function NexusAI:wheelmoved(x, y)
    self.scrollOffset = math.max(0, self.scrollOffset + y * 30)
end

return NexusAI