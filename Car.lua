Car = Class{}

function Car:init(player, x, y, width, height, street, r, g, b, a)

    self.player = player
    self.street = street

    if self.player then
        -- Initialize the player's car.
        self.x = x
        self.y = y
        self.width = width
        self.height = height

        self.r = r
        self.g = g
        self.b = b
        self.a = a

        -- Player starts in the middle lane.
        self.position = 2

    else
        -- Initialize an enemy car.
        self.position = math.random(1, 3)

        self.x = 0
        self.y = -50

        self.width = 30
        self.height = 50

        self.r = 1
        self.g = 1
        self.b = 1
        self.a = 1
    end

    -- Initial vertical speed.
    self.dy = 200

    -- Calculate the initial horizontal position immediately.
    self.x = self.street:getLaneCenter(self.position) - self.width / 6
end


function Car:update(dt)

    -- Update speed according to the current difficulty.
    self.dy = 200 + Difficultytimer


    -- Position the car in the center of its lane.
    -- The visual car is offset by width/6 because of its drawing shape.
    self.x = self.street:getLaneCenter(self.position) - self.width / 6

    -- Only enemy cars move vertically.
    if not self.player then
        self.y = self.y + self.dy * dt
    end
end


-- Draws a car using three rectangles.
function draw_car(x, y, width, height)

    love.graphics.rectangle('fill', x, y, width/3, height)
    love.graphics.rectangle('fill', x-height/5, y+width/4, width, width/3)
    love.graphics.rectangle('fill', x-height/5, y+width*1.1, width, width/3)
end


function Car:render()

    love.graphics.setColor(self.r, self.g, self.b, self.a)
    draw_car(self.x, self.y, self.width, self.height)
end


function Car:collides(car)

    -- Check horizontal overlap.
    if self.x + self.width <= car.x or
       car.x + car.width <= self.x then
        return false
    end

    -- Check vertical overlap.
    if self.y + self.height <= car.y or
       car.y + car.height <= self.y then
        return false
    end

    return true
end