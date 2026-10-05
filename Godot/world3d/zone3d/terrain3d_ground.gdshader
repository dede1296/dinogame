shader_type spatial;
// The ground of a 3D zone on Terrain3D (ZoneTerrain, Kind.TERRAIN3D; docs/migration-3d.md, phase 4):
// Terrain3D's shader override. Its vertex() is Terrain3D 1.0.2's own (the clipmap: the mesh follows
// the camera and reads the height maps of the regions, with its levels of detail blended), copied
// as the plugin generates it; its fragment() paints the ground as the home-made mesh does
// (terrain_paint.gdshaderinc, shared), so the cartoon look carries over unchanged: no texture of
// Terrain3D's own (its asset list stays empty), no control map, the 2.5D's ground masks instead.
// The light is the engine's, as on the old ground (no toon steps there either): same roughness,
// same smooth normals (per vertex, from the heights one metre apart, as the old mesh's vertices).
// Terrain3D sets every uniform whose name starts with "_" itself.

render_mode blend_mix, depth_draw_opaque, cull_back, skip_vertex_transform;

uniform vec3 _camera_pos = vec3(0.f);
uniform float _mesh_size = 48.f;
uniform uint _background_mode = 1u;
uniform uint _mouse_layer = 0x80000000u;
uniform float _vertex_spacing = 1.0;
uniform float _vertex_density = 1.0;
uniform float _region_size = 1024.0;
uniform float _region_texel_size = 0.0009765625;
uniform int _region_map_size = 32;
uniform int _region_map[1024];
uniform vec2 _region_locations[1024];
uniform highp sampler2DArray _height_maps : repeat_disable;
uniform highp sampler2DArray _control_maps : repeat_disable;

#include "res://world3d/zone3d/terrain_paint.gdshaderinc"

// metres between the heights the light's normal is worked out from (the old mesh: its 1 m vertices)
uniform float normal_step_m = 1.0;

varying float v_vertex_xz_dist;
varying vec3 v_vertex;
varying vec3 v_normal;     // world space, smooth: from the heights normal_step_m around the vertex

// --- Terrain3D 1.0.2 (src/shaders/main.glsl), unchanged ---

ivec3 get_index_coord(const vec2 uv, const int search) {
	vec2 r_uv = round(uv);
	vec2 o_uv = mod(r_uv, _region_size);
	ivec2 pos;
	int bounds, layer_index = -1;
	for (int i = -1; i < clamp(search, 0, 2); i++) {
		if ((layer_index == -1 && _background_mode == 0u) || i < 0) {
			r_uv -= i == -1 ? vec2(0.0) : vec2(float(o_uv.x <= o_uv.y), float(o_uv.y <= o_uv.x));
			pos = ivec2(floor((r_uv) * _region_texel_size)) + (_region_map_size / 2);
			bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
			layer_index = (_region_map[pos.y * _region_map_size + pos.x] * bounds - 1);
		}
	}
	return ivec3(ivec2(mod(r_uv, _region_size)), layer_index);
}

void vertex() {
	v_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_vertex_xz_dist = length(v_vertex.xz - _camera_pos.xz);
	// Blend the levels of detail into one another (geomorphing).
	float scale = MODEL_MATRIX[0][0];
	float vertex_lerp = smoothstep(0.55, 0.95, (v_vertex_xz_dist / scale - _mesh_size - 4.0) / (_mesh_size - 2.0));
	vec2 v_fract = fract(VERTEX.xz * 0.5) * 2.0;
	vec2 shift = (scale < _vertex_spacing + 1e-6) ?
		mix(v_fract, vec2(v_fract.x, -v_fract.y),
			round(fract(round(mod(v_vertex.z * _vertex_density, 4.0)) *
			round(mod(v_vertex.x * _vertex_density, 4.0)) * 0.25))) :
		v_fract * round((fract(v_vertex.xz * 0.25 / scale) - 0.5) * 4.0);
	vec2 start_pos = v_vertex.xz * _vertex_density;
	vec2 end_pos = (v_vertex.xz - shift * scale) * _vertex_density;
	v_vertex.xz -= shift * scale * vertex_lerp;
	UV = v_vertex.xz * _vertex_density;
	UV2 = fma(UV, vec2(_region_texel_size), vec2(0.5 * _region_texel_size));
	ivec3 v_region = get_index_coord(start_pos, 1);
	uint control = floatBitsToUint(texelFetch(_control_maps, v_region, 0)).r;
	bool hole = bool(control >> 2u & 0x1u);
	v_normal = vec3(0.0, 1.0, 0.0);
	// A hole, or outside the regions with no background: no vertex (NaN culls the triangle).
	if (!(CAMERA_VISIBLE_LAYERS == _mouse_layer) && (hole || (_background_mode == 0u && v_region.z == -1))) {
		v_vertex.x = 0. / 0.;
	} else {
		ivec3 coord_a = get_index_coord(start_pos, 1);
		ivec3 coord_b = get_index_coord(end_pos, 1);
		float h = mix(texelFetch(_height_maps, coord_a, 0).r, texelFetch(_height_maps, coord_b, 0).r, vertex_lerp);
		v_vertex.y = h;
		// ours: the smooth normal of the old mesh (its vertices: the heights 1 m on either side)
		vec2 p = round(v_vertex.xz * _vertex_density);
		float k = max(round(normal_step_m * _vertex_density), 1.0);
		float l = texelFetch(_height_maps, get_index_coord(p - vec2(k, 0.0), 1), 0).r;
		float r = texelFetch(_height_maps, get_index_coord(p + vec2(k, 0.0), 1), 0).r;
		float u = texelFetch(_height_maps, get_index_coord(p - vec2(0.0, k), 1), 0).r;
		float d = texelFetch(_height_maps, get_index_coord(p + vec2(0.0, k), 1), 0).r;
		v_normal = vec3(l - r, 2.0 * k * _vertex_spacing, u - d);
	}
	VERTEX = (VIEW_MATRIX * vec4(v_vertex, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

// --- ours ---

void fragment() {
	// The light's normal: smooth, worked out per vertex (v_normal, as the old mesh's vertex normals).
	// The cliffs' rock follows the drawn face instead.
	NORMAL = normalize(mat3(VIEW_MATRIX) * normalize(v_normal));
	ALBEDO = ground_colour(v_vertex, face_normal(v_vertex));
	ROUGHNESS = 0.95;
}
