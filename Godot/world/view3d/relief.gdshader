// Fixed scenery in relief (MultiMesh of meshes made by tools/modeles3d/reliefs.py): the
// scenery's own picture, laid on a mesh shaped by its depth, so from the front it is the
// picture exactly, and it has volume, parallax, real occlusion and shadows. Lit like the
// pictures (billboard.gdshader: same normal, same darker foot), except that the side facing
// the sun follows the mesh's own faces. Per instance (INSTANCE_CUSTOM), as the pictures:
// x = flipped, y = scale, z = shake (searched), w = lift in metres (turned over).
// Also the real 3D models (Prop.KINDS "model", one material per painted surface); a prop
// mirrored as its model is a single mesh: no custom data (its node flips it), `opacity`.
// A house with a door that opens (world/view3d/doors.gd): its body and its leaves, each a single
// mesh too.
// With a normal map (reliefs: tools/modeles3d/reliefs.py; models: baked, tangent space), the
// side facing the sun follows the map's shape instead, and the details (bricks, tiles, planks,
// cracks) catch the sun or the moon more strongly: only how much they lean away from the
// shape around them, so they stand out without the whole being brighter or darker; the hollows
// (ao_tex) likewise darker only than what surrounds them.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform bool occluder = false;       // tall: see-through when it hides Chloé
uniform float half_width = 1.0;      // metres, for the see-through test
uniform float roundness = 0.5;       // how much the sun follows the mesh's faces
uniform float base_shade = 0.25;     // how much darker the foot is
// Models (painted atlas: UV says nothing of the height): the foot measured on the mesh, over
// this height (m); 0: over the picture (reliefs, UV.y).
uniform float foot_height = 0.0;
// Normal map: 0 none; 1 in the picture's frame (reliefs: x right, y up, z towards the camera,
// the whole normal); 2 in the mesh's tangent frame (models, glTF).
uniform int normal_mode = 0;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform sampler2D ao_tex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform bool has_ao = false;
uniform float detail = 0.5;          // how strongly the details catch the light
uniform float cavity = 1.0;          // how much darker the hollows are (ao_tex)
uniform float blur_lod = 4.0;        // the shape around the details: the maps at this mip level
instance uniform float opacity = 1.0; // a mirrored prop fading out (its modulate.a)
global uniform vec3 player_world;
global uniform vec3 sun_dir;         // towards the sun (or the moon), world space
global uniform float sun_light;      // 0 (overcast night) to 1 (bright sun)

varying float hide;
varying vec3 v_normal;               // the mesh's own normal, world space
varying vec3 v_tangent;              // its tangent frame, world space (models' normal maps)
varying vec3 v_binormal;
varying float v_flip;
varying float v_up;                  // 0 at the foot, 1 from 35 % of the height up (darker foot)

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_flip = 1.0;
	v_up = foot_height > 0.0 ? clamp(VERTEX.y / foot_height, 0.0, 1.0) : 1.0 - UV.y;
	if (INSTANCE_CUSTOM.x > 0.5) {   // mirrored, as a picture flipped
		VERTEX.x = -VERTEX.x;
		NORMAL.x = -NORMAL.x;
		TANGENT.x = -TANGENT.x;
		BINORMAL.x = -BINORMAL.x;
		v_flip = -1.0;
	}
	VERTEX *= INSTANCE_CUSTOM.y > 0.0 ? INSTANCE_CUSTOM.y : 1.0;   // (0: a single mesh)
	float top = clamp(1.0 - UV.y, 0.0, 1.0);
	VERTEX.x += INSTANCE_CUSTOM.z * sin(TIME * 42.0) * 0.16 * (0.3 + top);
	VERTEX.y += INSTANCE_CUSTOM.w;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_tangent = normalize((MODEL_MATRIX * vec4(TANGENT, 0.0)).xyz);
	v_binormal = normalize((MODEL_MATRIX * vec4(BINORMAL, 0.0)).xyz);

	// See-through when Chloé stands just behind it (the camera looks towards -z).
	hide = 0.0;
	if (occluder) {
		float in_front = origin.z - player_world.z;
		hide = step(0.2, in_front) * (1.0 - step(9.0, in_front))
			* (1.0 - step(half_width * 0.8 + 0.5, abs(origin.x - player_world.x)));
	}
}

// A normal map's texel as a vector (z rebuilt: the map may keep only x and y).
vec3 unpack_normal(vec4 texel) {
	vec2 xy = texel.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

// A normal of the map in world space: in the picture's frame (flipped with the picture) or in
// the mesh's tangent frame.
vec3 map_to_world(vec3 n, mat4 model) {
	if (normal_mode == 1) {
		return (model * vec4(n.x * v_flip, n.y, n.z, 0.0)).xyz;
	}
	return normalize(v_tangent) * n.x + normalize(v_binormal) * n.y + normalize(v_normal) * n.z;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (hide > 0.5 && mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), 2.0) < 1.0) {
		discard;
	}
	// Fading: fewer and fewer of its pixels (still solid, so never mis-sorted).
	if (opacity < 1.0 && fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715)))) >= opacity) {
		discard;
	}
	// The light as on a picture: level, towards the camera (see billboard.gdshader), so it is
	// exactly as bright as the scenery around it.
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 facing = normalize(cross(right, vec3(0.0, 1.0, 0.0)));
	NORMAL = normalize((VIEW_MATRIX * vec4(facing, 0.0)).xyz);
	float shade = mix(1.0 - base_shade, 1.0, smoothstep(0.0, 0.35, v_up));
	// The side facing the sun (or the moon) brighter, the other darker: its real faces (the
	// normal map's, finer, when it has one).
	vec3 n = v_normal;
	float relief = 0.0;
	if (normal_mode > 0) {
		// Its shape: the map blurred (the mesh's normal is coarser). Its details: how much more
		// they lean towards the sun than the shape around them (only sideways, so they average
		// out: never brighter or darker as a whole).
		vec3 fine = unpack_normal(texture(normal_tex, UV));
		vec3 around = unpack_normal(textureLod(normal_tex, UV, blur_lod));
		n = normalize(map_to_world(around, MODEL_MATRIX));
		vec3 lean = map_to_world(vec3(fine.xy - around.xy, 0.0), MODEL_MATRIX);
		relief = clamp(detail * sun_light * dot(lean, sun_dir), -0.5, 0.5);
	}
	shade *= (1.0 + roundness * 0.3 * sun_light * dot(n, sun_dir)) * (1.0 + relief);
	if (has_ao) {
		// Hollows darker than what surrounds them (not the whole thing).
		float ao = texture(ao_tex, UV).r;
		float ao_around = max(textureLod(ao_tex, UV, blur_lod).r, 0.05);
		shade *= mix(1.0, clamp(ao / ao_around, 0.0, 1.5), cavity);
	}
	ALBEDO = c.rgb * shade;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
