# Lua fundamentals

How the Lua runtime works, applied to this project. This explains the
language mechanics behind every file in `src/`.

## Values and types

Lua has **eight basic types**; the ones used here are:

| Type | Example | Notes |
|---|---|---|
| `nil` | `nil` | Represents "no value". Accessing a missing table key returns `nil`. |
| `boolean` | `true`, `false` | Note: only `false` and `nil` are falsy. |
| `number` | `12`, `3.14` | All numbers are floats (doubles). |
| `string` | `"Breakout"` | Immutable sequences of bytes. |
| `function` | `function() end` | First-class values: can be stored, passed and returned. |
| `table` | `{}` | The universal data structure (see below). |

## Tables: the universal structure

A **table** is both an array and a map. This is what makes Lua simple:

```lua
local t = {}            -- new table
t.x = 10                -- map:  t.x == 10
t[1] = "a"              -- array: indexed from 1 (not 0!)
t[2] = "b"
#t                      -- length operator -> 2
```

In this project every entity (`Ball`, `Paddle`, …) is a table that stores its
state (attributes) as fields:

```lua
local self = { x = 400, y = 300, radius = 6 }
```

## Functions and closures

Functions are first-class. They can be stored in tables (that is how **methods**
work) and can capture local variables (**closures**):

```lua
function Ball:update(dt)      -- defines a method on Ball
    self.x = self.x + self.speedX * dt
end
```

The `:` (colon) syntax is sugar: `ball:update(dt)` is exactly the same as
`ball.update(ball, dt)` — `self` is passed automatically.

## Modules and `require`

A Lua **module** is just a file that returns a value (usually a table). This is
how the project is split into one file per class:

```lua
-- src/ball.lua
local Ball = {}          -- module table
Ball.__index = Ball
function Ball.new(x, y, radius) ... end
return Ball
```

Consumers load it with `require`:

```lua
local Ball = require("src.ball")
local ball = Ball.new(400, 300, 6)
```

`require` runs the file once, caches the result, and returns it. The `src.`
prefix maps to the `src/` directory.

## Metatables: "classes" without classes

Lua has no built-in classes. **Metatables** add object-oriented behavior:

```lua
local Ball = {}
Ball.__index = Ball        -- failed lookups fall back to this table

function Ball.new(x, y, radius)
    local self = setmetatable({ x = x, y = y, radius = radius }, Ball)
    return self
end

function Ball:update(dt) ... end
```

How it works:

1. `Ball.new(...)` builds a plain table and tags it with `setmetatable(self, Ball)`.
2. When you call `ball:update(dt)`, Lua looks for `update` in `ball`. It is not
   there (the instance only holds data), so Lua checks `ball`'s metatable and
   finds `Ball.__index` — which is `Ball` itself.
3. It finds `Ball.update` and calls it with `self = ball`.

This is the **prototype-based** OOP pattern. See `docs/oop-in-lua.md` for the
full explanation applied to this codebase.

## The LÖVE callback loop

`LÖVE` drives the game with a fixed set of **callbacks** that we implement in
`main.lua`:

| Callback | Runs | Role |
|---|---|---|
| `love.load()` | Once, at startup | Initialize the game (`Game.load()`) |
| `love.update(dt)` | Every frame | Advance state using delta time |
| `love.draw()` | Every frame | Render the scene |
| `love.keypressed(key)` | On key press | Route input to the game |
| `love.keyreleased(key)` | On key release | Clear held-input flags |

`dt` is the time elapsed since the last frame (in seconds). All movement uses
`dt`, so the game runs the same speed regardless of frame rate.

## Truthiness and idiomatic Lua

```lua
if not instance then return end   -- nil -> false
if self.message ~= "" then ... end
```

Remember: **`0` and `""` are truthy** in Lua. Always compare explicitly.

## Why Lua for this project

- Tiny, fast, embeddable; the standard for lightweight 2D game logic.
- Tables + metatables give just enough structure for clean OOP without a
  heavyweight class system.
- LÖVE bundles Lua, so there is **nothing to install** beyond LÖVE itself.