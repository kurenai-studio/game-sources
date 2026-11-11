shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0.0, 0.2) = 0.04;
uniform float border_visability : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_intensity : hint_range(0.0, 5.0) = 3;
uniform float gradient_steps : hint_range(1.0, 20.0) = 10;
uniform bool extend_beyond_bounds = true;

const vec2 OFFSETS[16] = vec2[](
	vec2(1, 0), // 0°
	vec2(0.92388, 0.382683), 
	vec2(0.707107, 0.707107), 
	vec2(0.382683, 0.92388),
	vec2(0, 1), // 90°
	vec2(-0.382683, 0.92388), 
	vec2(-0.707107, 0.707107), 
	vec2(-0.92388, 0.382683),
	vec2(-1, 0), // 180°
	vec2(-0.92388, -0.382683), 
	vec2(-0.707107, -0.707107), 
	vec2(-0.382683, -0.92388),
	vec2(0, -1), // 270°
	vec2(0.382683, -0.92388), 
	vec2(0.707107, -0.707107), 
	vec2(0.92388, -0.382683)
);

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// Start with the original sprite
	COLOR = original_color;
	
	// Only add glow effect in transparent or semi-transparent areas
	if (original_color.a < 0.9 && border_visability > 0.001) {
		vec2 aspect_corrected_thickness = vec2(line_thickness, line_thickness / (TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y));

		float min_distance = 1.0;
		for (int i = 0; i < OFFSETS.length(); i++) {
			vec2 sample_uv = UV + OFFSETS[i] * aspect_corrected_thickness;

			for (float t = 0.0; t <= 1.0; t += 1.0/gradient_steps) {
				vec2 check_uv = mix(UV, sample_uv, t);
				
				vec4 sample_color;
				if (check_uv.x >= 0.0 && check_uv.x <= 1.0 && check_uv.y >= 0.0 && check_uv.y <= 1.0) {
					sample_color = texture(TEXTURE, check_uv);
				} else {
					sample_color = vec4(0.0);
				}
				
				if (sample_color.a > 0.5) {
					min_distance = min(min_distance, t);
					break;
				}
			}
		}

		// Only apply glow if we found nearby sprite content
		if (min_distance < 1.0) {
			float gradient = 1.0 - pow(min_distance, gradient_intensity);
			gradient *= border_visability;

			vec4 glow_color = line_color;
			glow_color.a *= gradient;

			// Blend glow with original (preserving original where it exists)
			COLOR = mix(glow_color, original_color, original_color.a);
		}
	}
}