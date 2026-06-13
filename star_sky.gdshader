shader_type sky;

// 宇宙空間の星空。EYEDIR（視線方向）をもとに手続き的に星を描く無限遠の背景。

uniform vec3 space_color : source_color = vec3(0.008, 0.01, 0.02);
uniform float star_amount : hint_range(0.0, 0.2) = 0.04;
uniform float star_size : hint_range(0.01, 0.3) = 0.09;
uniform float brightness = 1.5;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// 方向ベクトルをグリッドに分割し、各セルに確率的に星を置く。
float starfield(vec3 dir, float scale, float density, float sz) {
	vec3 s = dir * scale;
	vec3 cell = floor(s);
	vec3 f = fract(s) - 0.5;
	float h = hash13(cell);
	if (h < 1.0 - density) {
		return 0.0;
	}
	float twinkle = 0.5 + 0.5 * hash13(cell + 5.0);
	float d = length(f);
	return smoothstep(sz, 0.0, d) * twinkle;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	// 3 層重ねて、大小さまざまな星に奥行きを出す。
	float stars = 0.0;
	stars += starfield(dir, 250.0, star_amount, star_size);
	stars += starfield(dir, 500.0, star_amount * 0.7, star_size * 0.7) * 0.7;
	stars += starfield(dir, 800.0, star_amount * 0.5, star_size * 0.5) * 0.5;
	COLOR = space_color + vec3(stars) * brightness;
}
