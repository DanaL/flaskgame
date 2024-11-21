local gameState = {
  moves = 0,
  bottles = {},
  selectedBottle = nil,
  assets = {
    bottleImage = nil,
    bottleScale = {}
  },
  popup = {
    active = false,
    text = "",
    colors = {},
    particles = {},
    startTime = 0,
    duration = 4,  -- How long to show popup
    particleSystem = nil
  }
}

-- Add at the start of your file, before love.load()
local COLORS = {
  EMPTY = 0,
  RED = 1,
  GREEN = 2,
  BLUE = 3,
  PURPLE = 4,
  ORANGE = 5
}

function love.load()
  love.window.setTitle("Untitled Liquid Puzzle Game")
  gameState.fonts = {
    regular = love.graphics.newFont("assets/fonts/slkscr.ttf", 18),
    popup = love.graphics.newFont("assets/fonts/slkscr.ttf", 48), 
    popupSmall = love.graphics.newFont("assets/fonts/slkscr.ttf", 36) 
  }
  love.graphics.setFont(gameState.fonts.regular)

  love.graphics.setBackgroundColor(0.67, 0.85, 0.9, 0.5)

  -- Initialize game state
  bottleWidth = 100
  bottleHeight = 300

  gameState.assets.bottleImage = love.graphics.newImage("assets/sprites/bottle.png")
  gameState.assets.bottleImage:setFilter("nearest", "nearest")
  gameState.assets.bottleScale = {
    x = bottleWidth / gameState.assets.bottleImage:getWidth(),
    y = bottleHeight / gameState.assets.bottleImage:getHeight()
  }

  gameState.assets.bottleMask = love.graphics.newImage("assets/sprites/bottle_mask.png")
  gameState.assets.bottleMask:setFilter("nearest", "nearest")
  
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

  gameState.assets.bottleMaskData = love.image.newImageData("assets/sprites/bottle_mask.png")

  -- Create some test bottles with different colored liquids
  configBottles(1)
  
  liquidHeight = bottleHeight / 4 -- Each liquid segment height

  -- Add button dimensions
  resetButton = {
    x = 50,
    y = 50,
    width = 100,
    height = 40
  }

  bottleClink = love.audio.newSource("assets/sounds/clink.mp3", "static")
  bottleClink:setVolume(0.75)
  plopSound = love.audio.newSource("assets/sounds/plop.mp3", "static")
  victorySound = love.audio.newSource("assets/sounds/victory.mp3", "static")

  -- Store initial bottle state
  initialBottles = {}
  for i, bottle in ipairs(gameState.bottles) do
    initialBottles[i] = {}
    for j, color in ipairs(bottle) do
      initialBottles[i][j] = color
    end
  end

  -- Initialize particle system for the win effect
  local particleImg = love.graphics.newImage("assets/sprites/particle.png")  -- Create a small white circle image
  gameState.popup.particleSystem = love.graphics.newParticleSystem(particleImg, 1000)
  gameState.popup.particleSystem:setParticleLifetime(0.5, 2)
  gameState.popup.particleSystem:setLinearAcceleration(-100, -100, 100, 100)
  gameState.popup.particleSystem:setColors(
    1, 0, 0, 1,    -- Red
    0, 1, 0, 1,    -- Green
    1, 1, 0, 1,    -- Yellow
    1, 0, 1, 1     -- Purple
  )
  gameState.popup.particleSystem:setSizes(2, 1, 0)  -- Particles shrink over time
end

