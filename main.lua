-- Load external libraries:
-- push: Handles virtual resolution and scaling.
-- class: Provides an object-oriented class system.
push = require 'push'
Class = require 'class'

-- Load the classes used by the game.
require 'Car'
require 'Street'

-- Actual window resolution.
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- Internal game resolution.
-- The game is rendered at this smaller resolution and scaled up by push.
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- Base speed used for the cars.
CAR_SPEED = 200

-- Timer used to control how quickly the player can change lanes.
local timer = 0

-- Table containing all currently spawned enemy cars.
local cars = {}

-- Timer controlling when new enemy cars spawn.
local spawntimer = 0

-- Timer controlling the difficulty progression.
Difficultytimer = 0

-- Timer controlling how often the player receives a score point.
local scoretimer = 0

-- Stores all saved high scores.
local highscores = {}

-- Maximum number of high scores displayed and saved.
local MAX_HIGHSCORES = 10

-- Controls the time interval between enemy car spawns.
-- The value decreases as the game gets harder.
S = 1.0


function love.load()
    -- Use nearest-neighbor filtering to keep pixel graphics sharp.
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Set the game window title.
    love.window.setTitle('Racer')

    -- Load different font sizes for the user interface.
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    titleFont = love.graphics.newFont('font.ttf', 48)
    love.graphics.setFont(smallFont)

    -- Configure the actual game window.
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        resizable = false,
        fullscreen = false,
        vsync = true
    })

    -- Initialize the virtual resolution.
    -- This allows the game to keep its original aspect ratio when scaled.
    push.setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, { upscale = 'normal' })

    -- Initialize the game state and score.
    Highscore = 0
    gameState = 'start'

    -- Create the street and the player's car.
    street = Street(5, 0, VIRTUAL_WIDTH/2, VIRTUAL_HEIGHT, 1, 1, 1, 1)
    racer = Car(true, 0, VIRTUAL_HEIGHT/1.5, 30, 50, street, 1, 0, 0, 1)

    -- Load previously saved high scores from the file.
    loadHighscores()
end


function love.keypressed(key)
    -- Escape closes the game.
    if key == 'escape' then
        love.event.quit()

    -- Enter starts, pauses or restarts the game depending on the current state.
    elseif key == 'enter' or key == 'return' then

        if gameState == 'race' then
            -- Return to the start screen.
            gameState = 'pause'

        elseif gameState == 'start' then
            -- Start a new race.
            gameState = 'race'

        elseif gameState == 'pause' then
            -- Start a new race.
            gameState = 'race'

        elseif gameState == 'game over' then
            -- Reset all game variables and start again.
            resetGame()
            gameState = 'race'
        end
    end
end


function love.update(dt)
    -- Only update the game logic while a race is active.
    if gameState == 'race' then

        -- Increase all timers using delta time.
        -- Delta time makes the game independent of the frame rate.
        timer = timer + dt
        spawntimer = spawntimer + dt
        Difficultytimer = Difficultytimer + dt
        Highscore = math.floor(Highscore)
        scoretimer = scoretimer + dt

        -- Increase the score once every second.
        if scoretimer >= 1 then
            Highscore = Highscore + 1
            scoretimer = scoretimer - 1
        end

        -- Increase the difficulty every five seconds.
        if Difficultytimer >= 5 then
            -- Reduce the spawn interval to make enemy cars appear more frequently.
            if S > 0.58 then
                S = S-0.02
                Difficultytimer = 0
            end
        end

        -- Spawn a new enemy car once the spawn timer reaches the current interval.
        if spawntimer >= S then
            table.insert(cars, Car(false, nil, nil, nil, nil, street))
            spawntimer = 0
        end

        -- Update all enemy cars.
        -- Iterate backwards so cars can safely be removed from the table.
        for i = #cars, 1, -1 do
            local car = cars[i]
            car:update(dt)

            -- Remove cars that have completely passed the bottom of the screen.
            -- Award 10 additional points for successfully avoiding them.
            if car.y > VIRTUAL_HEIGHT+car.height then
                table.remove(cars,i)
                Highscore = Highscore + 10
            end
        end

        -- Limit lane switching to once every 0.1 seconds.
        -- This prevents the player from switching lanes uncontrollably.
        if timer >= 0.1 then

            -- Move one lane to the left using A.
            if love.keyboard.isDown('a') then
                if racer.position == 2 then
                    racer.position = 1
                elseif racer.position == 3 then
                    racer.position = 2
                end
                timer = 0

            -- Move one lane to the right using D.
            elseif love.keyboard.isDown('d') then
                if racer.position == 1 then
                    racer.position = 2
                elseif racer.position == 2 then
                    racer.position = 3
                end
                timer = 0
            end
        end

        -- Update the player's car.
        racer:update(dt)

        -- Reset the collision flag before checking for new collisions.
        collision = false

        -- Check whether the player's car collides with any enemy car.
        for i, car in pairs(cars) do
            if racer:collides(car) then
                collision = true

                -- Save the current score in the high score list.
                addHighscore(Highscore)

                -- End the current race.
                gameState = 'game over'
                break
            end
        end
    end
