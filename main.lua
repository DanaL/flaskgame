-- Add at the start of your file, before love.load()
local COLORS = {
    EMPTY = 0,
    RED = 1,
    GREEN = 2,
    BLUE = 3
}

function love.load()
    -- Initialize game state
    bottles = {}
    
    -- Create some test bottles with different colored liquids
    for i = 1, 4 do
        bottles[i] = {COLORS.RED, COLORS.GREEN, COLORS.BLUE, COLORS.RED}
    end
    
    -- Add an empty bottle for transfers
    bottles[5] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
    bottles[6] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
    
    -- Game variables
    selectedBottle = nil
    bottleWidth = 50
    bottleHeight = 150
    liquidHeight = bottleHeight / 4  -- Each liquid segment height
    
    -- Add button dimensions
    resetButton = {
        x = 50,
        y = 50,
        width = 100,
        height = 40
    }
    
    -- Store initial bottle state
    initialBottles = {}
    for i, bottle in ipairs(bottles) do
        initialBottles[i] = {}
        for j, color in ipairs(bottle) do
            initialBottles[i][j] = color
        end
    end
end

function love.draw()
    -- Make sure we reset to white color at the start of draw
    love.graphics.setColor(1, 1, 1)

    -- Draw reset button with more contrast
    love.graphics.setColor(0.5, 0.5, 0.5)  -- Darker gray for button
    love.graphics.rectangle("fill", resetButton.x, resetButton.y, resetButton.width, resetButton.height)
    love.graphics.setColor(1, 1, 1)        -- Black for outline
    love.graphics.rectangle("line", resetButton.x, resetButton.y, resetButton.width, resetButton.height)
    love.graphics.setColor(1, 1, 1)        -- White for text
    love.graphics.printf("Reset", resetButton.x, resetButton.y + 12, resetButton.width, "center")
    
    -- Make sure we reset to white before drawing bottles
    love.graphics.setColor(1, 1, 1)
    
    -- Draw each bottle
    for i, bottle in ipairs(bottles) do
        -- Highlight selected bottle
        if selectedBottle == i then
            love.graphics.setColor(1, 1, 0, 0.3) -- yellow highlight
            love.graphics.rectangle("fill", 
                100 + (i-1) * 100 -5, 
                300 -5, 
                bottleWidth + 10, 
                bottleHeight + 10)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 
            100 + (i-1) * 100, 
            300, 
            bottleWidth, 
            bottleHeight)
        
        -- Draw liquids
        for j, color in ipairs(bottle) do
            if color > COLORS.EMPTY then
                -- Set different colors based on the number
                if color == COLORS.RED then
                    love.graphics.setColor(1, 0, 0) -- Red
                elseif color == COLORS.GREEN then
                    love.graphics.setColor(0, 1, 0) -- Green
                elseif color == COLORS.BLUE then
                    love.graphics.setColor(0, 0, 1) -- Blue
                end
                
                love.graphics.rectangle("fill",
                    100 + (i-1) * 100,
                    300 + bottleHeight - (j * liquidHeight),
                    bottleWidth,
                    liquidHeight)
            end
        end
    end
end

function love.mousepressed(x, y, button)
    -- Check if reset button was clicked
    if x >= resetButton.x and x <= resetButton.x + resetButton.width and
       y >= resetButton.y and y <= resetButton.y + resetButton.height then
        -- Reset game state
        bottles = {}
        for i, bottle in ipairs(initialBottles) do
            bottles[i] = {}
            for j, color in ipairs(bottle) do
                bottles[i][j] = color
            end
        end
        selectedBottle = nil
        return
    end

    local bottleClicked = false
    -- Check if a bottle was clicked
    for i, bottle in ipairs(bottles) do
        local bx = 100 + (i-1) * 100
        local by = 300
        
        if x >= bx and x <= bx + bottleWidth and
           y >= by and y <= by + bottleHeight then
            bottleClicked = true
            if selectedBottle == nil then
                -- Only select if bottle isn't empty
                if not isBottleEmpty(bottle) then
                    selectedBottle = i
                end
            else
                -- Try to pour from selected bottle to clicked bottle
                if selectedBottle ~= i then  -- Can't pour into same bottle
                    pourLiquid(selectedBottle, i)
                end
                selectedBottle = nil
            end
        end
    end

    -- If we clicked outside any bottle, clear the selection
    if not bottleClicked then
        selectedBottle = nil
    end
end

function isBottleEmpty(bottle)
    for _, colour in ipairs(bottle) do
        if colour ~= COLORS.EMPTY then
            return false
        end
    end
    return true
end

function getTopColour(bottle)
    local topColour = COLORS.EMPTY
    local count = 0

    local topRow = 0
    for i = #bottle, 1, -1 do
        if bottle[i] ~= COLORS.EMPTY then
            topColour = bottle[i]
            topRow = i
            break
        end
    end

    for i = topRow, 1, -1 do
        if bottle[i] == topColour then
            count = count + 1
        else
            break
        end
    end

    if topColour == COLORS.BLUE then
      print("Top colour is blue", count)
    end
    return topColour, count
end

function getEmptySpaces(bottle)
    local count = 0
    for _, colour in ipairs(bottle) do
        if colour == COLORS.EMPTY then
            count = count + 1
        end
    end
    return count
end

function pourLiquid(fromIdx, toIdx)
    local fromBottle = bottles[fromIdx]
    local toBottle = bottles[toIdx]

    -- Debug prints
    print("Attempting to pour from bottle", fromIdx, "to bottle", toIdx)
    print("From bottle contents:", table.concat(fromBottle, ", "))
    print("To bottle contents:", table.concat(toBottle, ", "))

    local topColour, colourCount = getTopColour(fromBottle)
    local emptySpaces = getEmptySpaces(toBottle)

    -- More debug info
    print("Top colour:", topColour, "Count:", colourCount)
    print("Empty spaces in target:", emptySpaces)

    local canPour = emptySpaces > 0
    if canPour then
        local toTopColour, _ = getTopColour(toBottle)
        canPour = toTopColour == COLORS.EMPTY or toTopColour == topColour
    end

    if canPour then
        local amountToPour = math.min(colourCount, emptySpaces)

        for i = #fromBottle, 1, -1 do
            if fromBottle[i] == topColour and amountToPour > 0 then
                fromBottle[i] = COLORS.EMPTY
                amountToPour = amountToPour - 1                
            end
        end

        amountToPour = math.min(colourCount, emptySpaces)
        for i = 1, #toBottle, 1 do
            if toBottle[i] == COLORS.EMPTY and amountToPour > 0 then
                toBottle[i] = topColour
                amountToPour = amountToPour - 1
            end
        end
    end
end