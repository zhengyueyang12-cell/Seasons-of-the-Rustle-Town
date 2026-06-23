shader_type canvas_item;
render_mode blend_mix;

uniform vec2 scroll_speed = vec2(0.06, 0.1);
uniform float wave_scale : hint_range(1.0, 24.0) = 7.0;
uniform vec3 water_deep : source_color = vec3(0.07, 0.2, 0.38);
uniform vec3 water_shallow : source_color = vec3(0.18, 0.45, 0.68);
uniform vec3 water_highlight : source_color = vec3(0.52, 0.78, 0.92);
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.38;
uniform float alpha : hint_range(0.0, 1.0) = 0.9;

vec2 grad2(vec2 p) {
	vec2 h = fract(sin(vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	)) * 43758.5453);
	vec2 g = h * 2.0 - 1.0;
	return g / max(length(g), 0.001);
}

vec2 fade(vec2 t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlin(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = fade(f);

	float n00 = dot(grad2(i), f);
	float n10 = dot(grad2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float n01 = dot(grad2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float n11 = dot(grad2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

	return mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y);
}

float fbm(vec2 p, int octaves, float lacunarity, float gain) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	float max_amp = 0.0;

	for (int i = 0; i < 6; i++) {
		if (i >= octaves) {
			break;
		}
		value += amplitude * perlin(p * frequency);
		max_amp += amplitude;
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return value / max_amp * 0.5 + 0.5;
}

float water_waves(vec2 uv) {
	vec2 flow = scroll_speed * TIME;
	float layer_a = fbm(uv * 1.0 + flow, 4, 2.0, 0.5);
	float layer_b = fbm(uv * 1.9 + flow * vec2(1.2, 0.8) + 19.7, 3, 2.1, 0.45);
	float layer_c = fbm(uv * 4.2 - flow * 0.6 + 41.3, 2, 2.2, 0.4);
	return layer_a * 0.55 + layer_b * 0.3 + layer_c * 0.15;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.05) {
		discard;
	}

	vec2 uv = UV * wave_scale;
	float waves = water_waves(uv);
	vec3 color_rgb = mix(water_deep, water_shallow, waves);
	float highlight_mask = smoothstep(0.58, 0.82, waves);
	color_rgb = mix(color_rgb, water_highlight, highlight_mask * ripple_strength);

	COLOR = vec4(color_rgb, tex.a * alpha);
}
