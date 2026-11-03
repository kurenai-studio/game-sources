shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform float speed : hint_range(1.0, 10.0) = 5.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5, 0.5);
    
    // Heartbeat thumping calculation
    float pulse = sin(TIME * speed) * 0.5 + 0.5;
    
    // Pull the screen pixels inward/outward from the center based on heartbeat
    vec2 dir = uv - center;
    float dist = length(dir);
    vec2 distorted_uv = center + dir * (1.0 + (pulse * 0.05 * intensity));
    
    // Sample the screen with chromatic aberration split
    float r = texture(SCREEN_TEXTURE, distorted_uv + vec2(0.005 * intensity, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, distorted_uv).g;
    float b = texture(SCREEN_TEXTURE, distorted_uv - vec2(0.005 * intensity, 0.0)).b;
    vec3 col = vec3(r, g, b);
    
    // Drain color (desaturate) and darken edges heavily
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(luma), 0.5 * intensity);
    
    // Vignette (dark border closing in)
    float vignette = smoothstep(0.5, 0.1, dist + (pulse * 0.1));
    col *= mix(1.0, vignette + 0.2, intensity);
    
    COLOR = vec4(col, 1.0);
}