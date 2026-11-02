function love.conf(t)
    -- set window title
    t.window.title = 'Simon - the game'
    
    -- to display live console output in sublime text 2
    io.stdout:setvbuf("no")

    -- windows debugging
    t.console = true
end
