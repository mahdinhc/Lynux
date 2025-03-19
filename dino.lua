-- dinoApp.lua
local dinoApp = {}
dinoApp.__index = dinoApp

-- Configuration and constants
local CONFIG = {
  FPS = 60,
  WIDTH = 600,   -- Design width
  HEIGHT = 400,  -- Design height
  BOTTOM_PAD = 10,
  GRAVITY = 0.6,
  INITIAL_JUMP_VELOCITY = 12,
  SPEED = 6,
  ACCELERATION = 0.001,
  MAX_SPEED = 13,
  INVERT_DISTANCE = 700,
  -- You can add more constants if needed.
}

-- Sprite definitions (adjust coordinates as needed)
local SPRITES = {
  CACTUS_LARGE = { x = 332, y = 2, w = 25, h = 50 },
  CACTUS_SMALL = { x = 228, y = 2, w = 17, h = 35 },
  CLOUD = { x = 86, y = 2, w = 46, h = 14 },
  MOON = { x = 484, y = 2, w = 20, h = 40 },
  PTERODACTYL = { x = 134, y = 2, w = 46, h = 40 },
  RESTART = { x = 2, y = 2, w = 36, h = 32 },
  TEXT_SPRITE = { x = 655, y = 2, w = 191, h = 11 },
  TREX = { x = 848, y = 2, w = 44, h = 47 },
  STAR = { x = 645, y = 2, w = 20, h = 20 },
}

-- Trex animation definitions
local TrexAnim = {
  WAITING = { frames = {44, 0}, msPerFrame = 1000/3 },
  RUNNING = { frames = {88, 132}, msPerFrame = 1000/12 },
  CRASHED = { frames = {220}, msPerFrame = 1000/60 },
  JUMPING = { frames = {0}, msPerFrame = 1000/60 },
  DUCKING  = { frames = {264, 323}, msPerFrame = 1000/8 },
}

-- Global game state (per instance)
local GameState = {
  playing = false,
  crashed = false,
  highScore = 0,
  speed = CONFIG.SPEED,
  distanceRan = 0,
  time = 0,
}

------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------
local function getRandomNum(min, max)
  return math.floor(math.random() * (max - min + 1)) + min
end

local function checkCollision(a, b)
  return a.x < b.x + b.w and a.x + a.w > b.x and
         a.y < b.y + b.h and a.y + a.h > b.y
end

------------------------------------------------------------
-- Global assets (loaded once per dinoApp instance)
------------------------------------------------------------
local spritesheet = nil

------------------------------------------------------------
-- Trex Object
------------------------------------------------------------
local Trex = {}
Trex.__index = Trex

function Trex:new()
  local self = setmetatable({}, Trex)
  self.width = SPRITES.TREX.w
  self.height = SPRITES.TREX.h
  self.duckWidth = 59
  self.groundY = CONFIG.HEIGHT - self.height - CONFIG.BOTTOM_PAD
  self.x = 50
  self.y = self.groundY
  self.jumping = false
  self.ducking = false
  self.jumpVelocity = 0
  self.speedDrop = false
  self.timer = 0
  self.msPerFrame = TrexAnim.WAITING.msPerFrame
  self.currentFrame = 1
  self.currentAnim = TrexAnim.WAITING
  return self
end

function Trex:update(dt)
  self.timer = self.timer + dt * 1000
  if self.timer >= self.msPerFrame then
    self.currentFrame = self.currentFrame % #self.currentAnim.frames + 1
    self.timer = 0
  end
  if self.jumping then
    local framesElapsed = dt * 60
    if self.speedDrop then
      self.y = self.y + self.jumpVelocity * 1.5 * framesElapsed
    else
      self.y = self.y + self.jumpVelocity * framesElapsed
    end
    self.jumpVelocity = self.jumpVelocity + CONFIG.GRAVITY * framesElapsed
    if self.y >= self.groundY then
      self.y = self.groundY
      self.jumping = false
      self.jumpVelocity = 0
    end
  end
end