end


function love.draw()
    -- Start drawing using the virtual resolution provided by push.
    push.start()

    -- Draw the street and the player's car.
    street:render()
    racer:render()

    -- Draw all enemy cars.
    for i, cars in pairs(cars) do
        cars:render()
    end

    -- Draw the score, high score list and game state messages.
    renderText()

    -- Finish rendering and scale the result to the actual window.
    push.finish()
end


function renderText()

    -- Calculate the available UI area to the right of the street.
    local uiX = street.x + street.width
    local uiWidth = VIRTUAL_WIDTH - uiX
    local uiCenter = uiX + uiWidth / 2

    love.graphics.setColor(1, 1, 1, 1)

    --------------------------------------------------
    -- GAME TITLE
    --------------------------------------------------

    love.graphics.setFont(titleFont)

    local title = 'Racer'
    local subtitle = '2D'

    -- Calculate the combined width of both title parts.
    local titleWidth = titleFont:getWidth(title)
    local subtitleWidth = titleFont:getWidth(subtitle)
    local totalTitleWidth = titleWidth + subtitleWidth

    -- Center the complete title in the UI area.
    local titleX = uiCenter - totalTitleWidth / 2

    -- Draw "Racer".
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, titleX, 10)

    -- Draw "2D" in red.
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print(subtitle, titleX + titleWidth, 10)


    --------------------------------------------------
    -- CURRENT SCORE
    --------------------------------------------------

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(largeFont)

    -- Center the current score below the title.
    love.graphics.printf(
        'Score: ' .. tostring(Highscore),
        uiX,
        65,
        uiWidth,
        'center'
    )


    --------------------------------------------------
    -- HIGHSCORE TABLE
    --------------------------------------------------

    love.graphics.setFont(largeFont)
    love.graphics.setColor(1, 1, 1, 1)

    -- Center the highscore heading.
    love.graphics.printf(
        'HIGH SCORES',
        uiX,
        90,
        uiWidth,
        'center'
    )

    -- Configure the table columns.
    local tableWidth = 110
    local tableX = uiCenter - tableWidth / 2
    local rowHeight = 11
    local tableY = 110

    -- Column headings.
    love.graphics.setFont(smallFont)

    love.graphics.printf(
        'RANK',
        tableX,
        tableY,
        35,
        'left'
    )

    love.graphics.printf(
        'SCORE',
        tableX + 40,
        tableY,
        70,
        'right'
    )

    -- Draw a separator underneath the column headings.
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.line(
        tableX,
        tableY + 10,
        tableX + tableWidth,
        tableY + 10
    )

    -- Display the top 10 high scores.
    love.graphics.setColor(1, 1, 1, 1)

    for i = 1, MAX_HIGHSCORES do

        local score = highscores[i] or 0
        local rowY = tableY + 14 + (i - 1) * rowHeight

        -- Draw rank.
        love.graphics.printf(
            tostring(i) .. '.',
            tableX,
            rowY,
            35,
            'left'
        )

        -- Draw score.
        love.graphics.printf(
            tostring(score),
            tableX + 40,
            rowY,
            70,
            'right'
        )
    end


    -- Draw a centered message box.
    -- Calculates its size automatically based on the text.
    local function drawMessageBox(title, subtitle)

        local padding = 10
        local boxX = VIRTUAL_WIDTH/7 - 10
        local boxY = 60

        -- Measure the required text dimensions.
        love.graphics.setFont(scoreFont)
        local titleWidth = scoreFont:getWidth(title)
        local titleHeight = scoreFont:getHeight()

        local subtitleWidth = 0
        local subtitleHeight = 0

        if subtitle then
            love.graphics.setFont(largeFont)
            subtitleWidth = largeFont:getWidth(subtitle)
            subtitleHeight = largeFont:getHeight()
        end

        -- Use the widest text to determine the box width.
        local boxWidth = math.max(titleWidth, subtitleWidth) + padding * 2

        -- Calculate the total box height.
        local boxHeight = titleHeight + subtitleHeight + padding * 3

        -- Draw the white background rectangle.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle(
            'fill',
            boxX,
            boxY,
            boxWidth,
            boxHeight
        )

        -- Draw the title centered horizontally.
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(scoreFont)

        love.graphics.printf(
            title,
            boxX + padding,
            boxY + padding,
            boxWidth - padding * 2,
            'center'
        )

        -- Draw the subtitle centered underneath the title.
        if subtitle then
            love.graphics.setFont(largeFont)

            love.graphics.printf(
                subtitle,
                boxX + padding,
                boxY + padding * 2 + titleHeight,
                boxWidth - padding * 2,
                'center'
            )
        end
    end


    -- Display the appropriate message depending on the game state.
    if gameState == 'start' then

        drawMessageBox('Start?', 'Press Enter')

    elseif gameState == 'game over' then

        drawMessageBox('Game Over!', 'Press Enter')

    elseif gameState == 'pause' then

        drawMessageBox('PAUSE!', nil)

    end

