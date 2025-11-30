-- poker.lua - Enhanced Texas Hold'em Poker App with Responsive UI
local PokerApp = {}
PokerApp.__index = PokerApp

function PokerApp.new()
    local self = setmetatable({}, PokerApp)
    
    -- Enhanced color scheme
    self.COLORS = {
        bg = {0.08, 0.10, 0.14},
        table = {0.12, 0.20, 0.16},
        tableHighlight = {0.18, 0.28, 0.22},
        tableOutline = {0.25, 0.35, 0.3},
        card = {0.98, 0.98, 0.96},
        cardHighlight = {1.0, 1.0, 1.0},
        cardBack = {0.25, 0.45, 0.7},
        cardBackHighlight = {0.35, 0.55, 0.8},
        redSuit = {0.9, 0.2, 0.2},
        blackSuit = {0.15, 0.15, 0.15},
        buttonBase = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        buttonActive = {0.2, 0.7, 0.9},
        buttonFold = {0.9, 0.3, 0.3},
        text = {0.95, 0.95, 0.95},
        textDim = {0.7, 0.7, 0.7},
        gold = {0.95, 0.85, 0.3},
        chipRed = {0.9, 0.2, 0.2},
        chipBlue = {0.2, 0.4, 0.9},
        chipGreen = {0.2, 0.7, 0.3},
        chipGold = {0.95, 0.75, 0.1}
    }

    -- Game state
    self.game = {
        state = 'START',
        turn = 'PLAYER',
        deck = {},
        player = { hand = {}, chips = 1500, currentBet = 0, status = "", lastAction = "" },
        cpu = { hand = {}, chips = 1500, currentBet = 0, status = "", lastAction = "", dialogue = "" },
        community = {},
        pot = 0,
        dealer = 'PLAYER',
        message = "Welcome to Texas Hold'em!",
        subMessage = "Press 'Deal' to start",
        minBet = 25,
        timer = 0,
        raiseAmount = 50,
        maxRaise = 500,
        animationTimer = 0,
        showCards = false,
        lastWinner = nil
    }

    self.layout = {}
    self.buttons = {}
    self.fonts = {}
    
    self.SUITS = {'hearts', 'diamonds', 'clubs', 'spades'}
    self.RANKS = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
    self.RANK_STR = {[11]='J', [12]='Q', [13]='K', [14]='A'}
    
    -- Enhanced statistics
    self.stats = {
        handsPlayed = 0,
        playerWins = 0,
        cpuWins = 0,
        folds = 0,
        biggestPot = 0,
        currentStreak = 0,
        bestStreak = 0
    }
    
    -- CPU personality and dialogues
    self.cpuPersonality = {
        aggressive = 0.6, -- 0-1 scale
        bluffFrequency = 0.3,
        dialogues = {
            raise = {
                "I'm feeling lucky! Raising the stakes!",
                "Time to put some pressure on!",
                "Let's make this interesting!",
                "I see your bet and raise!",
                "You can't handle this heat!"
            },
            call = {
                "I'll match that and see where this goes.",
                "Okay, let's see what you've got.",
                "Calling your bet. Don't disappoint me!",
                "I'm not scared! Let's do this.",
                "Alright, I'll play along."
            },
            fold = {
                "Too risky for me. I'm out!",
                "I'll live to fight another day.",
                "You can have this one. I'm folding.",
                "Not worth it. I fold!",
                "My cards aren't that great. I'm out."
            },
            win = {
                "Haha! Victory is mine!",
                "Better luck next time, friend!",
                "I read you like a book!",
                "The chips are mine! All mine!",
                "Another win for the master!"
            },
            lose = {
                "Wow, you got me that time!",
                "I'll get you next hand!",
                "Well played! You earned that one.",
                "Lucky break! But I'm coming back!",
                "Okay, you win this round."
            },
            bluff = {
                "I've got the perfect hand!",
                "You should probably fold now...",
                "This is going to be expensive for you!",
                "I can't believe my luck today!",
                "Ready to lose all your chips?"
            }
        }
    }
    
    -- Animation states
    self.animations = {
        dealing = false,
        cardDealTimer = 0,
        cardsDealt = 0,
        potHighlight = 0,
        buttonPulse = 0,
        cardReveal = 0
    }
    
    -- Responsive breakpoints
    self.breakpoints = {
        small = 600,
        medium = 900,
        large = 1200
    }
    
    return self
end

function PokerApp:draw(x, y, width, height)
    -- Set up layout for this draw call
    self:calcLayout(width, height)
    
    -- Background with gradient effect
    self:drawBackground(x, y, width, height)
    
    -- Draw game content
    if self.game.state == 'START' then
        self:drawStartScreen(x, y, width, height)
    elseif self.game.state == 'GAMEOVER' then
        self:drawGameOver(x, y, width, height)
    else
        self:drawGameTable(x, y, width, height)
    end
end

