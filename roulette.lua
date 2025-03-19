-- roulette.lua
local RouletteApp = {}
RouletteApp.__index = RouletteApp

-- Create a new instance of the Roulette app.
function RouletteApp.new()
    local self = setmetatable({}, RouletteApp)
    
    -- Internal “designed” dimensions (the original roulette game was 700x400)
    self.width = 700
    self.height = 400
    
    -- Game state
    self.defaultBet = 25000
    self.bets = {}            -- table to store bets
    self.balance = self.defaultBet
    self.prevBalance = self.balance
    self.chipValue = 10
    self.lastWon = 0
    
    -- (These values will be recalculated in draw() based on the current window size.)
    self.gridCellSize = 30  
    self.gridX = self.width/2 - 2.3 * self.gridCellSize
    self.gridY = self.height/2 - 3.5 * self.gridCellSize
    self.rouletteRadius = 2.5 * self.gridCellSize
    self.centerX = self.gridX - 150
    self.centerY = self.gridY + 100
    
    -- Roulette wheel and ball properties
    self.currentAngle = 0
    self.spinSpeed = 0
    self.ballAngle = 0
    self.ballSpeed = 0
    self.ballRadius = self.rouletteRadius - 10
    self.prevMod = 0
    self.landedNumber = nil
    self.landedColor = nil

    -- Buttons and scales
    self.buttons = {"CLEAR", "DOUBLE", "ALL", "SPIN"}
    self.bettingScales = {10, 50, 100, 500, 1000, 5000, 10000, 50000, 1000000, 5000000, 10000000, 50000000}

    -- Colors (same as your original game)
    self.colors = {
        black = {0.109804, 0.109804, 0.109804},
        white = {1, 1, 1},
        trans = {1, 1, 1, 0.05},
        bg = {0.109804, 0.109804, 0.109804},
        chip = {1, 0.905882, 0.172549},
        ball = {0.996078, 1, 0.172549},
        green = {0.149020, 0.796078, 0.129412},
        red = {1, 0.172549, 0.172549},
    }
    
    -- Fonts (adjust the file path as needed)
    self.mainFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf")
    self.smallFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 10)
    
    -- Define roulette sections (wheel segments)
    self.rouletteSections = {
        {number = 0, color = "green"},
        {number = 32, color = "red"},
        {number = 15, color = "black"},
        {number = 19, color = "red"},
        {number = 4, color = "black"},
        {number = 21, color = "red"},
        {number = 2, color = "black"},
        {number = 25, color = "red"},
        {number = 17, color = "black"},
        {number = 34, color = "red"},
        {number = 6, color = "black"},
        {number = 27, color = "red"},
        {number = 13, color = "black"},
        {number = 36, color = "red"},
        {number = 11, color = "black"},
        {number = 30, color = "red"},
        {number = 8, color = "black"},
        {number = 23, color = "red"},
        {number = 10, color = "black"},
        {number = 5, color = "red"},
        {number = 24, color = "black"},
        {number = 16, color = "red"},
        {number = 33, color = "black"},
        {number = 1, color = "red"},
        {number = 20, color = "black"},
        {number = 14, color = "red"},
        {number = 31, color = "black"},
        {number = 9, color = "red"},
        {number = 22, color = "black"},
        {number = 18, color = "red"},
        {number = 29, color = "black"},
        {number = 7, color = "red"},
        {number = 28, color = "black"},
        {number = 12, color = "red"},
        {number = 35, color = "black"},
        {number = 3, color = "red"},
        {number = 26, color = "black"}
    }
    
    -- Define additional grid areas
    self.rouletteGrid = {
        { {num=3,  color="red"},   {num=2,  color="black"}, {num=1, color="red"} },
        { {num=6,  color="black"}, {num=5,  color="red"},   {num=4, color="black"} },
        { {num=9,  color="red"},   {num=8,  color="black"}, {num=7, color="red"} },
        { {num=12, color="red"},   {num=11, color="black"}, {num=10, color="black"} },
        { {num=15, color="black"}, {num=14, color="red"},   {num=13, color="black"} },
        { {num=18, color="red"},   {num=17, color="black"}, {num=16, color="red"} },
        { {num=21, color="red"},   {num=20, color="black"}, {num=19, color="black"} },
        { {num=24, color="black"}, {num=23, color="red"},   {num=22, color="black"} },
        { {num=27, color="red"},   {num=26, color="black"}, {num=25, color="red"} },
        { {num=30, color="red"},   {num=29, color="black"}, {num=28, color="red"} },
        { {num=33, color="black"}, {num=32, color="red"},   {num=31, color="black"} },
        { {num=36, color="red"},   {num=35, color="black"}, {num=34, color="red"} }
    }
    
    self.rouletteCol1 = {"2-1", "2-1", "2-1"}
    self.rouletteRow1 = {"1 to 12", "13 to 24", "25 to 36"}
    self.rouletteRow2 = {"1-18","EVEN", "RED", "BLACK", "ODD", "19-36"}
    self.rouletteZero = "0"
    
    -- Load sounds (ensure the audio files exist in your project)
    self.tickSound = love.audio.newSource("audio/tick.wav", "static")
    self.tickSound:setVolume(0.7)
    self.woohSound = love.audio.newSource("audio/wooh.wav", "static")
    self.woohSound:setVolume(1)
    
    return self
