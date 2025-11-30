local BrowserApp = {}
BrowserApp.__index = BrowserApp

--------------------------------------------------------------------------------
-- Enhanced Professional Website Database with Functional Websites
--------------------------------------------------------------------------------
local websiteDatabase = {
  ["http://example.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "h1", _text = "Welcome to Example.com", _attr = { align = "center", color = "#003366" } },
      { tag = "p",  _text = "This is the main page rendered as HTML.", _attr = { bgcolor = "#f8f9fa" } },
      { tag = "button", _attr = { text = "Visit Google", href = "http://google.com", bgcolor = "#4285f4", color = "#ffffff" } },
      { tag = "input", _attr = { placeholder = "Search example.com...", value = "", width = "300", height = "40", bgcolor = "#ffffff", color="#000000", border = "1px solid #ddd" } },
    }
  },
  ["http://google.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "div", _attr = { align = "center", style = "margin-top: 100px" }, children = {
        { tag = "h1", _text = "Google", _attr = { color = "#4285f4", style = "font-size: 72px; margin-bottom: 20px" } },
        { tag = "input", _attr = { placeholder = "Search Google or type a URL", value = "", width = "584", height = "44", bgcolor = "#ffffff", color="#000000", border = "1px solid #dfe1e5", radius = "24px" } },
        { tag = "div", _attr = { style = "margin-top: 20px" }, children = {
          { tag = "button", _attr = { text = "Google Search", href = "http://google.com/search", bgcolor = "#f8f9fa", color = "#3c4043", border = "1px solid #f8f9fa" } },
          { tag = "button", _attr = { text = "I'm Feeling Lucky", href = "http://google.com/doodles", bgcolor = "#f8f9fa", color = "#3c4043", border = "1px solid #f8f9fa" } },
        }}
      }}
    }
  },
  ["http://github.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { bgcolor = "#24292f", style = "padding: 16px; color: white" }, children = {
        { tag = "span", _text = "GitHub", _attr = { style = "font-weight: bold; font-size: 20px" } },
        { tag = "input", _attr = { placeholder = "Search GitHub...", value = "", width = "300", height = "32", bgcolor = "#24292f", color="#ffffff", border = "1px solid #57606a" } },
      }},
      { tag = "div", _attr = { style = "padding: 40px" }, children = {
        { tag = "h1", _text = "Where the world builds software", _attr = { style = "font-size: 48px; margin-bottom: 20px" } },
        { tag = "p", _text = "Millions of developers and companies build, ship, and maintain their software on GitHub.", _attr = { style = "font-size: 20px; color: #57606a" } },
        { tag = "button", _attr = { text = "Sign up for GitHub", href = "http://github.com/signup", bgcolor = "#2da44e", color = "#ffffff" } },
      }}
    }
  },
  ["http://stackoverflow.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { bgcolor = "#f48225", style = "padding: 12px" }, children = {
        { tag = "span", _text = "Stack Overflow", _attr = { style = "font-weight: bold; color: white; font-size: 18px" } },
      }},
      { tag = "div", _attr = { style = "padding: 40px; background: #f8f9f9" }, children = {
        { tag = "h1", _text = "Every developer has a tab open to Stack Overflow", _attr = { style = "font-size: 36px; margin-bottom: 20px" } },
        { tag = "input", _attr = { placeholder = "Search...", value = "", width = "600", height = "44", bgcolor = "#ffffff", color="#000000", border = "1px solid #babfc4" } },
        { tag = "button", _attr = { text = "Ask Question", href = "http://stackoverflow.com/questions/ask", bgcolor = "#0095ff", color = "#ffffff" } },
      }}
    }
  },
  ["http://linkedin.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { bgcolor = "#283e4a", style = "padding: 12px" }, children = {
        { tag = "span", _text = "LinkedIn", _attr = { style = "font-weight: bold; color: white; font-size: 20px" } },
      }},
      { tag = "div", _attr = { style = "padding: 60px; background: #f3f6f8" }, children = {
        { tag = "h1", _text = "Welcome to your professional community", _attr = { style = "font-size: 42px; margin-bottom: 20px" } },
        { tag = "input", _attr = { placeholder = "Email", value = "", width = "300", height = "40", bgcolor = "#ffffff", color="#000000", border = "1px solid #ccc" } },
        { tag = "input", _attr = { placeholder = "Password", value = "", width = "300", height = "40", bgcolor = "#ffffff", color="#000000", border = "1px solid #ccc" } },
        { tag = "button", _attr = { text = "Sign in", href = "http://linkedin.com/feed", bgcolor = "#0073b1", color = "#ffffff" } },
      }}
    }
  },
  ["http://twitter.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "div", _attr = { style = "display: flex; height: 100vh" }, children = {
        { tag = "div", _attr = { bgcolor = "#1d9bf0", style = "flex: 1; display: flex; align-items: center; justify-content: center" }, children = {
          { tag = "span", _text = "🐦", _attr = { style = "font-size: 300px" } },
        }},
        { tag = "div", _attr = { style = "flex: 1; padding: 60px" }, children = {
          { tag = "h1", _text = "Happening now", _attr = { style = "font-size: 64px; margin-bottom: 40px" } },
          { tag = "button", _attr = { text = "Create account", href = "http://twitter.com/signup", bgcolor = "#1d9bf0", color = "#ffffff", style = "width: 300px; height: 40px" } },
          { tag = "button", _attr = { text = "Sign in", href = "http://twitter.com/login", bgcolor = "#ffffff", color="#1d9bf0", border = "1px solid #1d9bf0", style = "width: 300px; height: 40px" } },
        }}
      }}
    }
  },
  ["http://amazon.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { bgcolor = "#232f3e", style = "padding: 12px; color: white" }, children = {
        { tag = "span", _text = "amazon", _attr = { style = "font-weight: bold; font-size: 20px" } },
        { tag = "input", _attr = { placeholder = "Search Amazon...", value = "", width = "600", height = "36", bgcolor = "#ffffff", color="#000000" } },
      }},
      { tag = "div", _attr = { style = "padding: 40px; background: #eaeded" }, children = {
        { tag = "h1", _text = "Welcome to Amazon", _attr = { style = "font-size: 36px; margin-bottom: 20px" } },
        { tag = "p", _text = "Today's Deals - Electronics - Customer Service - Home", _attr = { style = "font-size: 16px; color: #007185" } },
      }}
    }
  },
  ["http://reddit.com"] = {
    type = "functional",
    functionalType = "forum",
    title = "Reddit",
    description = "The front page of the internet",
    posts = {
      {
        id = 1,
        title = "TIL that honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly good to eat.",
        author = "u/history_fan",
        upvotes = 15420,
        comments = 842,
        subreddit = "r/todayilearned",
        timestamp = "5 hours ago"
      },
      {
        id = 2,
        title = "What's your unpopular opinion that you're willing to defend?",
        author = "u/curious_mind",
        upvotes = 8921,
        comments = 3247,
        subreddit = "r/askreddit",
        timestamp = "2 hours ago"
      },
      {
        id = 3,
        title = "My cat learned how to open doors and now I have to child-proof my entire house",
        author = "u/cat_owner_problems",
        upvotes = 7563,
        comments = 421,
        subreddit = "r/cats",
        timestamp = "7 hours ago"
      }
    },
    subreddits = {
      "r/all", "r/popular", "r/funny", "r/askreddit", "r/gaming", "r/movies", "r/music", "r/science", "r/programming"
    }
  },
  ["http://youtube.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { bgcolor = "#ff0000", style = "padding: 12px; color: white" }, children = {
        { tag = "span", _text = "YouTube", _attr = { style = "font-weight: bold; font-size: 20px" } },
        { tag = "input", _attr = { placeholder = "Search", value = "", width = "400", height = "32", bgcolor = "#121212", color="#ffffff" } },
      }},
      { tag = "div", _attr = { style = "padding: 20px; background: #181818" }, children = {
        { tag = "h1", _text = "Welcome to YouTube", _attr = { color = "#ffffff" } },
        { tag = "p", _text = "Enjoy your favorite videos and music", _attr = { color = "#aaaaaa" } },
      }}
    }
  },
  ["http://microsoft.com"] = {
    type = "normal",
    tag = "div",
    children = {
      { tag = "nav", _attr = { style = "padding: 16px; border-bottom: 1px solid #d2d2d2" }, children = {
        { tag = "span", _text = "Microsoft", _attr = { style = "font-weight: bold; font-size: 20px; color: #737373" } },
      }},
      { tag = "div", _attr = { style = "padding: 80px; text-align: center" }, children = {
        { tag = "h1", _text = "Empowering every person and every organization on the planet to achieve more", _attr = { style = "font-size: 32px; margin-bottom: 20px" } },
        { tag = "button", _attr = { text = "Learn more", href = "http://microsoft.com/about", bgcolor = "#0067b1", color = "#ffffff" } },
      }}
    }
  },
  ["http://search.com"] = {
    type = "functional",
    functionalType = "search",
    title = "Search Engine",
    description = "Search the web",
    searchResults = {
      {
        title = "LÖVE - Free 2D Game Engine",
        url = "https://love2d.org",
        description = "LÖVE is an awesome framework you can use to make 2D games in Lua. It's free, open-source, and works on Windows, Mac OS X, Linux, Android and iOS."
      },
      {
        title = "Lua Programming Language",
        url = "https://lua.org",
        description = "Official website of the Lua programming language. Lua is a powerful, efficient, lightweight, embeddable scripting language."
      },
      {
        title = "Love2D Community Forums",
        url = "https://love2d.org/forums",
        description = "Official community forums for LÖVE game engine. Get help, share your projects, and connect with other developers."
      }
    }
  },
  ["http://forum.com"] = {
    type = "functional",
    functionalType = "forum",
    title = "Community Forum",
    description = "Discuss and share ideas",
    posts = {
      {
        id = 1,
        title = "Welcome to our new forum!",
        author = "Admin",
        content = "We're excited to launch our new community forum. Feel free to introduce yourself!",
        replies = 24,
        timestamp = "2024-01-15"
      },
      {
        id = 2,
        title = "How to get started with Love2D?",
        author = "NewUser123",
        content = "I'm new to game development and want to learn Love2D. Any tips for beginners?",
        replies = 15,
        timestamp = "2024-01-14"
      },
      {
        id = 3,
        title = "Showcase: My first game made with Love2D",
        author = "GameDevPro",
        content = "After 3 months of learning, I've completed my first game. Check it out!",
        replies = 42,
        timestamp = "2024-01-13"
      }
    }
  },
  ["http://home.com"] = {
    type = "functional",
    functionalType = "home",
    title = "Browser Home",
    description = "Your personalized homepage",
    quickLinks = {
      { name = "Search", url = "http://search.com" },
      { name = "Reddit", url = "http://reddit.com" },
      { name = "Forum", url = "http://forum.com" },
      { name = "Google", url = "http://google.com" },
      { name = "GitHub", url = "http://github.com" }
    },
    recentSites = {
      "http://google.com",
      "http://reddit.com",
      "http://github.com",
      "http://stackoverflow.com"
    }
  }
}