function PokerApp:calcLayout(width, height)
    self.layout.w, self.layout.h = width, height
    self.layout.cx, self.layout.cy = width/2, height/2
    
    -- Determine screen size category
    self.layout.screenSize = "large"
    if width < self.breakpoints.small then
        self.layout.screenSize = "small"
    elseif width < self.breakpoints.medium then
        self.layout.screenSize = "medium"
    end
    
    -- Responsive card sizing
    local cardScale = 1.0
    if self.layout.screenSize == "small" then
        cardScale = 0.7
    elseif self.layout.screenSize == "medium" then
        cardScale = 0.85
    end
    
    self.layout.cardW = math.min(width * 0.08 * cardScale, 110)
    self.layout.cardH = self.layout.cardW * 1.4
    self.layout.padding = self.layout.cardW * 0.15
    
    -- Responsive fonts
    local baseFontSize = math.max(10, height * 0.02)
    self.fonts.tiny = love.graphics.newFont(math.floor(baseFontSize * 0.7))
    self.fonts.small = love.graphics.newFont(math.floor(baseFontSize * 0.9))
    self.fonts.medium = love.graphics.newFont(math.floor(baseFontSize * 1.2))
    self.fonts.large = love.graphics.newFont(math.floor(baseFontSize * 1.6))
    self.fonts.huge = love.graphics.newFont(math.floor(baseFontSize * 2.5))
    
    -- Table dimensions
    self.layout.tableR = math.min(width * 0.45, height * 0.4)
    
    -- Responsive button layout
    local btnW, btnH, btnSpacing
    
    if self.layout.screenSize == "small" then
        btnW = math.min(width * 0.22, 140)
        btnH = math.max(35, height * 0.055)
        btnSpacing = btnW * 0.8
    else
        btnW = math.min(width * 0.16, 200)
        btnH = math.max(45, height * 0.065)
        btnSpacing = btnW * 1.1
    end
    
    local btnY = height - btnH - (self.layout.screenSize == "small" and 15 or 25)
    
    -- Adjust button positions based on screen size
    if self.layout.screenSize == "small" then
        self.buttons = {
            {id="fold", text="FOLD", x=width/2 - btnSpacing*1.5, y=btnY, w=btnW, h=btnH, type="fold"},
            {id="check", text="CHECK", x=width/2 - btnSpacing*0.5, y=btnY, w=btnW, h=btnH, type="action"},
            {id="raise", text="RAISE", x=width/2 + btnSpacing*0.5, y=btnY, w=btnW, h=btnH, type="action"},
            {id="deal", text="DEAL HAND", x=width/2 - btnW/2, y=height/2, w=btnW, h=btnH, type="action"},
            {id="raisePlus", text="+", x=width/2 + btnSpacing*1.5, y=btnY, w=btnH * 0.8, h=btnH * 0.8, type="adjust"},
            {id="raiseMinus", text="-", x=width/2 + btnSpacing*1.5 + btnH * 0.9, y=btnY, w=btnH * 0.8, h=btnH * 0.8, type="adjust"}
        }
    else
        self.buttons = {
            {id="fold", text="FOLD", x=width/2 - btnSpacing*1.6, y=btnY, w=btnW, h=btnH, type="fold"},
            {id="check", text="CHECK", x=width/2 - btnSpacing*0.5, y=btnY, w=btnW, h=btnH, type="action"},
            {id="raise", text="RAISE", x=width/2 + btnSpacing*0.6, y=btnY, w=btnW, h=btnH, type="action"},
            {id="deal", text="DEAL HAND", x=width/2 - btnW/2, y=height/2, w=btnW, h=btnH, type="action"},
            {id="raisePlus", text="+", x=width/2 + btnSpacing*1.8, y=btnY, w=btnH, h=btnH, type="adjust"},
            {id="raiseMinus", text="-", x=width/2 + btnSpacing*2.4, y=btnY, w=btnH, h=btnH, type="adjust"}
        }
    end
    
    -- Player and CPU hand positions
    self.layout.playerHandY = height - self.layout.cardH - (self.layout.screenSize == "small" and 60 or 100)
    self.layout.cpuHandY = self.layout.screenSize == "small" and 60 or 100
    
    -- Info panel positions
    self.layout.infoTop = self.layout.screenSize == "small" and 10 or 20
    self.layout.infoSpacing = self.layout.screenSize == "small" and 25 or 40
end

function PokerApp:drawBackground(x, y, width, height)
    -- Gradient background
    for i = 0, height, 2 do
        local progress = i / height
        local r = self.COLORS.bg[1] * (1 - progress * 0.3)
        local g = self.COLORS.bg[2] * (1 - progress * 0.3)
        local b = self.COLORS.bg[3] * (1 - progress * 0.3)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", x, y + i, width, 2)
    end
    
    -- Subtle pattern overlay
    love.graphics.setColor(1, 1, 1, 0.02)
    local patternSize = 40
    for i = 0, width, patternSize do
        for j = 0, height, patternSize do
            if (i + j) % (patternSize * 2) == 0 then
                love.graphics.rectangle("fill", x + i, y + j, patternSize, patternSize)
            end
        end
    end
end

function PokerApp:update(dt)
    -- Timer for CPU thinking or State Transitions
    if self.game.timer > 0 then
        self.game.timer = self.game.timer - dt
        if self.game.timer <= 0 then
            self:processTimerEvent()
        end
    end
    
    -- Animation updates
    if self.animations.dealing then
        self.animations.cardDealTimer = self.animations.cardDealTimer - dt
        if self.animations.cardDealTimer <= 0 then
            self.animations.cardsDealt = self.animations.cardsDealt + 1
            self.animations.cardDealTimer = 0.15
            
            if self.animations.cardsDealt >= 4 then -- 2 player cards + 2 CPU cards
                self.animations.dealing = false
            end
        end
    end
    
    if self.animations.potHighlight > 0 then
        self.animations.potHighlight = self.animations.potHighlight - dt
    end
    
    if self.animations.buttonPulse > 0 then
        self.animations.buttonPulse = self.animations.buttonPulse - dt
    end
    
    if self.animations.cardReveal > 0 then
        self.animations.cardReveal = self.animations.cardReveal - dt
    end
    
    -- Update Button States
    self:updateUIState()
end

function PokerApp:updateUIState()
    local callAmount = self.game.cpu.currentBet - self.game.player.currentBet
    
    for _, btn in ipairs(self.buttons) do
        if btn.id == "check" then
            if callAmount > 0 then 
                btn.text = "CALL $" .. callAmount 
            else 
                btn.text = "CHECK" 
            end
        elseif btn.id == "raise" then
            btn.text = "RAISE $" .. self.game.raiseAmount
        end
    end
end

function PokerApp:processTimerEvent()
    if self.game.state == 'GAMEOVER' then return end
    
    if self.game.turn == 'CPU' then
        self:cpuAI()
    elseif self.game.state == 'SHOWDOWN' then
        self:startNewHand()
    end
end

-- Enhanced Game Logic Functions
function PokerApp:resetDeck()
    self.game.deck = {}
    for _, s in ipairs(self.SUITS) do
        for _, r in ipairs(self.RANKS) do
            table.insert(self.game.deck, {suit=s, rank=r})
        end
    end
    -- Fisher-Yates shuffle
    for i = #self.game.deck, 2, -1 do
        local j = math.random(i)
        self.game.deck[i], self.game.deck[j] = self.game.deck[j], self.game.deck[i]
    end
end