function configBottles(level)
  local colours = pickColours(level)

  if level >= 1 and level <= 5 then
    gameState.totalSegments = 3
  elseif level >= 6 and level <= 10 then
    gameState.totalSegments = 4
  else
    gameState.totalSegments = 5
  end

  local colour1 = colours[1]
  local colour2 = colours[2]
  local colour3 = colours[3]

  local bottles = {}  
  for j, color in ipairs(colours) do
    local bottle = {}
    for k = 1, gameState.totalSegments do
      table.insert(bottle, colours[j])
    end
    table.insert(bottles, bottle)
  end
  table.insert(bottles, {})
  
  bottles = shuffleBottles(bottles)
  
  gameState.bottles = {}
  for i, bottle in ipairs(bottles) do
    gameState.bottles[i] = bottle
    print("Total segments:", #bottle  , gameState.totalSegments)
    for j = #bottle + 1, gameState.totalSegments do
      table.insert(gameState.bottles[i], COLORS.EMPTY)
    end
  end

  for i, bottle in ipairs(gameState.bottles) do
    print(table.concat(bottle, ", "))
  end
  -- gameState.bottles = {}
  -- for j, color in ipairs(colours) do
  --   local bottle = {}
  --   for k = 1, gameState.totalSegments do
  --     table.insert(bottle, colours[j])
  --   end
  --   table.insert(gameState.bottles, bottle)
  -- end
  -- local emptyBottle = {}
  -- for k = 1, gameState.totalSegments do
  --   table.insert(emptyBottle, COLORS.EMPTY)
  -- end
  -- table.insert(gameState.bottles, emptyBottle)

  -- gameState.bottles[1] = { colour1, colour2, colour1 }
  -- gameState.bottles[2] = { colour2, colour2, colour3 }
  -- gameState.bottles[3] = { colour3, colour3, colour1 }
  -- gameState.bottles[4] = { COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY }

  -- gameState.bottles[1] = {colour1, colour2, colour3, COLORS.EMPTY}
  -- gameState.bottles[2] = {colour1, colour2, colour3, colour2}
  -- gameState.bottles[3] = {colour3, colour1, COLORS.EMPTY, COLORS.EMPTY}
  -- gameState.bottles[4] = {colour2, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
  -- gameState.bottles[5] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}
  -- gameState.bottles[6] = {COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY, COLORS.EMPTY}  
end

function shuffleBottles(bottles)  
  for _ = 1, 500 do
    -- find all bottles with space
    local hasSpace = {}
    for i, bottle in ipairs(bottles) do
      if #bottle < gameState.totalSegments then
        table.insert(hasSpace, i)
      end
    end

    -- find all bottles with liquid
    local hasLiquid = {}
    for i, bottle in ipairs(bottles) do
      if #bottle > 0 then
        table.insert(hasLiquid, i)
      end
    end
    
    local source = hasLiquid[love.math.random(1, #hasLiquid)]
    
    -- does Lua not have a way to remove an element by value??
    local destOptions = {}
    for i = 1, #hasSpace do
      if hasSpace[i] ~= sourceIndex then
        table.insert(destOptions, hasSpace[i])
      end
    end

    local dest = destOptions[love.math.random(1, #destOptions)]
    
    local colour = table.remove(bottles[source])
    table.insert(bottles[dest], colour)
  end

  validConfig(bottles)
    
  return bottles
end

function validConfig(bottles)
  -- I /think/ so long as you have a move that changes the top colours,
  -- it's probably valid?
  local moves = possibleMoves(bottles)

  print("Valid moves:")
  for _, move in ipairs(moves) do
    print("From bottle " .. move[1] .. " to bottle " .. move[2])
  end
end

function possibleMoves(bottles)
  local possibleMoves = {}  -- Initialize the table
  for i, bottle in ipairs(bottles) do
    local moves = possibleMovesForBottle(bottles, i)    
    for _, move in ipairs(moves) do
      table.insert(possibleMoves, move)
    end
  end  

  return possibleMoves
end

function possibleMovesForBottle(bottles, sourceIdx)
  local moves = {}
  if bottles[sourceIdx] == 0 then
    return moves
  end

  local sourceColour = bottles[sourceIdx][#bottles[sourceIdx]]

  for i, bottle in ipairs(bottles) do
    if i ~= sourceIdx then
      if #bottles[i] == 0 then
        table.insert(moves, {sourceIdx, i})      
      elseif bottles[i][#bottles[i]] == sourceColour and #bottles[i] < gameState.totalSegments then
        table.insert(moves, {sourceIdx, i})
      end
    end
  end
  
  return moves
end

function copyBottles(bottles)
  local copy = {}
  for i, bottle in ipairs(bottles) do
    copy[i] = {}
    for j, colour in ipairs(bottle) do
      copy[i][j] = colour
    end
  end
  
  return copy
end

function pickColours(level)
  -- Determine number of colors based on level
  local numColours
  if level <= 5 then
    numColours = 3
  elseif level <= 10 then
    numColours = 4
  else
    numColours = 5
  end

  -- Create array of available colors (excluding EMPTY)
  local availableColours = {
    COLORS.RED,
    COLORS.GREEN, 
    COLORS.BLUE,
    COLORS.PURPLE,
    COLORS.ORANGE
  }

  -- Randomly select colors for this level
  local levelColours = {}
  for i = 1, numColours do
    -- Pick random index from remaining colours
    local randIndex = love.math.random(1, #availableColours)
    -- Add the color to our level colours
    table.insert(levelColours, availableColours[randIndex])
    -- Remove it from available colors
    table.remove(availableColours, randIndex)
  end

  return levelColours
end

function fillBottleSegment(segment, colour, x, y)
  -- Create a quad for the bottom third of the mask
  local maskWidth = gameState.assets.bottleMask:getWidth()
  local maskHeight = gameState.assets.bottleMask:getHeight()
  local segmentHeight = maskHeight / gameState.totalSegments
  local segmentY = (gameState.totalSegments - segment) * segmentHeight
  local segmentQuad =
    love.graphics.newQuad(
    0, -- x position in source image
    segmentY, -- y position in source image
    maskWidth, -- width to capture
    segmentHeight, -- height to capture
    maskWidth, -- total width of source image
    maskHeight -- total height of source image
  )

  local r, g, b = colourToRGB(colour)
  love.graphics.setColor(r, g, b, 0.5)    
 
  love.graphics.draw(
    gameState.assets.liquidMask,
    segmentQuad,
    x,
    y + (bottleHeight * (gameState.totalSegments - segment) / gameState.totalSegments),
    0,
    gameState.assets.bottleScale.x,
    gameState.assets.bottleScale.y
  )
end

function drawBottle(bottle, x, y, bottleNum)
  if gameState.selectedBottle == bottleNum then
    x = x + 10
    y = y - 10    
  end

  for j, color in ipairs(bottle) do
    if color ~= COLORS.EMPTY then
      fillBottleSegment(j, color, x, y)
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

function colourToRGB(colour)
  if colour == COLORS.RED then
    return 1, 0, 0
  elseif colour == COLORS.GREEN then
    return 0, 1, 0
  elseif colour == COLORS.BLUE then
    return 0, 0, 1
  elseif colour == COLORS.PURPLE then
    return 1, 0, 1
  elseif colour == COLORS.ORANGE then
    return 1, 0.5, 0
  end
end

function love.draw()
  -- Make sure we reset to white color at the start of draw
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(gameState.fonts.regular)

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
    drawBottle(bottle, x, y, i)
  end

  -- Draw popup if active
  if gameState.popup.active then
    -- Draw semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw particles
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
      gameState.popup.particleSystem, 
      love.graphics.getWidth() / 2, 
      love.graphics.getHeight() / 2
    )
    
    love.graphics.setFont(gameState.fonts.popup)
    
    -- Draw text with rainbow effect
    local text = gameState.popup.text
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    local x = love.graphics.getWidth() / 2 - textWidth / 2
    local y = love.graphics.getHeight() / 4 - textHeight / 2
    
    -- Rainbow wave effect
    for i = 1, #text do
      local char = text:sub(i,i)
      local offset = math.sin(love.timer.getTime() * 3 + i * 0.3) * 10
      local hue = (love.timer.getTime() * 0.5 + i * 0.1) % 1
      local r, g, b = HSV(hue, 1, 1)
      
      love.graphics.setColor(r, g, b, 1)
      love.graphics.print(
        char, 
        x + font:getWidth(text:sub(1, i-1)), 
        y + offset
      )
    end
    
    -- Draw moves count
    love.graphics.setFont(gameState.fonts.popupSmall)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
      "Completed in " .. gameState.moves .. " moves!", 
      x, 
      y + textHeight + 20
    )
  end
end

function wasResetClicked(x, y)
  return
    x >= resetButton.x and x <= resetButton.x + resetButton.width 
    and y >= resetButton.y and y <= resetButton.y + resetButton.height
end

function love.mousepressed(x, y, button)
  if gameState.popup.active then
    gameState.popup.active = false
    victorySound:stop()
    return
  end

  -- Check if reset button was clicked
  if wasResetClicked(x, y) then
    -- Reset game state
    gameState.bottles = {}
    gameState.moves = 0
    for i, bottle in ipairs(initialBottles) do
      gameState.bottles[i] = {}
      for j, color in ipairs(bottle) do
        gameState.bottles[i][j] = color
      end
    end
    gameState.selectedBottle = nil
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
          if gameState.selectedBottle == nil then
            -- Only select if bottle isn't empty
            if not isBottleEmpty(bottle) then
              gameState.selectedBottle = i
              local clink = bottleClink:clone()
              clink:play()
            end
          else
            -- Try to pour from selected bottle to clicked bottle
            if gameState.selectedBottle ~= i then -- Can't pour into same bottle
              pourLiquid(gameState.selectedBottle, i)
            end
            gameState.selectedBottle = nil
          end
          break
        end
      end
    end
  end

  -- If we clicked outside any bottle, clear the selection
  if not bottleClicked then
    gameState.selectedBottle = nil
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
  local topColour, colourCount = getTopColour(fromBottle)
  local emptySpaces = getEmptySpaces(toBottle)

  local canPour = emptySpaces > 0
  
  if canPour then
    gameState.moves = gameState.moves + 1
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

    local plop = plopSound:clone()
    plop:play()

    checkWin()
  end
end

function checkWin()
  -- First, count how many segments of each color exist
  local colorCounts = {}
  for _, bottle in ipairs(gameState.bottles) do
    for _, color in ipairs(bottle) do
      if color ~= COLORS.EMPTY then
        colorCounts[color] = (colorCounts[color] or 0) + 1
      end
    end
  end

  -- Then check each bottle to ensure it either:
  -- 1. Is completely empty, or
  -- 2. Contains all segments of one color
  for _, bottle in ipairs(gameState.bottles) do
    if not isBottleEmpty(bottle) then
      local bottleColor = nil
      local segmentCount = 0
      
      for _, color in ipairs(bottle) do
        if color ~= COLORS.EMPTY then
          if bottleColor == nil then
            bottleColor = color
          elseif color ~= bottleColor then
            return false
          end
          segmentCount = segmentCount + 1
        end
      end
      
      -- Check if this bottle has ALL segments of this color
      if segmentCount ~= colorCounts[bottleColor] then
        return false
      end
    end
  end
  
  -- If we get here, player has won
  showWinPopup()
  return true
end

function showWinPopup()
  gameState.popup.active = true
  gameState.popup.text = "Level Complete!"
  gameState.popup.startTime = love.timer.getTime()
  
  -- Reset and emit particles
  gameState.popup.particleSystem:reset()
  gameState.popup.particleSystem:emit(200)
  
  victorySound:play()
end

function love.update(dt)
  -- Update popup
  if gameState.popup.active then
    gameState.popup.particleSystem:update(dt)
    
    -- Check if popup should end
    if love.timer.getTime() - gameState.popup.startTime > gameState.popup.duration then
      gameState.popup.active = false
    end
  end
end

-- Helper function to convert HSV to RGB
function HSV(h, s, v)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end
  return r, g, b
end
