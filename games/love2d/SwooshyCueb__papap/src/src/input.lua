if not pcall(function() bit = require('bit32') end) then
    bit = require('extern/numberlua')
end

cfg = {
    repeat_interval = 0.75,
    repeat_delay = 1.5
}

direction_input = {
    arrow = 0x01,
    wasd = 0x02,
    dpad = 0x04
}

a_input = {
    enter = 0x01,
    wasd = 0x02,
    space = 0x04,
    btn = 0x08
}

x_input = {
    rshift = 0x01,
    lshift = 0x02,
    btn = 0x04
}

start_input = {
    esc = 0x01,
    btn = 0x02
}

input_state = {
    left = 0x0,
    right = 0x0,
    up = 0x0,
    down = 0x0,
    a = 0x0,
    x = 0x0,
    start = 0x0
}

direction = {
    left = 0x1,
    right = 0x2,
    up = 0x3,
    down = 0x4
}

control = {
    direction = 0x0
}

function stateval(curr, inp, press)
    if press then
        return bit.bor(curr, inp)
    else
        return bit.band(curr, bit.bnot(inp))
    end
end

function proc_input(key, sc, btn, press)

    if key == 'left' then
        input_state.left = stateval(input_state.left, direction_input.arrow, press)
    elseif sc == 'a' then
        input_state.left = stateval(input_state.left, direction_input.wasd, press)
    elseif btn == 'dpleft' then
        input_state.left = stateval(input_state.left, direction_input.dpad, press)

    elseif key == 'right' then
        input_state.right = stateval(input_state.right, direction_input.arrow, press)
    elseif sc == 'd' then
        input_state.right = stateval(input_state.right, direction_input.wasd, press)
    elseif btn == 'dpright' then
        input_state.right = stateval(input_state.right, direction_input.dpad, press)

    elseif key == 'up' then
        input_state.up = stateval(input_state.up, direction_input.arrow, press)
    elseif sc == 'w' then
        input_state.up = stateval(input_state.up, direction_input.wasd, press)
    elseif btn == 'dpup' then
        input_state.up = stateval(input_state.up, direction_input.dpad, press)

    elseif key == 'down' then
        input_state.down = stateval(input_state.down, direction_input.arrow, press)
    elseif sc == 's' then
        input_state.down = stateval(input_state.down, direction_input.wasd, press)
    elseif btn == 'dpdown' then
        input_state.down = stateval(input_state.down, direction_input.dpad, press)

    elseif sc == 'return' then
        input_state.a = stateval(input_state.a, a_input.enter, press)
    elseif sc == 'e' then
        input_state.a = stateval(input_state.a, a_input.wasd, press)
    elseif sc == 'space' then
        input_state.a = stateval(input_state.a, a_input.space, press)
    elseif btn == 'a' then
        input_state.a = stateval(input_state.a, a_input.btn, press)

    elseif sc == 'rshift' then
        input_state.x = stateval(input_state.x, x_input.rshift, press)
    elseif sc == 'lshift' then
        input_state.x = stateval(input_state.x, x_input.lshift, press)
    elseif btn == 'x' then
        input_state.x = stateval(input_state.x, x_input.btn, press)

    elseif sc == 'escape' then
        input_state.start = stateval(input_state.start, start_input.esc, press)
    elseif btn == 'start' then
        input_state.start = stateval(input_state.start, start_input.btn, press)

    end

end
