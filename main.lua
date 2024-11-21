local gameState = {
  level = 1,
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
  },
  bubbles = {},
  currentScreen = "splash",
  splashTimer = 0,
  splashDuration = 5
}

local clickedButton = ""
local winningMovesCount = 0
local isMusicPlaying = true

-- Add at the start of your file, before love.load()
local COLORS = {
  EMPTY = 0,
  RED = 1,
  GREEN = 2,
  BLUE = 3,
  PURPLE = 4,
  ORANGE = 5
}

-- Add this near the top with other game state variables
local backgroundTheme = {
  top = {r = 0, g = 0, b = 0},
  bottom = {r = 0, g = 0, b = 0}
}

function love.load()
  love.window.setTitle("Pour Decisions 1.0.0")
  gameState.splashImage = love.graphics.newImage("assets/images/splashscreen.png")

  backgroundMusic = love.audio.newSource("assets/music/soundtrack01.mp3", "stream")
  backgroundMusic:setLooping(true) 
  backgroundMusic:setVolume(0.2)
  backgroundMusic:play()    

  gameState.fonts = {
    regular = love.graphics.newFont("assets/fonts/slkscr.ttf", 18),
    popup = love.graphics.newFont("assets/fonts/slkscr.ttf", 48), 
    popupSmall = love.graphics.newFont("assets/fonts/slkscr.ttf", 36) 
  }
  love.graphics.setFont(gameState.fonts.regular)

  -- Initialize game state
  BottleWidth = 100
  BottleHeight = 300

  gameState.assets.bottleImage = love.graphics.newImage("assets/sprites/bottle.png")
  gameState.assets.bottleImage:setFilter("nearest", "nearest")
  gameState.assets.bottleScale = {
    x = BottleWidth / gameState.assets.bottleImage:getWidth(),
    y = BottleHeight / gameState.assets.bottleImage:getHeight()
  }

  gameState.assets.bottleMask = love.graphics.newImage("assets/sprites/bottle_mask.png")
  gameState.assets.bottleMask:setFilter("nearest", "nearest")
  
  gameState.assets.liquidMask = love.graphics.newCanvas(BottleWidth, BottleHeight)
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

  SetNewBottleConfig(gameState.level)
  
  liquidHeight = BottleHeight / 4 -- Each liquid segment height

  NewGameButton = { x = 50, y = 50, width = 150, height = 40 }
  ResetButton = { x = 225, y = 50, width = 100, height = 40 }
  MusicButton = { x = 600, y = 50, width = 150, height = 40 }

  bottleClink = love.audio.newSource("assets/sounds/clink.mp3", "static")
  bottleClink:setVolume(0.75)
  plopSound = love.audio.newSource("assets/sounds/plop.mp3", "static")
  victorySound = love.audio.newSource("assets/sounds/victory.mp3", "static")

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

  local themes = {
    {  -- Blue gradient
      top = {r = 0.9, g = 0.95, b = 1},    -- Very light blue
      bottom = {r = 1, g = 0.92, b = 0.99} -- Slightly darker soft blue
    },
    {  -- Peach gradient
      top = {r = 0.98, g = 0.95, b = 0.9},    -- Very light peach
      bottom = {r = 0.95, g = 0.9, b = 0.92}   -- Soft pink-beige
    },
    {  -- Green gradient
      top = {r = 0.9, g = 0.98, b = 0.95},    -- Very light mint
      bottom = {r = 0.75, g = 0.95, b = 0.9}   -- Soft green-white
    }
  }
  
  -- Select random theme
  local selectedTheme = themes[love.math.random(1, #themes)]
  backgroundTheme.top = selectedTheme.top
  backgroundTheme.bottom = selectedTheme.bottom
end

function SetNewBottleConfig(level)
  local colours = pickColours(level)

  if level >= 1 and level <= 5 then
    gameState.totalSegments = 3
  elseif level >= 6 and level <= 10 then
    gameState.totalSegments = 4
  else
    gameState.totalSegments = 5
  end

  local bottles = {}
  for j = 1, #colours do
    local bottle = {}
    for k = 1, gameState.totalSegments do
      table.insert(bottle, colours[j])
    end
    table.insert(bottles, bottle)
  end
  table.insert(bottles, {})

  bottles = ShuffleBottles(bottles)

  gameState.bottles = {}
  for i, bottle in ipairs(bottles) do
    gameState.bottles[i] = bottle
    for j = #bottle + 1, gameState.totalSegments do
      table.insert(gameState.bottles[i], COLORS.EMPTY)
    end
  end

  -- Store initial bottle state
  initialBottles = {}
  for i, bottle in ipairs(gameState.bottles) do
    initialBottles[i] = {}
    for j, color in ipairs(bottle) do
      initialBottles[i][j] = color
    end
  end

  SetupBubbleArray()
end

function ShuffleBottles(bottles)
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

  return bottles
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
    y + (BottleHeight * (gameState.totalSegments - segment) / gameState.totalSegments),
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
    return 0, 0.6, 1
  elseif colour == COLORS.PURPLE then
    return 1, 0, 1
  elseif colour == COLORS.ORANGE then
    return 1, 0.5, 0
  end
end

function DrawButton(button, text)
  if love.mouse.isDown(1) and text == clickedButton then
    love.graphics.setColor(0.18, 0.31, 0.31)
  else
    love.graphics.setColor(0.5, 0.5, 0.5)
  end
  love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(text, button.x, button.y + 12, button.width, "center")
end

function DrawLevelLabel()
  love.graphics.setColor(0, 0, 0)
  local text = "Level: " .. gameState.level
  love.graphics.setFont(gameState.fonts.popup)
  love.graphics.printf(text, 50, 115, 400, "left")
  love.graphics.setFont(gameState.fonts.regular)
end

function XOffset()
  return (love.graphics.getWidth() - 125 * #gameState.bottles) / 2
end

function love.draw()
  love.graphics.clear()
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()

  -- Use the selected theme colors
  love.graphics.setColor(backgroundTheme.top.r, backgroundTheme.top.g, backgroundTheme.top.b, 1)
  love.graphics.rectangle("fill", 0, 0, width, height/2)
  
  love.graphics.setColor(backgroundTheme.bottom.r, backgroundTheme.bottom.g, backgroundTheme.bottom.b, 1)
  love.graphics.rectangle("fill", 0, height/2, width, height/2)
  
  -- Smooth blend between the two colors
  for i = 1, 20 do
    local alpha = i / 20
    local y = (height/2) - (100 * (1-alpha))
    love.graphics.setColor(
      backgroundTheme.bottom.r,
      backgroundTheme.bottom.g,
      backgroundTheme.bottom.b,
      alpha
    )
    love.graphics.rectangle("fill", 0, y, width, 10)
  end
  
  love.graphics.setColor(1, 1, 1, 1)

  if gameState.currentScreen == "splash" then
    love.graphics.draw(gameState.splashImage, 0, 0)
    return
  end

  -- Make sure we reset to white color at the start of draw
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(gameState.fonts.regular)

  DrawButton(ResetButton, "Reset")
  DrawButton(NewGameButton, "New Game")
  DrawButton(MusicButton, isMusicPlaying and "Music: On" or "Music: Off")
  DrawLevelLabel()

  -- Make sure we reset to white before drawing bottles
  love.graphics.setColor(1, 1, 1)

  for i, bottle in ipairs(gameState.bottles) do
    local x = XOffset() + (i - 1) * 125
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
      "Completed in " .. winningMovesCount .. " moves!", 
      x, 
      y + textHeight + 20
    )
  end

  -- Draw bubbles
  for i, bubble in ipairs(gameState.bubbles) do
    if bubble.particle ~= nil then
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(bubble.particle, bubble.x, 500)
    end
  end
end

function WasButtonClicked(button, x, y)
  return
    x >= button.x and x <= button.x + button.width 
    and y >= button.y and y <= button.y + button.height
end

function ResetLevel()
  gameState.bottles = {}
  gameState.moves = 0
  for i, bottle in ipairs(initialBottles) do
    gameState.bottles[i] = {}
    for j, color in ipairs(bottle) do
      gameState.bottles[i][j] = color
    end
  end
  gameState.selectedBottle = nil

  SetupBubbleArray()
end

function SetupBubbleArray()
  gameState.bubbles = {}
  for i = 1, #gameState.bottles do
    local bubble = {
      x = -1,
      topY = -1,
      nextBubble = love.timer.getTime() + love.math.random(5, 10),
      active = false,
      particle = nil
    }
    table.insert(gameState.bubbles, bubble)
  end
end

function love.mousepressed(x, y, button)
  if gameState.currentScreen == "splash" then
    gameState.currentScreen = "game"
    return
  end

  if gameState.popup.active then
    gameState.popup.active = false
    victorySound:stop()
    return
  end

  clickedButton = ""
  if WasButtonClicked(ResetButton, x, y) then
    ResetLevel()
    clickedButton = "Reset"
    return
  elseif WasButtonClicked(NewGameButton, x, y) then
    SetNewBottleConfig(1)
    gameState.level = 1
    gameState.moves = 0
    ResetLevel()
    clickedButton = "New Game"
    return
  elseif WasButtonClicked(MusicButton, x, y) then
    isMusicPlaying = not isMusicPlaying
    if isMusicPlaying then
      backgroundMusic:play()
    else
      backgroundMusic:pause()
    end
    clickedButton = "Music"
    return
  end

  local bottleClicked = false
  -- Check if a bottle was clicked
  for i, bottle in ipairs(gameState.bottles) do
    local bx = XOffset() + (i - 1) * 125
    local by = 225

    if x >= bx and x <= bx + BottleWidth and y >= by and y <= by + BottleHeight then
      local localX = math.floor((x - bx) / gameState.assets.bottleScale.x)
      local localY = math.floor((y - by) / gameState.assets.bottleScale.y)

      if
        localX >= 0 and localX < gameState.assets.bottleMaskData:getWidth() and localY >= 0 and
          localY < gameState.assets.bottleMaskData:getHeight()
       then
        local r, g, b, a = gameState.assets.bottleMaskData:getPixel(localX, localY)
        if a > 0.5 then
          bottleClicked = true

          CancelBubble(i)
          
          if gameState.selectedBottle == nil then
            -- Only select if bottle isn't empty
            if not IsBottleEmpty(bottle) then
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

function CancelBubble(bottleNum)
  local bubble = gameState.bubbles[bottleNum]
  if bubble.particle ~= nil then
    bubble.particle = nil
    bubble.active = false
    bubble.nextBubble = love.timer.getTime() + math.random(5, 10)
  end
end

function IsBottleEmpty(bottle)
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
    if not IsBottleEmpty(bottle) then
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
  ShowWinPopup()
  gameState.level = gameState.level + 1
  winningMovesCount = gameState.moves
  SetNewBottleConfig(gameState.level)
  gameState.moves = 0
  return true
end

function ShowWinPopup()
  gameState.popup.active = true
  gameState.popup.text = "Level Complete!"
  gameState.popup.startTime = love.timer.getTime()

  -- Reset and emit particles
  gameState.popup.particleSystem:reset()
  gameState.popup.particleSystem:emit(200)

  victorySound:play()
end

function love.update(dt)
  if gameState.currentScreen == "splash" then
    gameState.splashTimer = gameState.splashTimer + dt
    if gameState.splashTimer >= gameState.splashDuration then
      gameState.currentScreen = "game"

      if isMusicPlaying then
        backgroundMusic:play()
      end
    end
    return
  end

  -- Update popup
  if gameState.popup.active then
    gameState.popup.particleSystem:update(dt)
  
    -- Check if popup should end
    if love.timer.getTime() - gameState.popup.startTime > gameState.popup.duration then
      gameState.popup.active = false
    end
  end

  -- Do we want to create any bubbles?
  for i, bubble in ipairs(gameState.bubbles) do
    local time = love.timer.getTime()
    local bottle = gameState.bottles[i]
    if bubble.active then
      bubble.particle:update(dt)
    elseif not IsBottleEmpty(bottle) and time > bubble.nextBubble then
      CreateNewBubbleParticle(bubble, i)
      bubble.active = true
    end
  end
end

function CreateNewBubbleParticle(bubble, bottleNum)
  local offsetX = love.math.random(-15, 15)
  bubble.x =  XOffset() + (bottleNum - 1) * 125 + BottleWidth / 2 + love.math.random(-15, 15)

  local emptyCount = getEmptySpaces(gameState.bottles[bottleNum])

  local fillRatio = (gameState.totalSegments - emptyCount) / gameState.totalSegments
  
  local baseLifetime = 2
  local minLifetime = baseLifetime * fillRatio
  local maxLifetime = minLifetime + 1  -- Add a small random variance

  local liquidTopY = 225 + (BottleHeight * emptyCount / gameState.totalSegments)  -- 225 is the bottle's Y position
  local distance = 500 - liquidTopY

  local xAccel = 0
  if offsetX < -10 then
    xAccel = 25  -- Push right if too far left
  elseif offsetX > 10 then
    xAccel = -25  -- Push left if too far right
  else
    xAccel = love.math.random(-10, 10)  -- Small random drift if near center
  end
  local particleImg = love.graphics.newImage("assets/sprites/particle.png")
  bubble.particle = love.graphics.newParticleSystem(particleImg, 1)
  bubble.particle:setParticleLifetime(minLifetime, maxLifetime)
  bubble.particle:setEmissionRate(1)
  bubble.particle:setSizes(0.7, 0.5)

  bubble.particle:setLinearAcceleration(xAccel, -distance, xAccel, -distance * 1.2) -- Move upward
  bubble.particle:setLinearDamping(0.8)
  --bubble.particle:setRelativePosition(0, liquidTopY - 500)  -- Relative to particle system position
  
  bubble.particle:setColors(
    1, 1, 1, 0.8,  -- Start color (white with 80% opacity)
    1, 1, 1, 0     -- End color (fade to transparent)
  )
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
