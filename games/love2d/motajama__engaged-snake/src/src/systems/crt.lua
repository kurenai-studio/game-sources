local CRT = {}
CRT.__index = CRT

local shader_source = [[
extern number time;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 px = Texel(texture, texture_coords) * color;
    number mono = dot(px.rgb, vec3(0.299, 0.587, 0.114));
    number scan = 0.88 + 0.12 * sin(screen_coords.y * 0.7 + time * 3.0);
    number vignette_x = smoothstep(0.0, 0.12, texture_coords.x) * (1.0 - smoothstep(0.88, 1.0, texture_coords.x));
    number vignette_y = smoothstep(0.0, 0.12, texture_coords.y) * (1.0 - smoothstep(0.88, 1.0, texture_coords.y));
    number vignette = max(0.35, vignette_x * vignette_y);
    number noise = fract(sin(dot(screen_coords + time, vec2(12.9898, 78.233))) * 43758.5453);
    vec3 mono_color = vec3(0.35, 1.0, 0.55) * mono;
    mono_color *= scan * vignette;
    mono_color += (noise - 0.5) * 0.03;
    return vec4(mono_color, px.a);
}
]]

function CRT.new(renderer)
    local shader = nil
    local supported = false

    if love.graphics.getSupported then
        local features = love.graphics.getSupported()
        supported = features and features.shader
    end

    if supported and love.graphics.newShader then
        local ok, value = pcall(love.graphics.newShader, shader_source)
        if ok then
            shader = value
        end
    end

    return setmetatable({
        renderer = renderer,
        shader = shader,
        time = 0,
    }, CRT)
end

function CRT:update(dt)
    self.time = self.time + dt
end

function CRT:draw(canvas)
    love.graphics.setColor(1, 1, 1, 1)

    if self.shader then
        self.shader:send("time", self.time)
        love.graphics.setShader(self.shader)
        love.graphics.draw(canvas, 0, 0, 0, self.renderer.scale, self.renderer.scale)
        love.graphics.setShader()
        return
    end

    love.graphics.setColor(0.4, 1, 0.6, 1)
    love.graphics.draw(canvas, 0, 0, 0, self.renderer.scale, self.renderer.scale)
    love.graphics.setColor(0, 0, 0, 0.15)
    for y = 0, self.renderer.base_height * self.renderer.scale, 4 do
        love.graphics.rectangle("fill", 0, y, self.renderer.base_width * self.renderer.scale, 2)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return CRT
