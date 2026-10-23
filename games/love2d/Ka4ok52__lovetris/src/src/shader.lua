return [[
uniform float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    float pulse = 1.0 + sin(time * 5.0) * 0.15;
    return pixel * color * pulse;
}
]]