-- local xml2lua = require("xml2lua")  -- if you wish to encode/decode later
local BrowserApp = {}
BrowserApp.__index = BrowserApp

--------------------------------------------------------------------------------
-- Website database using an array‑based XML-like HTML document.
--------------------------------------------------------------------------------
local websiteDatabase = {
  ["http://example.com"] = {
    tag = "div",
    children = {
      { tag = "h1", _text = "Welcome to Example.com", _attr = { align = "center", color = "#003366" } },
      { tag = "p",  _text = "This is the main page rendered as HTML.", _attr = { bgcolor = "#EEEEEE" } },
      { tag = "button", _attr = { text = "Google", href = "http://google.com", bgcolor = "#DDDDDD" } },
      { tag = "input", _attr = { placeholder = "Type here...", value = "", width = "200", height = "30", bgcolor = "#FFFFFF", color="#000000" } },
      { tag = "input", _attr = { placeholder = "Type here...", value = "", width = "300", height = "30", bgcolor = "#232323", color="#ffffff" } },
    }
  },
  ["http://love2d.org"] = {
    tag = "div",
    children = {
      { tag = "h1", _text = "LOVE2D", _attr = { align = "center", bold = "true" } },
      { tag = "p",  _text = "Learn about the LOVE2D game framework." },
      { tag = "img", _attr = { src = "love_logo.png", width = "100", height = "100" } },
      { tag = "button", _attr = { text = "Visit Example.org", href = "http://example.org" } },
    }
  },
  ["http://google.com"] = {
    tag = "div",
    children = {
      { tag = "h1", _text = "Google" },
      { tag = "p",  _text = "Search the web with Google. Woooooh my my my gooood mmm" },
      { tag = "a",  _attr = { href = "http://example.com", text = "Go to Example.com", underline = "true" } },
    }
  },
  ["http://example.org"] = {
    tag = "div",
    children = {
      { tag = "h1", _text = "Example.org" },
      { tag = "p",  _text = "Another example website with dummy content." },
      { tag = "button", _attr = { text = "Go Back", action = "back" } },
    }
  },
}

--------------------------------------------------------------------------------
-- Helper: parse a color string ("#RRGGBB" or "r,g,b")
--------------------------------------------------------------------------------
function BrowserApp:parseColor(colorStr)
  if type(colorStr) ~= "string" then return nil end
  if string.sub(colorStr,1,1) == "#" and #colorStr == 7 then
      local r = tonumber(string.sub(colorStr,2,3), 16) / 255
      local g = tonumber(string.sub(colorStr,4,5), 16) / 255
      local b = tonumber(string.sub(colorStr,6,7), 16) / 255
      return r, g, b
  else
      local r, g, b = colorStr:match("([^,]+),([^,]+),([^,]+)")
      if r and g and b then
          return tonumber(r), tonumber(g), tonumber(b)
      end
  end
  return nil
end

--------------------------------------------------------------------------------
-- Helper: collect style attributes from an element's _attr.
-- Supported: align, color, bgcolor, bold, italic, underline
--------------------------------------------------------------------------------
function BrowserApp:collectStyles(element)
  local styles = {}
  if element._attr then
    if element._attr.align then styles.align = element._attr.align end
    if element._attr.color then 
      local r, g, b = self:parseColor(element._attr.color)
      if r then styles.color = {r, g, b} end
    end
    if element._attr.bgcolor then 
      local r, g, b = self:parseColor(element._attr.bgcolor)
      if r then styles.bgcolor = {r, g, b} end
    end
    if element._attr.bold then styles.bold = (element._attr.bold == "true" or element._attr.bold == true) end
    if element._attr.italic then styles.italic = (element._attr.italic == "true" or element._attr.italic == true) end
    if element._attr.underline then styles.underline = (element._attr.underline == "true" or element._attr.underline == true) end
  end
  return styles
end