function Trex:draw()
  local frameVal = self.currentAnim.frames[self.currentFrame]
  local spriteW, spriteH
  if self.ducking and self.currentAnim ~= TrexAnim.CRASHED then
    spriteW = self.duckWidth
    spriteH = SPRITES.TREX.h
  else
    spriteW = SPRITES.TREX.w
    spriteH = SPRITES.TREX.h
  end
  local quad = love.graphics.newQuad(SPRITES.TREX.x + frameVal, SPRITES.TREX.y, spriteW, spriteH,
    spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

function Trex:startJump()
  if not self.jumping and not self.ducking then
    self.jumping = true
    self.jumpVelocity = -CONFIG.INITIAL_JUMP_VELOCITY - (GameState.speed / 10)
  end
end

function Trex:setDuck(isDucking)
  self.ducking = isDucking
  if isDucking then
    self.currentAnim = TrexAnim.DUCKING
    self.msPerFrame = TrexAnim.DUCKING.msPerFrame
    self.currentFrame = 1
  else
    self.currentAnim = TrexAnim.RUNNING
    self.msPerFrame = TrexAnim.RUNNING.msPerFrame
    self.currentFrame = 1
  end
end

function Trex:reset()
  self.x = 50
  self.y = self.groundY
  self.jumping = false
  self.ducking = false
  self.jumpVelocity = 0
  self.currentAnim = TrexAnim.RUNNING
  self.currentFrame = 1
  self.timer = 0
end

------------------------------------------------------------
-- Obstacle Object
------------------------------------------------------------
local Obstacle = {}
Obstacle.__index = Obstacle

local ObstacleTypes = {
  {
    type = "CACTUS_SMALL",
    w = SPRITES.CACTUS_SMALL.w,
    h = SPRITES.CACTUS_SMALL.h,
    y = 105,
    collisionBoxes = { {x = 0, y = 7, w = 5, h = 27} },
  },
  {
    type = "CACTUS_LARGE",
    w = SPRITES.CACTUS_LARGE.w,
    h = SPRITES.CACTUS_LARGE.h,
    y = 90,
    collisionBoxes = { {x = 0, y = 12, w = 7, h = 38} },
  },
  {
    type = "PTERODACTYL",
    w = SPRITES.PTERODACTYL.w,
    h = SPRITES.PTERODACTYL.h,
    y = 75,
    numFrames = 2,
    frameRate = 1000/6,
    speedOffset = 0.8,
  },
}

function Obstacle:new(xStart)
  local t = {}
  setmetatable(t, Obstacle)
  local ot = ObstacleTypes[getRandomNum(1, #ObstacleTypes)]
  t.type = ot.type
  t.w = ot.w
  t.h = ot.h
  t.y = (type(ot.y) == "table" and ot.y[getRandomNum(1, #ot.y)] or ot.y) + 250
  t.x = xStart or CONFIG.WIDTH
  t.numFrames = ot.numFrames or 1
  t.currentFrame = 1
  t.timer = 0
  t.frameRate = ot.frameRate or 0
  t.speedOffset = ot.speedOffset or 0
  return t
end

function Obstacle:update(dt, speed)
  local moveSpeed = speed + self.speedOffset
  self.x = self.x - moveSpeed * dt * 60
  if self.numFrames > 1 then
    self.timer = self.timer + dt * 1000
    if self.timer >= self.frameRate then
      self.currentFrame = self.currentFrame % self.numFrames + 1
      self.timer = 0
    end
  end
end

function Obstacle:draw()
  local sprite
  if self.type == "CACTUS_SMALL" then
    sprite = SPRITES.CACTUS_SMALL
  elseif self.type == "CACTUS_LARGE" then
    sprite = SPRITES.CACTUS_LARGE
  elseif self.type == "PTERODACTYL" then
    sprite = SPRITES.PTERODACTYL
  end
  local frameOffset = 0
  if self.numFrames > 1 then
    frameOffset = (self.currentFrame - 1) * sprite.w
  end
  local quad = love.graphics.newQuad(sprite.x + frameOffset, sprite.y, sprite.w, sprite.h,
    spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

function Obstacle:isOffscreen()
  return self.x + self.w < 0
end

------------------------------------------------------------
-- Horizon (obstacle spawner)
------------------------------------------------------------
local Horizon = {}
Horizon.__index = Horizon

function Horizon:new()
  local self = setmetatable({}, Horizon)
  self.obstacles = {}
  self.spawnTimer = 0
  self.spawnInterval = 1.5
  return self
end

function Horizon:update(dt)
  self.spawnTimer = self.spawnTimer + dt
  if self.spawnTimer >= self.spawnInterval then
    table.insert(self.obstacles, Obstacle:new(CONFIG.WIDTH))
    self.spawnTimer = 0
  end
  for i = #self.obstacles, 1, -1 do
    local obs = self.obstacles[i]
    obs:update(dt, GameState.speed)
    if obs:isOffscreen() then
      table.remove(self.obstacles, i)
    end
  end
end

function Horizon:draw()
  for _, obs in ipairs(self.obstacles) do
    obs:draw()
  end
end

function Horizon:reset()
  self.obstacles = {}
  self.spawnTimer = 0
end

------------------------------------------------------------
-- DistanceMeter
------------------------------------------------------------
local DistanceMeter = {}
DistanceMeter.__index = DistanceMeter

function DistanceMeter:new()
  local self = setmetatable({}, DistanceMeter)
  self.x = CONFIG.WIDTH - 100
  self.y = 5
  self.maxDigits = 5
  self.digits = {0,0,0,0,0}
  return self
end

function DistanceMeter:update(distance)
  local score = math.floor(distance * 0.025)
  local str = string.format("%0" .. self.maxDigits .. "d", score)
  self.digits = {}
  for i = 1, #str do
    self.digits[i] = str:sub(i, i)
  end
  return score
end

function DistanceMeter:draw()
  love.graphics.print("Score: " .. table.concat(self.digits), self.x, self.y)
  love.graphics.print("High Score: " .. GameState.highScore, self.x, self.y + 20)
end

------------------------------------------------------------
-- Cloud Object
------------------------------------------------------------
local Cloud = {}
Cloud.__index = Cloud

function Cloud:new(xStart)
  local self = setmetatable({}, Cloud)
  self.x = xStart or CONFIG.WIDTH
  self.y = getRandomNum(30, 71)
  self.w = SPRITES.CLOUD.w
  self.h = SPRITES.CLOUD.h
  return self
end

function Cloud:update(dt, speed)
  self.x = self.x - speed * dt * 60
end

function Cloud:draw()
  local quad = love.graphics.newQuad(SPRITES.CLOUD.x, SPRITES.CLOUD.y, SPRITES.CLOUD.w, SPRITES.CLOUD.h,
    spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

------------------------------------------------------------
-- NightMode (Moon)
------------------------------------------------------------
local NightMode = {}
NightMode.__index = NightMode

function NightMode:new()
  local self = setmetatable({}, NightMode)
  self.opacity = 0
  self.x = CONFIG.WIDTH - 50
  self.y = 30
  self.phases = {140,120,100,60,40,20,0}
  self.currentPhase = 1
  return self
end

function NightMode:update(dt, activated)
  if activated then
    if self.opacity < 1 then self.opacity = self.opacity + 0.035 * dt * 60 end
    self.x = self.x - 0.25 * dt * 60
    if self.x < -SPRITES.MOON.w then self.x = CONFIG.WIDTH end
  else
    if self.opacity > 0 then self.opacity = self.opacity - 0.035 * dt * 60 end
  end
end

function NightMode:draw()
  love.graphics.setColor(1, 1, 1, self.opacity)
  local quad = love.graphics.newQuad(SPRITES.MOON.x + self.phases[self.currentPhase], SPRITES.MOON.y,
    SPRITES.MOON.w, SPRITES.MOON.h, spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
  love.graphics.setColor(1, 1, 1, 1)
end

------------------------------------------------------------
-- Runner (game controller)
------------------------------------------------------------
local Runner = {}
Runner.__index = Runner

function Runner:new()
  local self = setmetatable({}, Runner)
  self.width = CONFIG.WIDTH
  self.height = CONFIG.HEIGHT
  self.trex = Trex:new()
  self.horizon = Horizon:new()
  self.distanceMeter = DistanceMeter:new()
  self.clouds = {}
  self.nightMode = NightMode:new()
  return self
end

function Runner:update(dt)
  if GameState.playing then
    self.trex:update(dt)
    self.horizon:update(dt)
    if math.random() < 0.01 then
      table.insert(self.clouds, Cloud:new())
    end
    for i = #self.clouds, 1, -1 do
      local cloud = self.clouds[i]
      cloud:update(dt, GameState.speed * 0.2)
      if cloud.x + cloud.w < 0 then
        table.remove(self.clouds, i)
      end
    end
    GameState.distanceRan = GameState.distanceRan + GameState.speed * dt * 60
    local score = self.distanceMeter:update(GameState.distanceRan)
    if score > GameState.highScore then
      GameState.highScore = score
    end
    if GameState.speed < CONFIG.MAX_SPEED then
      GameState.speed = GameState.speed + CONFIG.ACCELERATION
    end
    local trexBox = { x = self.trex.x + 1, y = self.trex.y + 1, w = self.trex.width - 2, h = self.trex.height - 2 }
    for _, obs in ipairs(self.horizon.obstacles) do
      local obsBox = { x = obs.x + 1, y = obs.y + 1, w = obs.w - 2, h = obs.h - 2 }
      if checkCollision(trexBox, obsBox) then
        GameState.crashed = true
        GameState.playing = false
      end
    end
    if GameState.distanceRan > CONFIG.INVERT_DISTANCE then
      self.nightMode:update(dt, true)
    else
      self.nightMode:update(dt, false)
    end
  end
end

function Runner:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, CONFIG.WIDTH, CONFIG.HEIGHT)
  
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.rectangle("fill", 0, CONFIG.HEIGHT - 12, CONFIG.WIDTH, 12)
  love.graphics.setColor(1,1,1)
  
  for _, cloud in ipairs(self.clouds) do
    cloud:draw()
  end
  self.horizon:draw()
  self.trex:draw()
  self.distanceMeter:draw()
  self.nightMode:draw()
  
  if GameState.crashed then
    love.graphics.print("Game Over! Press R to Restart", CONFIG.WIDTH/2 - 100, CONFIG.HEIGHT/2)
  elseif not GameState.playing then
    love.graphics.print("Press UP or SPACE to Start", CONFIG.WIDTH/2 - 90, CONFIG.HEIGHT/2)
  end
end

function Runner:reset()
  GameState.playing = false
  GameState.crashed = false
  GameState.distanceRan = 0
  GameState.speed = CONFIG.SPEED
  self.trex:reset()
  self.horizon:reset()
  self.clouds = {}
end

------------------------------------------------------------
-- dinoApp Module Methods
------------------------------------------------------------
function dinoApp.new()
  local self = setmetatable({}, dinoApp)
  math.randomseed(os.time())
  -- Load spritesheet
  spritesheet = love.graphics.newImage("assets/100-offline-sprite.png")
  -- Initialize game state
  GameState.playing = false
  GameState.crashed = false
  GameState.distanceRan = 0
  GameState.speed = CONFIG.SPEED
  self.runner = Runner:new()
  return self
end

function dinoApp:update(dt)
  self.runner:update(dt)
end

-- Draw the game within the given subwindow area, scaling to fit.
function dinoApp:draw(offsetX, offsetY, width, height)
  love.graphics.push()
  love.graphics.translate(offsetX, offsetY)
  -- Compute uniform scaling factor based on design resolution (CONFIG.WIDTH, CONFIG.HEIGHT)
  local scaleX = width / CONFIG.WIDTH
  local scaleY = height / CONFIG.HEIGHT
  local scaleFactor = math.min(scaleX, scaleY)
  love.graphics.scale(scaleFactor, scaleFactor)
  -- Optionally, confine drawing to the subwindow area:
  local prevScissor = { love.graphics.getScissor() }
  love.graphics.setScissor(0, 0, width / scaleFactor, height / scaleFactor)
  self.runner:draw()
  love.graphics.setScissor(unpack(prevScissor))
  love.graphics.pop()
end

function dinoApp:keypressed(key)
  if key == "up" or key == "space" then
    if not GameState.playing and not GameState.crashed then
      GameState.playing = true
    end
    self.runner.trex:startJump()
  elseif key == "down" then
    self.runner.trex:setDuck(true)
  elseif key == "r" and GameState.crashed then
    self.runner:reset()
  end
end

function dinoApp:keyreleased(key)
  if key == "down" then
    self.runner.trex:setDuck(false)
  end
end

return dinoApp
