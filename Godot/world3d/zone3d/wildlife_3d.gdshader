// The little life of a 3D zone (wildlife_3d.gd), drawn in batches (one MultiMesh per kind):
// a painted picture of a few cells side by side (the 2.5D's, assets/art/fauna), one cell per
// instance (INSTANCE_CUSTOM.x), turned to the camera by the CPU (Wildlife3D._card);
// - wings: the butterfly, flat, its two wings beating about its body (INSTANCE_CUSTOM.y: how far
//   up they are, radians). Its 2.5D picture is only a white shape of two discs to tint: its wings
//   are drawn here instead — a forewing reaching forward, a smaller hindwing, a black rim with white
//   spots, a dark body — in its tint;
// - swarm: a swarm's specks (mosquitoes) moved and turned to the camera here alone: each instance is
//   one speck of the swarm INSTANCE_CUSTOM.x (its middle and size: `swarms`), circling it on its own
//   rhythm (INSTANCE_CUSTOM.yzw), its cells flickering.
// COLOR: the instance's tint.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float frames = 1.0;
uniform float glow = 0.0;      // lit from within too (out at night)
uniform bool wings = false;
uniform bool swarm = false;
uniform vec4 swarms[16];       // xyz: a swarm's middle (world), w: its specks' size (0: not out)
uniform float cloud = 0.35;    // m: how far the specks go round the middle
uniform float fps = 24.0;

const vec3 INK = vec3(0.07, 0.05, 0.04);
const vec3 SPOT = vec3(1.0, 0.98, 0.92);

void vertex() {
	if (swarm) {
		vec4 s = swarms[int(INSTANCE_CUSTOM.x + 0.5)];
		vec3 seed = INSTANCE_CUSTOM.yzw;
		vec3 at = s.xyz + vec3(sin(TIME * (1.7 + seed.x * 1.6) + seed.y * 6.283),
			sin(TIME * (2.3 + seed.y * 1.9) + seed.z * 6.283) * 0.6,
			cos(TIME * (1.9 + seed.z * 1.4) + seed.x * 6.283)) * cloud * (0.45 + 0.55 * seed.z);
		vec3 right = MAIN_CAM_INV_VIEW_MATRIX[0].xyz * s.w;
		vec3 up = MAIN_CAM_INV_VIEW_MATRIX[1].xyz * s.w;
		vec3 back = MAIN_CAM_INV_VIEW_MATRIX[2].xyz * s.w;
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(back, 0.0), vec4(at, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
		UV.x = (UV.x + floor(mod(TIME * fps + seed.x * 13.0, frames))) / frames;
	} else if (wings) {
		float side = VERTEX.x < 0.0 ? -1.0 : 1.0;
		float r = abs(VERTEX.x);
		float a = INSTANCE_CUSTOM.y;
		VERTEX = vec3(side * r * cos(a), r * sin(a), VERTEX.z);
		NORMAL = normalize(vec3(-side * sin(a), cos(a), 0.0));
	} else {
		UV.x = (UV.x + floor(INSTANCE_CUSTOM.x + 0.5)) / frames;
	}
}

// A white spot of radius `r` at `at` (the wing's own coordinates).
float spot(vec2 q, vec2 at, float r) {
	return 1.0 - smoothstep(r * 0.7, r, distance(q, at));
}

void fragment() {
	if (wings) {
		// q.x: 0 at the body, 1 at the wing's tip; q.y: 0 at the head, 1 at the tail
		vec2 q = vec2(abs(UV.x - 0.5) * 2.0, UV.y);
		vec2 f = q - vec2(0.48, 0.36);
		f.y += f.x * 0.35;                       // (its tip reaching forward)
		float fore = length(f / vec2(0.5, 0.25));
		float hind = length((q - vec2(0.36, 0.7)) / vec2(0.34, 0.22));
		float e = min(fore, hind);
		bool body = q.x < 0.06 && q.y > 0.12 && q.y < 0.9;
		if (e > 1.0 && !body) {
			discard;
		}
		vec3 col = COLOR.rgb * mix(0.7, 1.0, smoothstep(0.0, 0.35, q.x));   // darker by the body
		float rim = smoothstep(0.8, 0.86, fore < hind ? fore : hind);
		col = mix(col, INK, rim);
		col = mix(col, INK, (1.0 - smoothstep(0.0, 0.025, abs(fore - hind))) * step(e, 0.95));   // between the two wings
		float spots = max(max(spot(q, vec2(0.84, 0.17), 0.045), spot(q, vec2(0.93, 0.29), 0.04)), spot(q, vec2(0.6, 0.27), 0.05));
		col = mix(col, SPOT, spots * step(fore, 1.0));
		if (body) {
			col = INK * 1.6;
		}
		ALBEDO = col;
		ROUGHNESS = 1.0;
		SPECULAR = 0.1;
		EMISSION = col * glow;
	} else {
		vec4 c = texture(tex, UV);
		vec3 col = c.rgb * COLOR.rgb;
		ALBEDO = col;
		ALPHA = c.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
		ROUGHNESS = 0.9;
		SPECULAR = 0.2;
		EMISSION = col * glow;
	}
}