function PokerApp:startNewHand()
    if self.game.player.chips <= 0 or self.game.cpu.chips <= 0 then
        self.game.state = 'GAMEOVER'
        self.game.message = self.game.player.chips > 0 and "VICTORY! YOU WIN THE TOURNAMENT!" or "GAME OVER - OUT OF CHIPS"
        return
    end

    self.stats.handsPlayed = self.stats.handsPlayed + 1
    self:resetDeck()
    
    -- Reset hand states
    self.game.player.hand = {}
    self.game.cpu.hand = {}
    self.game.community = {}
    self.game.player.currentBet = 0
    self.game.cpu.currentBet = 0
    self.game.player.status = ""
    self.game.cpu.status = ""
    self.game.player.lastAction = ""
    self.game.cpu.lastAction = ""
    self.game.showCards = false
    
    -- Start dealing animation
    self.animations.dealing = true
    self.animations.cardDealTimer = 0.2
    self.animations.cardsDealt = 0
    self.animations.cardReveal = 0.5
    
    -- Deal initial cards (face down for animation)
    self.game.player.hand = {table.remove(self.game.deck), table.remove(self.game.deck)}
    self.game.cpu.hand = {table.remove(self.game.deck), table.remove(self.game.deck)}
    
    -- Switch Dealer
    self.game.dealer = (self.game.dealer == 'PLAYER') and 'CPU' or 'PLAYER'
    
    -- Blinds
    local sb = self.game.minBet / 2
    local bb = self.game.minBet
    
    if self.game.dealer == 'PLAYER' then
        self:placeBet('player', sb)
        self:placeBet('cpu', bb)
        self.game.turn = 'PLAYER'
        self.game.message = "You are Small Blind ($"..sb.."). Your action."
        self.game.subMessage = "CPU is Big Blind"
    else
        self:placeBet('cpu', sb)
        self:placeBet('player', bb)
        self.game.turn = 'CPU'
        self.game.message = "You are Big Blind ($"..bb.."). CPU is thinking..."
        self.game.timer = 1.5
    end
    
    self.game.state = 'PREFLOP'
end

function PokerApp:placeBet(who, amount)
    local actor = (who == 'player') and self.game.player or self.game.cpu
    local actualBet = math.min(amount, actor.chips)
    
    actor.chips = actor.chips - actualBet
    actor.currentBet = actor.currentBet + actualBet
    self.game.pot = self.game.pot + actualBet
    
    -- Update biggest pot stat
    if self.game.pot > self.stats.biggestPot then
        self.stats.biggestPot = self.game.pot
    end
    
    -- Highlight pot animation
    self.animations.potHighlight = 1.0
    
    return actualBet
end

function PokerApp:nextStreet()
    self.game.player.currentBet = 0
    self.game.cpu.currentBet = 0
    
    if self.game.state == 'PREFLOP' then
        self.game.state = 'FLOP'
        self.game.message = "The Flop is dealt"
        self.game.subMessage = ""
        for i=1,3 do table.insert(self.game.community, table.remove(self.game.deck)) end
    elseif self.game.state == 'FLOP' then
        self.game.state = 'TURN'
        self.game.message = "The Turn is dealt"
        table.insert(self.game.community, table.remove(self.game.deck))
    elseif self.game.state == 'TURN' then
        self.game.state = 'RIVER'
        self.game.message = "The River is dealt"
        table.insert(self.game.community, table.remove(self.game.deck))
    elseif self.game.state == 'RIVER' then
        self:evaluateShowdown()
        return
    end
    
    self.game.turn = (self.game.dealer == 'PLAYER') and 'CPU' or 'PLAYER'
    
    if self.game.turn == 'PLAYER' then
        self.game.message = self.game.state .. " - Your turn to act"
    else
        self.game.message = self.game.state .. " - CPU is thinking..."
        self.game.timer = 1.5
    end
end

function PokerApp:playerAction(action)
    if self.game.turn ~= 'PLAYER' then return end
    
    local toCall = self.game.cpu.currentBet - self.game.player.currentBet
    
    if action == "fold" then
        self.stats.folds = self.stats.folds + 1
        self.game.player.status = "Folded"
        self.game.player.lastAction = "folded"
        self.game.cpu.chips = self.game.cpu.chips + self.game.pot
        self.game.message = "You Folded. CPU wins $" .. self.game.pot
        self.game.subMessage = self:getRandomDialogue("win")
        self.game.pot = 0
        self.game.showCards = true
        self.game.timer = 3.0
        self.game.state = 'SHOWDOWN'
        self.stats.currentStreak = 0
        
    elseif action == "check" then
        if toCall > 0 then
            self:placeBet('player', toCall)
            self.game.player.status = "Called $" .. toCall
            self.game.player.lastAction = "called"
            self:nextStreet()
        else
            self.game.player.status = "Checked"
            self.game.player.lastAction = "checked"
            if self.game.cpu.status == "Checked" then
                self:nextStreet()
            else
                self.game.turn = 'CPU'
                self.game.message = "CPU is thinking..."
                self.game.timer = 1.2
            end
        end
        
    elseif action == "raise" then
        local raiseAmt = toCall + self.game.raiseAmount
        if raiseAmt > self.game.player.chips then
            raiseAmt = self.game.player.chips
        end
        self:placeBet('player', raiseAmt)
        self.game.player.status = "Raised $" .. self.game.raiseAmount
        self.game.player.lastAction = "raised"
        self.game.turn = 'CPU'
        self.game.message = "CPU is thinking..."
        self.game.timer = 1.5
    elseif action == "raisePlus" then
        self.game.raiseAmount = math.min(self.game.raiseAmount + 25, self.game.maxRaise, self.game.player.chips)
        self.animations.buttonPulse = 0.3
    elseif action == "raiseMinus" then
        self.game.raiseAmount = math.max(self.game.raiseAmount - 25, self.game.minBet)
        self.animations.buttonPulse = 0.3
    end
end

