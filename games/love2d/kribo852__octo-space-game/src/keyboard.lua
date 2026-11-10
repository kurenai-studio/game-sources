local keyboard = {}

function keyboard.hello()
    print("Keyboard is online!")
end

function keyboard.register_key_binding(game_state, key, action)
    if not keyboard[game_state] then
        keyboard[game_state] = {}
    end
    keyboard[game_state][key] = action
end


function keyboard.run_key_actions(game_state)
    
    for key,action in pairs(keyboard[game_state]) do
        if love.keyboard.isDown(key) then
            action()
        end
    end
end

return keyboard