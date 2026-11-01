
function difficultyLoad()
    pointer = 0
    pointerY = 0
    time = 0
    textCount = pointer + 1
    diffTexts = {
        "for kids.",
        "actual easy mode.",
        "casual!"
    }
end


function difficultyUpdate(dt)
    time = time + dt

    if buttonPressed(1) then
        pointer = (pointer - 1) % 3
        textCount = pointer + 1
        sound(4)
    elseif buttonPressed(3) then
        pointer = (pointer + 1) % 3
        textCount = pointer + 1
        sound(4)
    elseif buttonPressed(2) or buttonPressed(4) then
        sound(5)
        newState(states.play, diffTable[pointer + 1], pointer + 1)
    end

    if abs(pointer * 16 - pointerY) > 1 then
        local dist = pointer * 16 - pointerY
        pointerY = pointerY + dist * dt * 8
    else
        pointerY = pointer * 16
    end
end


function difficultyDraw()

    bigsprite(21, 32, 12, 4, 1)

    color(2)
    print("select the\ndifficulty", 40, 26)
    color(1)
    print("select the\ndifficulty", 40, 27)
    color(4)
    print("select the\ndifficulty", 40, 28)

    palette(4)
    bigsprite(29, 48, 48, 2, 1)
    print("easy", 54, 52)

    palette(3)
    bigsprite(29, 48, 64, 2, 1)
    print("hard", 54, 68)

    palette(2)
    bigsprite(29, 48, 80, 2, 1)
    print("insn", 54, 84)

    --Draw the pointers
    palette(2)
    sprite(31, 35 - sin(time * 4) * 3, 51 + pointerY)

    palette(1)
    sprite(31, 83 + sin(time * 4) * 3, 51 + pointerY)

    bigsprite(37, 48, 48 + pointer * 16, 2, 1)

    palette( 5 - textCount)
    color(3)
    printf(diffTexts[textCount], 16, 104, 100, "center")

end
