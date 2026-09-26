// Scenery standing in the 3D world (MultiMesh of quads): trees, bushes, flowers, tall grass.
// Lit as if rounded (a foliage ball, a rock), darker at the foot, so it has volume.
// Always faces the camera (also when casting shadows), upright; sways in the wind; the top
// leans away when Chloé walks through; a tall one turns see-through when it hides her.
// Per instance (INSTANCE_CUSTOM): x = flipped, y = scale, z = shake (a tree searched),
// w = lift in metres (a stone turned over).
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float stretch = 1.15;        // upright pictures seen from above look squashed
uniform float sway = 0.0;            // metres of sway at the top
uniform float push = 0.0;            // metres Chloé pushes the top away
uniform float push_radius = 0.9;
uniform float stiffness = 2.0;       // higher = only the very top bends
uniform bool occluder = false;       // tall: see-through when it hides Chloé
uniform float half_width = 1.0;      // metres, for the see-through test
uniform float roundness = 0.0;       // 0 flat (a sign), ~0.8 a tree crown or a bush
uniform float base_shade = 0.25;     // how much darker the foot is
global uniform vec3 player_world;
global uniform vec3 sun_dir;         // towards the sun (or the moon), world space
global uniform float sun_light;      // 0 (overcast night) to 1 (bright sun)

varying float hide;
varying vec3 v_right;
varying vec3 v_facing;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	if (INSTANCE_CUSTOM.x > 0.5) {
		UV.x = 1.0 - UV.x;
	}
	VERTEX.xy *= INSTANCE_CUSTOM.y;
	VERTEX.y *= stretch;
	float top = pow(clamp(1.0 - UV.y, 0.0, 1.0), stiffness);
	float s = sin(TIME * 1.3 + origin.x * 0.62 + origin.z * 0.34) * sway
		+ sin(TIME * 3.5 + origin.x * 2.4) * sway * 0.25;
	vec2 d = origin.xz - player_world.xz;
	float near = 1.0 - smoothstep(0.0, push_radius, length(d));
	VERTEX.x += (s + (d.x >= 0.0 ? 1.0 : -1.0) * near * push) * top;
	VERTEX.x += INSTANCE_CUSTOM.z * sin(TIME * 42.0) * 0.16 * (0.3 + top);
	VERTEX.y += INSTANCE_CUSTOM.w;

	// Face the main camera (in the shadow pass too, so shadows match), stay upright.
	vec3 right = normalize(vec3(MAIN_CAM_INV_VIEW_MATRIX[0].x, 0.0, MAIN_CAM_INV_VIEW_MATRIX[0].z));
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 facing = normalize(cross(right, up));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(up, 0.0), vec4(facing, 0.0), vec4(origin, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	v_right = right;
	v_facing = facing;

	// See-through when Chloé stands just behind it (the camera looks towards -z).
	hide = 0.0;
	if (occluder) {
		float in_front = origin.z - player_world.z;
		hide = step(0.2, in_front) * (1.0 - step(9.0, in_front))
			* (1.0 - step(half_width * 0.8 + 0.5, abs(origin.x - player_world.x)));
	}
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (hide > 0.5 && mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), 2.0) < 1.0) {
		discard;
	}
	// Volume: a rounded normal (left/right and top/bottom lean away), lit by the sun.
	vec2 q = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	vec3 nl = normalize(vec3(q.x * roundness, (q.y * 0.55 + 0.35) * roundness, 1.0));
	vec3 nw = normalize(v_right * nl.x + vec3(0.0, 1.0, 0.0) * nl.y + v_facing * nl.z);
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	// Darker at the foot and deep inside, lighter at the edges the light catches.
	float inner = textureLod(tex, UV, 4.0).a;
	float shade = mix(1.0 - base_shade, 1.0, smoothstep(0.0, 0.35, 1.0 - UV.y));
	shade *= mix(1.06, 0.92, inner * roundness);
	// The side facing the sun (or the moon) brighter, the other darker: follows the hour.
	shade *= 1.0 + roundness * 0.3 * sun_light * dot(nw, sun_dir);
	ALBEDO = c.rgb * shade;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
