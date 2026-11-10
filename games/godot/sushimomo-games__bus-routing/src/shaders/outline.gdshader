shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float line_thickness : hint_range(-10, 30) = 0.0;
uniform vec2 sprite_scale = vec2(1.0, 1.0);

const vec2 OFFSETS[8] = {
    vec2(-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1), 
    vec2(1, -1), vec2(1, 0), vec2(1, 1)
};

void fragment() {
    vec4 base_color = texture(TEXTURE, UV) * COLOR;

    if (line_thickness < 0.1) {
        COLOR = base_color;
    } else { 
        vec2 size = (TEXTURE_PIXEL_SIZE * line_thickness) / sprite_scale;
        float outline = 0.0;

        for (int i = 0; i < 8; i++) {
            outline += texture(TEXTURE, UV + size * OFFSETS[i]).a;
        }

        outline = min(outline, 1.0);

        COLOR = mix(base_color, line_color, outline - texture(TEXTURE, UV).a);
    }
}