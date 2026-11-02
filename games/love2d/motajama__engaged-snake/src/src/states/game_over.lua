return function(game)
    local state = {}

    function state:enter()
        game.state_machine:change("score_entry", { victory = false })
    end

    return state
end
