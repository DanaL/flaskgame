local gameState = {
  bottles = {},
  selectedBottle = nil,
  assets = {
    bottleImage = nil,
    bottleScale = {}
  }
}

-- Add at the start of your file, before love.load()
local COLORS = {
  EMPTY = 0,
  RED = 1,
  GREEN = 2,
  BLUE = 3
}

function love.load()
  love.graphics.setBackgroundColor(0.67, 0.85, 0.9, 0.5)

  -- Initialize game state
  bottleWidth = 100
  bottleHeight = 300

  gameState.assets.bottleImage = love.graphics.newImage("assets/sprites/bottle.png")
  gameState.assets.bottleImage:setFilter("nearest", "nearest")

  --local foo = gameState.assets.bottleImage:getData()
  -- Create the mask for the bottle sprite
  gameState.assets.bottleMask = love.graphics.newImage("assets/sprites/bottle_mask.png")
  gameState.assets.bottleMask:setFilter("nearest", "nearest")
  gameState.assets.bottleScale = {
    x = bottleWidth / gameState.assets.bottleImage:getWidth(),
    y = bottleHeight / gameState.assets.bottleImage:getHeight()
  }
  --gameState.assets.bottleMaskData = gameState.assets.bottleMask:getData()

  gameState.assets.liquidMask = love.graphics.newCanvas(bottleWidth, bottleHeight)
  love.graphics.setCanvas(gameState.assets.liquidMask)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(
    gameState.assets.bottleMask,
    0,
    0,
    0,
    gameState.assets.bottleScale.x,
    gameState.assets.bottleScale.y
  )
  love.graphics.setCanvas()

  -- Create a quad for the bottom third of the mask
  local maskWidth = gameState.assets.bottleMask:getWidth()
  local maskHeight = gameState.assets.bottleMask:getHeight()
  local bottomQuarterHeight = maskHeight / 4
  gameState.assets.bottomQuarterQuad =
    love.graphics.newQuad(
    0, -- x position in source image
    maskHeight - bottomQuarterHeight, -- y position in source image
    maskWidth, -- width to capture
    bottomQuarterHeight, -- height to capture
    maskWidth, -- total width of source image
    maskHeight -- total height of source image
  )
  gameState.assets.bottleMaskData = love.image.newImageData("assets/sprites/bottle_mask.png")

  -- Create some test bottles with different colored liquids

  gameState.bottles[1] = {COLORS.RED, COLORS.GREEN, COLORS.BLUE, COLORS.EMPTY}
  gameState.bottles[2] = {COLORS.RED, COLORS.GREEN, COLORS.BLUE, COLORS.GREEN}
  gameState.bottles[3] = {COLORS.BLUE, COLORS.RED, COLORS.EMPTY, COLORS.EMPTY}
  gameState.bottles[4] = {COLORS.GREEN, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
  gameState.bottles[5] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
  gameState.bottles[6] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}

  -- Game variables
  selectedBottle = nil

  liquidHeight = bottleHeight / 4 -- Each liquid segment height

  -- Add button dimensions
  resetButton = {
    x = 50,
    y = 50,
    width = 100,
    height = 40
  }

  -- Store initial bottle state
  initialBottles = {}
  for i, bottle in ipairs(gameState.bottles) do
    initialBottles[i] = {}
    for j, color in ipairs(bottle) do
      initialBottles[i][j] = color
    end
  end
end

