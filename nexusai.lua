-- nexusai.lua
local NexusAI = {}
NexusAI.__index = NexusAI

-- AI responses for different categories
local responses = {
    greeting = {
        "Greetings! I'm NexusAI, your digital assistant.",
        "Hello! How can I assist you today?",
        "Hi there! I'm here to help with any questions you have."
    },
    help = {
        "I can help with:\n- System information\n- File operations\n- Application guidance\n- General knowledge\nJust ask!",
        "My capabilities include:\n- Answering questions\n- Explaining system features\n- Providing tips\n- Finding information\nWhat do you need help with?",
        "I specialize in:\n- Technical support\n- File management\n- Application usage\n- Problem solving\nHow can I assist?"
    },
    system = {
        "This system runs Lynux OS, a lightweight operating system designed for efficiency.",
        "Current system time: " .. os.date("%H:%M:%S") .. "\nDate: " .. os.date("%Y-%m-%d"),
        "You have several applications available:\n- Email\n- Browser\n- Files\n- Terminal\n- Text Editor\n- And more!"
    },
    file = {
        "Files are managed through the Files app. You can create, edit, and organize documents there.",
        "To access files, open the Files application from the taskbar.",
        "Files are stored in a hierarchical structure. Use the Terminal or Files app to navigate."
    },
    unknown = {
        "I'm not sure I understand. Could you rephrase that?",
        "My knowledge on that topic is limited. Try asking something else.",
        "I'm still learning! Could you ask about something else?",
        "I don't have information about that. Maybe try a different question?"
    },
    fun = {
        "Did you know? The first computer bug was an actual moth found in a Harvard Mark II in 1947!",
        "Fun fact: The QWERTY keyboard layout was designed to slow typists down to prevent jamming on old typewriters.",
        "Trivia: The world's first computer programmer was Ada Lovelace in the 1840s!",
        "Interesting: There are more possible iterations of a game of chess than atoms in the known universe."
    }
}

function NexusAI.new()
    local self = setmetatable({}, NexusAI)
    self.messages = {
        {text = "Initializing NexusAI...", sender = "system"},
        {text = "System connected. Neural network online.", sender = "system"},
        {text = "Hello! I'm NexusAI, your virtual assistant. How can I help you today?", sender = "ai"}
    }
    self.inputText = ""
    self.font = love.graphics.newFont(12)
    self.scrollOffset = 0
    self.cursorVisible = true
    self.cursorTimer = 0
    self.thinking = false
    self.thinkTimer = 0
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
        if self.thinkTimer > 2 then
            self:generateResponse()
            self.thinking = false
        end
    end
end

function NexusAI:draw(x, y, width, height)
    love.graphics.setColor(0.95, 0.95, 0.98)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Chat area
    local chatHeight = height
    love.graphics.setScissor(x, y + 30, width, chatHeight)
    
    local messageY = y + 30 + chatHeight - 10 - self.scrollOffset
    for i = #self.messages, 1, -1 do
        local msg = self.messages[i]
        local textWidth = width - 40
        
        -- Calculate text height
        local _, wrapped = self.font:getWrap(msg.text, textWidth)
        local textHeight = #wrapped * self.font:getHeight()
        
        messageY = messageY - textHeight - 20
        
        -- Draw message bubble
        if msg.sender == "user" then
            love.graphics.setColor(0.9, 0.95, 1)
            love.graphics.rectangle("fill", x + width - textWidth - 30, messageY, textWidth + 20, textHeight + 10, 5)
            love.graphics.setColor(0.2, 0.4, 0.8)
            love.graphics.print("You:", x + 10, messageY)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(msg.text, x + width - textWidth - 25, messageY + 5, textWidth, "left")
        else
            love.graphics.setColor(0.85, 0.9, 0.95)
            love.graphics.rectangle("fill", x + 10, messageY, textWidth + 20, textHeight + 10, 5)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("NexusAI:", x + 10, messageY)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(msg.text, x + 15, messageY + 5, textWidth, "left")
        end
        
        if messageY < y + 30 then
            break
        end
    end
    
    love.graphics.setScissor()
    
    -- Input area
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y + height - 50, width, 50)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", x, y + height - 50, width, 50)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.font)
    love.graphics.print("You: ", x + 10, y + height - 35)
    
    -- Input text with cursor
    local inputX = x + 50
    love.graphics.printf(self.inputText, inputX, y + height - 35, width - 60, "left")
    
    if self.cursorVisible and not self.thinking then
        local cursorX = inputX + self.font:getWidth(self.inputText)
        love.graphics.line(cursorX, y + height - 35, cursorX, y + height - 15)
    end
    
    -- Thinking indicator
    if self.thinking then
        love.graphics.setColor(0.5, 0.5, 0.5)
        local dots = math.floor(self.thinkTimer * 2) % 4
        love.graphics.print("Thinking" .. string.rep(".", dots), x + width - 100, y + height - 35)
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
    elseif key == "return" and self.inputText:len() > 0 and not self.thinking then
        self:sendMessage()
    elseif key == "up" then
        self.scrollOffset = math.min(self.scrollOffset + 20, 1000)
    elseif key == "down" then
        self.scrollOffset = math.max(self.scrollOffset - 20, 0)
    end
end

function NexusAI:sendMessage()
    table.insert(self.messages, {text = self.inputText, sender = "user"})
    
    self.thinking = true
    self.thinkTimer = 0
    self.inputText = ""
    
    -- Auto-scroll to bottom
    self.scrollOffset = 0
end

function NexusAI:generateResponse()
    local input = self.messages[#self.messages].text:lower()
    local response
    
    if input:find("hello") or input:find("hi") or input:find("hey") then
        response = responses.greeting[math.random(#responses.greeting)]
    elseif input:find("help") or input:find("what can you do") then
        response = responses.help[math.random(#responses.help)]
    elseif input:find("system") or input:find("os") or input:find("about") then
        response = responses.system[math.random(#responses.system)]
    elseif input:find("file") or input:find("document") or input:find("folder") then
        response = responses.file[math.random(#responses.file)]
    elseif input:find("joke") or input:find("fun") or input:find("interesting") then
        response = responses.fun[math.random(#responses.fun)]
    else
        response = responses.unknown[math.random(#responses.unknown)]
    end
    
    table.insert(self.messages, {text = response, sender = "ai"})
end

function NexusAI:wheelmoved(x, y)
    self.scrollOffset = math.max(0, self.scrollOffset + y * 20)
end

return NexusAI