function PokerApp:cpuAI()
    local toCall = self.game.player.currentBet - self.game.cpu.currentBet
    local handStrength = self:estimateHandStrength(self.game.cpu.hand, self.game.community)
    local bluffFactor = math.random()
    local potOdds = toCall > 0 and (toCall / (self.game.pot + toCall)) or 0
    
    -- Personality adjustments
    local adjustedHandStrength = handStrength * (0.8 + self.cpuPersonality.aggressive * 0.4)
    local bluffChance = self.cpuPersonality.bluffFrequency
    
    local action = "fold"
    
    if toCall == 0 then
        -- CPU can check or bet
        if adjustedHandStrength > 0.35 or (bluffFactor < bluffChance and adjustedHandStrength > 0.15) then
            local betAmount = math.min(self.game.minBet * math.random(2, 4), math.floor(self.game.cpu.chips * 0.4))
            self:placeBet('cpu', betAmount)
            self.game.cpu.status = "Bets $" .. betAmount
            self.game.cpu.lastAction = "bet"
            self.game.cpu.dialogue = self:getRandomDialogue("raise")
            self.game.turn = 'PLAYER'
            self.game.message = "CPU Bets. Your turn."
            self.game.subMessage = self.game.cpu.dialogue
        else
            self.game.cpu.status = "Checked"
            self.game.cpu.lastAction = "checked"
            if self.game.player.lastAction == "checked" or self.game.state ~= 'PREFLOP' then
                if self.game.dealer == 'CPU' and self.game.state == 'PREFLOP' then
                    self.game.turn = 'PLAYER'
                else
                    self:nextStreet()
                end
            else
                self.game.turn = 'PLAYER'
                self.game.message = "CPU Checks. Your turn."
                self.game.subMessage = self:getRandomDialogue("call")
            end
        end
    else
        -- CPU faces a bet
        if adjustedHandStrength > 0.55 or (adjustedHandStrength > potOdds + 0.15 and adjustedHandStrength > 0.25) then
            if (adjustedHandStrength > 0.75 and bluffFactor > 0.3) or (bluffFactor < bluffChance and adjustedHandStrength > 0.4) then
                local raiseAmt = toCall + math.min(self.game.minBet * math.random(2, 4), math.floor(self.game.cpu.chips * 0.5))
                self:placeBet('cpu', raiseAmt)
                self.game.cpu.status = "Raised!"
                self.game.cpu.lastAction = "raised"
                self.game.cpu.dialogue = self:getRandomDialogue(bluffFactor < bluffChance and "bluff" or "raise")
                self.game.turn = 'PLAYER'
                self.game.message = "CPU Raises!"
                self.game.subMessage = self.game.cpu.dialogue
            else
                self:placeBet('cpu', toCall)
                self.game.cpu.status = "Called"
                self.game.cpu.lastAction = "called"
                self.game.cpu.dialogue = self:getRandomDialogue("call")
                self.game.subMessage = self.game.cpu.dialogue
                self:nextStreet()
            end
        elseif adjustedHandStrength > potOdds and adjustedHandStrength > 0.2 then
            self:placeBet('cpu', toCall)
            self.game.cpu.status = "Called"
            self.game.cpu.lastAction = "called"
            self.game.cpu.dialogue = self:getRandomDialogue("call")
            self.game.subMessage = self.game.cpu.dialogue
            self:nextStreet()
        else
            self.game.cpu.status = "Folded"
            self.game.cpu.lastAction = "folded"
            self.game.cpu.dialogue = self:getRandomDialogue("fold")
            self.game.player.chips = self.game.player.chips + self.game.pot
            self.game.message = "CPU Folds! You win $" .. self.game.pot
            self.game.subMessage = self.game.cpu.dialogue
            self.game.pot = 0
            self.game.showCards = true
            self.game.timer = 3.0
            self.game.state = 'SHOWDOWN'
            self.stats.currentStreak = self.stats.currentStreak + 1
            if self.stats.currentStreak > self.stats.bestStreak then
                self.stats.bestStreak = self.stats.currentStreak
            end
        end
    end
end

function PokerApp:evaluateShowdown()
    self.game.state = 'SHOWDOWN'
    self.game.showCards = true
    local pScore, pDesc = self:getHandScore(self.game.player.hand, self.game.community)
    local cScore, cDesc = self:getHandScore(self.game.cpu.hand, self.game.community)
    
    local txt = "You: " .. pDesc .. " | CPU: " .. cDesc
    
    if pScore > cScore then
        self.game.message = txt .. " - YOU WIN!"
        self.game.subMessage = self:getRandomDialogue("lose")
        self.game.player.chips = self.game.player.chips + self.game.pot
        self.stats.playerWins = self.stats.playerWins + 1
        self.stats.currentStreak = self.stats.currentStreak + 1
        if self.stats.currentStreak > self.stats.bestStreak then
            self.stats.bestStreak = self.stats.currentStreak
        end
    elseif cScore > pScore then
        self.game.message = txt .. " - CPU WINS!"
        self.game.subMessage = self:getRandomDialogue("win")
        self.game.cpu.chips = self.game.cpu.chips + self.game.pot
        self.stats.cpuWins = self.stats.cpuWins + 1
        self.stats.currentStreak = 0
    else
        self.game.message = txt .. " - SPLIT POT!"
        self.game.subMessage = "It's a tie!"
        local halfPot = math.floor(self.game.pot/2)
        self.game.player.chips = self.game.player.chips + halfPot
        self.game.cpu.chips = self.game.cpu.chips + halfPot
    end
    
    self.game.pot = 0
    self.game.timer = 4.0
end

