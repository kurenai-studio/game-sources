
function load()

    diffTable = {1.5, 1.7, 2.5}

    highScores = {0, 0, 0}

    music(1, true)

    states = {
        start = "start",
        difficulty = "difficulty",
        play = "play",
        over = "over"
    }
    state = states.start

    startLoad()
    difficultyLoad()
    playLoad(1, 1)
    overLoad(0, 1)
end


function update(dt)

    if state == states.start then
        startUpdate(dt)
    elseif state == states.difficulty then
        difficultyUpdate(dt)
    elseif state == states.play then
        playUpdate(dt)
    elseif state == states.over then
        overUpdate(dt)
    end

end


function draw()

    if state == states.start then
        startDraw()
    elseif state == states.difficulty then
        difficultyDraw()
    elseif state == states.play then
        playDraw()
    elseif state == states.over then
        overDraw()
    end

end


function newState(s, cond, cond2)
    state = s
    if state == states.start then
        startLoad()
    elseif state == states.difficulty then
        difficultyLoad()
    elseif state == states.play then
        playLoad(cond, cond2)
    elseif state == states.over then
        overLoad(cond, cond2)
    end
end


function saveScore()
    writable = pow(highScores[1] * 17, 4) .. " " .. pow(highScores[2] * 17, 4) .. " " .. pow(highScores[3] * 17, 4)
    love.filesystem.write("ead.ma", writable)
end


function loadScore()
    loaded = love.filesystem.read("ead.ma")

    loadedScores = {}

    if loaded == nil then
        loadedScores = {0, 0, 0}
    else
        for score in string.gmatch(loaded, "%S+") do
            table.insert(loadedScores, tonumber((score^0.25) / 17) )
        end
    end

    highScores = loadedScores
end
