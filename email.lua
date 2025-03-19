-- email.lua
local EmailApp = {}
EmailApp.__index = EmailApp

function EmailApp.new()
   local self = setmetatable({}, EmailApp)
   self.emails = {
       { subject = "Welcome", sender = "noreply@example.com", body = "Welcome to our service!" },
       { subject = "Meeting Reminder", sender = "boss@example.com", body = "Don't forget the meeting at 10 AM." },
       { subject = "Newsletter", sender = "news@example.com", body = "This week in news..." },
   }
   self.selected = 1
   return self
end

function EmailApp:draw(x, y, width, height)
   love.graphics.setColor(1, 1, 1)
   love.graphics.rectangle("fill", x, y, width, height)
   love.graphics.setColor(0, 0, 0)
   love.graphics.printf("Inbox:", x + 10, y + 10, width - 20, "left")
   for i, email in ipairs(self.emails) do
       local text = i .. ". " .. email.subject .. " - " .. email.sender
       if i == self.selected then
           love.graphics.setColor(0.8, 0.8, 1)  -- Highlight selected email
           love.graphics.rectangle("fill", x + 10, y + 30 + (i - 1) * 20, width - 20, 20)
           love.graphics.setColor(0, 0, 0)
       else
           love.graphics.setColor(1, 1, 1)
       end
	   love.graphics.setColor(0, 0, 0)
       love.graphics.print(text, x + 15, y + 30 + (i - 1) * 20)
   end

   -- Display the body of the selected email
   local email = self.emails[self.selected]
   if email then
       love.graphics.setColor(0, 0, 0)
       love.graphics.printf("Content:\n" .. email.body, x + 10, y + 30 + (#self.emails) * 20 + 10, width - 20, "left")
   end
end

function EmailApp:mousepressed(x, y, button)
   if button == 1 then
       local listYStart = 30
       local lineHeight = 20
       local index = math.floor((y - listYStart) / lineHeight) + 1
       if index >= 1 and index <= #self.emails then
           self.selected = index
       end
   end
end

function EmailApp:update(dt)
   -- No dynamic update needed for this simple example
end

return EmailApp
