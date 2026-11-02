return function(game)
    local state = {}

    function state:enter()
        game.state_machine:change("score_entry", { victory = true })
    end

    return state
end
