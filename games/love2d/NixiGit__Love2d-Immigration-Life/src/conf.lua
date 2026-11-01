function love.conf(t)
    -- Identity and version
    t.identity = "Immigration-Life"             -- Save directory name
    t.version = "11.5"                          -- LOVE version compatibility
    t.console = false                           -- Enable console on Windows (debug)

    -- Window settings
    t.window.title = "Immigration Life"         -- Window title
    t.window.icon = nil                         -- Path to icon image
    t.window.width = 800                        -- Window width
    t.window.height = 800                       -- Window height
    t.window.borderless = false                 -- Remove window border
    t.window.resizable = false                  -- Allow window resizing
    t.window.minwidth = 800                     -- Minimum window width
    t.window.minheight = 600                    -- Minimum window height
    t.window.fullscreen = false                 -- Start in fullscreen
    t.window.fullscreentype = "desktop"         -- Fullscreen type
    t.window.vsync = 1                          -- Vertical sync mode
    t.window.msaa = 1                           -- Multi-sample anti-aliasing
    t.window.depth = nil                        -- Depth buffer bits
    t.window.stencil = nil                      -- Stencil buffer bits
    t.window.display = 1                        -- Monitor to display on
    t.window.highdpi = false                    -- High-DPI mode (Retina)
    t.window.usedpiscale = false                -- Use DPI scale

    -- Modules to enable
    t.modules.audio = true                      -- Audio module
    t.modules.data = true                       -- Data encoding module
    t.modules.event = true                      -- Event module
    t.modules.font = true                       -- Font module
    t.modules.graphics = true                   -- Graphics module
    t.modules.image = true                      -- Image module
    t.modules.joystick = true                   -- Joystick module
    t.modules.keyboard = true                   -- Keyboard module
    t.modules.math = true                       -- Math module
    t.modules.mouse = true                      -- Mouse module
    t.modules.physics = false                   -- Physics module (Box2D)
    t.modules.sound = true                      -- Sound module
    t.modules.system = true                     -- System module
    t.modules.thread = true                     -- Thread module
    t.modules.timer = true                      -- Timer module
    t.modules.touch = true                      -- Touch module
    t.modules.video = false                     -- Video module
    t.modules.window = true                     -- Window module
end