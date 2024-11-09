function love.conf(t)
    t.window.title = "Bottle Sort Puzzle"    -- The title of your window
    t.window.width = 800                     -- Game's default width
    t.window.height = 600                    -- Game's default height
    
    -- Optional but recommended settings
    t.version = "11.4"                       -- The LÖVE version this game was made for
    t.console = true                         -- Enable console output for Windows
    
    -- You can disable unused modules to save memory
    t.modules.joystick = false               -- We don't use joystick in this game
    t.modules.physics = false                -- We don't use physics in this game
end 