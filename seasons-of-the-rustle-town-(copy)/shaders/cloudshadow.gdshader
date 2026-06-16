shader_type canvas_item;
render_mode blend_mix;

// ── 可调参数 ──────────────────────────────────────────────
uniform vec2 scroll_speed = vec2(0.3, 0.1);          // 云影流动方向与速度
uniform float cloud_scale : hint_range(0.5, 20.0) = 3.0;
uniform float contrast : hint_range(0.0, 1.0) = 0.45; // 云团明暗对比（越高云块越分明）
uniform float softness : hint_range(0.01, 0.5) = 0.18; // 边缘柔化宽度
uniform float alpha_min : hint_range(0.0, 1.0) = 0.1;  // 薄云处透明度
uniform float alpha_max : hint_range(0.0, 1.0) = 0.6;  // 厚云处透明度
uniform vec3 color_light = vec3(0.0, 0.0, 0.03);       // 薄云：近黑/深蓝灰
uniform vec3 color_dark = vec3(0.05, 0.05, 0.1);       // 厚云：深灰

// ── 经典梯度 Perlin 噪声（2D）──────────────────────────────
// 为每个格点生成随机梯度向量
vec2 grad2(vec2 p) {
	vec2 h = fract(sin(vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	)) * 43758.5453);
	vec2 g = h * 2.0 - 1.0;
	return g / max(length(g), 0.001);
}

// 五次 Hermite 插值（比 smoothstep 更平滑，Perlin 标准做法）
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

// ── 分形布朗运动：多层 Perlin 叠加，产生蓬松不规则云团 ─────
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
	// 归一化到 [0, 1]
	return value / max_amp * 0.5 + 0.5;
}

// 多层云团合成：大/中/小尺度 + 不同偏移，避免重复图案
float cloud_density(vec2 uv) {
	vec2 flow = scroll_speed * TIME;

	float large  = fbm(uv * 1.0  + flow,              4, 2.0, 0.5);
	float medium = fbm(uv * 2.3  + flow * 1.3 + 17.3, 3, 2.1, 0.45);
	float small  = fbm(uv * 5.7  + flow * 0.7 + 43.1, 2, 2.2, 0.4);

	// 加权混合：大块决定主体，中小层增加蓬松边缘
	return large * 0.55 + medium * 0.30 + small * 0.15;
}

void fragment() {
	vec2 uv = UV * cloud_scale;

	float density = cloud_density(uv);

	// smoothstep 柔化边缘并调节对比度
	float edge_low  = contrast - softness;
	float edge_high = contrast + softness;
	float mask = smoothstep(edge_low, edge_high, density);

	// 二次 smoothstep 让过渡更自然（可选优化）
	mask = smoothstep(0.0, 1.0, mask);

	// 根据云厚映射颜色与透明度
	vec3 shadow_rgb = mix(color_light, color_dark, mask);
	float shadow_alpha = mix(alpha_min, alpha_max, mask);

	COLOR = vec4(shadow_rgb, shadow_alpha);
}