--------------------------------------------------------------------------------
-- BrowserApp Constructor and URL Handling
--------------------------------------------------------------------------------
function BrowserApp.new()
  local self = setmetatable({}, BrowserApp)
  self.url = "http://example.com"
  self.htmlContent = websiteDatabase[self.url] or {
      tag = "div",
      children = { { tag = "p", _text = "404 Page Not Found: " .. self.url } }
  }
  self.urlActive = false
  self.history = { self.url }
  self.currentIndex = 1
  self.buttonRegions = {}
  self.defaultFont = love.graphics.newFont(14)
  self.h1Font = love.graphics.newFont(24)
  self.h2Font = love.graphics.newFont(20)
  self.h3Font = love.graphics.newFont(18)
  self.h4Font = love.graphics.newFont(16)
  self.h5Font = love.graphics.newFont(14)
  self.h6Font = love.graphics.newFont(12)
  -- love.graphics.setFont(self.defaultFont)
  self.scrollOffset = 0
  self.scrollSpeed = 20  -- pixels per scroll
  self.maxScroll = 0
  self.loading = false
  self.loadingTimer = 0
  self.loadingDuration = 0
  -- For text editing in the URL bar:
  self.urlCursor = #self.url + 1
  self.urlCursorTimer = 0
  self.urlCursorVisible = true
  -- active input field (if any) for in-page <input> tags.
  self.activeInput = nil
  return self
end

function BrowserApp:setURL(url)
  self.url = url
  self.urlCursor = #url + 1
  self.htmlContent = websiteDatabase[url] or {
      tag = "div",
      children = { { tag = "p", _text = "404 Page Not Found: " .. url } }
  }
end

function BrowserApp:loadURL(url)
  self.scrollOffset = 0
  self.loading = true
  self.loadingTimer = 0
  self.loadingDuration = math.random() * 0.2 + 0.4
  self.loadingNextURL = url
  -- Clear any active input field.
  self.activeInput = nil
end

function BrowserApp:back()
  if self.currentIndex > 1 then
      self.currentIndex = self.currentIndex - 1
      self:loadURL(self.history[self.currentIndex])
  end
end

function BrowserApp:forward()
  if self.currentIndex < #self.history then
      self.currentIndex = self.currentIndex + 1
      self:loadURL(self.history[self.currentIndex])
  end
end

function BrowserApp:reload()
  self:loadURL(self.url)
end

