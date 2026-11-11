shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float inner_stroke_thickness = 1.0;
uniform float frequency = 8.0;
uniform float phase_speed = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Start with the original texture
	vec4 original_texture = texture(TEXTURE, UV);
	
	// Create dotted outline effect
	vec4 circle_outline = vec4(0.0);

	// Only apply effects if the original texture has some alpha
	if (original_texture.a > 0.0) {
		// Dotted Outline Effect - Simple rectangular outline
		vec2 texture_size = vec2(textureSize(TEXTURE, 0));
		vec2 texel_size = 1.0 / texture_size;
		
		// Check if we're near the edge of the texture rectangle
		vec2 border_distance = min(UV, 1.0 - UV);
		float min_border_distance = min(border_distance.x, border_distance.y);
		
		// Create ring based on distance from texture edge
		float ring_thickness_uv = inner_stroke_thickness * texel_size.x;
		float ring = step(min_border_distance, ring_thickness_uv) * step(0.001, min_border_distance);

		// Animated wave effect - define pos for angle calculation
		vec2 pos = UV - vec2(0.5);  // Center coordinates for angle calculation
		float angle = atan(pos.y, pos.x);
		if (angle < 0.0) {
			angle += 2.0 * PI;
		}
		
		float wave = 0.5 * sin(frequency * angle + TIME * phase_speed) + 0.5;
		ring *= step(0.5, wave);

		circle_outline = vec4(color.rgb, ring * color.a);
	}

	// Blend original texture with dotted outline
	// Start with original texture
	COLOR = original_texture;
	
	// Add dotted outline on top (additive blending)
	COLOR.rgb += circle_outline.rgb * circle_outline.a;
	
	// Preserve original alpha
	COLOR.a = original_texture.a;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