--------------------------------------------------------------------------------
-- Enhanced Color Parser with CSS-style colors
--------------------------------------------------------------------------------
function BrowserApp:parseColor(colorStr)
  if type(colorStr) ~= "string" then return nil end
  
  -- Hex colors
  if string.sub(colorStr,1,1) == "#" then
    if #colorStr == 7 then  -- #RRGGBB
      local r = tonumber(string.sub(colorStr,2,3), 16) / 255
      local g = tonumber(string.sub(colorStr,4,5), 16) / 255
      local b = tonumber(string.sub(colorStr,6,7), 16) / 255
      return r, g, b
    elseif #colorStr == 4 then  -- #RGB
      local r = tonumber(string.sub(colorStr,2,2), 16) / 15
      local g = tonumber(string.sub(colorStr,3,3), 16) / 15
      local b = tonumber(string.sub(colorStr,4,4), 16) / 15
      return r, g, b
    end
  end
  
  -- RGB format
  local r, g, b = colorStr:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
  if r and g and b then
    return tonumber(r)/255, tonumber(g)/255, tonumber(b)/255
  end
  
  -- Named colors
  local namedColors = {
    red = {1, 0, 0},
    green = {0, 0.5, 0},
    blue = {0, 0, 1},
    white = {1, 1, 1},
    black = {0, 0, 0},
    gray = {0.5, 0.5, 0.5},
    yellow = {1, 1, 0},
    orange = {1, 0.65, 0},
    purple = {0.5, 0, 0.5},
  }
  
  if namedColors[colorStr:lower()] then
    local color = namedColors[colorStr:lower()]
    return color[1], color[2], color[3]
  end
  
  -- Comma-separated values (0-255 or 0.0-1.0)
  local r, g, b = colorStr:match("([^,]+),([^,]+),([^,]+)")
  if r and g and b then
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r and g and b then
      if r > 1 or g > 1 or b > 1 then  -- Assume 0-255 range
        return r/255, g/255, b/255
      else  -- Assume 0.0-1.0 range
        return r, g, b
      end
    end
  end
  
  return nil