--------------------------------------------------------------------------------
-- Rendering Functions: renderHTML and renderElement.
-- Supports tags: div, h1–h6, p, button, a, img, input.
-- Applies style attributes and renders active text editing with a blinking cursor.
--------------------------------------------------------------------------------
function BrowserApp:renderHTML(element, x, y, maxWidth)
  local newY = y
  local styles = self:collectStyles(element)
  local color = {0, 0, 0}
  if styles.color then color = styles.color end
  if styles.bgcolor then
    local r, g, b = table.unpack(styles.bgcolor)
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x, newY, maxWidth, self.defaultFont:getHeight() + 4)
    love.graphics.setColor(0, 0, 0)
  end
  if element._text then
      love.graphics.setColor(color)
      local align = styles.align or "left"
      local text = element._text
      love.graphics.printf(text, x, newY, maxWidth, align)
      local _, lines = self.defaultFont:getWrap(text, maxWidth)
      newY = newY + (#lines * self.defaultFont:getHeight()) + 5
      love.graphics.setColor(1, 1, 1)
  end
  if element.children then
      for _, child in ipairs(element.children) do
          newY = self:renderElement(child, x, newY, maxWidth)
      end
  end
  return newY
end

function BrowserApp:renderElement(element, x, y, maxWidth)
  local newY = y
  local tag = element.tag or ""
  local styles = self:collectStyles(element)
  local align = styles.align or "left"
  local color = {0, 0, 0}
  if styles.color then color = styles.color end
  
  if tag == "div" then
      newY = newY + 5
      newY = self:renderHTML(element, x + 10, newY, maxWidth - 20)
  elseif tag == "h1" then
      love.graphics.setFont(self.h1Font)
      love.graphics.setColor(color)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h1Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
      love.graphics.setColor(1, 1, 1)
  elseif tag == "h2" then
      love.graphics.setFont(self.h2Font)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h2Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
  elseif tag == "h3" then
      love.graphics.setFont(self.h3Font)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h3Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
  elseif tag == "h4" then
      love.graphics.setFont(self.h4Font)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h4Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
  elseif tag == "h5" then
      love.graphics.setFont(self.h5Font)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h5Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
  elseif tag == "h6" then
      love.graphics.setFont(self.h6Font)
      love.graphics.printf(element._text or "", x, newY, maxWidth, "center")
      newY = newY + self.h6Font:getHeight() + 10
      love.graphics.setFont(self.defaultFont)
  elseif tag == "p" then
      love.graphics.setColor(color)
      love.graphics.printf(element._text or "", x, newY, maxWidth, align)
      local _, lines = self.defaultFont:getWrap(element._text or "", maxWidth)
      newY = newY + (#lines * self.defaultFont:getHeight()) + 5
      love.graphics.setColor(1, 1, 1)
  elseif tag == "button" then
      local btnWidth = 150
      local btnHeight = 30
      local baseColor = {0.2, 0.6, 1}
      if element._attr and element._attr.bgcolor then
          local r, g, b = self:parseColor(element._attr.bgcolor)
          baseColor = {r, g, b}
      end
      -- Draw drop shadow.
      love.graphics.setColor(0, 0, 0, 0.2)
      love.graphics.rectangle("fill", x+2, newY+2, btnWidth, btnHeight, 5, 5)
      -- Touch effect: lighten color on hover.
      local mx, my = love.mouse.getPosition()
      local hovered = (mx >= x and mx <= x+btnWidth and my >= newY and my <= newY+btnHeight)
      if hovered then
          baseColor = {baseColor[1]*1.1, baseColor[2]*1.1, baseColor[3]*1.1}
      end
      love.graphics.setColor(unpack(baseColor))
      love.graphics.rectangle("fill", x, newY, btnWidth, btnHeight, 5, 5)
      love.graphics.setColor(1, 1, 1)
      local buttonText = (element._attr and element._attr.text) or ""
      love.graphics.printf(buttonText, x, newY + 7, btnWidth, "center")
      table.insert(self.buttonRegions, {
          x = x,
          y = newY - self.scrollOffset,
          width = btnWidth,
          height = btnHeight,
          onClick = function()
              if element._attr and element._attr.href then
                  self:loadURL(element._attr.href)
              elseif element._attr and element._attr.action == "back" then
                  self:back()
              end
          end
      })
      newY = newY + btnHeight + 10
  elseif tag == "a" then
      love.graphics.setColor(color)
      local linkText = (element._attr and element._attr.text) or ""
      love.graphics.printf(linkText, x, newY, maxWidth, align)
      table.insert(self.buttonRegions, {
          x = x,
          y = newY - self.scrollOffset,
          width = maxWidth,
          height = self.defaultFont:getHeight(),
          onClick = function()
              if element._attr and element._attr.href then
                  self:loadURL(element._attr.href)
              end
          end
      })
      newY = newY + self.defaultFont:getHeight() + 5
      love.graphics.setColor(1, 1, 1)
  elseif tag == "img" then
      local imgWidth = tonumber(element._attr and element._attr.width) or 50
      local imgHeight = tonumber(element._attr and element._attr.height) or 50
      -- Draw image placeholder with drop shadow.
      love.graphics.setColor(0, 0, 0, 0.2)
      love.graphics.rectangle("fill", x+2, newY+2, imgWidth, imgHeight)
      love.graphics.setColor(0.8, 0.8, 0.8)
      love.graphics.rectangle("fill", x, newY, imgWidth, imgHeight)
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("line", x, newY, imgWidth, imgHeight)
      love.graphics.printf("IMG", x, newY + imgHeight / 2 - 7, imgWidth, "center")
      love.graphics.setColor(1, 1, 1)
      newY = newY + imgHeight + 10
  elseif tag == "input" then
      local inWidth = tonumber(element._attr and element._attr.width) or 150
      local inHeight = tonumber(element._attr and element._attr.height) or 30
      local value = element._attr and element._attr.value or ""
      local placeholder = element._attr and element._attr.placeholder or ""
      local baseBgColor = {1, 1, 1}
      if element._attr and element._attr.bgcolor then
          local r, g, b = self:parseColor(element._attr.bgcolor)
          baseBgColor = {r, g, b}
      end
      local mx, my = love.mouse.getPosition()
      local hovered = (mx >= x and mx <= x+inWidth and my >= newY and my <= newY+inHeight)
      if hovered then
          baseBgColor = {baseBgColor[1]*0.95, baseBgColor[2]*0.95, baseBgColor[3]*0.95}
      end
      -- Draw drop shadow for input.
      love.graphics.setColor(0, 0, 0, 0.2)
      love.graphics.rectangle("fill", x+2, newY+2, inWidth, inHeight, 3, 3)
      love.graphics.setColor(unpack(baseBgColor))
      love.graphics.rectangle("fill", x, newY, inWidth, inHeight, 3, 3)
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("line", x, newY, inWidth, inHeight, 3, 3)
      if value == "" then
          love.graphics.setColor(0.5, 0.5, 0.5)
          love.graphics.printf(placeholder, x + 5, newY + 5, inWidth - 10, "left")
      else
          love.graphics.printf(value, x + 5, newY + 5, inWidth - 10, "left")
      end
      love.graphics.setColor(0, 0, 0)
      if self.activeInput and self.activeInput.element == element then
          local cursorPos = self.activeInput.cursor or (#value + 1)
          local beforeCursor = value:sub(1, cursorPos - 1)
          local cursorX = x + 5 + self.defaultFont:getWidth(beforeCursor)
          if self.activeInput.cursorVisible then
              love.graphics.rectangle("fill", cursorX, newY + 5, 2, self.defaultFont:getHeight())
          end
      end
      table.insert(self.buttonRegions, {
          x = x,
          y = newY - self.scrollOffset,
          width = inWidth,
          height = inHeight,
          onClick = function()
              self.activeInput = { element = element, cursor = (#(element._attr.value or "") + 1), cursorTimer = 0, cursorVisible = true }
          end
      })
      newY = newY + inHeight + 10
  else
      if element._text then
          love.graphics.printf(element._text, x, newY, maxWidth, align)
          local _, lines = self.defaultFont:getWrap(element._text, maxWidth)
          newY = newY + (#lines * self.defaultFont:getHeight()) + 5
      end
  end
  return newY
end

--------------------------------------------------------------------------------
-- BrowserApp:draw() Implementation
--------------------------------------------------------------------------------
function BrowserApp:draw(x, y, width, height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", x, y, width, height)
  if self.loading then
      local percent = self.loadingTimer / self.loadingDuration
      love.graphics.setColor(0, 0.6, 1)
      love.graphics.rectangle("fill", x, y, width * percent, 5)
  end
  self.buttonRegions = {}
  local inputX = x + 5
  local inputY = y + 10
  local inputHeight = 30
  local searchButtonWidth = 80
  local inputWidth = width - 20 - searchButtonWidth
  if self.urlActive then
      love.graphics.setColor(0.8, 0.8, 1)
  else
      love.graphics.setColor(0.8, 0.8, 0.7)
  end
  love.graphics.rectangle("fill", inputX, inputY, inputWidth, inputHeight)
  love.graphics.setColor(0, 0, 0)
  love.graphics.setFont(self.defaultFont)
  love.graphics.printf(self.url, inputX + 10, inputY + 7, inputWidth - 20, "left")
  if self.urlActive then
      local beforeCursor = self.url:sub(1, self.urlCursor - 1)
      local cursorX = inputX + 10 + self.defaultFont:getWidth(beforeCursor) 
      if self.urlCursorVisible then
          love.graphics.rectangle("fill", cursorX, inputY + 7, 2, self.defaultFont:getHeight())
      end
  end
  local buttonX = inputX + inputWidth + 5
  local buttonY = inputY
  love.graphics.setColor(0.2, 0.6, 1)
  love.graphics.rectangle("fill", buttonX, buttonY, searchButtonWidth, inputHeight, 5, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("Search", buttonX, buttonY + 7, searchButtonWidth, "center")
  table.insert(self.buttonRegions, {
      x = buttonX,
      y = buttonY,
      width = searchButtonWidth,
      height = inputHeight,
      onClick = function() self:loadURL(self.url) end
  })
  local contentY = y + 50
  love.graphics.setScissor(x, contentY, width, height - 50)
  love.graphics.push()
  love.graphics.translate(0, -self.scrollOffset)
  love.graphics.setColor(0, 0, 0)
  if not self.loading then
      local totalContentHeight = self:renderHTML(self.htmlContent, x + 10, contentY, width - 20)
      self.maxScroll = math.max(0, totalContentHeight - (height - 50))
  else
      love.graphics.setColor(0.5, 0.5, 0.5)
      love.graphics.printf("Loading...", x + 10, contentY + 20, width - 20, "center")
  end
  love.graphics.pop()
  love.graphics.setScissor()
  if self.maxScroll > 0 then
      local scrollbarHeight = (height - 50) * ((height - 50) / (self.maxScroll + height - 50))
      local scrollbarY = 130 + (self.scrollOffset / self.maxScroll) * ((height - 50) - scrollbarHeight)
      love.graphics.setColor(0.7, 0.7, 0.7)
      love.graphics.rectangle("fill", x + width - 10, scrollbarY, 5, scrollbarHeight)
  end
end

--------------------------------------------------------------------------------
-- Other BrowserApp Functions
--------------------------------------------------------------------------------
function BrowserApp:wheelmoved(x, y)
  self.scrollOffset = self.scrollOffset - y * self.scrollSpeed
  self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
end

function BrowserApp:mousepressed(x, y, button, X, Y)
  if button == 1 then
      if y >= 10 and y <= 40 then
          self.urlActive = not self.urlActive
          self.activeInput = nil
      end
      if self.loading then return end
      for _, btn in ipairs(self.buttonRegions) do
          if X >= btn.x and X <= btn.x + btn.width and Y >= btn.y and Y <= btn.y + btn.height then
              if btn.onClick then btn.onClick(self) end
              return
          end
      end
      self.activeInput = nil
  end
end

function BrowserApp:keypressed(key)
  if self.loading then return end
  if self.urlActive then
      if key == "left" then
          if self.urlCursor > 1 then self.urlCursor = self.urlCursor - 1 end
      elseif key == "right" then
          if self.urlCursor <= #self.url then self.urlCursor = self.urlCursor + 1 end
      elseif key == "backspace" then
          if self.urlCursor > 1 then
              self.url = self.url:sub(1, self.urlCursor - 1) .. self.url:sub(self.urlCursor + 1)
              self.urlCursor = self.urlCursor - 1
          end
      elseif key == "delete" then
          self.url = self.url:sub(1, self.urlCursor - 1) .. self.url:sub(self.urlCursor + 1)
      elseif key == "return" then
          self:loadURL(self.url)
          self.urlActive = false
      end
  elseif self.activeInput then
      if key == "left" then
          if self.activeInput.cursor > 1 then self.activeInput.cursor = self.activeInput.cursor - 1 end
      elseif key == "right" then
          local val = self.activeInput.element._attr.value or ""
          if self.activeInput.cursor <= #val then self.activeInput.cursor = self.activeInput.cursor + 1 end
      elseif key == "backspace" then
          local val = self.activeInput.element._attr.value or ""
          if self.activeInput.cursor > 1 then
              self.activeInput.element._attr.value = val:sub(1, self.activeInput.cursor - 1) .. val:sub(self.activeInput.cursor + 1)
              self.activeInput.cursor = self.activeInput.cursor - 1
          end
      elseif key == "delete" then
          local val = self.activeInput.element._attr.value or ""
          self.activeInput.element._attr.value = val:sub(1, self.activeInput.cursor - 1) .. val:sub(self.activeInput.cursor + 1)
      elseif key == "return" then
          self.activeInput = nil
      end
  else
      if key == "left" then
          self:back()
      elseif key == "right" then
          self:forward()
      elseif key == "space" then
          self:reload()
      elseif key == "up" then
          self.scrollOffset = math.max(0, self.scrollOffset - self.scrollSpeed)
      elseif key == "down" then
          self.scrollOffset = math.min(self.maxScroll, self.scrollOffset + self.scrollSpeed)
      end
  end
end

function BrowserApp:textinput(text)
  if self.urlActive then
      local before = self.url:sub(1, self.urlCursor - 1)
      local after = self.url:sub(self.urlCursor)
      self.url = before .. text .. after
      self.urlCursor = self.urlCursor + #text
  elseif self.activeInput then
      local val = self.activeInput.element._attr.value or ""
      local before = val:sub(1, self.activeInput.cursor - 1)
      local after = val:sub(self.activeInput.cursor)
      self.activeInput.element._attr.value = before .. text .. after
      self.activeInput.cursor = self.activeInput.cursor + #text
  end
end

function BrowserApp:update(dt)
  if self.loading then
      self.loadingTimer = self.loadingTimer + dt
      if self.loadingTimer >= self.loadingDuration then
          self.loading = false
          self.loadingTimer = 0
          local url = self.loadingNextURL
          self:setURL(url)
          if self.history[self.currentIndex] ~= url then
              for i = #self.history, self.currentIndex + 1, -1 do
                  table.remove(self.history, i)
              end
              table.insert(self.history, url)
              self.currentIndex = #self.history
          end
      end
  end
  if self.urlActive then
      self.urlCursorTimer = self.urlCursorTimer + dt
      if self.urlCursorTimer >= 0.5 then
          self.urlCursorVisible = not self.urlCursorVisible
          self.urlCursorTimer = self.urlCursorTimer - 0.5
      end
  end
  if self.activeInput then
      self.activeInput.cursorTimer = (self.activeInput.cursorTimer or 0) + dt
      if self.activeInput.cursorTimer >= 0.5 then
          self.activeInput.cursorVisible = not self.activeInput.cursorVisible
          self.activeInput.cursorTimer = self.activeInput.cursorTimer - 0.5
      end
  end
end

function BrowserApp:showMessage(message)
  self.htmlContent = {
      tag = "div",
      children = {
          { tag = "h1", _text = "Message" },
          { tag = "p", _text = message },
          { tag = "button", _attr = { text = "Go Back", action = "back" } }
      }
  }
end

return BrowserApp