function PokerApp:getRandomDialogue(category)
    local dialogues = self.cpuPersonality.dialogues[category]
    return dialogues[math.random(1, #dialogues)]
end

function PokerApp:estimateHandStrength(hole, comm)
    if #comm == 0 then
        -- Pre-flop estimation
        local r1, r2 = hole[1].rank, hole[2].rank
        local suited = hole[1].suit == hole[2].suit
        
        -- Premium hands
        if r1 == 14 and r2 == 14 then return 0.95 end -- AA
        if r1 == 14 and r2 == 13 and suited then return 0.93 end -- AKs
        if (r1 == 14 and r2 == 13) then return 0.90 end -- AKo
        if r1 == 14 and r2 == 14 then return 0.95 end -- AA
        if r1 == 13 and r2 == 13 then return 0.91 end -- KK
        
        -- Good pairs
        if r1 == r2 and r1 >= 10 then return 0.85 end -- QQ, JJ, TT
        if r1 == r2 and r1 >= 7 then return 0.75 end -- 99, 88, 77
        
        -- Suited connectors
        if suited and math.abs(r1 - r2) == 1 and r1 >= 6 then return 0.65 end
        
        -- Default weak hand
        return 0.3
    end
    
    local s, _ = self:getHandScore(hole, comm)
    if s > 8000000 then return 1.0      -- Straight Flush
    elseif s > 7000000 then return 0.95  -- Four of a Kind
    elseif s > 6000000 then return 0.90  -- Full House
    elseif s > 5000000 then return 0.85  -- Flush
    elseif s > 4000000 then return 0.75  -- Straight
    elseif s > 3000000 then return 0.65  -- Three of a Kind
    elseif s > 2000000 then return 0.55  -- Two Pair
    elseif s > 1000000 then return 0.45  -- Pair
    else return 0.2 end                  -- High Card
end

-- Enhanced Drawing Functions
function PokerApp:drawStartScreen(x, y, width, height)
    -- Title with gradient effect
    love.graphics.setColor(self.COLORS.gold)
    love.graphics.setFont(self.fonts.huge)
    local title = "TEXAS HOLD'EM POKER"
    local titleW = self.fonts.huge:getWidth(title)
    love.graphics.print(title, x + width/2 - titleW/2, y + height/4)
    
    -- Subtitle
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    local subtitle = "High Stakes Championship"
    local subW = self.fonts.medium:getWidth(subtitle)
    -- love.graphics.print(subtitle, x + width/2 - subW/2, y + height/4 + (self.layout.screenSize == "small" and 40 : 60))
    
    -- Enhanced Statistics
    love.graphics.setFont(self.fonts.small)
    local statsText = string.format("Hands: %d | Wins: %d | Losses: %d | Folds: %d", 
        self.stats.handsPlayed, self.stats.playerWins, self.stats.cpuWins, self.stats.folds)
    local statsW = self.fonts.small:getWidth(statsText)
    love.graphics.print(statsText, x + width/2 - statsW/2, y + height/2 - 40)
    
    -- Additional stats
    local statsText2 = string.format("Biggest Pot: $%d | Current Streak: %d | Best Streak: %d", 
        self.stats.biggestPot, self.stats.currentStreak, self.stats.bestStreak)
    local statsW2 = self.fonts.small:getWidth(statsText2)
    love.graphics.print(statsText2, x + width/2 - statsW2/2, y + height/2 - 15)
    
    -- Deal button with enhanced styling
    for _, btn in ipairs(self.buttons) do
        if btn.id == "deal" then
            self:drawButton(btn, x, y, true)
        end
    end
    
    -- Tips - responsive positioning
    love.graphics.setColor(self.COLORS.textDim)
    love.graphics.setFont(self.fonts.tiny)
    local tipText = "Tip: Watch for betting patterns and CPU's dialogue for hints!"
    local tipW = self.fonts.tiny:getWidth(tipText)
    -- local tipY = self.layout.screenSize == "small" and y + height - 30 : y + height - 50
	local tipY = (self.layout.screenSize == "small" and (y + height - 30) or (y + height - 50))

    love.graphics.print(tipText, x + width/2 - tipW/2, tipY)
end

function PokerApp:drawGameOver(x, y, width, height)
    love.graphics.setColor(self.COLORS.gold)
    love.graphics.setFont(self.fonts.huge)
    local w = self.fonts.huge:getWidth(self.game.message)
    love.graphics.print(self.game.message, x + width/2 - w/2, y + height/2 - 50)
    
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    local finalStats = string.format("Final Score: %d wins, %d losses in %d hands", 
        self.stats.playerWins, self.stats.cpuWins, self.stats.handsPlayed)
    local statsW = self.fonts.medium:getWidth(finalStats)
    love.graphics.print(finalStats, x + width/2 - statsW/2, y + height/2 + 20)
    
    love.graphics.setFont(self.fonts.small)
    local restartText = "Press 'Deal' to Play Again"
    local restartW = self.fonts.small:getWidth(restartText)
    love.graphics.print(restartText, x + width/2 - restartW/2, y + height/2 + 70)
end

function PokerApp:drawGameTable(x, y, width, height)
    -- Draw poker table surface with gradient
    self:drawPokerTable(x, y, width, height)
    
    -- Pot display with animation
    self:drawPotDisplay(x, y, width, height)
    
    -- Main message and submessage (CPU dialogue)
    self:drawGameMessages(x, y, width, height)

    -- Community Cards with dealing animation
    self:drawCommunityCards(x, y, width, height)

    -- Player Hand & Info
    self:drawPlayerArea(x, y, width, height)

    -- CPU Hand & Info
    self:drawCPUArea(x, y, width, height)

    -- Draw chips in pot
    self:drawChips(x + width/2, y + height/2, self.game.pot)

    -- UI Buttons
    if self.game.turn == 'PLAYER' and self.game.state ~= 'SHOWDOWN' then
        self:drawButtons(x, y)
    end
    
    -- Raise amount display
    if self.game.turn == 'PLAYER' then
        self:drawRaiseAmount(x, y, width, height)
    end
end

function PokerApp:drawPokerTable(x, y, width, height)
    -- Table with gradient
    for i = 0, self.layout.tableR * 2, 2 do
        local progress = i / (self.layout.tableR * 2)
        local r = self.COLORS.table[1] + (self.COLORS.tableHighlight[1] - self.COLORS.table[1]) * progress
        local g = self.COLORS.table[2] + (self.COLORS.tableHighlight[2] - self.COLORS.table[2]) * progress
        local b = self.COLORS.table[3] + (self.COLORS.tableHighlight[3] - self.COLORS.table[3]) * progress
        love.graphics.setColor(r, g, b)
        love.graphics.circle("fill", x + width/2, y + height/2, self.layout.tableR - i/2)
    end
    
    -- Table outline
    love.graphics.setColor(self.COLORS.tableOutline)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", x + width/2, y + height/2, self.layout.tableR)
    
    -- Table felt pattern
    love.graphics.setColor(1, 1, 1, 0.05)
    local patternSize = 30
    for i = -self.layout.tableR, self.layout.tableR, patternSize do
        for j = -self.layout.tableR, self.layout.tableR, patternSize do
            if i*i + j*j < self.layout.tableR * self.layout.tableR then
                if (i + j) % (patternSize * 2) == 0 then
                    love.graphics.rectangle("fill", x + width/2 + i, y + height/2 + j, patternSize, patternSize)
                end
            end
        end
    end
end

function PokerApp:drawPotDisplay(x, y, width, height)
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.large)
    local potText = "Pot: $" .. self.game.pot
    local potW = self.fonts.large:getWidth(potText)
    
    -- Animate pot when it changes
    if self.animations.potHighlight > 0 then
        local pulse = 0.5 + 0.5 * math.sin(self.animations.potHighlight * 20)
        love.graphics.setColor(1, 1, 0.5, pulse)
    end
    love.graphics.print(potText, x + width/2 - potW/2, y + self.layout.infoTop)
end

function PokerApp:drawGameMessages(x, y, width, height)
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    local msgW = self.fonts.medium:getWidth(self.game.message)
    love.graphics.print(self.game.message, x + width/2 - msgW/2, y + self.layout.infoTop + self.layout.infoSpacing)
    
    if self.game.subMessage ~= "" then
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.setFont(self.layout.screenSize == "small" and self.fonts.tiny or self.fonts.small)
        local subW = love.graphics.getFont():getWidth(self.game.subMessage)
        love.graphics.print(self.game.subMessage, x + width/2 - subW/2, y + self.layout.infoTop + self.layout.infoSpacing * 2)
    end
end

function PokerApp:drawCommunityCards(x, y, width, height)
    local totalW = (#self.game.community * (self.layout.cardW + self.layout.padding)) - self.layout.padding
    local startX = x + width/2 - totalW / 2
    local commY = y + height/2 - self.layout.cardH/2
    
    for i, card in ipairs(self.game.community) do
        self:drawCard(card, startX + (i-1)*(self.layout.cardW + self.layout.padding), commY)
    end
end

function PokerApp:drawPlayerArea(x, y, width, height)
    local pHandX = x + width/2 - (self.layout.cardW + self.layout.padding/2)
    local pHandY = y + self.layout.playerHandY
    
    for i, card in ipairs(self.game.player.hand) do
        if self.animations.dealing and self.animations.cardsDealt < i then
            self:drawCardBack(pHandX + (i-1)*(self.layout.cardW + 8), pHandY)
        else
            self:drawCard(card, pHandX + (i-1)*(self.layout.cardW + 8), pHandY)
        end
    end
	local offset = self.layout.screenSize == "small" and 80 or 120
	self:drawPlayerHUD("PLAYER", self.game.player, x + 30, y + height - offset, self.game.dealer == 'PLAYER')
end

function PokerApp:drawCPUArea(x, y, width, height)
    local cHandX = x + width/2 - (self.layout.cardW + self.layout.padding/2)
    local cHandY = y + self.layout.cpuHandY
    
    for i, card in ipairs(self.game.cpu.hand) do
        if self.animations.dealing and self.animations.cardsDealt < i+2 then
            self:drawCardBack(cHandX + (i-1)*(self.layout.cardW + 8), cHandY)
        elseif self.game.showCards or self.game.state == 'SHOWDOWN' then
            self:drawCard(card, cHandX + (i-1)*(self.layout.cardW + 8), cHandY)
        else
            self:drawCardBack(cHandX + (i-1)*(self.layout.cardW + 8), cHandY)
        end
    end
    self:drawPlayerHUD("CPU", self.game.cpu, x + 30, y + (self.layout.screenSize == "small" and 20), self.game.dealer == 'CPU')
end

function PokerApp:drawRaiseAmount(x, y, width, height)
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.small)
    local raiseText = "Raise Amount: $" .. self.game.raiseAmount
    local raiseW = self.fonts.small:getWidth(raiseText)
    local raiseX = self.layout.screenSize == "small" and x + width/2 - raiseW/2 
    local raiseY = self.layout.screenSize == "small" and y + height - 100 
    love.graphics.print(raiseText, raiseX, raiseY)
end

function PokerApp:drawChips(x, y, amount)
    local chipCount = math.min(math.floor(amount / 25), 12)
    
    for i = 1, chipCount do
        local angle = (i * 0.5) % (2 * math.pi)
        local offsetX = math.cos(angle) * (15 + i * 0.5)
        local offsetY = math.sin(angle) * (10 + i * 0.3)
        
        -- Different colored chips based on value
        if amount >= 500 then
            love.graphics.setColor(self.COLORS.chipGold)
        elseif amount >= 200 then
            love.graphics.setColor(self.COLORS.chipRed)
        elseif amount >= 100 then
            love.graphics.setColor(self.COLORS.chipBlue)
        else
            love.graphics.setColor(self.COLORS.chipGreen)
        end
        
        love.graphics.circle("fill", x + offsetX, y + offsetY, 12)
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.circle("line", x + offsetX, y + offsetY, 12)
        
        -- Chip highlight
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.arc("fill", x + offsetX, y + offsetY, 10, math.pi * 0.2, math.pi * 0.8)
    end
end

function PokerApp:drawPlayerHUD(name, actor, x, y, isDealer)
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print(name, x, y)
    
    -- Chips with color coding
    if actor.chips > 1000 then
        love.graphics.setColor(self.COLORS.gold)
    else
	love.graphics.setColor(0.7, 0.7, 0.9)
    end
    love.graphics.print("$" .. actor.chips, x, y + 25)
    
    -- Status and last action
    if actor.status ~= "" then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print(actor.status, x + (self.layout.screenSize == "small" and 80), y + 25)
    end
    
    -- Dealer button
    if isDealer then
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", x + (self.layout.screenSize == "small" and 70), y + 10, 8)
        love.graphics.setColor(0,0,0)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print("D", x + (self.layout.screenSize == "small" and 67), y + 4)
    end
    
    -- Draw chips stack visualization
    self:drawChipStack(x + (self.layout.screenSize == "small" and 150), y + 15, actor.chips)
end

function PokerApp:drawChipStack(x, y, chips)
    local stackHeight = math.min(math.floor(chips / 100), 8)
    
    for i = 1, stackHeight do
        if chips >= 1000 then
            love.graphics.setColor(self.COLORS.chipGold)
        elseif chips >= 500 then
            love.graphics.setColor(self.COLORS.chipRed)
        else
            love.graphics.setColor(self.COLORS.chipBlue)
        end
        love.graphics.rectangle("fill", x, y - i * 3, 20, 2)
        
        -- Stack shading
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("line", x, y - i * 3, 20, 2)
    end
end

function PokerApp:drawButtons(x, y)
    for _, btn in ipairs(self.buttons) do
        if btn.id ~= "deal" then
            self:drawButton(btn, x, y, false)
        end
    end
end

function PokerApp:drawButton(btn, offsetX, offsetY, isMain)
    local mx, my = love.mouse.getPosition()
    local isHover = mx > btn.x + offsetX and mx < btn.x + offsetX + btn.w and 
                   my > btn.y + offsetY and my < btn.y + offsetY + btn.h
    
    local btnColor
    if isHover then 
        btnColor = self.COLORS.buttonHover
    elseif btn.type == "fold" then 
        btnColor = self.COLORS.buttonFold
    else 
        btnColor = self.COLORS.buttonActive 
    end
    
    -- Pulsing animation for adjust buttons
    if (btn.id == "raisePlus" or btn.id == "raiseMinus") and self.animations.buttonPulse > 0 then
        local pulse = 0.2 + 0.8 * math.sin(self.animations.buttonPulse * 20)
        btnColor = {
            btnColor[1] * pulse,
            btnColor[2] * pulse,
            btnColor[3] * pulse
        }
    end
    
    -- Enhanced button with shadow and gradient
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.rectangle("fill", btn.x + offsetX + 3, btn.y + offsetY + 5, btn.w, btn.h, 12)
    
    -- Button body with gradient
    for i = 0, btn.h, 2 do
        local progress = i / btn.h
        local r = btnColor[1] * (1 - progress * 0.2)
        local g = btnColor[2] * (1 - progress * 0.2)
        local b = btnColor[3] * (1 - progress * 0.2)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", btn.x + offsetX, btn.y + offsetY + i, btn.w, 2)
    end
    
    -- Button border
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x + offsetX, btn.y + offsetY, btn.w, btn.h, 10)
    
    -- Hover glow
    if isHover then
        love.graphics.setColor(1,1,1,0.1)
        love.graphics.rectangle("fill", btn.x + offsetX, btn.y + offsetY, btn.w, btn.h, 10)
    end
    
    -- Text
    love.graphics.setColor(self.COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    local tw = self.fonts.medium:getWidth(btn.text)
    local th = self.fonts.medium:getHeight()
    love.graphics.print(btn.text, btn.x + offsetX + btn.w/2 - tw/2, btn.y + offsetY + btn.h/2 - th/2)
end

-- Enhanced Card Drawing Functions
function PokerApp:drawCard(card, x, y)
    -- Card background with subtle texture
    if self.animations.cardReveal > 0 then
        local revealProgress = 1 - (self.animations.cardReveal / 0.5)
        love.graphics.setColor(
            self.COLORS.card[1] * revealProgress + self.COLORS.cardBack[1] * (1 - revealProgress),
            self.COLORS.card[2] * revealProgress + self.COLORS.cardBack[2] * (1 - revealProgress),
            self.COLORS.card[3] * revealProgress + self.COLORS.cardBack[3] * (1 - revealProgress)
        )
    else
        love.graphics.setColor(self.COLORS.card)
    end
    love.graphics.rectangle("fill", x, y, self.layout.cardW, self.layout.cardH, 6)
    
    -- Card border
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, self.layout.cardW, self.layout.cardH, 6)
    
    -- Card highlight
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", x, y, self.layout.cardW, self.layout.cardH * 0.3, 6, 6, 0, 0)
    
    local isRed = (card.suit == 'hearts' or card.suit == 'diamonds')
    love.graphics.setColor(isRed and self.COLORS.redSuit or self.COLORS.blackSuit)
    
    -- Rank in corner
    love.graphics.setFont(self.fonts.medium)
    local rStr = self.RANK_STR[card.rank] or tostring(card.rank)
    love.graphics.print(rStr, x + 6, y + 4)
    
    -- Suit in corner
    self:drawSuitShape(card.suit, x + 10, y + 25, self.layout.cardW * 0.15)
    
    -- Large center suit
    local cx, cy = x + self.layout.cardW/2, y + self.layout.cardH/2 + 8
    self:drawSuitShape(card.suit, cx, cy, self.layout.cardW * 0.25)
