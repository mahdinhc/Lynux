local EmailApp = {}
EmailApp.__index = EmailApp

function EmailApp.new()
    local self = setmetatable({}, EmailApp)
    self.emails = {
        {
            subject = "Welcome",
            sender = "noreply@example.com",
            body = "Welcome to our service!\n\nWe're excited to have you on board."
        },
        {
            subject = "Meeting Reminder",
            sender = "boss@example.com",
            body = "Just a reminder about our meeting at 10 AM.\n\nLocation: Conference Room A."
        },
        {
            subject = "Newsletter",
            sender = "news@example.com",
            body = "Here's what happened this week in news...\n\n1. Market rallies.\n2. New product launches.\n3. Community events."
        },
    }
    self.selected = 1
    return self
end

function EmailApp:draw(x, y, width, height)
    local emailListWidth = 160
    local emailContentWidth = width - emailListWidth - 1

    -- Draw email list area (LEFT side)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x, y, emailListWidth, height)

    -- Header
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", x, y, emailListWidth, 40)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Inbox", x, y + 10, emailListWidth, "center")

    -- Email items
    local itemY = y + 50
    local itemHeight = 60

    for i, email in ipairs(self.emails) do
        if i == self.selected then
            love.graphics.setColor(0.8, 0.85, 1)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.rectangle("fill", x, itemY, emailListWidth, itemHeight - 5)

        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(email.subject, x + 10, itemY + 10, emailListWidth - 20, "left")

        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(email.sender, x + 10, itemY + 30, emailListWidth - 20, "left")

        itemY = itemY + itemHeight
    end

    -- Separator line
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", x + emailListWidth, y, 1, height)

    -- Draw content area (RIGHT side)
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x + emailListWidth + 1, y, emailContentWidth, height)

    local email = self.emails[self.selected]
    if email then
        local padding = 20
        local contentX = x + emailListWidth + 1
        local textY = y + padding

        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Subject:", contentX + padding, textY)

        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.print(email.subject, contentX + padding, textY + 20)

        textY = textY + 60
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("From: " .. email.sender, contentX + padding, textY)

        textY = textY + 40
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.line(contentX + padding, textY, contentX + emailContentWidth - padding, textY)

        textY = textY + 20
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(email.body, contentX + padding, textY, emailContentWidth - 2 * padding, "left")
    end
end

function EmailApp:mousepressed(x, y, button)
    if button == 1 then
        local emailListWidth = 250
        local listYStart = 50
        local itemHeight = 60

        if x <= emailListWidth then
            local index = math.floor((y - listYStart) / itemHeight) + 1
            if index >= 1 and index <= #self.emails then
                self.selected = index
            end
        end
    end
end

function EmailApp:keypressed(key)
    if key == "up" then
        self.selected = math.max(1, self.selected - 1)
    elseif key == "down" then
        self.selected = math.min(#self.emails, self.selected + 1)
    end
end

function EmailApp:update(dt)
    -- Placeholder for future updates
end

return EmailApp
