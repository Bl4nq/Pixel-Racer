
-- Street class.
-- Responsible for drawing the road and calculating lane positions.
Street = Class{}

-- Constants for road appearance.
local PLANK_WIDTH = 5
local DASH_LENGTH = 16
local DASH_GAP = 16
local LANE_COUNT = 3


function Street:init(x, y, width, height, r, g, b, a)

    -- Position and dimensions of the street.
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- Street color (RGBA).
    self.r = r or 1
    self.g = g or 1
    self.b = b or 1
    self.a = a or 1

    -- Calculate the width of one lane.
    self.lane_width = (width - PLANK_WIDTH * (LANE_COUNT + 1)) / LANE_COUNT
end


-- Returns the horizontal center position of a specific lane.
-- lane: Lane number (1 = left, 2 = middle, 3 = right).
function Street:getLaneCenter(lane)

    -- Prevent invalid lane numbers.
    lane = math.max(1, math.min(LANE_COUNT, lane))

    -- Calculate the actual center of the selected lane.
    return self.x + PLANK_WIDTH
        + self.lane_width / 2
        + (lane - 1) * (self.lane_width + PLANK_WIDTH)
end


-- Draws a dotted vertical lane marking.
local function drawDottedLane(x, y, width, height)

    local spacing = DASH_LENGTH + DASH_GAP
    local currentY = y

    while currentY < y + height do

        -- Draw one dash.
        love.graphics.rectangle(
            'fill',
            x,
            currentY,
            width,
            math.min(DASH_LENGTH, y + height - currentY)
        )

        -- Move to the next dash.
        currentY = currentY + spacing
    end
end


function Street:render()

    love.graphics.setColor(self.r, self.g, self.b, self.a)

    -- Draw the left outer road marking.
    love.graphics.rectangle(
        'fill',
        self.x,
        self.y,
        PLANK_WIDTH,
        self.height
    )

    -- Draw the dotted lane separators.
    for i = 1, LANE_COUNT - 1 do

        local laneX = self.x + i * (self.lane_width + PLANK_WIDTH)

        drawDottedLane(
            laneX,
            self.y,
            PLANK_WIDTH,
            self.height
        )
    end

    -- Draw the right outer road marking.
    local rightX = self.x + self.width - PLANK_WIDTH

    love.graphics.rectangle(
        'fill',
        rightX,
        self.y,
        PLANK_WIDTH,
        self.height
    )

    -- Reset drawing color.
    love.graphics.setColor(1, 1, 1, 1)
end