end

function PokerApp:drawCardBack(x, y)
    -- Animated card flip
    if self.animations.cardReveal > 0 then
        local revealProgress = self.animations.cardReveal / 0.5
        love.graphics.setColor(
            self.COLORS.card[1] * (1 - revealProgress) + self.COLORS.cardBack[1] * revealProgress,
            self.COLORS.card[2] * (1 - revealProgress) + self.COLORS.cardBack[2] * revealProgress,
            self.COLORS.card[3] * (1 - revealProgress) + self.COLORS.cardBack[3] * revealProgress
        )
    else
        love.graphics.setColor(self.COLORS.card)
    end
    love.graphics.rectangle("fill", x, y, self.layout.cardW, self.layout.cardH, 6)
    
    -- Card back pattern
    love.graphics.setColor(self.COLORS.cardBack)
    love.graphics.rectangle("fill", x+4, y+4, self.layout.cardW-8, self.layout.cardH-8, 4)
    
    -- Diamond pattern
    love.graphics.setColor(1,1,1,0.15)
    local patternSize = self.layout.cardW / 4
    for i = 0, 3 do
        for j = 0, 5 do
            if (i + j) % 2 == 0 then
                self:drawSuitShape('diamonds', x + patternSize * (i + 0.5), y + patternSize * (j + 0.5), patternSize * 0.3)
            end
        end
    end
    
    -- Cross pattern
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(1,1,1,0.1)
    love.graphics.line(x+4, y+4, x+self.layout.cardW-4, y+self.layout.cardH-4)
    love.graphics.line(x+self.layout.cardW-4, y+4, x+4, y+self.layout.cardH-4)
    
    -- Card back highlight
    love.graphics.setColor(1,1,1,0.05)
    love.graphics.rectangle("fill", x, y, self.layout.cardW, self.layout.cardH * 0.3, 6, 6, 0, 0)
