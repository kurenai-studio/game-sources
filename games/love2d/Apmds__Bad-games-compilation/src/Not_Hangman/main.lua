function love.load()
    love.window.setTitle('\"Hangman\"')
    love.window.setMode(800, 600)
    game_font = love.graphics.newFont(30)
    words = require("words")
    math.randomseed(os.time())

    restart_game()
end

function love.update(dt)
    
end

function love.draw()
    love.graphics.setBackgroundColor(0.8, 0.8, 0.8)
    love.graphics.setFont(game_font)
    love.graphics.setColor(0, 0, 0)
    -- Draws the lines and letters(not including spaces)
    for i = 1, #current_word, 1 do
        local current_letter = string.sub(current_word, i, i)
        if current_letter ~= " " then
            love.graphics.line(45*i, 500, 45*i + 30, 500)
        end
        if table_contains(guessed_letters, current_letter) or game_ended then
            love.graphics.print(current_letter, 45*i + 7, 465)
        end

    end
    
    love.graphics.print("Guess: " .. guess, 30, 70)
    love.graphics.print("Lives: " .. lives, 30, 130)
    
    -- Reset "button"
    love.graphics.rectangle("fill", 600, 30, 100, 100)

    if game_ended then
        if lives <= 0 then
            love.graphics.print("Game over :(", 30, 190)
        else
            love.graphics.print("GG", 30, 190)
        end
    end
end

function love.textinput(t)
    if game_ended then
        return
    end
    guess = guess .. t
end

function love.keypressed(key)
    if game_ended then
        return
    end
    if key == "backspace" then
        guess = string.sub(guess, 1, #guess-1)
    elseif key == "return" then
        -- Ignore an empty guess
        if guess == "" then
            return 0
        end

        if guess == current_word then
            game_ended = true
        elseif string.find(current_word, guess) and #guess == 1 then
            table.insert(guessed_letters, guess)
        else
            lives = lives - 1
            if lives == 0 then
                game_ended = true
            end
        end
        guess = ""
        if not game_ended then
            game_ended = check_word()
        end
    end
end

-- Returns true if the table contains the item
function table_contains(table, item)
    for i, value in pairs(table) do
        if value == item then
            return true
        end
    end
    return false
end

-- Resets the game
function restart_game()
    current_word = words[math.random(1, #words)]
    guessed_letters = {" "}
    guess = ""
    lives = 5
    game_ended = false
end

function love.mousereleased(x, y, button)
    -- "Reset button"
    if x>600 and x<700 and y>30 and y<130 then
        restart_game()
    end
end

-- Returns true if the word was guessed
function check_word()
    for i = 1, #current_word do
        local current_letter = string.sub(current_word, i, i)
        if not table_contains(guessed_letters, current_letter) then
            return false
        end
    end
    return true
end