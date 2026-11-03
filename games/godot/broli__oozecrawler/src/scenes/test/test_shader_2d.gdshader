shader_type canvas_item;

// The base color passed from the editor or GDScript
uniform vec4 base_color : source_color = vec4(0.3, 0.85, 0.3, 1.0);

void fragment() {
    vec2 center = vec2(0.5);
    float dist = distance(UV, center);

    if (dist > 0.5) {
        // 1. Outside the circle -> completely invisible
        COLOR = vec4(0.0); 
		
    } 
    else if (dist >= 0.47) {
        // 2. Thick black border (outer rim)
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } 
    else {
        // 3. Slime Body: Alpha grows from 0.0 at center to 0.5 at the border
        float body_progress = dist / 0.28; // 0.0 at center, 1.0 at border edge
        //float alpha = body_progress * 0.5;  // Scales up to 50% alpha
		float alpha = mix(1.0,0.5,body_progress);
        vec4 current_color = vec4(base_color.rgb, alpha);

        // 4. The Eye (offset to top-right)
        vec2 eye_pos = vec2(0.62, 0.38); //white eyeball
		//pupil nudge
		vec2 pupil_pos = eye_pos + vec2(0.05,-0.035);
		//calc dist
        float eye_dist = distance(UV, eye_pos);
		float pupil_dist = distance(UV,pupil_pos);

        if (pupil_dist < 0.03) {
            // Inner pupil: solid black
            current_color = vec4(0.0, 0.0, 0.0, 1.0);
        } else if (eye_dist < 0.09) {
            // Outer eye: solid white
            current_color = vec4(1.0, 1.0, 1.0, 1.0);
        }

        COLOR = current_color;
    }
}