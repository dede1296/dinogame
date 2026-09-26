// Soft cloud shadows drifting over the whole region (multiplied over everything below).
shader_type canvas_item;
render_mode blend_mul;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 wind = vec2(14.0, 6.0);   // world px per second
uniform float darkness = 0.16;
uniform float scale = 1100.0;          // world px per noise repeat
uniform float coverage = 0.55;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float n = texture(noise_tex, (world - wind * TIME) / scale).r;
	float cloud = smoothstep(coverage, coverage + 0.2, n);
	COLOR = vec4(vec3(1.0 - cloud * darkness), 1.0);
}
