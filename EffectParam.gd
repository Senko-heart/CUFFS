class_name EffectParam
extends LoaderHelper

enum EffectType {
	Nothing, TileImage,
	FilterWhite, FilterLight, FilterBlack, FilterDark,
	RasterScroll, WaveCircle, Shimmer, MeshWarp,
	ShadingOff, ShadingLight,
	SmashParticle2D, SmashParticle3D,
}

var type := EffectType.Nothing
var flags := 0
var interval := 0
var degree_step := 0
var shaking_width := 0
var mesh_size := 0
var frequency := 0
var size_view := Vector2i.ZERO
var pt_speed := Vector2i.ZERO
var alpha_range := 0
var ms_per_degree := 0
var pt_smash_point := Vector2i.ZERO
var smash_power := 0.0
var random_power := 0.0
var deceleration := 0.0
var velocity := Vector3.ZERO
var gravity := Vector3.ZERO
var rev_speed := Vector3.ZERO
var rev_random := Vector3.ZERO

func load(dict: Dictionary) -> bool:
	return (
		load_int(dict, &"type")
	and load_int(dict, &"flags")
	and load_int(dict, &"interval")
	and load_int(dict, &"degree_step")
	and load_int(dict, &"shaking_width")
	and load_int(dict, &"mesh_size")
	and load_int(dict, &"frequency")
	and load_vec2i(dict, &"size_view")
	and load_vec2i(dict, &"pt_speed")
	and load_int(dict, &"alpha_range")
	and load_int(dict, &"ms_per_degree")
	and load_vec2i(dict, &"pt_smash_point")
	and load_float(dict, &"smash_power")
	and load_float(dict, &"random_power")
	and load_float(dict, &"deceleration")
	and load_vec3(dict, &"velocity")
	and load_vec3(dict, &"gravity")
	and load_vec3(dict, &"rev_speed")
	and load_vec3(dict, &"rev_random"))

func dump() -> Dictionary:
	return {
		type = type,
		flags = flags,
		interval = interval,
		degree_step = degree_step,
		shaking_width = shaking_width,
		mesh_size = mesh_size,
		frequency = frequency,
		size_view = { x = size_view.x, y = size_view.y },
		pt_speed = { x = pt_speed.x, y = pt_speed.y },
		alpha_range = alpha_range,
		ms_per_degree = ms_per_degree,
		pt_smash_point = { x = pt_smash_point.x, y = pt_smash_point.y },
		smash_power = smash_power,
		random_power = random_power,
		deceleration = deceleration,
		velocity = { x = velocity.x, y = velocity.y, z = velocity.z },
		gravity = { x = gravity.x, y = gravity.y, z = gravity.z },
		rev_speed = { x = rev_speed.x, y = rev_speed.y, z = rev_speed.z },
		rev_random = { x = rev_random.x, y = rev_random.y, z = rev_random.z },
	}
