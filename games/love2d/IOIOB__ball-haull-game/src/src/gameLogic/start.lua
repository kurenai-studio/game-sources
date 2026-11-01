
function startLoad()
    time = 0
    selection = 0
    pointerY = 0
end


function startUpdate(dt)
    time = time + dt

    if buttonPressed(1) or buttonPressed(3) then
        selection = 16 - selection
        sound(4)
    elseif buttonPressed(2) or buttonPressed(4) then
        sound(5)
        if selection > 0 then
            quit()
        else
            newState(states.difficulty)
        end
    end

    if abs(selection - pointerY) > 1 then
        local dist = selection - pointerY
        pointerY = pointerY + dist * dt * 8
    else
        pointerY = selection
    end

end


function startDraw()
    palette(1)

    --Draw logo
    bigsprite(25, 32, 34 + cos(time*4), 4, 2)

    --Draw the buttons
    bigsprite(29, 48, 67, 2, 1)
    print("play", 54, 71)

    bigsprite(29, 48, 83, 2, 1)
    print("quit", 54, 87)

    --Draw the pointers
    palette(2)
    sprite(31, 35 - sin(time * 4) * 3, 70 + pointerY)

    palette(1)
    sprite(31, 83 + sin(time * 4) * 3, 70 + pointerY)

    bigsprite(37, 48, 67 + selection, 2, 1)


    --Draw the balls
    for i = 1, 20 do
        palette((i % 2) + 2)
        sprite(1, (sin(time + i / 3.2) * 54) + 56, (cos(time + i / 3.2) * 54) + 56)
    end


    --Print studio name
    palette(1)
    color(4)
    print("by\nj", 2, 111)

end
