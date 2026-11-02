local Snake = require("src.systems.snake")

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
    end
end

local snake = Snake.new(4, 4)
snake:set_direction("up")
snake:set_direction("left")

assert_equal(snake.queued_direction, "up", "queued reverse should be ignored before next move")

local head = snake:move()
assert_equal(head.x, 4, "head x after accepted turn")
assert_equal(head.y, 3, "head y after accepted turn")
assert_equal(snake.direction, "up", "direction after accepted turn")

snake:set_direction("down")
assert_equal(snake.queued_direction, "up", "direct reverse should be ignored")
