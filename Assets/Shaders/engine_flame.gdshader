shader_type spatial;

uniform sampler2D noise;
uniform sampler2D gradient;
uniform float fade = 1.0;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow(
		(clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)),
		amount
	);
}

void fragment() {
	float basic_fresnel = fresnel(2.0, NORMAL, VIEW);
	vec4 pixel = texture(noise, UV * vec2(1, 0.25) + vec2(0, -2.0 * TIME));
	vec4 color = texture(gradient, vec2(UV.y, 0));
	ALBEDO = 0.4 + 0.1 * pixel.rgb * color.rgb;
	EMISSION = ALBEDO * 5.0;
	ALPHA = pixel.r * pow(1.0-UV.y, 10.0 * fade) * basic_fresnel;
}