end

function PokerApp:drawSuitShape(suit, x, y, r)
    if suit == 'hearts' then
        love.graphics.circle("fill", x-r/2, y-r/2, r/2)
        love.graphics.circle("fill", x+r/2, y-r/2, r/2)
        love.graphics.polygon("fill", x-r, y-r/4, x+r, y-r/4, x, y+r)
    elseif suit == 'diamonds' then
        love.graphics.polygon("fill", x, y-r, x+r*0.8, y, x, y+r, x-r*0.8, y)
    elseif suit == 'clubs' then
        love.graphics.circle("fill", x-r/2, y, r/2.5)
        love.graphics.circle("fill", x+r/2, y, r/2.5)
        love.graphics.circle("fill", x, y-r/1.5, r/2.5)
        love.graphics.polygon("fill", x-r/3, y-r/4, x+r/3, y-r/4, x, y+r)
    elseif suit == 'spades' then
        love.graphics.circle("fill", x-r/2, y+r/4, r/2)
        love.graphics.circle("fill", x+r/2, y+r/4, r/2)
        love.graphics.polygon("fill", x-r, y+r/2, x+r, y+r/2, x, y-r)
        love.graphics.polygon("fill", x, y, x+r/4, y+r, x-r/4, y+r)
    end
end

-- Check if a point is inside a button
function PokerApp:isPointInButton(x, y, btn)
    return x >= btn.x and x <= btn.x + btn.w and
           y >= btn.y and y <= btn.y + btn.h
