--[[
Love2D Configuration

Sets up window properties, modules, and performance settings
for optimal card game experience.
--]]

function love.conf(t)
    t.identity = "CardGame"           -- Save directory name
    t.version = "11.4"               -- Target Love2D version
    t.console = false                -- Don't show console on Windows
    t.accelerometerjoystick = false  -- Disable on mobile for performance
    
    -- Window configuration
    t.window.title = "Card Game"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 720
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1              -- Enable vsync for smooth animation
    t.window.msaa = 0               -- Disable MSAA for pixel art
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    t.window.highdpi = false        -- Consistent scaling across devices
    t.window.usedpiscale = true
    t.window.x = nil
    t.window.y = nil
    
    -- Enable required modules
    t.modules.audio = true          -- Sound effects and music
    t.modules.data = true           -- Data compression/encoding
    t.modules.event = true          -- Event handling
    t.modules.filesystem = true     -- File I/O for saves and assets
    t.modules.font = true           -- Text rendering
    t.modules.graphics = true       -- 2D rendering
    t.modules.image = true          -- Image loading
    t.modules.joystick = false      -- Disable joystick for card game
    t.modules.keyboard = true       -- Keyboard input
    t.modules.math = true           -- Math utilities and RNG
    t.modules.mouse = true          -- Mouse input for card selection
    t.modules.physics = false       -- No physics needed
    t.modules.sound = true          -- Audio decoding
    t.modules.system = true         -- System info
    t.modules.thread = false        -- Single-threaded for determinism
    t.modules.timer = true          -- High-precision timing
    t.modules.touch = true          -- Touch input for mobile support
    t.modules.video = false         -- No video playback needed
    t.modules.window = true         -- Window management
end
