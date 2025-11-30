-- dinoApp.lua
local dinoApp = {}
dinoApp.__index = dinoApp

-- Configuration matching original Chrome Dino game more closely
local CONFIG = {
  FPS = 60,
  WIDTH = 600,
  HEIGHT = 150,  -- Match original height
  GROUND_Y = 125, -- Ground position
  GRAVITY = 0.6,
  INITIAL_JUMP_VELOCITY = -12,
  SPEED = 6,
  ACCELERATION = 0.001,
  MAX_SPEED = 13,
  INVERT_DISTANCE = 700,
}

-- Fixed sprite definitions (matching Chrome Dino)
local SPRITES = {
  CACTUS_SMALL = { x = 228, y = 2, w = 17, h = 35 },
  CACTUS_LARGE = { x = 332, y = 2, w = 25, h = 50 },
  CACTUS_SMALL_2 = { x = 228, y = 2, w = 17, h = 35 },  -- Alternative small cactus
  CACTUS_LARGE_2 = { x = 332, y = 2, w = 25, h = 50 }, -- Alternative large cactus
  PTERODACTYL = { x = 134, y = 2, w = 46, h = 40 },
  TREX = { x = 848, y = 2, w = 44, h = 47 },
  TREX_DUCKING_1 = { x = 1118, y = 2, w = 59, h = 47 },  -- Ducking frame 1
  TREX_DUCKING_2 = { x = 1177, y = 2, w = 59, h = 47 }, -- Ducking frame 2
  CLOUD = { x = 86, y = 2, w = 46, h = 14 },
  HORIZON = { x = 2, y = 54, w = 600, h = 12 },  -- Ground line
}

-- Trex animation frames (pixel offsets in sprite sheet)
local TrexAnim = {
  WAITING = { frames = {0, 44}, msPerFrame = 1000/3 },
  RUNNING = { frames = {88, 132}, msPerFrame = 1000/12 },
  CRASHED = { frames = {220}, msPerFrame = 1000/60 },
  JUMPING = { frames = {0}, msPerFrame = 1000/60 },
  DUCKING = { frames = {264, 323}, msPerFrame = 1000/8 },
}

-- Game state
local GameState = {
  playing = false,
  crashed = false,
  highScore = 0,
  speed = CONFIG.SPEED,
  distanceRan = 0,
  time = 0,
}

local spritesheet = nil

------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------
local function getRandomNum(min, max)
  return math.floor(math.random() * (max - min + 1)) + min
  end

local function checkCollision(a, b)
  -- Simple AABB collision with some tolerance
  local tolerance = 5
  return a.x < b.x + b.w - tolerance and 
         a.x + a.w - tolerance > b.x and
         a.y < b.y + b.h - tolerance and 
         a.y + a.h - tolerance > b.y
end

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
  self.groundY = CONFIG.GROUND_Y - self.height
  self.x = 50
  self.y = self.groundY
  self.jumping = false
  self.ducking = false
  self.jumpVelocity = 0
  self.timer = 0
  self.msPerFrame = TrexAnim.WAITING.msPerFrame
  self.currentFrame = 1
  self.currentAnim = TrexAnim.WAITING
  return self
end

function Trex:update(dt)
  self.timer = self.timer + dt * 1000
  
  -- Update animation frame
  if self.timer >= self.msPerFrame then
    self.currentFrame = self.currentFrame % #self.currentAnim.frames + 1
    self.timer = 0
  end
  
  -- Handle jumping physics
  if self.jumping then
    self.y = self.y + self.jumpVelocity
    self.jumpVelocity = self.jumpVelocity + CONFIG.GRAVITY
    
    -- Hit the ground
    if self.y >= self.groundY then
      self.y = self.groundY
      self.jumping = false
      self.jumpVelocity = 0
      if self.ducking then
        self.currentAnim = TrexAnim.DUCKING
        self.msPerFrame = TrexAnim.DUCKING.msPerFrame
      else
        self.currentAnim = TrexAnim.RUNNING
        self.msPerFrame = TrexAnim.RUNNING.msPerFrame
      end
    end
  end
end