end

--------------------------------------------------------------------------------
-- Enhanced Style Collection with CSS-like properties
--------------------------------------------------------------------------------
function BrowserApp:collectStyles(element)
  local styles = {}
  if element._attr then
    -- Text alignment
    if element._attr.align then styles.align = element._attr.align end
    if element._attr.style and element._attr.style:match("text%-align:") then
      styles.align = element._attr.style:match("text%-align:%s*([^;]+)")
    end
    
    -- Colors
    if element._attr.color then 
      local r, g, b = self:parseColor(element._attr.color)
      if r then styles.color = {r, g, b} end
    end
    if element._attr.bgcolor then 
      local r, g, b = self:parseColor(element._attr.bgcolor)
      if r then styles.bgcolor = {r, g, b} end
    end
    
    -- Text styles
    if element._attr.bold then styles.bold = (element._attr.bold == "true" or element._attr.bold == true) end
    if element._attr.italic then styles.italic = (element._attr.italic == "true" or element._attr.italic == true) end
    if element._attr.underline then styles.underline = (element._attr.underline == "true" or element._attr.underline == true) end
    
    -- Border and radius
    if element._attr.border then styles.border = element._attr.border end
    if element._attr.radius then styles.radius = element._attr.radius end
    
    -- Parse style attribute for CSS-like properties
    if element._attr.style then
      for prop, value in element._attr.style:gmatch("([%w-]+):%s*([^;]+)") do
        if prop == "margin" or prop == "padding" then
          styles[prop] = value
        elseif prop == "font-size" then
          styles.fontSize = value
        elseif prop == "font-weight" then
          styles.bold = (value == "bold")
        elseif prop == "background-color" then
          local r, g, b = self:parseColor(value)
          if r then styles.bgcolor = {r, g, b} end
        elseif prop == "color" then
          local r, g, b = self:parseColor(value)
          if r then styles.color = {r, g, b} end
        end
      end
    end
  end
  return styles