function fillBottleSegment(segment, totalSegments, colour, x, y)
  -- Create a quad for the bottom third of the mask
  local maskWidth = gameState.assets.bottleMask:getWidth()
  local maskHeight = gameState.assets.bottleMask:getHeight()
  local segmentHeight = maskHeight / totalSegments
  local segmentY = (totalSegments - segment) * segmentHeight
  local segmentQuad =
    love.graphics.newQuad(
    0, -- x position in source image
    segmentY, -- y position in source image
    maskWidth, -- width to capture
    segmentHeight, -- height to capture
    maskWidth, -- total width of source image
    maskHeight -- total height of source image
  )

  if (colour == COLORS.RED) then
    love.graphics.setColor(1, 0, 0, 0.5) -- Semi-transparent red
  elseif (colour == COLORS.GREEN) then
    love.graphics.setColor(0, 1, 0, 0.5) -- Semi-transparent green
  elseif (colour == COLORS.BLUE) then
    love.graphics.setColor(0, 0, 1, 0.5) -- Semi-transparent blue
  end

  love.graphics.draw(
    gameState.assets.liquidMask,
    segmentQuad,
    x,
    y + (bottleHeight * (totalSegments - segment) / totalSegments),
    0,
    gameState.assets.bottleScale.x,
    gameState.assets.bottleScale.y
  )
end

function drawBottle(bottle, x, y)
  for j, color in ipairs(bottle) do
    if color ~= COLORS.EMPTY then
      fillBottleSegment(j, 4, color, x, y)
    end
  end

  -- Draw bottle sprite
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(
    gameState.assets.bottleImage,
    x,
    y,
    0,
    gameState.assets.bottleScale.x,
    gameState.assets.bottleScale.y
  )
end

function love.draw()
  -- Make sure we reset to white color at the start of draw
  love.graphics.setColor(1, 1, 1)

  -- Draw reset button with more contrast
  love.graphics.setColor(0.5, 0.5, 0.5) -- Darker gray for button
  love.graphics.rectangle("fill", resetButton.x, resetButton.y, resetButton.width, resetButton.height)
  love.graphics.setColor(1, 1, 1) -- Black for outline
  love.graphics.rectangle("line", resetButton.x, resetButton.y, resetButton.width, resetButton.height)
  love.graphics.setColor(1, 1, 1) -- White for text
  love.graphics.printf("Reset", resetButton.x, resetButton.y + 12, resetButton.width, "center")

  -- Make sure we reset to white before drawing bottles
  love.graphics.setColor(1, 1, 1)

  for i, bottle in ipairs(gameState.bottles) do
    local x = 25 + (i - 1) * 125
    local y = 225
    drawBottle(bottle, x, y)
  end
end

function love.mousepressed(x, y, button)
  -- Check if reset button was clicked
  if
    x >= resetButton.x and x <= resetButton.x + resetButton.width and y >= resetButton.y and
      y <= resetButton.y + resetButton.height
   then
    -- Reset game state
    gameState.bottles = {}
    for i, bottle in ipairs(initialBottles) do
      gameState.bottles[i] = {}
      for j, color in ipairs(bottle) do
        gameState.bottles[i][j] = color
      end
    end
    selectedBottle = nil
    return
  end

  local bottleClicked = false
  -- Check if a bottle was clicked
  for i, bottle in ipairs(gameState.bottles) do
    local bx = 25 + (i - 1) * 125
    local by = 225

    if x >= bx and x <= bx + bottleWidth and y >= by and y <= by + bottleHeight then
      local localX = math.floor((x - bx) / gameState.assets.bottleScale.x)
      local localY = math.floor((y - by) / gameState.assets.bottleScale.y)

      if
        localX >= 0 and localX < gameState.assets.bottleMaskData:getWidth() and localY >= 0 and
          localY < gameState.assets.bottleMaskData:getHeight()
       then
        local r, g, b, a = gameState.assets.bottleMaskData:getPixel(localX, localY)
        if a > 0.5 then
          bottleClicked = true
          if selectedBottle == nil then
            -- Only select if bottle isn't empty
            if not isBottleEmpty(bottle) then
              selectedBottle = i
            end
          else
            -- Try to pour from selected bottle to clicked bottle
            if selectedBottle ~= i then -- Can't pour into same bottle
              pourLiquid(selectedBottle, i)
            end
            selectedBottle = nil
          end
          break
        end
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
  local fromBottle = gameState.bottles[fromIdx]
  local toBottle = gameState.bottles[toIdx]

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
