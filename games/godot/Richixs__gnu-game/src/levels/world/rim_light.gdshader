shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float rim_thickness : hint_range(0.0, 100.0) = 2.0; 
uniform float rim_falloff : hint_range(0.1, 10.0) = 2.0;
uniform float global_opacity : hint_range(0.0, 1.0) = 0.6; 

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    
    if (current_color.a < 0.1) {
        vec2 ps = TEXTURE_PIXEL_SIZE;
        float max_found_alpha = 0.0;
        
        for(float i = -rim_thickness; i <= rim_thickness; i++){
            for(float j = -rim_thickness; j <= rim_thickness; j++){
                vec2 sample_uv = UV + vec2(round(i), round(j)) * ps;
                
                sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));
                
                float dist = length(vec2(i, j));
                
                if (dist <= rim_thickness) {
                    float sample_alpha = texture(TEXTURE, sample_uv).a;
                    
                    float weight = 1.0 - (dist / rim_thickness);
                    max_found_alpha = max(max_found_alpha, sample_alpha * weight);
                }
            }
        }

        float glow_alpha = pow(max_found_alpha, rim_falloff);
        
        if (glow_alpha > 0.0) {
            COLOR = vec4(rim_color.rgb, glow_alpha * rim_color.a * global_opacity);
        } else {
            discard;
        }
        
    } else {
        COLOR = current_color;
    }
}