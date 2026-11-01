#version 140

in vec2 var_texcoord0;
out vec4 color_out;

uniform sampler2D texture_sampler;

uniform fs_uniforms
{
	vec4 tint;
	vec4 source_color;
	vec4 target_color;
	vec4 tolerance;
};

void main()
{
	vec4 pixel = texture(texture_sampler, var_texcoord0);

	if (pixel.a > 0.0)
	{
		// Les textures utilisées par Defold ont un alpha prémultiplié.
		vec3 original_color = pixel.rgb / pixel.a;

		vec3 difference = abs(original_color - source_color.rgb);

		float max_difference = max(
			difference.r,
			max(difference.g, difference.b)
		);

		if (max_difference <= tolerance.x)
		{
			pixel.rgb = target_color.rgb * pixel.a;
		}
	}

	vec4 tint_pm = vec4(tint.rgb * tint.a, tint.a);
	color_out = pixel * tint_pm;
}