function Trex:draw()
  local frameVal = self.currentAnim.frames[self.currentFrame]
  local spriteW, spriteH, spriteX, spriteY
  
  if self.ducking then
    spriteW = self.duckWidth
    spriteH = SPRITES.TREX.h
    -- Use ducking sprites
    if self.currentFrame == 1 then
      spriteX = SPRITES.TREX_DUCKING_1.x
    else
      spriteX = SPRITES.TREX_DUCKING_2.x
    end
    spriteY = SPRITES.TREX_DUCKING_1.y
  else
    spriteW = SPRITES.TREX.w
    spriteH = SPRITES.TREX.h
    spriteX = SPRITES.TREX.x + frameVal
    spriteY = SPRITES.TREX.y
  end
  
  local quad = love.graphics.newQuad(spriteX, spriteY, spriteW, spriteH,
    spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

function Trex:startJump()
  if not self.jumping and not self.ducking then
    self.jumping = true
    self.jumpVelocity = CONFIG.INITIAL_JUMP_VELOCITY
    self.currentAnim = TrexAnim.JUMPING
    self.msPerFrame = TrexAnim.JUMPING.msPerFrame
    self.currentFrame = 1
  end
end

function Trex:setDuck(isDucking)
  if self.jumping then return end -- Can't duck while jumping
  
  if isDucking and not self.ducking then
    self.ducking = true
    self.currentAnim = TrexAnim.DUCKING
    self.msPerFrame = TrexAnim.DUCKING.msPerFrame
    self.currentFrame = 1
    self.y = self.groundY  -- Stay on ground when ducking
  elseif not isDucking and self.ducking then
    self.ducking = false
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

function Trex:getCollisionBox()
  if self.ducking then
    return {
      x = self.x + 1,
      y = self.y + 18,
      w = self.duckWidth - 2,
      h = 25
    }
  else
    return {
      x = self.x + 22,
      y = self.y,
      w = 17,
      h = 16
    }
  end
end

------------------------------------------------------------
-- Obstacle Object
------------------------------------------------------------
local Obstacle = {}
Obstacle.__index = Obstacle

local ObstacleTypes = {
  {
    type = "CACTUS_SMALL",
    width = SPRITES.CACTUS_SMALL.w,
    height = SPRITES.CACTUS_SMALL.h,
    y = CONFIG.GROUND_Y - SPRITES.CACTUS_SMALL.h,
    sprite = SPRITES.CACTUS_SMALL,
    collisionBox = {x = 0, y = 7, w = 5, h = 27}
  },
  {
    type = "CACTUS_LARGE", 
    width = SPRITES.CACTUS_LARGE.w,
    height = SPRITES.CACTUS_LARGE.h,
    y = CONFIG.GROUND_Y - SPRITES.CACTUS_LARGE.h,
    sprite = SPRITES.CACTUS_LARGE,
    collisionBox = {x = 0, y = 12, w = 7, h = 38}
  },
  {
    type = "CACTUS_SMALL_2",
    width = SPRITES.CACTUS_SMALL.w,
    height = SPRITES.CACTUS_SMALL.h, 
    y = CONFIG.GROUND_Y - SPRITES.CACTUS_SMALL.h,
    sprite = SPRITES.CACTUS_SMALL_2,
    collisionBox = {x = 0, y = 7, w = 5, h = 27}
  },
  {
    type = "CACTUS_LARGE_2",
    width = SPRITES.CACTUS_LARGE.w,
    height = SPRITES.CACTUS_LARGE.h,
    y = CONFIG.GROUND_Y - SPRITES.CACTUS_LARGE.h,
    sprite = SPRITES.CACTUS_LARGE_2,
    collisionBox = {x = 0, y = 12, w = 7, h = 38}
  },
  {
    type = "PTERODACTYL",
    width = SPRITES.PTERODACTYL.w,
    height = SPRITES.PTERODACTYL.h,
    y = CONFIG.GROUND_Y - SPRITES.PTERODACTYL.h - 20, -- Fly above ground
    sprite = SPRITES.PTERODACTYL,
    collisionBox = {x = 15, y = 15, w = 16, h = 5},
    speedOffset = 0.8
  }
}

function Obstacle:new(xStart)
  local self = setmetatable({}, Obstacle)
  local ot = ObstacleTypes[getRandomNum(1, #ObstacleTypes)]
  
  self.type = ot.type
  self.width = ot.width
  self.height = ot.height
  self.y = ot.y
  self.x = xStart or CONFIG.WIDTH
  self.sprite = ot.sprite
  self.collisionBox = ot.collisionBox
  self.speedOffset = ot.speedOffset or 0
  self.remove = false
  
  return self
end

function Obstacle:update(dt, speed)
  local moveSpeed = speed + self.speedOffset
  self.x = self.x - moveSpeed
  if self.x + self.width < 0 then
    self.remove = true
  end
end

function Obstacle:draw()
  local quad = love.graphics.newQuad(self.sprite.x, self.sprite.y, 
    self.sprite.w, self.sprite.h, spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

function Obstacle:getCollisionBox()
  return {
    x = self.x + (self.collisionBox.x or 0),
    y = self.y + (self.collisionBox.y or 0),
    w = self.collisionBox.w,
    h = self.collisionBox.h
  }
end

------------------------------------------------------------
-- Horizon (Ground and obstacle spawner)
------------------------------------------------------------
local Horizon = {}
Horizon.__index = Horizon

function Horizon:new()
  local self = setmetatable({}, Horizon)
  self.obstacles = {}
  self.groundX = 0
  self.spawnTimer = 0
  self.spawnInterval = 1.5 -- seconds between obstacles
  return self
end

function Horizon:update(dt, speed)
  -- Update ground position
  self.groundX = (self.groundX - speed) % SPRITES.HORIZON.w
  
  -- Spawn obstacles
  self.spawnTimer = self.spawnTimer + dt
  if self.spawnTimer >= self.spawnInterval then
    table.insert(self.obstacles, Obstacle:new(CONFIG.WIDTH))
    self.spawnTimer = 0
    -- Decrease spawn interval as game gets harder
    self.spawnInterval = math.max(0.6, self.spawnInterval * 0.99)
  end
  
  -- Update obstacles
  for i = #self.obstacles, 1, -1 do
    local obs = self.obstacles[i]
    obs:update(dt, speed)
    if obs.remove then
      table.remove(self.obstacles, i)
    end
  end
end

function Horizon:draw()
  -- Draw ground (tiled)
  local groundQuad = love.graphics.newQuad(SPRITES.HORIZON.x, SPRITES.HORIZON.y, 
    SPRITES.HORIZON.w, SPRITES.HORIZON.h, spritesheet:getDimensions())
  
  -- Draw multiple ground segments to cover the screen
  for x = self.groundX - SPRITES.HORIZON.w, CONFIG.WIDTH, SPRITES.HORIZON.w do
    love.graphics.draw(spritesheet, groundQuad, x, CONFIG.GROUND_Y)
  end
  
  -- Draw obstacles
  for _, obs in ipairs(self.obstacles) do
    obs:draw()
  end
end

function Horizon:reset()
  self.obstacles = {}
  self.groundX = 0
  self.spawnTimer = 0
  self.spawnInterval = 1.5
end

------------------------------------------------------------
-- Distance Meter
------------------------------------------------------------
local DistanceMeter = {}
DistanceMeter.__index = DistanceMeter

function DistanceMeter:new()
  local self = setmetatable({}, DistanceMeter)
  self.x = CONFIG.WIDTH - 100
  self.y = 10
  self.score = 0
  self.highScore = 0
  return self
end

function DistanceMeter:update(distance)
  self.score = math.floor(distance / 5) -- Convert to score
  if self.score > self.highScore then
    self.highScore = self.score
  end
end

function DistanceMeter:draw()
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.print("HI: " .. string.format("%05d", self.highScore), self.x, self.y)
  love.graphics.print(string.format("%05d", self.score), self.x + 60, self.y)
  love.graphics.setColor(1, 1, 1)
end

------------------------------------------------------------
-- Cloud Object
------------------------------------------------------------
local Cloud = {}
Cloud.__index = Cloud

function Cloud:new()
  local self = setmetatable({}, Cloud)
  self.x = CONFIG.WIDTH
  self.y = getRandomNum(20, 70)
  self.speed = getRandomNum(1, 3)
  self.sprite = SPRITES.CLOUD
  return self
end

function Cloud:update(dt, gameSpeed)
  self.x = self.x - self.speed * 0.5 -- Clouds move slower than game
  return self.x + self.sprite.w < 0
end

function Cloud:draw()
  local quad = love.graphics.newQuad(self.sprite.x, self.sprite.y,
    self.sprite.w, self.sprite.h, spritesheet:getDimensions())
  love.graphics.draw(spritesheet, quad, self.x, self.y)
end

------------------------------------------------------------
-- Game Controller
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
  self.cloudTimer = 0
  return self
end

function Runner:update(dt)
  if GameState.playing then
    -- Update game elements
    self.trex:update(dt)
    self.horizon:update(dt, GameState.speed)
    
    -- Spawn clouds occasionally
    self.cloudTimer = self.cloudTimer + dt
    if self.cloudTimer > 3 and #self.clouds < 3 and math.random() < 0.3 then
      table.insert(self.clouds, Cloud:new())
      self.cloudTimer = 0
    end
    
    -- Update clouds
    for i = #self.clouds, 1, -1 do
      if self.clouds[i]:update(dt, GameState.speed) then
        table.remove(self.clouds, i)
      end
    end
    
    -- Update distance and speed
    GameState.distanceRan = GameState.distanceRan + GameState.speed * dt
    self.distanceMeter:update(GameState.distanceRan)
    
    if GameState.speed < CONFIG.MAX_SPEED then
      GameState.speed = GameState.speed + CONFIG.ACCELERATION
    end
    
    -- Check collisions
    local trexBox = self.trex:getCollisionBox()
    for _, obs in ipairs(self.horizon.obstacles) do
      local obsBox = obs:getCollisionBox()
      if checkCollision(trexBox, obsBox) then
        GameState.crashed = true
        GameState.playing = false
        self.trex.currentAnim = TrexAnim.CRASHED
        self.trex.msPerFrame = TrexAnim.CRASHED.msPerFrame
        break
      end
    end
  end
end

function Runner:draw()
  -- Draw sky background
  love.graphics.setColor(0.97, 0.97, 0.97) -- Light gray background
  love.graphics.rectangle("fill", 0, 0, CONFIG.WIDTH, CONFIG.HEIGHT)
  love.graphics.setColor(1, 1, 1)
  
  -- Draw clouds
  for _, cloud in ipairs(self.clouds) do
    cloud:draw()
  end
  
  -- Draw horizon (ground and obstacles)
  self.horizon:draw()
  
  -- Draw trex
  self.trex:draw()
  
  -- Draw UI
  self.distanceMeter:draw()
  
  -- Draw game state messages
  if GameState.crashed then
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("GAME OVER - PRESS R TO RESTART", CONFIG.WIDTH/2 - 120, CONFIG.HEIGHT/2 - 10)
    love.graphics.setColor(1, 1, 1)
  elseif not GameState.playing then
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("PRESS SPACE TO START", CONFIG.WIDTH/2 - 80, CONFIG.HEIGHT/2 - 10)
    love.graphics.setColor(1, 1, 1)
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
  self.distanceMeter.score = 0
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

function dinoApp:draw(offsetX, offsetY, width, height)

   -- Draw background
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.rectangle("fill", offsetX, offsetY, width, height)

  love.graphics.push()
  love.graphics.translate(offsetX, offsetY)
  
  -- Scale to fit the window while maintaining aspect ratio
  local scaleX = width / CONFIG.WIDTH
  local scaleY = height / CONFIG.HEIGHT
  local scale = math.min(scaleX, scaleY)
  
  love.graphics.scale(scale, scale)
  
  -- Center the game in the available space
  local scaledWidth = CONFIG.WIDTH * scale
  local scaledHeight = CONFIG.HEIGHT * scale
  local translateX = (width - scaledWidth) / (2 * scale)
  local translateY = (height - scaledHeight) / (2 * scale)
  
  love.graphics.translate(translateX, translateY)
  
  -- Set scissor to prevent drawing outside the window
  local prevScissor = { love.graphics.getScissor() }
  love.graphics.setScissor(offsetX, offsetY, width, height)
  
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