end

------------------------------------------------------------
-- Update: Called every frame with dt (delta time)
------------------------------------------------------------
function RouletteApp:update(dt)
    if self.spinSpeed > 0.25 then
        self.currentAngle = self.currentAngle + self.spinSpeed * dt
        self.spinSpeed = self.spinSpeed * 0.99 -- Gradually slow down
        self.ballAngle = self.ballAngle - self.ballSpeed * dt
        self.ballSpeed = math.max(self.spinSpeed * 1.5, 0)
        local mod = (self.currentAngle * self.spinSpeed) % (math.pi*2)
        if self.prevMod >= mod then
            self.tickSound:setPitch(self.spinSpeed)
            love.audio.play(self.tickSound)
        end
        self.prevMod = mod
    elseif self.landedNumber == nil then
        local normalizedAngle = (self.ballAngle - self.currentAngle) % (2 * math.pi)
        local sectionSize = 2 * math.pi / #self.rouletteSections
        local landedIndex = math.floor(normalizedAngle / sectionSize) + 1
        self.landedNumber = self.rouletteSections[landedIndex].number
        self.landedColor = self.rouletteSections[landedIndex].color
        if self.landedNumber then self:checkBets(self.landedNumber, self.landedColor) end
        if self.lastWon < 0 then
            love.audio.play(self.woohSound)
        end
    end
end

------------------------------------------------------------
-- Draw: Render the roulette game within the app window.
-- The parameters (offsetX, offsetY, w, h) come from the desktop
-- so that the game is drawn inside a draggable window.
------------------------------------------------------------
function RouletteApp:draw(offsetX, offsetY, w, h)
    -- Store current app window dimensions and compute scaling factors.
    self._w = w
    self._h = h
    local scaleX = w / self.width
    local scaleY = h / self.height
    self._scaleX = scaleX
    self._scaleY = scaleY
    
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.setColor(self.colors.black)
	love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.scale(scaleX, scaleY)
    
    -- Recalculate grid sizes based on our internal width.
    local gridCellSize = self.width / 23
    if gridCellSize > 40 then gridCellSize = 40 end
    self.gridCellSize = gridCellSize
    self.gridX = self.width/2 - 2.3 * gridCellSize
    self.gridY = self.height/2 - 3.5 * gridCellSize
    self.rouletteRadius = 3.5 * gridCellSize
    self.centerX = self.gridX - 5 * gridCellSize
    self.centerY = self.gridY + 3.33 * gridCellSize

    -- Draw the roulette wheel and betting grid.
    self:drawWheel()
    self:drawBettingGrid()
    
    -- Draw buttons.
    for i, label in ipairs(self.buttons) do
        local x = self.gridX + (i-1) * gridCellSize * 2.4
        local y = self.gridY + gridCellSize * 7
        love.graphics.setColor(self.colors.trans)
        love.graphics.rectangle("fill", x, y, gridCellSize*2, gridCellSize)
        love.graphics.setColor(self.colors.white)
        love.graphics.printf(label, x, y + gridCellSize/4, gridCellSize*2, "center")
    end
    
    -- Draw betting scale chips.
    for i, val in ipairs(self.bettingScales) do
        if val <= self.balance then
            local x = self.gridX + gridCellSize * (i - 2/3)
            local y = self.gridY + gridCellSize * 6
            if self.chipValue == val then
                love.graphics.setColor(1,1,1,0.3)
                love.graphics.circle("fill", x, y, gridCellSize/2)
            end
            self:drawChip(val, x, y, gridCellSize)
        end
    end
    
    -- Display balance, total bet sum, and last win.
    local sum = 0
    for _, bet in pairs(self.bets) do
        sum = sum + bet
    end
    love.graphics.setColor(self.colors.white)
    love.graphics.print("$" .. self:format_num_comma(self.balance) ..
                          " $" .. self:format_num_comma(sum) ..
                          " $" .. self:format_num_comma(self.lastWon), 10, 10)
    
    love.graphics.pop()