end

--------------------------------------------------------------------------------
-- Enhanced BrowserApp Constructor
--------------------------------------------------------------------------------
function BrowserApp.new()
  local self = setmetatable({}, BrowserApp)
  self.url = "http://home.com"  -- Start with functional home page
  self.websiteData = websiteDatabase[self.url] or {
      type = "normal",
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
  self.scrollOffset = 0
  self.scrollSpeed = 20
  self.maxScroll = 0
  self.loading = false
  self.loadingTimer = 0
  self.loadingDuration = 0
  self.urlCursor = #self.url + 1
  self.urlCursorTimer = 0
  self.urlCursorVisible = true
  self.activeInput = nil
  self.windowWidth = 800
  self.windowHeight = 600
  
  -- Functional website state
  self.searchQuery = ""
  self.activePost = nil
  self.functionalInput = ""
  
  return self
end

--------------------------------------------------------------------------------
-- Functional Website Rendering
--------------------------------------------------------------------------------
function BrowserApp:renderFunctionalWebsite(x, y, width, height)
  local website = self.websiteData
  local currentY = y
  
  if website.functionalType == "home" then
    currentY = self:renderHomePage(x, currentY, width)
  elseif website.functionalType == "search" then
    currentY = self:renderSearchPage(x, currentY, width)
  elseif website.functionalType == "forum" then
    currentY = self:renderForumPage(x, currentY, width)
  end
  
  return currentY
end

function BrowserApp:renderHomePage(x, y, width)
  local website = self.websiteData
  local currentY = y
  
  -- Header
  love.graphics.setColor(0.2, 0.4, 0.8)
  love.graphics.rectangle("fill", x, currentY, width, 80)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.h1Font)
  love.graphics.printf(website.title, x, currentY + 20, width, "center")
  love.graphics.setFont(self.defaultFont)
  love.graphics.printf(website.description, x, currentY + 55, width, "center")
  currentY = currentY + 100
  
  -- Quick Links
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.setFont(self.h3Font)
  love.graphics.printf("Quick Links", x, currentY, width, "center")
  currentY = currentY + 40
  
  love.graphics.setFont(self.defaultFont)
  local linkWidth = 120
  local linkHeight = 40
  local linksPerRow = math.floor(width / (linkWidth + 20))
  local linkX = x + (width - (linksPerRow * (linkWidth + 20))) / 2
  
  for i, link in ipairs(website.quickLinks) do
    local row = math.floor((i - 1) / linksPerRow)
    local col = (i - 1) % linksPerRow
    local linkXPos = linkX + col * (linkWidth + 20)
    local linkYPos = currentY + row * (linkHeight + 15)
    
    -- Draw link button
    love.graphics.setColor(0.1, 0.5, 0.9)
    love.graphics.rectangle("fill", linkXPos, linkYPos, linkWidth, linkHeight, 8, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(link.name, linkXPos, linkYPos + 12, linkWidth, "center")
    
    -- Register clickable region
    table.insert(self.buttonRegions, {
      x = linkXPos,
      y = linkYPos - self.scrollOffset,
      width = linkWidth,
      height = linkHeight,
      onClick = function()
        self:loadURL(link.url)
      end
    })
  end
  
  currentY = currentY + math.ceil(#website.quickLinks / linksPerRow) * (linkHeight + 15) + 30
  
  -- Recent Sites
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.setFont(self.h3Font)
  love.graphics.printf("Recent Sites", x, currentY, width, "center")
  currentY = currentY + 40
  
  love.graphics.setFont(self.defaultFont)
  for i, site in ipairs(website.recentSites) do
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", x + 20, currentY, width - 40, 30, 5, 5)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.printf(site, x + 30, currentY + 8, width - 60, "left")
    
    table.insert(self.buttonRegions, {
      x = x + 20,
      y = currentY - self.scrollOffset,
      width = width - 40,
      height = 30,
      onClick = function()
        self:loadURL(site)
      end
    })
    
    currentY = currentY + 40
  end
  
  return currentY
end

function BrowserApp:renderSearchPage(x, y, width)
  local website = self.websiteData
  local currentY = y
  
  -- Header
  love.graphics.setColor(0.1, 0.6, 0.3)
  love.graphics.rectangle("fill", x, currentY, width, 80)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.h1Font)
  love.graphics.printf(website.title, x, currentY + 20, width, "center")
  love.graphics.setFont(self.defaultFont)
  love.graphics.printf(website.description, x, currentY + 55, width, "center")
  currentY = currentY + 100
  
  -- Search Box
  local searchWidth = 600
  local searchX = x + (width - searchWidth) / 2
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", searchX, currentY, searchWidth, 40, 5, 5)
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.rectangle("line", searchX, currentY, searchWidth, 40, 5, 5)
  
  love.graphics.setColor(0.3, 0.3, 0.3)
  if self.functionalInput == "" then
    love.graphics.printf("Enter your search query...", searchX + 10, currentY + 12, searchWidth - 20, "left")
  else
    love.graphics.printf(self.functionalInput, searchX + 10, currentY + 12, searchWidth - 20, "left")
  end
  
  -- Search button
  love.graphics.setColor(0.1, 0.5, 0.9)
  love.graphics.rectangle("fill", searchX + searchWidth + 10, currentY, 80, 40, 5, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("Search", searchX + searchWidth + 10, currentY + 12, 80, "center")
  
  table.insert(self.buttonRegions, {
    x = searchX,
    y = currentY - self.scrollOffset,
    width = searchWidth,
    height = 40,
    onClick = function()
      self.activeInput = { 
        element = { _attr = { value = self.functionalInput } }, 
        cursor = #self.functionalInput + 1,
        cursorTimer = 0,
        cursorVisible = true,
        functional = true
      }
    end
  })
  
  table.insert(self.buttonRegions, {
    x = searchX + searchWidth + 10,
    y = currentY - self.scrollOffset,
    width = 80,
    height = 40,
    onClick = function()
      self.searchQuery = self.functionalInput
    end
  })
  
  currentY = currentY + 60
  
  -- Search Results
  if self.searchQuery ~= "" then
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setFont(self.h3Font)
    love.graphics.printf('Search results for: "' .. self.searchQuery .. '"', x, currentY, width, "center")
    currentY = currentY + 40
    
    love.graphics.setFont(self.defaultFont)
    for i, result in ipairs(website.searchResults) do
      love.graphics.setColor(0.9, 0.9, 0.9)
      love.graphics.rectangle("fill", x + 10, currentY, width - 20, 80, 5, 5)
      love.graphics.setColor(0.1, 0.3, 0.8)
      love.graphics.printf(result.title, x + 20, currentY + 10, width - 40, "left")
      love.graphics.setColor(0.1, 0.5, 0.1)
      love.graphics.printf(result.url, x + 20, currentY + 30, width - 40, "left")
      love.graphics.setColor(0.3, 0.3, 0.3)
      love.graphics.printf(result.description, x + 20, currentY + 50, width - 40, "left")
      
      table.insert(self.buttonRegions, {
        x = x + 10,
        y = currentY - self.scrollOffset,
        width = width - 20,
        height = 80,
        onClick = function()
          self:loadURL(result.url)
        end
      })
      
      currentY = currentY + 100
    end
  end
  
  return currentY
end

function BrowserApp:renderForumPage(x, y, width)
  local website = self.websiteData
  local currentY = y
  
  -- Header
  if website.title == "Reddit" then
    love.graphics.setColor(1, 0.27, 0)  -- Reddit orange
  else
    love.graphics.setColor(0.2, 0.4, 0.7)  -- Default blue
  end
  love.graphics.rectangle("fill", x, currentY, width, 60)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.h1Font)
  love.graphics.printf(website.title, x, currentY + 15, width, "center")
  currentY = currentY + 80
  
  -- Description
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.setFont(self.defaultFont)
  love.graphics.printf(website.description, x, currentY, width, "center")
  currentY = currentY + 30
  
  -- Subreddits (if Reddit)
  if website.title == "Reddit" and website.subreddits then
    love.graphics.setColor(0.8, 0.8, 0.8)
    for i, sub in ipairs(website.subreddits) do
      local subWidth = love.graphics.getFont():getWidth(sub) + 20
      local subX = x + 10 + ((i - 1) * (subWidth + 10))
      
      if subX + subWidth < width then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", subX, currentY, subWidth, 25, 3, 3)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.printf(sub, subX, currentY + 5, subWidth, "center")
        
        table.insert(self.buttonRegions, {
          x = subX,
          y = currentY - self.scrollOffset,
          width = subWidth,
          height = 25,
          onClick = function()
            -- In a real implementation, this would load the subreddit
            self:showMessage("Loading " .. sub .. "...")
          end
        })
      end
    end
    currentY = currentY + 40
  end
  
  -- Posts
  for i, post in ipairs(website.posts) do
    -- Post container
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x + 10, currentY, width - 20, 120, 5, 5)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x + 10, currentY, width - 20, 120, 5, 5)
    
    -- Voting buttons (left side)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", x + 15, currentY + 10, 30, 80, 3, 3)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.printf("▲", x + 15, currentY + 15, 30, "center")
    love.graphics.printf(tostring(post.upvotes), x + 15, currentY + 45, 30, "center")
    love.graphics.printf("▼", x + 15, currentY + 70, 30, "center")
    
    -- Post content
    local contentX = x + 55
    local contentWidth = width - 75
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.h4Font)
    love.graphics.printf(post.title, contentX, currentY + 10, contentWidth, "left")
    
    love.graphics.setFont(self.defaultFont)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("by " .. post.author .. " • " .. post.timestamp, contentX, currentY + 40, contentWidth, "left")
    
    if post.content then
      love.graphics.setColor(0.4, 0.4, 0.4)
      love.graphics.printf(post.content, contentX, currentY + 60, contentWidth, "left")
    end
    
    -- Comments/Replies
    love.graphics.setColor(0.6, 0.6, 0.6)
    local commentText = post.comments and (tostring(post.comments) .. " comments") or (tostring(post.replies) .. " replies")
    love.graphics.printf(commentText, contentX, currentY + 90, contentWidth, "left")
    
    -- Make post clickable
    table.insert(self.buttonRegions, {
      x = x + 10,
      y = currentY - self.scrollOffset,
      width = width - 20,
      height = 120,
      onClick = function()
        self.activePost = post
      end
    })
    
    currentY = currentY + 140
  end
  
  return currentY
