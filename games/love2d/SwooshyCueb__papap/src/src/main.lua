require('common')
require('grid')
require('piece')
require('board')
require('math')
require('input')
require('menu')
if not pcall(function() bit = require('bit32') end) then
    bit = require('extern/numberlua')
end

debug = true

gb = nil
state = nil

bgimg = nil

bc = 0
flood = 30
currtimer = 30
tt = nil

function love.load(arg)
    math.randomseed(os.time())
    love.graphics.setBlendMode('alpha')
    gen_piece_images()

    love.window.setIcon(piece_images[PIECE_SRC]:newImageData())

    gb = board(8, 12)

    -- For some reason this breaks things.
    -- love.window.setMode(gb.sz.x, gb.sz.y)

    bgimg = love.graphics.newImage('assets/images/papap_background.png')

    love.keyboard.setKeyRepeat(false)

    bc = love.timer.getTime()
    tt = love.graphics.newText(igfont_fxw, nil)

    menu_start = menu('')
    menu_start:add_button('new game', GAME_STATE_NEW)
    menu_start:add_button('exit', GAME_STATE_EXIT)
    menu_start:finalize()

    menu_pause = menu('game paused')
    menu_pause:add_button('resume', GAME_STATE_PLAY)
    menu_pause:add_button('new game', GAME_STATE_NEW)
    menu_pause:add_button('exit', GAME_STATE_EXIT)
    menu_pause:finalize()

    menu_go_loss = menu('game over. try again?', true)
    menu_go_loss:add_button('new game', GAME_STATE_NEW)
    menu_go_loss:add_button('exit', GAME_STATE_EXIT)
    menu_go_loss:finalize()

    menu_go_win = menu('good job! go again?', true)
    menu_go_win:add_button('new game', GAME_STATE_NEW)
    menu_go_win:add_button('exit', GAME_STATE_EXIT)
    menu_go_win:finalize()

    state = GAME_STATE_LAUNCH
end

function love.keypressed(key, sc, rpt)
    btnpressed(key, sc, rpt, nil)
    proc_input(key, sc, nil, true)
end

function love.keyreleased(key, sc)
    proc_input(key, sc, nil, false)
end

function love.gamepadpressed(js, btn)
    btnpressed(nil, nil, nil, btn)
    proc_input(nil, nil, btn, true)
end

function love.gamepadreleased(js, btn)
    proc_input(nil, nil, btn, false)
end

function btnpressed(key, sc, rpt, btn)
    if state == GAME_STATE_PLAY then
        if key == 'left' or sc == 'a' or btn == 'dpleft' then
            gb:movsel(DIR_LEFT)
        end
        if key == 'right' or sc == 'd' or btn == 'dpright' then
            gb:movsel(DIR_RIGHT)
        end
    end

    if key == 'up' or sc == 'w' or btn == 'dpup' then
        if state == GAME_STATE_LAUNCH then
            menu_start:movsel(DIR_UP)
        elseif state == GAME_STATE_PLAY then
            gb:movsel(DIR_UP)
        elseif state == GAME_STATE_PAUSED then
            menu_pause:movsel(DIR_UP)
        elseif state == GAME_STATE_LOSS then
            menu_go_loss:movsel(DIR_UP)
        elseif state == GAME_STATE_WIN then
            menu_go_win:movsel(DIR_UP)
        end
    end
    if key == 'down' or sc == 's' or btn == 'dpdown' then
        if state == GAME_STATE_LAUNCH then
            menu_start:movsel(DIR_DOWN)
        elseif state == GAME_STATE_PLAY then
            gb:movsel(DIR_DOWN)
        elseif state == GAME_STATE_PAUSED then
            menu_pause:movsel(DIR_DOWN)
        elseif state == GAME_STATE_LOSS then
            menu_go_loss:movsel(DIR_DOWN)
        elseif state == GAME_STATE_WIN then
            menu_go_win:movsel(DIR_DOWN)
        end
    end

    -- TODO: Drop this input if directional button pressed
    if sc == 'return' or sc == 'e' or sc == 'space' or btn == 'a' then
        if state == GAME_STATE_LAUNCH then
            state = menu_start:press()
        elseif state == GAME_STATE_PLAY then
            gb:play()
        elseif state == GAME_STATE_PAUSED then
            state = menu_pause:press()
        elseif state == GAME_STATE_LOSS then
            state = menu_go_loss:press()
        elseif state == GAME_STATE_WIN then
            state = menu_go_win:press()
        end
    end

    if sc == 'escape' or btn == 'start' then
        if state == GAME_STATE_PLAY then
            state = GAME_STATE_PAUSED
        elseif state == GAME_STATE_PAUSED then
            state = GAME_STATE_PLAY
        end
    end

end

function love.update(dt)

    if state == GAME_STATE_NEW then
        gb = board(8, 12)
        currtimer = 30
        state = GAME_STATE_PLAY
    end

    if state == GAME_STATE_PLAY then
        if input_state.x ~= 0 then
            currtimer = currtimer - dt*20
        else
            currtimer = currtimer - dt
        end
        if currtimer > 0 then
            tt:set(string.format('%05.2f', currtimer))
        else
            tt:set(string.format('%05.2f', 0.0))
            gostate = gb:drip(dt)
            if gostate == GAME_STATE_LOSS then
                state = GAME_STATE_LOSS
            elseif gostate == GAME_STATE_WIN then
                state = GAME_STATE_WIN
            end
        end
    elseif state == GAME_STATE_EXIT then
        os.exit()
    end
end

function love.draw(dt)
    love.graphics.setBackgroundColor(colors.game_bg)
    love.graphics.clear()
    love.graphics.setColor(colors.game_bg_alpha)
        love.graphics.draw(bgimg)
    love.graphics.setColor(colors.default)
    if state == GAME_STATE_LAUNCH then
        love.graphics.draw(menu_start.canvas)
    elseif state == GAME_STATE_PLAY then
        love.graphics.draw(gb.canvas)
        love.graphics.draw(tt, 12 + TILE_W, gb.sz.y - (6 + TILE_H))
    elseif state == GAME_STATE_PAUSED then
        love.graphics.draw(menu_pause.canvas)
    elseif state == GAME_STATE_LOSS then
        love.graphics.draw(gb.canvas)
        love.graphics.draw(tt, 12 + TILE_W, gb.sz.y - (6 + TILE_H))
        love.graphics.draw(menu_go_loss.canvas)
    elseif state == GAME_STATE_WIN then
        love.graphics.draw(gb.canvas)
        love.graphics.draw(tt, 12 + TILE_W, gb.sz.y - (6 + TILE_H))
        love.graphics.draw(menu_go_win.canvas)
    end
end
