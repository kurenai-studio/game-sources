shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.3, 0.85, 0.3, 1.0);
uniform int tier = 1; // Controls how many wisps appear
uniform float core_radius = 20.0;

void fragment() {
    vec2 center = vec2(0.5);
    vec2 p = UV - center;
    float dist = distance(UV, center);
    float angle = atan(p.y, p.x); // -PI to +PI (0.0 is the 3 o'clock mark)

    // 1. Calculate uniform border width (3.0px) in UV space
    float border_uv = 3.0 / (core_radius * 2.0);
    float rim_start = 0.5 - border_uv; 

    // 2. Fusion seam: arc at angle 0.0 that pinches inward slightly
    float seam_mask = smoothstep(0.35, 0.0, abs(angle));
    float pinch = border_uv * 0.6 * seam_mask;
    float local_rim_start = rim_start - pinch;

    if (dist > 0.5) {
        COLOR = vec4(0.0); 
    } 
    else if (dist >= local_rim_start) {
        // Normally dark, but glows bright white/accent at the seam
        vec3 dark_rim = vec3(0.05, 0.05, 0.07);
        vec3 seam_glow = mix(base_color.rgb * 1.5, vec3(1.0), 0.75);
        COLOR = vec4(mix(dark_rim, seam_glow, seam_mask * 0.9), 1.0);
    } 
    else {
        // 1. Core depth shading (dense outer shell, self-luminous center)
        float normalized_dist = dist / rim_start;
        vec3 core_color = mix(base_color.rgb * 1.35, base_color.rgb * 0.3, normalized_dist);

        // 2. Surface tension edge glow
        float rim = smoothstep(rim_start - 0.08, rim_start, dist);
        core_color += base_color.rgb * 0.25 * rim;

        // 3. Twirling fume curling inward from the seam
        float spiral_prog = clamp((local_rim_start - dist) / 0.16, 0.0, 1.0);
        if (spiral_prog > 0.0 && spiral_prog < 1.0 && abs(angle) < 1.4) {
            float twitch = sin(TIME * 5.0 + spiral_prog * 8.0) * 0.04;
            float fume_angle = spiral_prog * 0.75 + twitch;
            float ang_diff = abs(angle - fume_angle);
            float fume_width = mix(0.10, 0.02, spiral_prog);
            float fume = smoothstep(fume_width, 0.005, ang_diff) * (1.0 - spiral_prog);
            core_color = mix(core_color, vec3(1.0), fume * 0.85);
        }

        // 4. Internal Ethereal Wisps (Tier Counter) with High-Contrast Auras
        int wisp_count = tier - 1; // Tier 1 has 0 wisps (dormant stone)
        
        if (wisp_count == 1) {
            // Tier 2: Single pulsing spirit flame in center
            vec2 flame_uv = (UV - center);
            flame_uv.y *= 1.3;
            float d = length(flame_uv);
            float pulse = 0.045 + sin(TIME * 4.0) * 0.006;

            // Outer dark aura for contrast on light bodies
            float aura = smoothstep(pulse * 1.5, pulse, d);
            core_color = mix(core_color, vec3(0.02, 0.02, 0.05), aura * 0.7);

            // Blazing inner bead
            float wisp = smoothstep(pulse, 0.008, d);
            core_color = mix(core_color, vec3(1.0), wisp * 0.95);
        } 
        else if (wisp_count > 1) {
            // Tier 3+: Orbiting wisps with streaming comet tails
            float angle_step = 6.2831853 / float(wisp_count);
            for (int i = 0; i < wisp_count; i++) {
                float head_angle = float(i) * angle_step + (TIME * 0.9);
                
                for (int t = 0; t < 5; t++) {
                    float trail_angle = head_angle - (float(t) * 0.07);
                    vec2 trail_pos = center + vec2(cos(trail_angle), sin(trail_angle)) * 0.17;
                    float d = distance(UV, trail_pos);
                    
                    float radius = 0.042 - (float(t) * 0.007);
                    float brightness = 1.0 - (float(t) * 0.2);

                    // 1. Dark outline aura (creates sharp contrast against light cores)
                    float aura = smoothstep(radius * 1.55, radius * 0.9, d);
                    core_color = mix(core_color, vec3(0.02, 0.02, 0.05), aura * brightness * 0.65);

                    // 2. Luminous white spark (creates sharp contrast against dark cores)
                    float trail = smoothstep(radius, 0.005, d) * brightness;
                    core_color = mix(core_color, vec3(1.0), trail * 0.92);
                }
            }
        }


        COLOR = vec4(core_color, 1.0);
    }
}
