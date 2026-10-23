local Lume = require("lib.lume")

return function(targetLightHex, targetDarkHex)
	local origLight = Lume.color("#ffffff")
	local origDark = Lume.color("#111a33")
	local targetLight = Lume.color(targetLightHex)
	local targetDark = Lume.color(targetDarkHex)
	local colorTolerance = 0.01

	local shaderCode = [[
        uniform vec3 origLight;
        uniform vec3 origDark;
        uniform vec3 targetLight;
        uniform vec3 targetDark;
        uniform float colorTolerance;
        vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, tex_coords);
            vec3 pixel_rgb = pixel.rgb;
            if (distance(pixel_rgb, origLight) < colorTolerance) {
                return vec4(targetLight, pixel.a);
            } else if (distance(pixel_rgb, origDark) < colorTolerance) {
                return vec4(targetDark, pixel.a);
            }
            return pixel;
        }
    ]]

	local shader = love.graphics.newShader(shaderCode)
	shader:send("origLight", origLight)
	shader:send("origDark", origDark)
	shader:send("targetLight", targetLight)
	shader:send("targetDark", targetDark)
	shader:send("colorTolerance", colorTolerance)

	return shader
end
