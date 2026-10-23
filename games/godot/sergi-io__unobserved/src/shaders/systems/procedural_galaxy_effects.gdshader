shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 camera_position = vec2(0.0);
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform float seed = 0.0;
uniform float parallax_scale = 0.025;
uniform float intensity = 0.8;
uniform float animation_speed = 0.035;
uniform float density = 0.45;
uniform float cluster_scale = 1.0;
uniform float streak_strength = 0.75;
uniform vec4 warm_color : source_color = vec4(1.0, 0.62, 0.16, 1.0);
uniform vec4 cool_color : source_color = vec4(0.22, 0.85, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.98, 0.96, 1.0, 1.0);
uniform int detail_steps = 3;

float hash12(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33 + seed * 0.013);
	return fract((p.x + p.y) * p.z);
}

vec2 hash22(vec2 value) {
	vec3 p = fract(vec3(value.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33 + seed * 0.017);
	return fract((p.xx + p.yz) * p.zy);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	mat2 m = mat2(vec2(1.53, -1.18), vec2(1.09, 1.44));
	for (int i = 0; i < 4; i++) {
		if (i >= detail_steps) {
			break;
		}
		value += value_noise(p) * amplitude;
		p = m * p + vec2(2.41, -1.79);
		amplitude *= 0.52;
	}
	return value;
}

mat2 rotation2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

vec3 galaxy_cell(vec2 p, vec2 cell, vec2 neighbor, float time_value, inout float alpha_accum) {
	vec2 id = cell + neighbor;
	vec2 rnd = hash22(id + seed * 0.071);
	float presence = hash12(id + 17.0);
	float density_amount = clamp(density, 0.0, 3.0);
	float threshold = 1.0 - pow(density_amount / 3.0, 0.72) * 0.32;
	if (presence < threshold) {
		return vec3(0.0);
	}

	float color_pick = hash12(id + 31.0);
	float angle = hash12(id + 47.0) * 6.28318530718 + time_value * mix(-0.12, 0.12, hash12(id + 71.0));
	vec2 center = id + rnd;
	vec2 local = rotation2d(angle) * (p - center);
	float radius = mix(0.055, 0.18, hash12(id + 89.0));
	float aspect = mix(0.24, 0.68, hash12(id + 103.0));
	vec2 e = vec2(local.x, local.y / max(aspect, 0.001));
	float d = length(e) / radius;

	float core = exp(-d * d * 5.4);
	float halo = exp(-d * 2.2) * 0.44;
	float arms_angle = atan(e.y, e.x);
	float arms_radius = length(e);
	float arms = sin(arms_angle * mix(2.0, 4.0, hash12(id + 131.0)) + arms_radius * 16.0 - time_value * 1.7);
	arms = smoothstep(0.62, 1.0, arms) * exp(-d * 1.8);
	float streak = exp(-abs(local.y) / max(radius * aspect * 0.38, 0.001)) * smoothstep(radius * 2.4, 0.0, abs(local.x));
	streak *= streak_strength * mix(0.2, 1.0, hash12(id + 157.0));

	float sparkle = smoothstep(0.96, 1.0, hash12(floor(local * 120.0) + id)) * exp(-d * 0.8);
	float mask = clamp(core + halo + arms * 0.6 + streak * 0.46 + sparkle * 0.45, 0.0, 1.6);
	float twinkle = 0.9 + sin(time_value * 5.0 + presence * 37.0) * 0.1;
	mask *= twinkle;

	vec3 tint = mix(warm_color.rgb, cool_color.rgb, color_pick);
	tint = mix(tint, core_color.rgb, core * 0.78 + sparkle * 0.4);
	alpha_accum += mask * 0.2;
	return tint * mask;
}

void fragment() {
	vec2 safe_viewport = max(viewport_size, vec2(1.0));
	vec2 uv = UV - vec2(0.5);
	uv.x *= safe_viewport.x / safe_viewport.y;

	float time_value = TIME * animation_speed;
	vec2 parallax = camera_position * parallax_scale / safe_viewport.y;
	vec2 flow = vec2(time_value * 0.025, -time_value * 0.018);
	vec2 p = (uv + parallax + flow) * (5.0 / max(cluster_scale, 0.001));

	vec2 broad_cell = floor(p);
	vec3 color = vec3(0.0);
	float alpha_accum = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			color += galaxy_cell(p, broad_cell, vec2(float(x), float(y)), time_value, alpha_accum);
		}
	}

	float dust = fbm(p * 3.8 + vec2(seed * 0.01, -seed * 0.013) + time_value * 0.03);
	float dust_mask = smoothstep(0.72, 1.0, dust) * 0.14 * clamp(density, 0.0, 1.0);
	color += mix(cool_color.rgb, warm_color.rgb, dust) * dust_mask;
	alpha_accum += dust_mask;

	float vignette = 1.0 - smoothstep(0.48, 1.18, length(uv));
	color *= mix(0.35, 1.0, vignette);
	COLOR = vec4(color * intensity, clamp(alpha_accum * intensity, 0.0, 1.0));
}