end

-- Mouse input
function PokerApp:mousepressed(mx, my, button)
    if button ~= 1 then return end

    -- Handle START or GAMEOVER state
    if self.game.state == 'START' or self.game.state == 'GAMEOVER' then
        for _, btn in ipairs(self.buttons) do
            if btn.id == 'deal' and self:isPointInButton(mx, my, btn) then
                if self.game.state == 'GAMEOVER' then
                    -- Reset game for new tournament
                    self.game.player.chips = 1500
                    self.game.cpu.chips = 1500
                    self.stats.currentStreak = 0
                end
                self:startNewHand()
            end
        end
        return
    end

    -- Handle PLAYER actions during the game
    if self.game.turn == 'PLAYER' and self.game.state ~= 'SHOWDOWN' and self.game.state ~= 'GAMEOVER' then
        for _, btn in ipairs(self.buttons) do
            if btn.id ~= 'deal' and self:isPointInButton(mx, my, btn) then
                self:playerAction(btn.id)
            end
        end
    end
end



function PokerApp:keypressed(key)
    if key == 'space' and (self.game.state == 'GAMEOVER' or self.game.state == 'START') then
        self.game.player.chips = 1500
        self.game.cpu.chips = 1500
        self.stats.currentStreak = 0
        self.game.state = 'START'
        self.game.message = "New Tournament Started!"
    elseif key == 'r' and self.game.turn == 'PLAYER' then
        self.game.raiseAmount = math.min(self.game.raiseAmount + 25, self.game.maxRaise, self.game.player.chips)
        self.animations.buttonPulse = 0.3
    elseif key == 'e' and self.game.turn == 'PLAYER' then
        self.game.raiseAmount = math.max(self.game.raiseAmount - 25, self.game.minBet)
        self.animations.buttonPulse = 0.3
    elseif key == 'f' and self.game.turn == 'PLAYER' then
        self:playerAction("fold")
    elseif key == 'c' and self.game.turn == 'PLAYER' then
        self:playerAction("check")
    end
end

-- Hand Evaluation (from original code with minor improvements)
function PokerApp:getHandScore(hole, comm)
    local cards = {}
    for _,c in pairs(hole) do table.insert(cards, c) end
    for _,c in pairs(comm) do table.insert(cards, c) end
    if #cards < 5 then return 0, "Incomplete Hand" end
    
    local ranks, suits = {}, {hearts=0, diamonds=0, clubs=0, spades=0}
    for _, c in ipairs(cards) do
        ranks[c.rank] = (ranks[c.rank] or 0) + 1
        suits[c.suit] = suits[c.suit] + 1
    end
    
    local flushS = nil
    for s,n in pairs(suits) do
        if n>=5 then flushS = s end
    end
    
    local uRanks = {}
    for r,_ in pairs(ranks) do table.insert(uRanks, r) end
    table.sort(uRanks, function(a,b) return a>b end)
    
    local strHigh = 0
    local run = 0
    for i=1, #uRanks-1 do
        if uRanks[i] == uRanks[i+1]+1 then
            run = run + 1
            if run >= 4 then strHigh = uRanks[i-3] end
        else
            run = 0
        end
    end
    
    -- Check for Ace-low straight (A,2,3,4,5)
    if run < 4 and ranks[14] and ranks[2] and ranks[3] and ranks[4] and ranks[5] then
        strHigh = 5
    end
    
    local four, three, pair1, pair2 = 0, 0, 0, 0
    for r,n in pairs(ranks) do
        if n == 4 then
            four = r
        elseif n == 3 then
            if r > three then three = r end
        elseif n == 2 then
            if r > pair1 then
                pair2 = pair1
                pair1 = r
            elseif r > pair2 then
                pair2 = r
            end
        end
    end
    
    if flushS and strHigh > 0 then
        return 8000000 + strHigh, "Straight Flush"
    end
    if four > 0 then
        return 7000000 + four, "Four of a Kind"
    end
    if three > 0 and pair1 > 0 then
        return 6000000 + three, "Full House"
    end
    if flushS then
        return 5000000, "Flush"
    end
    if strHigh > 0 then
        return 4000000 + strHigh, "Straight"
    end
    if three > 0 then
        return 3000000 + three, "Three of a Kind"
    end
    if pair1 > 0 and pair2 > 0 then
        return 2000000 + (pair1 * 100) + pair2, "Two Pair"
    end
    if pair1 > 0 then
        return 1000000 + pair1, "Pair"
    end
    
    local kickers = 0
    for i=1, math.min(5, #uRanks) do
        kickers = kickers + uRanks[i] * math.pow(14, 5-i)
    end
    return kickers, "High Card"
end

return PokerApp