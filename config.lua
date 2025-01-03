function love.conf(t)
    t.window.title = "Bottle Sort Puzzle"    
    t.window.width = 800                     
    t.window.height = 600                    
    t.window.resizable = false
    t.window.vsync = 0
    
    -- Optional but recommended settings
    t.version = "11.4"                       -- The LÖVE version this game was made for
    t.console = true                         -- Enable console output for Windows
    
    -- You can disable unused modules to save memory
    t.modules.joystick = false               -- We don't use joystick in this game
    t.modules.physics = false                -- We don't use physics in this game
end 