end

------------------------------------------------------------
-- Mousepressed: Adjust mouse coordinates based on scaling
------------------------------------------------------------
function RouletteApp:mousepressed(x, y, button)
    if button == 1 then
        if self._scaleX and self._scaleY then
            x = x / self._scaleX
            y = y / self._scaleY
        end
        self:handleButtonClick(x, y)
        self:handleGridClick(x, y)
    end
end

------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------

function RouletteApp:drawChip(num, x, y, r)
    local a = 2 * math.pi / 10
    for i = 1, 10 do
        local angleStart = i * a
        local angleEnd = angleStart + a
        if i % 2 == 1 then
            love.graphics.setColor(self.colors.chip)
        else
            love.graphics.setColor(self.colors.white)
        end
        love.graphics.arc("fill", x, y, r/2.5, angleStart, angleEnd)
    end
    
    love.graphics.setColor(0.7, 0.7, 0)
    love.graphics.circle("fill", x, y, r/3.2)
    
    love.graphics.setColor(0, 0, 0, 0.73)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf(self:format_num(num), x - 20, y - self.smallFont:getHeight()/2, 40, "center")
    love.graphics.setFont(self.mainFont)
end

function RouletteApp:drawWheel()
    local a = 2 * math.pi / #self.rouletteSections
    for i, section in ipairs(self.rouletteSections) do
        local angleStart = ((i-1) * a) + self.currentAngle
        local angleEnd = angleStart + a
        love.graphics.setColor(self.colors[section.color])
        love.graphics.arc("fill", self.centerX, self.centerY, self.rouletteRadius, angleStart, angleEnd)
        
        if section.color == "green" or section.color == "red" then
            love.graphics.setColor(self.colors.black)
        else
            love.graphics.setColor(self.colors.red)
        end
        
        love.graphics.push()
        love.graphics.translate(self.centerX, self.centerY)
        love.graphics.rotate(angleStart)
        -- Print the number (using a zero offset for simplicity)
        love.graphics.print(section.number, self.rouletteRadius - 0.6 * self.gridCellSize, 0)
        love.graphics.pop()
    end
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(self.colors.red)
    love.graphics.arc("line", "open", self.centerX, self.centerY,
                      self.rouletteRadius - 0.8 * self.gridCellSize,
                      self.currentAngle + a * 2,
                      self.currentAngle + a * #self.rouletteSections)
    
    love.graphics.setColor(self.colors.black)
    love.graphics.circle("fill", self.centerX, self.centerY, self.rouletteRadius - 1.66 * self.gridCellSize)
    
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(self.colors.red)
    love.graphics.circle("line", self.centerX, self.centerY, self.rouletteRadius - 1.66 * self.gridCellSize)
    
    if self.landedNumber then
        if self.landedColor == "red" then
            love.graphics.setColor(self.colors.red)
        elseif self.landedColor == "black" then
            love.graphics.setColor(self.colors.trans)
        else 
            love.graphics.setColor(self.colors.green)
        end
        love.graphics.circle("fill", self.centerX, self.centerY, 15)
        if self.landedColor == "black" then
            love.graphics.setColor(self.colors.red)
        else 
            love.graphics.setColor(self.colors.black)
        end
        love.graphics.printf(self.landedNumber, self.centerX - 20, self.centerY - self.mainFont:getHeight()/2, 40, "center")
    end
    
    -- Draw the ball.
    self.ballRadius = self.rouletteRadius - 2 * self.gridCellSize
    local ballX = self.centerX + math.cos(self.ballAngle) * self.ballRadius
    local ballY = self.centerY + math.sin(self.ballAngle) * self.ballRadius
    love.graphics.setColor(self.colors.ball)
    love.graphics.circle("fill", ballX, ballY, 4.2)
end

function RouletteApp:drawBettingGrid()
    -- Draw the zero cell.
    love.graphics.setColor(self.colors.green)
    love.graphics.rectangle("fill", self.gridX - self.gridCellSize, self.gridY, self.gridCellSize, self.gridCellSize * 3)
    love.graphics.setColor(self.colors.black)
    love.graphics.printf(self.rouletteZero, self.gridX - self.gridCellSize, self.gridY + self.gridCellSize * 1.25, self.gridCellSize, "center")
    if self.bets[0] ~= nil then
        self:drawChip(self.bets[0], self.gridX - self.gridCellSize/2, self.gridY + self.gridCellSize * 1.5, self.gridCellSize)
    end
    
    -- Draw the first row of bets.
    for rowIndex, str in ipairs(self.rouletteRow1) do
        local cellSize = self.gridCellSize * 4
        local x = self.gridX + (rowIndex - 1) * cellSize
        local y = self.gridY + 3 * self.gridCellSize
        love.graphics.setColor(self.colors.trans)
        love.graphics.rectangle("fill", x, y, cellSize, self.gridCellSize)
        love.graphics.setColor(self.colors.white)
        love.graphics.printf(str, x, y + self.gridCellSize/4, cellSize, "center")
        local v = self.bets[40 + rowIndex]
        if v ~= nil then
            self:drawChip(v, x + cellSize/2, y + self.gridCellSize/2, self.gridCellSize)
        end
    end
    
    -- Draw the second row of bets.
    for rowIndex, str in ipairs(self.rouletteRow2) do
        local cellSize = self.gridCellSize * 2
        local x = self.gridX + (rowIndex - 1) * cellSize
        local y = self.gridY + 4 * self.gridCellSize
        if str == "RED" then
            love.graphics.setColor(self.colors.red)
        elseif str == "BLACK" then
            love.graphics.setColor(self.colors.black)
        else
            love.graphics.setColor(self.colors.trans)
        end
        love.graphics.rectangle("fill", x, y, cellSize, self.gridCellSize)
        love.graphics.setColor(self.colors.white)
        love.graphics.printf(str, x, y + self.gridCellSize/4, cellSize, "center")
        local v = self.bets[50 + rowIndex]
        if v ~= nil then
            self:drawChip(v, x + cellSize/2, y + self.gridCellSize/2, self.gridCellSize)
        end
    end
    
    -- Draw the “column 1” bets.
    for colIndex, str in ipairs(self.rouletteCol1) do
        local x = self.gridX + self.gridCellSize * 12
        local y = self.gridY + self.gridCellSize * (colIndex - 1)
        love.graphics.setColor(self.colors.trans)
        love.graphics.rectangle("fill", x, y, self.gridCellSize, self.gridCellSize)
        love.graphics.setColor(self.colors.white)
        love.graphics.printf(str, x, y + self.gridCellSize/4, self.gridCellSize, "center")
        local v = self.bets[60 + colIndex]
        if v ~= nil then
            self:drawChip(v, x + self.gridCellSize/2, y + self.gridCellSize/2, self.gridCellSize)
        end
    end
    
    -- Draw the main roulette grid.
    for rowIndex, row in ipairs(self.rouletteGrid) do
        for colIndex, cell in ipairs(row) do
            local x = self.gridX + (rowIndex - 1) * self.gridCellSize
            local y = self.gridY + (colIndex - 1) * self.gridCellSize
            love.graphics.setColor(self.colors[cell.color])
            love.graphics.rectangle("fill", x, y, self.gridCellSize, self.gridCellSize)
            if cell.color == "red" then 
                love.graphics.setColor(self.colors.black)
            elseif cell.color == "black" then 
                love.graphics.setColor(self.colors.red)
            else 
                love.graphics.setColor(self.colors.white)
            end
            love.graphics.printf("" .. cell.num, x, y + self.gridCellSize/4, self.gridCellSize, "center")
            local v = self.bets[cell.num]
            if v ~= nil then
                self:drawChip(v, x + self.gridCellSize/2, y + self.gridCellSize/2, self.gridCellSize)
            end
        end
    end
end

------------------------------------------------------------
-- Functions to handle mouse clicks on buttons and the grid.
------------------------------------------------------------
function RouletteApp:handleButtonClick(x, y)
    for i, label in ipairs(self.buttons) do
        local a = self.gridX + (i-1) * self.gridCellSize * 2.4
        local b = self.gridY + self.gridCellSize * 7
        if x >= a and x <= a + self.gridCellSize*2 and y >= b and y <= b + self.gridCellSize then
            if i == 1 then
                for _, val in pairs(self.bets) do
                    self.balance = self.balance + val
                end
                self.bets = {}
            elseif i == 2 then
                for i, val in pairs(self.bets) do
                    local d = val * 2
                    if self.balance - d >= 0 then
                        self.bets[i] = d
                    end
                end
            elseif i == 3 then
                self.chipValue = self.balance
            elseif i == 4 then
                self.spinSpeed = 6
                self.landedNumber = nil
                self.landedColor = nil
            end
        end
    end
    
    for i, val in ipairs(self.bettingScales) do
        local r = self.gridCellSize / 2.5
        local a = self.gridX + self.gridCellSize * (i - 2/3) - r
        local b = self.gridY + self.gridCellSize * 6 - r
        if x >= a and x <= a + r*2 and y >= b and y <= b + r*2 then
            self.chipValue = val
        end
    end
end

function RouletteApp:handleGridClick(x, y)
    -- Handle the zero cell.
    if x >= self.gridX - self.gridCellSize and x <= self.gridX and y >= self.gridY and y <= (self.gridY + self.gridCellSize*3) then
        local number = 0
        if not self.bets[number] and self.balance >= self.chipValue then
            self.bets[number] = self.chipValue
            self.balance = self.balance - self.chipValue
        elseif self.bets[number] then
            self.bets[number] = nil
            self.balance = self.balance + self.chipValue
        end
    end
    
    -- Handle the first betting row.
    for rowIndex, str in ipairs(self.rouletteRow1) do
        local cellSize = self.gridCellSize * 4
        local cellX = self.gridX + (rowIndex - 1) * cellSize
        local cellY = self.gridY + 3 * self.gridCellSize
        if x >= cellX and x <= cellX + cellSize and y >= cellY and y <= cellY + self.gridCellSize then
            local number = rowIndex + 40
            if not self.bets[number] and self.balance >= self.chipValue then
                self.bets[number] = self.chipValue
                self.balance = self.balance - self.chipValue
            elseif self.bets[number] then
                self.bets[number] = nil
                self.balance = self.balance + self.chipValue
            end
        end
    end
    
    -- Handle the second betting row.
    for rowIndex, str in ipairs(self.rouletteRow2) do
        local cellSize = self.gridCellSize * 2
        local cellX = self.gridX + (rowIndex - 1) * cellSize
        local cellY = self.gridY + 4 * self.gridCellSize
        if x >= cellX and x <= cellX + cellSize and y >= cellY and y <= cellY + self.gridCellSize then
            local number = rowIndex + 50
            if not self.bets[number] and self.balance >= self.chipValue then
                self.bets[number] = self.chipValue
                self.balance = self.balance - self.chipValue
            elseif self.bets[number] then
                self.bets[number] = nil
                self.balance = self.balance + self.chipValue
            end
        end
    end
    
    -- Handle the “column 1” bets.
    for colIndex, str in ipairs(self.rouletteCol1) do
        local cellX = self.gridX + self.gridCellSize * 12
        local cellY = self.gridY + self.gridCellSize * (colIndex - 1)
        if x >= cellX and x <= cellX + self.gridCellSize and y >= cellY and y <= cellY + self.gridCellSize then
            local number = colIndex + 60
            if not self.bets[number] and self.balance >= self.chipValue then
                self.bets[number] = self.chipValue
                self.balance = self.balance - self.chipValue
            elseif self.bets[number] then
                self.bets[number] = nil
                self.balance = self.balance + self.chipValue
            end
        end
    end
    
    -- Handle clicks on the main roulette grid.
    for rowIndex, row in ipairs(self.rouletteGrid) do
        for colIndex, cell in ipairs(row) do
            local cellX = self.gridX + (rowIndex - 1) * self.gridCellSize
            local cellY = self.gridY + (colIndex - 1) * self.gridCellSize
            if x >= cellX and x <= cellX + self.gridCellSize and y >= cellY and y <= cellY + self.gridCellSize then
                if not self.bets[cell.num] and self.balance >= self.chipValue then
                    self.bets[cell.num] = self.chipValue
                    self.balance = self.balance - self.chipValue
                elseif self.bets[cell.num] then
                    self.bets[cell.num] = nil
                    self.balance = self.balance + self.chipValue
                end
            end
        end
    end
end

------------------------------------------------------------
-- Number formatting functions.
------------------------------------------------------------
function RouletteApp:format_num(num)
    if num < 1000 then
        return tostring(num)
    elseif num < 1000000 then
        return tostring(math.floor(num / 1000)) .. "K"
    elseif num < 1000000000 then
        return tostring(math.floor(num / 1000000)) .. "M"
    elseif num < 1000000000000 then
        return tostring(math.floor(num / 1000000000)) .. "B"
    elseif num < 1000000000000000 then
        return tostring(math.floor(num / 1000000000000)) .. "T"
    elseif num < 1000000000000000000 then
        return tostring(math.floor(num / 1000000000000000)) .. "Q"
    end
    return "∞"
end

function RouletteApp:format_num_comma(n)
    local str = tostring(n)
    local out = ""
    local commaCount = 0
    for i = #str, 1, -1 do
        out = str:sub(i, i) .. out
        commaCount = commaCount + 1
        if commaCount == 3 and i > 1 then
            out = "," .. out
            commaCount = 0
        end
    end
    return out
end

------------------------------------------------------------
-- Determine winnings and clear bets.
------------------------------------------------------------
function RouletteApp:checkBets(num, col)
    if self.bets[num] and (num >= 0 and num <= 36) then
        self.balance = self.balance + self.bets[num] * 36
    end
    -- First row bets.
    if self.bets[41] and num >= 1 and num <= 12 then
        self.balance = self.balance + self.bets[41] * 3
    elseif self.bets[42] and num >= 13 and num <= 24 then
        self.balance = self.balance + self.bets[42] * 3
    elseif self.bets[43] and num >= 25 and num <= 36 then
        self.balance = self.balance + self.bets[43] * 3
    end
    -- Second row bets.
    if self.bets[51] and num >= 1 and num <= 18 then
        self.balance = self.balance + self.bets[51] * 2
    elseif self.bets[56] and num >= 19 and num <= 36 then
        self.balance = self.balance + self.bets[56] * 2
    end
    -- Even/Odd bets.
    if self.bets[52] and num % 2 == 0 then
        self.balance = self.balance + self.bets[52] * 2
    elseif self.bets[55] and num % 2 ~= 0 then
        self.balance = self.balance + self.bets[55] * 2
    end
    -- Red/Black bets.
    if self.bets[53] and col == "red" then
        self.balance = self.balance + self.bets[53] * 2
    elseif self.bets[54] and col == "black" then
        self.balance = self.balance + self.bets[54] * 2
    end
    -- Column bets.
    if self.bets[61] and (num >= 3 and num <= 36 and num % 3 == 0) then
        self.balance = self.balance + self.bets[61] * 3
    elseif self.bets[62] and (num >= 2 and num <= 35 and (num - 2) % 3 == 0) then
        self.balance = self.balance + self.bets[62] * 3
    elseif self.bets[63] and (num >= 1 and num <= 34 and (num - 1) % 3 == 0) then
        self.balance = self.balance + self.bets[63] * 3
    end
    
    self.lastWon = self.balance - self.prevBalance
    self.prevBalance = self.balance
    self.bets = {}
end

return RouletteApp