end

--------------------------------------------------------------------------------
-- Enhanced Input Field Rendering with Better Cursor Handling
--------------------------------------------------------------------------------
function BrowserApp:renderInputField(element, x, y, maxWidth)
  local styles = self:collectStyles(element)
  local inWidth = tonumber(element._attr and element._attr.width) or 150
  local inHeight = tonumber(element._attr and element._attr.height) or 30
  local value = element._attr and element._attr.value or ""
  local placeholder = element._attr and element._attr.placeholder or ""
  
  -- Background color
  local baseBgColor = {1, 1, 1}
  if styles.bgcolor then
    baseBgColor = styles.bgcolor
  end
  
  -- Border color
  local borderColor = {0.7, 0.7, 0.7}
  if self.activeInput and self.activeInput.element == element then
    borderColor = {0.2, 0.5, 1}
  end
  
  -- Hover effect
  local mx, my = love.mouse.getPosition()
  local hovered = (mx >= x and mx <= x+inWidth and my >= y and my <= y+inHeight)
  if hovered then
    baseBgColor = {baseBgColor[1]*0.95, baseBgColor[2]*0.95, baseBgColor[3]*0.95}
  end
  
  -- Draw input background with border
  love.graphics.setColor(unpack(baseBgColor))
  love.graphics.rectangle("fill", x, y, inWidth, inHeight, 4, 4)
  love.graphics.setColor(unpack(borderColor))
  love.graphics.rectangle("line", x, y, inWidth, inHeight, 4, 4)
  
  -- Draw text
  love.graphics.setColor(0, 0, 0)
  if value == "" then
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf(placeholder, x + 8, y + (inHeight - self.defaultFont:getHeight()) / 2, inWidth - 16, "left")
  else
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(value, x + 8, y + (inHeight - self.defaultFont:getHeight()) / 2, inWidth - 16, "left")
  end
  
  -- Draw cursor
  if self.activeInput and self.activeInput.element == element then
    local cursorPos = self.activeInput.cursor or (#value + 1)
    local beforeCursor = value:sub(1, cursorPos - 1)
    local cursorX = x + 8 + self.defaultFont:getWidth(beforeCursor)
    if self.activeInput.cursorVisible then
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("fill", cursorX, y + 6, 2, inHeight - 12)
    end
  end
  
  love.graphics.setColor(1, 1, 1)
  
  -- Register clickable region
  table.insert(self.buttonRegions, {
      x = x,
      y = y - self.scrollOffset,
      width = inWidth,
      height = inHeight,
      onClick = function()
          self.activeInput = { 
            element = element, 
            cursor = math.min(#value + 1, self:getCursorPosition(value, x + 8, mx)), 
            cursorTimer = 0, 
            cursorVisible = true 
          }
      end
  })
  
  return inHeight + 10
end

-- Helper to calculate cursor position based on click
function BrowserApp:getCursorPosition(text, startX, clickX)
  local currentX = startX
  for i = 1, #text do
    local charWidth = self.defaultFont:getWidth(text:sub(i, i))
    if clickX < currentX + charWidth / 2 then
      return i
    end
    currentX = currentX + charWidth
  end
  return #text + 1
end

--------------------------------------------------------------------------------
-- Enhanced Button Rendering
--------------------------------------------------------------------------------
function BrowserApp:renderButton(element, x, y, maxWidth)
  local styles = self:collectStyles(element)
  local btnWidth = tonumber(element._attr and element._attr.width) or 150
  local btnHeight = tonumber(element._attr and element._attr.height) or 36
  local baseColor = {0.2, 0.6, 1}
  
  if styles.bgcolor then
    baseColor = styles.bgcolor
  end
  
  -- Text color
  local textColor = {1, 1, 1}
  if styles.color then
    textColor = styles.color
  end
  
  -- Hover effect
  local mx, my = love.mouse.getPosition()
  local hovered = (mx >= x and mx <= x+btnWidth and my >= y and my <= y+btnHeight)
  if hovered then
    baseColor = {math.min(1, baseColor[1]*1.1), math.min(1, baseColor[2]*1.1), math.min(1, baseColor[3]*1.1)}
  end
  
  -- Draw button with shadow and rounded corners
  love.graphics.setColor(0, 0, 0, 0.1)
  love.graphics.rectangle("fill", x+2, y+2, btnWidth, btnHeight, 6, 6)
  
  love.graphics.setColor(unpack(baseColor))
  love.graphics.rectangle("fill", x, y, btnWidth, btnHeight, 6, 6)
  
  -- Border
  love.graphics.setColor(unpack(baseColor))
  love.graphics.rectangle("line", x, y, btnWidth, btnHeight, 6, 6)
  
  -- Button text
  love.graphics.setColor(unpack(textColor))
  local buttonText = (element._attr and element._attr.text) or ""
  love.graphics.printf(buttonText, x, y + (btnHeight - self.defaultFont:getHeight()) / 2, btnWidth, "center")
  
  table.insert(self.buttonRegions, {
      x = x,
      y = y - self.scrollOffset,
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
  
  love.graphics.setColor(1, 1, 1)
  return btnHeight + 10
end

function BrowserApp:setURL(url)
  self.url = url
  self.urlCursor = #url + 1
  self.websiteData = websiteDatabase[url] or {
      type = "normal",
      tag = "div",
      children = { { tag = "p", _text = "404 Page Not Found: " .. url } }
  }
  self.activePost = nil
  self.searchQuery = ""
  self.functionalInput = ""
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
      if self.websiteData.type == "functional" then
          local totalContentHeight = self:renderFunctionalWebsite(x + 10, contentY, width - 20)
          self.maxScroll = math.max(0, totalContentHeight - (height - 50))
      else
          local totalContentHeight = self:renderHTML(self.websiteData, x + 10, contentY, width - 20)
          self.maxScroll = math.max(0, totalContentHeight - (height - 50))
      end
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
      if self.activeInput.functional then
        -- Handle functional website input
        if key == "left" then
            if self.activeInput.cursor > 1 then self.activeInput.cursor = self.activeInput.cursor - 1 end
        elseif key == "right" then
            if self.activeInput.cursor <= #self.functionalInput then self.activeInput.cursor = self.activeInput.cursor + 1 end
        elseif key == "backspace" then
            if self.activeInput.cursor > 1 then
                self.functionalInput = self.functionalInput:sub(1, self.activeInput.cursor - 1) .. self.functionalInput:sub(self.activeInput.cursor + 1)
                self.activeInput.cursor = self.activeInput.cursor - 1
            end
        elseif key == "delete" then
            self.functionalInput = self.functionalInput:sub(1, self.activeInput.cursor - 1) .. self.functionalInput:sub(self.activeInput.cursor + 1)
        elseif key == "return" then
            self.activeInput = nil
        end
      else
        -- Handle normal website input
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
      if self.activeInput.functional then
        local before = self.functionalInput:sub(1, self.activeInput.cursor - 1)
        local after = self.functionalInput:sub(self.activeInput.cursor)
        self.functionalInput = before .. text .. after
        self.activeInput.cursor = self.activeInput.cursor + #text
      else
        local val = self.activeInput.element._attr.value or ""
        local before = val:sub(1, self.activeInput.cursor - 1)
        local after = val:sub(self.activeInput.cursor)
        self.activeInput.element._attr.value = before .. text .. after
        self.activeInput.cursor = self.activeInput.cursor + #text
      end
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
  self.websiteData = {
      type = "normal",
      tag = "div",
      children = {
          { tag = "h1", _text = "Message" },
          { tag = "p", _text = message },
          { tag = "button", _attr = { text = "Go Back", action = "back" } }
      }
  }
end

return BrowserApp