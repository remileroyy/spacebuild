shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float scanline_count : hint_range(0, 1800) = 200.0;
uniform float contrast = 2.0;
uniform bool greyscale = true;

// Used by the noise functin to generate a pseudo random value between 0.0 and 1.0
float random(vec2 uv){
    return fract(cos(uv.x * 83.4827 + uv.y * 92.2842) * 43758.5453123);
}

// Adds a vignette shadow to the edges of the image
float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity);
}

void fragment()
{
	vec4 text = texture(SCREEN_TEXTURE, UV);
	// Noise
	text.rgb += clamp(random(UV + fract(TIME)), 0.0, 1.0) * static_noise_intensity;
	// Vignette
	text.rgb *= vignette(UV);
	// Greyscale
	if (greyscale) text.rgb = vec3(text.r + text.g + text.b) / 3.;
	// Scanlines
	float s = sin(UV.y * scanline_count * PI * 2.0);
	s = (s * 0.5 + 0.5) * 0.9 + 0.1;
	text = text * vec4(vec3(pow(s, 0.25)), 1.0);
	// Contrast
	float midpoint = pow(0.5, 2.2);
	text.rgb = (text.rgb - vec3(midpoint)) * contrast + midpoint;
	
	COLOR = text;
}