end


function resetGame()
    -- Remove all enemy cars from the previous race.
    cars = {}

    -- Reset the score and all timers.
    Highscore = 0
    spawntimer = 0
    Difficultytimer = 0
    timer = 0

    -- Reset the spawn interval to its initial value.
    S = 1.0

    -- Place the player's car back in the middle lane.
    racer.position = 2

    -- Reset the collision flag.
    collision = false
end


function addHighscore(score)
    -- Add the new score to the high score table.
    table.insert(highscores, score)

    -- Sort scores from highest to lowest.
    table.sort(highscores, function(a, b)
        return a > b
    end)

    -- Remove the lowest scores if there are more than 10 entries.
    while #highscores > MAX_HIGHSCORES do
        table.remove(highscores)
    end

    -- Save the updated list to the file.
    saveHighscores()
end


function saveHighscores()
    -- Create a table containing the scores as strings.
    local data = {}

    for i, score in ipairs(highscores) do
        table.insert(data, tostring(score))
    end

    -- Write all scores to a text file.
    -- Each score is stored on a separate line.
    love.filesystem.write(
        'highscores.txt',
        table.concat(data, '\n')
    )
end


function loadHighscores()
    -- Check whether a high score file already exists.
    if love.filesystem.getInfo('highscores.txt') then

        -- Read the file line by line.
        for line in love.filesystem.lines('highscores.txt') do
            local score = tonumber(line)

            -- Only add valid numerical scores.
            if score then
                table.insert(highscores, score)
            end
        end
    end

    -- Sort loaded scores from highest to lowest.
    table.sort(highscores, function(a, b)
        return a > b
    end)
end