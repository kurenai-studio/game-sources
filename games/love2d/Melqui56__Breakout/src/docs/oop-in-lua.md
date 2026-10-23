# Object-oriented programming in Lua

Lua does not have classes, so this project uses the **prototype pattern**
through metatables. This document explains exactly how the pattern works and
how it maps to the code in `src/`.

## The class pattern

Every class follows the same shape. Using `Ball` as the reference:

```lua
-- 1. The class is a table that will act as the prototype.
local Ball = {}
Ball.__index = Ball        -- (2) failed lookups redirect here

-- 3. The constructor builds an instance.
function Ball.new(x, y, radius)
    local self = setmetatable({ x = x, y = y, radius = radius }, Ball)
    return self
end

-- 4. Methods are stored on the prototype.
function Ball:update(dt)
    self.x = self.x + self.speedX * dt
end

return Ball
```

### Step by step

1. **Prototype table.** `local Ball = {}` is the "class". It holds the methods.
2. **`__index`.** `Ball.__index = Ball` tells Lua: *when an instance does not
   have a key, look it up in `Ball`*.
3. **Constructor.** `Ball.new(...)` creates the instance (a plain data table),
   links it to the prototype with `setmetatable`, and returns it.
4. **Methods.** `function Ball:update(dt)` is sugar for
   `Ball.update = function(self, dt) ... end`. The colon passes `self` for you.

### Method lookup in practice

```lua
local ball = Ball.new(400, 300, 6)
ball:update(0.016)
```

`ball` only contains `x`, `y`, `radius`, `speedX`, `speedY`. `update` is not
there, so Lua consults the metatable, finds `__index = Ball`, and calls
`Ball.update(ball, 0.016)`. The instance receives `self = ball`.

## Attributes vs. methods

| Concern | Where it lives | Why |
|---|---|---|
| **Attributes** (data) | On the instance (constructor) | Each ball has its own position/speed |
| **Methods** (behavior) | On the prototype (`Ball`) | Shared by every instance, defined once |

This keeps memory small and matches the UML in `docs/architecture.md`: the
instance is the *object*, the prototype is the *class*.

## How each entity maps to the UML

| UML class | Prototype (`local X = {}`) | Constructor (`X.new`) | Key methods |
|---|---|---|---|
| `Ball` | `Ball` | `Ball.new(x, y, radius)` | `update`, `draw`, `launch`, `bounceVertical`, `reset` |
| `Paddle` | `Paddle` | `Paddle.new(x, y, width, speed)` | `update`, `moveLeft`, `moveRight`, `draw` |
| `Brick` | `Brick` | `Brick.new(x, y, w, h, hp, row)` | `update`, `draw`, `takeHit` |
| `Level` | `Level` | `Level.new()` | `load`, `update`, `draw`, `isComplete` |
| `Game` | `Game` | `Game.load()` (singleton) | `update`, `draw`, `handleInput`, `releaseInput` |
| `UI` | `UI` | `UI.new()` | `setHud`, `setMessage`, `draw` |

## `Game` as a singleton

`Game` is not instantiated with `new`; it keeps a private module-level
`instance`. This matches the UML: there is exactly **one** game object. Other
entities are created inside `Game.load()` and owned by it (composition).

## Naming and conventions

- One class per file, filename lowercase matching the class (`ball.lua`).
- `new` for constructors; colon methods use `self`.
- Return the class table at the end of every module.