extends Node3D

const SURVIVOR = preload("res://scripts/survivor.gd")
const INFECTED = preload("res://scripts/infected.gd")
const MAP = preload("res://scripts/city_map.gd")
const TERRAIN_SHADER = preload("res://scripts/terrain.gdshader")
const SKY_SHADER = preload("res://scripts/sky.gdshader")
const TILE := 250
const GRID := 1025
const STEP := 7.8125
const HALF := 4000.0
const DETAIL_RADIUS := 2

var city: Dictionary
var catalog: Dictionary
var pack_index: Dictionary
var elevations: PackedFloat32Array
var player: CharacterBody3D
var sedan: CharacterBody3D
var level_root := Node3D.new()
var tiles := {}
var pending: Array[Vector2i] = []
var packed_scenes := {}
var roads := {}
var terrain_material: ShaderMaterial
var shades := {}
var textures := {}
var tile_key := Vector2i(-1, -1)
var map_screen: Control
var hud: Label
var message: Label
var prompt: Label
var notice_time := 0.0
var map_open := false
var missions_done := {}
var saved_point := Vector3.ZERO
var door_states := {}
var cache_lid: Node3D
var cache_object: Node3D
var loot_available := true
var drive_speed := 0.0
var driving := false
var drive_camera: Camera3D
var special_doors: Array[Node3D] = []
var interactive_sites := {}
var walking_camera: Camera3D
var test_mode := false
var field_camera: Camera3D
var camera_index := -1
var travelling := false
var stream_focus := Vector3.ZERO


func _ready() -> void:
	test_mode = "--verify-city" in OS.get_cmdline_user_args()
	city = _json("city")
	catalog = _json("catalog")
	pack_index = _json("pack_index")
	elevations = FileAccess.get_file_as_bytes("res://data/elevation.bin").to_float32_array()
	assert(elevations.size() == GRID * GRID)
	_make_lighting()
	_make_materials()
	add_child(level_root)
	level_root.name = "StreamedDistricts"
	_make_horizon()
	_make_lakes()
	_make_distant_buildings()
	var origin: Array = city["spawn"]
	saved_point = grounded(float(origin[0]) - 2.0, float(origin[1]) + 7.0, 0.12)
	_update_stream(saved_point, true)
	_make_special_sites()
	_make_survival_encounter()
	_make_story_details()
	_make_ui()
	if "--verify-sites" in OS.get_cmdline_user_args():
		_verify_sites()
	elif test_mode:
		_verify()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-city="):
			_capture(arg.trim_prefix("--capture-city="))


func _json(stem: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + stem + ".json"))
	assert(raw is Dictionary, "Cannot load city data " + stem)
	return raw


func _make_lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	sky_mat.set_shader_parameter("cloud_density",_surface("0274"))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d0d5e1")
	env.ambient_light_energy = 0.66
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#b6bec6")
	env.fog_density = 0.00030
	env.fog_sky_affect = 0.23
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-29, -124, 0)
	sun.light_color = Color("#ffe5cb")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 175.0
	add_child(sun)


func _material(col: Color, roughness := 0.9, texture: Texture2D = null) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = col
	material.roughness = roughness
	material.albedo_texture = texture
	return material


func _surface(key: String) -> Texture2D:
	if textures.has(key):
		return textures[key]
	var row: Dictionary = pack_index.get(key, {})
	if row.has("surface"):
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(row["surface"])) == OK:
			image.generate_mipmaps()
			var texture := ImageTexture.create_from_image(image)
			textures[key] = texture
			return texture
	return null


func _make_materials() -> void:
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = TERRAIN_SHADER
	terrain_material.set_shader_parameter("aggregate", _surface("0288"))
	shades["asphalt"] = _material(Color("#66676d"), 0.82, _surface("0268"))
	shades["paving"] = _material(Color("#85847b"), 0.92, _surface("0288"))
	shades["yellow"] = _material(Color("#d7ae57"))
	shades["white"] = _material(Color("#cdcbb9"))
	shades["steel"] = _material(Color("#43484d"), 0.40)
	shades["ballast"] = _material(Color("#64605c"), 0.93, _surface("0302"))
	shades["water"] = _material(Color("#466978"), 0.30)
	shades["water"].metallic = 0.22
	shades["water"].cull_mode = BaseMaterial3D.CULL_DISABLED
	shades["stone"] = _material(Color("#abaaa1"), 0.78, _surface("0285"))
	shades["plaster"] = _material(Color("#a29a87"), 0.9, _surface("0288"))
	shades["glass"] = _material(Color("#72909a"), 0.28, _surface("0286"))
	shades["window"] = _material(Color("#344956"), 0.27)
	shades["industrial"] = _material(Color("#7c827d"), 0.78, _surface("0293"))
	shades["lit"] = _material(Color("#c5a975"), 0.48)
	shades["lit"].emission_enabled = true
	shades["lit"].emission = Color("#ad783e")
	shades["lit"].emission_energy_multiplier = 0.42
	shades["warm_stone"] = _material(Color("#a39782"), 0.84, _surface("0271"))
	shades["skyline"] = _material(Color("#697880"), 0.62, _surface("0281"))


func sample(x: float, z: float) -> float:
	var ix := clampf((x + HALF) / STEP, 0, GRID - 1.00001)
	var iz := clampf((z + HALF) / STEP, 0, GRID - 1.00001)
	var a := int(ix)
	var b := int(iz)
	var u := ix - a
	var v := iz - b
	var index := b * GRID + a
	if u + v <= 1.0:
		return elevations[index] * (1.0 - u - v) + elevations[index + 1] * u + elevations[index + GRID] * v
	return elevations[index + GRID + 1] * (u + v - 1.0) + elevations[index + 1] * (1.0 - v) + elevations[index + GRID] * (1.0 - u)


func grounded(x: float, z: float, lift := 0.0) -> Vector3:
	return Vector3(x, sample(x, z) + lift, z)


func _terrain(parent: Node3D, gx: int, gz: int, n: int, step: int, collision: bool, lowered := 0.0) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for j in range(n + 1):
		for i in range(n + 1):
			var ix := gx + i * step
			var iz := gz + j * step
			var x := float(ix) * STEP - HALF
			var z := float(iz) * STEP - HALF
			var h := elevations[iz * GRID + ix]
			vertices.append(Vector3(x, h - lowered, z))
			var speckle := (sin(x * 0.036) * cos(z * 0.027) + sin((x + z) * 0.019)) * 0.045
			var grass := Color(0.205 + speckle, 0.32 + speckle, 0.16 + speckle * 0.70)
			var rock := Color(0.45, 0.46, 0.45)
			var treeline := clampf((h - 114.0) / 143.0, 0, 0.9) * clampf((-z - 750.0) / 2200.0, 0, 1)
			colors.append(grass.lerp(rock, treeline))
	for j in range(n):
		for i in range(n):
			var a := j * (n + 1) + i
			var b := a + n + 1
			indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
	var mesh := _mesh(vertices, indices, colors)
	var visual := _mesh_node(parent, mesh, terrain_material)
	if collision:
		visual.create_trimesh_collision()


func _mesh(vertices: PackedVector3Array, indices: PackedInt32Array, colors := PackedColorArray()) -> ArrayMesh:
	var normal := PackedVector3Array()
	normal.resize(vertices.size())
	var uv := PackedVector2Array()
	for v in vertices:
		uv.append(Vector2(v.x, v.z) / 5.0)
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var direction := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		normal[a] += direction
		normal[b] += direction
		normal[c] += direction
	for i in normal.size():
		normal[i] = normal[i].normalized()
	var data := []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = vertices
	data[Mesh.ARRAY_NORMAL] = normal
	data[Mesh.ARRAY_TEX_UV] = uv
	data[Mesh.ARRAY_INDEX] = indices
	if not colors.is_empty():
		data[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	return mesh


func _mesh_node(parent: Node3D, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node


func _make_horizon() -> void:
	_terrain(self, 0, 0, 128, 8, false, 8.5)
	var ridges := Node3D.new()
	add_child(ridges)
	for i in range(4):
		var x := -6700.0 + i * 4100.0
		_prop(ridges, ["0001", x, -6350.0 - (i % 2) * 710.0, 180 + (i % 3) * 10, 1.1], false, 65.0)


func _make_lakes() -> void:
	for row: Array in city["lakes"]:
		var polygon := PackedVector2Array()
		var vertices := PackedVector3Array()
		for p: Array in row[0]:
			polygon.append(Vector2(float(p[0]), float(p[1])))
			vertices.append(Vector3(float(p[0]), float(row[1]), float(p[1])))
		var triangles := Geometry2D.triangulate_polygon(polygon)
		if not triangles.is_empty():
			_mesh_node(self, _mesh(vertices, triangles), shades["water"])


func _tile_for(point: Vector3) -> Vector2i:
	return Vector2i(clampi(floori((point.x + HALF) / TILE), 0, 31), clampi(floori((point.z + HALF) / TILE), 0, 31))


func _update_stream(center: Vector3, immediate := false) -> void:
	var focus := _tile_for(center)
	if focus == tile_key and not immediate:
		return
	tile_key = focus
	var wanted := {}
	for dz in range(-DETAIL_RADIUS, DETAIL_RADIUS + 1):
		for dx in range(-DETAIL_RADIUS, DETAIL_RADIUS + 1):
			var cell := focus + Vector2i(dx, dz)
			if cell.x >= 0 and cell.y >= 0 and cell.x < 32 and cell.y < 32:
				wanted[cell] = absi(dx) + absi(dz)
	for cell: Vector2i in tiles.keys():
		if not wanted.has(cell):
			tiles[cell].queue_free()
			tiles.erase(cell)
	pending.clear()
	for cell: Vector2i in wanted:
		if not tiles.has(cell):
			pending.append(cell)
	pending.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return wanted[a] < wanted[b])
	if immediate:
		while not pending.is_empty() and wanted[pending[0]] <= 1:
			_load_tile(pending.pop_front())


func _load_tile(cell: Vector2i) -> void:
	var parent := Node3D.new()
	parent.name = "District_%d_%d" % [cell.x, cell.y]
	level_root.add_child(parent)
	tiles[cell] = parent
	_terrain(parent, cell.x * 32, cell.y * 32, 32, 1, true)
	var record: Dictionary = city["chunks"].get("%d_%d" % [cell.x, cell.y], {})
	if record.is_empty():
		return
	_make_routes(parent, record["routes"])
	_make_buildings(parent, record["buildings"], true)
	for asset: Array in record["props"]:
		if asset[0] == "0164" and Vector2(asset[1], asset[2]).distance_to(Vector2(city["spawn"][0], city["spawn"][1])) < 10:
			continue
		_prop(parent, asset)
	for tree: Array in record["groves"]:
		_prop(parent, tree, false)


func _ribbon(surface: SurfaceTool, points: Array, width: float, offset: float, y_offset: float, elevations_override: Array = []) -> void:
	var section := []
	for i in range(points.size() - 1):
		var a: Array = points[i]
		var b: Array = points[i+1]
		var count := maxi(1, ceili(Vector2(a[0],a[1]).distance_to(Vector2(b[0],b[1])) / 5.2))
		for j in count:
			var f := float(j) / count
			var y := INF if elevations_override.is_empty() else lerpf(elevations_override[i], elevations_override[i+1], f)
			section.append([Vector2(lerpf(a[0],b[0],f), lerpf(a[1],b[1],f)), y])
	var last: Array = points[-1]
	section.append([Vector2(last[0], last[1]), INF if elevations_override.is_empty() else elevations_override[-1]])
	var prev := []
	var columns := maxi(1, ceili(width / 4.0))
	for i in section.size():
		var center: Vector2 = section[i][0]
		var delta: Vector2 = section[mini(i+1, section.size()-1)][0] - section[maxi(i-1,0)][0]
		var side := Vector2(-delta.y, delta.x).normalized()
		var row := []
		for k in range(columns+1):
			var p := center + side * (offset + (float(k)/columns - 0.5) * width)
			var y: float = section[i][1]
			row.append(grounded(p.x, p.y, y_offset) if is_inf(y) else Vector3(p.x, y+y_offset, p.y))
		if not prev.is_empty():
			for k in columns:
				for v: Vector3 in [prev[k], row[k], row[k+1], prev[k], row[k+1], prev[k+1]]:
					surface.set_normal(Vector3.UP)
					surface.set_uv(Vector2(v.x,v.z) / 5.0)
					surface.add_vertex(v)
		prev = row


func _make_routes(parent: Node3D, records: Array) -> void:
	var surfaces := {}
	for name in ["asphalt", "paving", "yellow", "white", "steel", "ballast", "water"]:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[name] = surface
	var used := {}
	for route: Array in records:
		var kind: String = route[1]
		var width: float = route[2]
		var points: Array = route[3]
		if kind == "water":
			_ribbon(surfaces["water"], points, width, 0, 0.01, route[4])
			used["water"] = true
			continue
		if kind == "bridge":
			_make_bridge(parent, points, route[4], width)
			continue
		if kind == "walk":
			_ribbon(surfaces["paving"], points, width, 0, 0.09)
			used["paving"] = true
			continue
		if kind == "rail":
			_ribbon(surfaces["ballast"], points, width, 0, 0.08)
			for offset: float in [-2.7, -1.2, 1.2, 2.7]:
				_ribbon(surfaces["steel"], points, 0.13, offset, 0.15)
			used["steel"] = true
			used["ballast"] = true
			continue
		var pad := 0.16 if route[0] == "HV" else 0.12
		_ribbon(surfaces["asphalt"], points, width, 0, pad)
		used["asphalt"] = true
		if kind != "runway" and kind != "expressway":
			for offset: float in [-1.0, 1.0]:
				_ribbon(surfaces["paving"], points, 2.4, offset * (width * 0.5 + 1.2), pad-0.015)
			used["paving"] = true
		var mark := "white" if kind == "runway" else "yellow"
		for i in range(points.size() - 1):
			var a: Array = points[i]
			var b: Array = points[i+1]
			var ax := lerpf(a[0],b[0],0.15)
			var az := lerpf(a[1],b[1],0.15)
			var bx := lerpf(a[0],b[0],0.56)
			var bz := lerpf(a[1],b[1],0.56)
			_ribbon(surfaces[mark], [[ax,az],[bx,bz]], 0.95 if kind == "runway" else 0.14, 0, pad+0.035)
		if kind == "runway" or width >= 20.0:
			for side: float in [-1.0,1.0]:
				_ribbon(surfaces["white"], points, 0.38 if kind == "runway" else 0.11, side * (width*0.5-0.45), pad+0.028)
			used["white"] = true
		used[mark] = true
	for name: String in used:
		var mesh: ArrayMesh = surfaces[name].commit()
		if mesh and mesh.get_surface_count() > 0:
			_mesh_node(parent, mesh, shades[name])


func _make_bridge(parent: Node3D, points: Array, heights: Array, width: float) -> void:
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ribbon(deck, points, width+1.6, 0, 0.05, heights)
	var node := _mesh_node(parent, deck.commit(), shades["asphalt"])
	node.create_trimesh_collision()
	var rails := SurfaceTool.new()
	rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mid: Array = points[1]
	var end: Array = points[2]
	var center := Vector2((mid[0]+end[0])*0.5,(mid[1]+end[1])*0.5)
	var axis := Vector2(end[0]-mid[0],end[1]-mid[1]).normalized()
	var side := Vector2(-axis.y,axis.x)
	var angle := atan2(axis.x,axis.y)
	for sign: float in [-1.0,1.0]:
		var xz := center + side * (sign*(width*0.5+0.38))
		var position := Vector3(xz.x,float(heights[1])+0.47,xz.y)
		_add_box(parent,position,Vector3(0.25,0.83,Vector2(mid[0],mid[1]).distance_to(Vector2(end[0],end[1]))),angle)
		_batch(parent,[Transform3D(Basis(Vector3.UP,angle).scaled_local(Vector3(0.25,0.83,68.0)),position)],shades["steel"])
	_ribbon(rails, points, 0.15, 0, 0.085, heights)
	_mesh_node(parent,rails.commit(),shades["yellow"])


func _cached_scene(key: String) -> PackedScene:
	if packed_scenes.has(key):
		var existing: PackedScene = packed_scenes[key]
		packed_scenes.erase(key)
		packed_scenes[key] = existing
		return existing
	if not packed_scenes.has(key) and catalog.has(key):
		var path: String = catalog[key]["path"]
		packed_scenes[key] = _runtime_scene(path)
		if packed_scenes.size() > 90:
			packed_scenes.erase(packed_scenes.keys().front())
	return packed_scenes.get(key) as PackedScene


func _runtime_scene(path: String) -> PackedScene:
	if not path.ends_with(".glb"):
		return load(path) as PackedScene
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path, state) != OK:
		push_error("Could not load model " + path)
		return null
	var model := document.generate_scene(state)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var geometry: ArrayMesh = mesh.mesh as ArrayMesh
		if geometry == null:
			continue
		for surface in geometry.get_surface_count():
			var material := geometry.surface_get_material(surface) as StandardMaterial3D
			if material and material.normal_enabled and (geometry.surface_get_format(surface) & Mesh.ARRAY_FORMAT_TANGENT) == 0:
				var fallback := material.duplicate() as StandardMaterial3D
				fallback.normal_enabled = false
				geometry.surface_set_material(surface,fallback)
	var packed := PackedScene.new()
	var error := packed.pack(model)
	model.free()
	return packed if error == OK else null


func _asset(key: String, parent: Node3D) -> Node3D:
	var packed := _cached_scene(key)
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	parent.add_child(model)
	return model


func _prop(parent: Node3D, row: Array, collision := true, explicit_y := INF) -> Node3D:
	var key: String = row[0]
	if not catalog.has(key):
		return null
	var bounds: Array = catalog[key]["bounds"]
	var model := _asset(key, parent)
	if model == null:
		return null
	var ratio: float = row[4]
	model.scale = Vector3.ONE * ratio
	model.rotation.y = deg_to_rad(row[3])
	var center := Vector3((bounds[0]+bounds[3])*0.5,bounds[1],(bounds[2]+bounds[5])*0.5)
	var p := grounded(row[1], row[2], 0.035)
	if not is_inf(explicit_y):
		p.y = explicit_y
	model.position = p - model.basis * center
	var size := Vector3(bounds[3]-bounds[0], bounds[4]-bounds[1], bounds[5]-bounds[2])
	if collision and size.y > 0.65:
		if key in ["0040","0139"]:
			for child in model.find_children("*","MeshInstance3D",true,false):
				var bounds_mesh: AABB = child.get_aabb()
				if bounds_mesh.size.y >= 0.65 and maxf(bounds_mesh.size.x,bounds_mesh.size.z) > 0.35:
					var fence_size := bounds_mesh.size
					fence_size.x = maxf(fence_size.x,0.14)
					fence_size.z = maxf(fence_size.z,0.14)
					_add_box(child,bounds_mesh.get_center(),fence_size)
		elif key in ["0043","0085","0097","0111","0112","0126","0127","0133","0329","0330","0237","0007"]:
			for child in model.find_children("*", "MeshInstance3D", true, false):
				child.create_trimesh_collision()
		elif size.y > 1.0 and minf(size.x,size.z) > 0.55:
			_add_box(model, center + Vector3.UP * size.y * 0.46, Vector3(size.x,maxf(0.6,size.y * 0.92),size.z))
	return model


func _add_box(parent: Node3D, at: Vector3, size: Vector3, angle := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation.y = angle
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	parent.add_child(body)
	return body


func _batch(parent: Node3D, transforms: Array, material: Material, near := true) -> void:
	if transforms.is_empty():
		return
	var unit := BoxMesh.new()
	unit.size = Vector3.ONE
	unit.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = unit
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = multimesh
	if not near:
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(batch)


func _make_buildings(parent: Node3D, buildings: Array, near: bool) -> void:
	var batches := {"stone": [], "warm_stone": [], "plaster": [], "glass": [], "skyline": [], "industrial": [], "window": [], "steel": [], "lit": []}
	for b: Array in buildings:
		var pos := grounded(b[1], b[2], -0.8)
		var width: float = b[3]
		var depth: float = b[4]
		var floors: int = b[5]
		var angle := deg_to_rad(b[6])
		var use: String = b[7]
		var style := ("glass" if near else "skyline") if use in ["commercial","office","mixed"] and floors >= 6 else ("industrial" if use in ["industrial","warehouse"] else ("warm_stone" if use in ["civic","institutional","government","academic"] else "plaster"))
		var basis := Basis(Vector3.UP, angle)
		var height := maxf(3.5, floors * 3.35)
		var size := Vector3(width, height, depth)
		if not near:
			size -= Vector3(0.45,0.55,0.45)
		batches[style].append(Transform3D(basis.scaled_local(size), pos + Vector3.UP * height * 0.5))
		if not near:
			continue
		_add_box(parent, pos + Vector3.UP * height * 0.5, size, angle)
		batches["steel"].append(Transform3D(basis.scaled_local(Vector3(width+0.4,0.42,depth+0.4)), pos + Vector3.UP * height))
		for story in range(floors):
			var y := 1.75 + story * 3.35
			var windows := clampi(floori(width / 4.6), 2, 16)
			for i in windows:
				var x := ((float(i)+0.5)/windows - 0.5) * width
				var panel := "lit" if (story * 37 + i * 7 + int(absf(pos.x))) % 31 == 0 else "window"
				for sign: float in [-1.0,1.0]:
					var where := pos + basis * Vector3(x,y,sign*(depth*0.5+0.04))
					batches[panel].append(Transform3D(basis.scaled_local(Vector3(width/windows*0.69,1.55,0.11)), where))
			var sides := clampi(floori(depth / 5.0), 2, 14)
			for i in sides:
				var z := ((float(i)+0.5)/sides-0.5)*depth
				for sign: float in [-1.0,1.0]:
					var where := pos + basis * Vector3(sign*(width*0.5+0.04),y,z)
					batches["window"].append(Transform3D(basis.scaled_local(Vector3(0.11,1.55,depth/sides*0.63)),where))
	for key: String in batches:
		_batch(parent, batches[key], shades[key], near)


func _make_distant_buildings() -> void:
	var all := []
	for chunk: Dictionary in city["chunks"].values():
		all.append_array(chunk["buildings"])
	_make_buildings(self, all, false)


func _make_special_sites() -> void:
	for entry: Array in city["special"]:
		var site := _asset(entry[0], self)
		if site == null:
			continue
		interactive_sites[entry[0]] = site
		site.position = Vector3(entry[1], entry[2], entry[3])
		site.rotation.y = deg_to_rad(entry[4])
		var assembly: Dictionary = catalog[entry[0]].get("children", {})
		for key: String in assembly:
			var path: String = assembly[key]
			if not packed_scenes.has(path):
				packed_scenes[path] = _runtime_scene(path)
			var model: PackedScene = packed_scenes[path]
			var parent := site.get_node_or_null(key)
			if model and parent:
				parent.add_child(model.instantiate())
		for node in site.find_children("*", "Node3D", true, false):
			if String(node.name).begins_with("HINGE"):
				special_doors.append(node)
				if entry[0] == "apartment" and String(node.name) != "HINGE_Lobby":
					node.rotation.y = 1.66
					door_states[node] = true
		if entry[0] == "shop":
			var closed := site.get_node_or_null("VIS_Shutter_Closed") as Node3D
			var raised := site.get_node_or_null("VIS_Shutter_Raised") as Node3D
			var collider := site.get_node_or_null("COL_Shutter/CollisionShape3D") as CollisionShape3D
			if closed:
				closed.hide()
			if raised:
				raised.show()
			if collider:
				collider.disabled = true
		else:
			_fit_apartment_entry(site)


func _fit_apartment_entry(site: Node3D) -> void:
	var apron := site.get_node("COL_Structure/COL_EntryPaving") as CollisionShape3D
	var shape := apron.shape.duplicate() as BoxShape3D
	shape.size.z += 0.50
	apron.shape = shape
	apron.position.z += 0.25
	var low := site.to_global(Vector3(0,0,-6.7))
	var local_y := site.to_local(grounded(low.x,low.z,0.025)).y
	var ramp := StaticBody3D.new()
	var length := 3.80
	ramp.position = Vector3(0,local_y*0.5-0.09,-4.81)
	ramp.rotation.x = atan2(local_y,length)
	site.add_child(ramp)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.7,0.18,sqrt(length*length+local_y*local_y))
	var visual := _mesh_node(ramp,mesh,shades["paving"])
	var collider := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = mesh.size
	collider.shape = ramp_shape
	ramp.add_child(collider)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _make_survival_encounter() -> void:
	player = SURVIVOR.new()
	player.city = self
	player.position = saved_point
	add_child(player)
	walking_camera = player.camera
	var x: float = city["spawn"][0]
	var z: float = city["spawn"][1]
	cache_object = Node3D.new()
	cache_object.position = grounded(x-6.0,z+11.0,0.06)
	add_child(cache_object)
	_asset("0328",cache_object)
	cache_lid = _asset("cache_lid",cache_object)
	sedan = CharacterBody3D.new()
	sedan.position = grounded(x+7.5,z-2.0,0.14)
	sedan.rotation.y = deg_to_rad(-45)
	sedan.collision_layer = 4
	sedan.collision_mask = 1
	sedan.floor_snap_length = 0.7
	var shell := _asset("0164", sedan)
	if shell:
		shell.position.y = -float(catalog["0164"]["bounds"][1])
	var chassis := CollisionShape3D.new()
	var hull := BoxShape3D.new()
	var contract: Dictionary = city["vehicle"]
	hull.size = Vector3(contract["overall_width_excluding_mirrors_m"],1.24,contract["overall_length_m"])
	chassis.position.y = 0.64
	chassis.shape = hull
	sedan.add_child(chassis)
	drive_camera = Camera3D.new()
	drive_camera.position = Vector3(0,3.05,6.4)
	drive_camera.rotation.x = -0.25
	drive_camera.far = 10000
	sedan.add_child(drive_camera)
	add_child(sedan)
	for offset: Vector2 in [Vector2(22,-18),Vector2(-22,-29),Vector2(35,9),Vector2(-13,35)]:
		var infected := INFECTED.new()
		infected.city = self
		infected.position = grounded(x+offset.x,z+offset.y,0.08)
		add_child(infected)


func _point(id: String) -> Array:
	for item: Array in city["points"]:
		if item[0] == id:
			return item
	return []


func _ground_decal(key: String, x: float, z: float, width: float) -> void:
	var image := _surface(key)
	if image == null:
		return
	var sprite := Sprite3D.new()
	sprite.texture = image
	sprite.pixel_size = width / image.get_width()
	sprite.position = grounded(x,z,0.21)
	sprite.rotation.x = -PI*0.5
	sprite.shaded = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.19
	add_child(sprite)


func _make_story_details() -> void:
	var origin: Array = city["spawn"]
	_ground_decal("0276",origin[0]-4.0,origin[1]+6.0,2.7)
	_ground_decal("0278",origin[0]-8.0,origin[1]+14.0,0.58)
	for id: String in ["P05","P07","P11","P12"]:
		var poi := _point(id)
		var light := OmniLight3D.new()
		light.name = "EmergencyPocket_" + id
		light.position = grounded(poi[2]+5.0,poi[3]+1.5,3.3)
		light.light_color = Color("#f2bc6b")
		light.light_energy = 2.3
		light.omni_range = 13.5
		add_child(light)


func cycle_camera() -> void:
	if driving or map_open:
		return
	var shots: Array = city["camera_shots"]
	camera_index += 1
	if camera_index >= shots.size():
		camera_index = -1
		walking_camera.make_current()
		_update_stream(player.global_position,true)
		return
	if field_camera == null:
		field_camera = Camera3D.new()
		field_camera.far = 11500.0
		add_child(field_camera)
	var shot: Dictionary = shots[camera_index]
	var origin := _point(shot["poi"])
	if origin.is_empty():
		return
	var eye: Array = shot["camera_offset_m"]
	var target: Array = shot["look_at_offset_m"]
	var pos := grounded(origin[2]+eye[0],origin[3]+eye[2],maxf(1.3,eye[1]))
	field_camera.global_position = pos
	field_camera.look_at(grounded(origin[2]+target[0],origin[3]+target[2],target[1]))
	field_camera.fov = rad_to_deg(2*atan(18.0/float(shot["focal_length_mm"])))
	field_camera.make_current()
	_update_stream(pos,true)
	announce(shot["name"] + " · C next view")


func interact() -> void:
	if driving:
		if absf(drive_speed) > 0.8:
			announce("Stop the sedan before exiting")
			return
		for side in [-1,1]:
			var p := sedan.to_global(Vector3(2.2 * side,0,0.2))
			var ray := PhysicsRayQueryParameters3D.create(sedan.global_position+Vector3.UP, p+Vector3.UP, 1)
			if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				continue
			player.global_position = grounded(p.x,p.z,0.06)
			player.collision_layer = 2
			player.collision_mask = 1|4
			player.show()
			walking_camera.make_current()
			driving = false
			announce("Exited sedan")
			return
		announce("No room to exit")
		return
	if player.global_position.distance_to(cache_object.global_position) < 2.35 and loot_available:
		loot_available = false
		player.equip_loot()
		if cache_lid:
			create_tween().tween_property(cache_lid,"rotation:x",-1.30,0.25)
		announce("Found crowbar, field dressing and medkit")
		return
	var nearest: Node3D
	var distance := 2.35
	for hinge: Node3D in special_doors:
		var d := (player.global_position+Vector3.UP*0.4).distance_to(hinge.global_position)
		if d < distance:
			distance = d
			nearest = hinge
	if nearest:
		var is_open: bool = not door_states.get(nearest,false)
		door_states[nearest] = is_open
		var angle := -1.64 if String(nearest.name) in ["HINGE_Door","HINGE_Lobby"] else 1.62
		create_tween().tween_property(nearest,"rotation:y",angle if is_open else 0.0,0.36)
		return
	if player.global_position.distance_to(sedan.global_position) < 3.1:
		driving = true
		player.collision_layer = 0
		player.collision_mask = 0
		player.hide()
		drive_camera.make_current()
		announce("WASD drive · Space brake · E exit")


func _make_ui() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)
	hud = Label.new()
	hud.position = Vector2(24,18)
	hud.add_theme_font_size_override("font_size",19)
	hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(hud)
	message = Label.new()
	message.anchor_top = 0.88
	message.anchor_bottom = 0.88
	message.anchor_right = 1.0
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",22)
	message.add_theme_color_override("font_shadow_color",Color.BLACK)
	message.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(message)
	prompt = Label.new()
	prompt.anchor_top = 0.76
	prompt.anchor_bottom = 0.76
	prompt.anchor_right = 1.0
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size",22)
	prompt.add_theme_color_override("font_color",Color("#ffd589"))
	prompt.add_theme_color_override("font_shadow_color",Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(prompt)
	map_screen = MAP.new()
	map_screen.city = self
	overlay.add_child(map_screen)
	map_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_screen.hide()
	announce("Hillview Steps  ·  search the cache by the road  ·  M opens the city map")


func announce(text: String) -> void:
	if message:
		message.text = text
		notice_time = 4.5


func toggle_map() -> void:
	map_open = not map_open
	map_screen.visible = map_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_open else Input.MOUSE_MODE_CAPTURED
	if map_open:
		map_screen.queue_redraw()


func travel(point: Array) -> void:
	if travelling:
		return
	if driving:
		announce("Exit the sedan before fast travel")
		return
	travelling = true
	var landing: Vector3 = await _safe_landing(point)
	travelling = false
	if not landing.is_finite():
		_update_stream(player.global_position,true)
		announce("No clear landing near " + point[1])
		return
	saved_point = landing
	camera_index = -1
	walking_camera.make_current()
	player.velocity = Vector3.ZERO
	player.global_position = saved_point
	missions_done[point[0]] = true
	toggle_map()
	announce(point[1])


func _safe_landing(point: Array) -> Vector3:
	var x: float = point[2]
	var z: float = point[3]
	if point[0] == "P06":
		x -= 2.0
		z += 7.0
		stream_focus = grounded(x,z)
	else:
		stream_focus = grounded(x,z-38.0)
	_update_stream(stream_focus,true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var shape := CapsuleShape3D.new()
	shape.radius = 0.31
	shape.height = 1.82
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1|4
	query.exclude = [player.get_rid()]
	var offsets := [Vector2.ZERO] if point[0] == "P06" else []
	for radius: float in [38.0,62.0,86.0,120.0]:
		for angle: float in [0.0,PI*0.5,PI,PI*1.5,PI*0.25,PI*0.75,PI*1.25,PI*1.75]:
			offsets.append(Vector2(sin(angle),-cos(angle))*radius)
	for offset: Vector2 in offsets:
		var base := grounded(x+offset.x,z+offset.y)
		if absf(base.x) > 3985 or absf(base.z) > 3985:
			continue
		var cast := PhysicsRayQueryParameters3D.create(base+Vector3.UP*2.4,base-Vector3.UP*1.8,1)
		var ground := get_world_3d().direct_space_state.intersect_ray(cast)
		if ground.is_empty() or Vector3(ground["normal"]).y < 0.82 or absf(Vector3(ground["position"]).y-base.y) > 0.55:
			continue
		query.transform = Transform3D(Basis.IDENTITY,Vector3(ground["position"])+Vector3.UP*0.99)
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			return Vector3(ground["position"])+Vector3.UP*0.12
	return Vector3.INF


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if driving:
		var input := float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
		var steer := float(Input.is_physical_key_pressed(KEY_A))-float(Input.is_physical_key_pressed(KEY_D))
		var goal := input * (17.0 if input > 0 else 5.4)
		if map_open or Input.is_physical_key_pressed(KEY_SPACE):
			goal = 0.0
		drive_speed = move_toward(drive_speed, goal, delta * (13.0 if absf(goal) < 0.1 else 5.0))
		sedan.rotation.y += steer * delta * clampf(drive_speed/5.0,-1.25,1.25)
		var direction := -sedan.global_basis.z
		sedan.velocity.x = direction.x * drive_speed
		sedan.velocity.z = direction.z * drive_speed
		sedan.velocity.y = -2.0 if sedan.is_on_floor() else sedan.velocity.y-15.0*delta
		sedan.move_and_slide()
		player.global_position = sedan.global_position
	var center := player.global_position
	var focus := stream_focus if travelling else (field_camera.global_position if camera_index >= 0 and field_camera else center)
	_update_stream(focus)
	if not pending.is_empty():
		_load_tile(pending.pop_front())
	if center.y < -110 or absf(center.x) > 3998 or absf(center.z) > 3998:
		if driving:
			sedan.position = saved_point + Vector3.RIGHT * 2.5
			sedan.velocity = Vector3.ZERO
			drive_speed = 0.0
		player.global_position = saved_point
		player.velocity = Vector3.ZERO
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			message.text = ""
	if hud:
		var closest := "Kaldran"
		var best := INF
		for district: Array in city["districts"]:
			var d := Vector2(center.x,center.z).distance_squared_to(Vector2(district[2],district[3]))
			if d < best:
				best = d
				closest = district[1]
		for point: Array in city["points"]:
			if Vector2(center.x,center.z).distance_to(Vector2(point[2],point[3])) < 65.0:
				missions_done[point[0]] = true
		hud.text = "P R O J E C T   Z    /    %s\nHP %03d    ·    E interact    ·    H heal    ·    M city map\n%s" % [
			closest.to_upper(),player.health,"%.0f km/h" % (absf(drive_speed)*3.6) if driving else "WASD move  ·  Shift sprint  ·  Space jump  ·  LMB swing"]
		prompt.text = _nearby_action()


func _nearby_action() -> String:
	if map_open or camera_index >= 0:
		return ""
	if driving:
		return "E  ·  Exit sedan" if absf(drive_speed) <= 0.8 else ""
	var position := player.global_position
	if loot_available and position.distance_to(cache_object.global_position) < 2.35:
		return "E  ·  Search supply cache"
	for hinge: Node3D in special_doors:
		if (position+Vector3.UP*0.4).distance_to(hinge.global_position) < 2.35:
			return "E  ·  Close door" if door_states.get(hinge,false) else "E  ·  Open door"
	if position.distance_to(sedan.global_position) < 3.1:
		return "E  ·  Enter sedan"
	return ""


func _capture(output: String) -> void:
	await get_tree().create_timer(1.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output)
	get_tree().quit()


func _verify() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var errors := []
	if city["districts"].size() != 21 or city["points"].size() != 24 or city["footprints"] != 1766:
		errors.append("Masterplan count mismatch")
	if pack_index.size() != 228 or city["arterials"] != 20 or city["rail_lines"] != 2:
		errors.append("Pack or transport count mismatch")
	var ground := PhysicsRayQueryParameters3D.create(saved_point+Vector3.UP*5,saved_point-Vector3.UP*5,1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ground)
	if hit.is_empty():
		errors.append("Hillview terrain collision missing")
	if special_doors.size() < 2:
		errors.append("Apartment and shop hinges not imported")
	if not is_instance_valid(cache_lid) or player.get_node_or_null("Look/Arm/Camera3D") == null:
		errors.append("Survival encounter missing")
	# Verify the real capsule under Godot physics on the authored street section.
	player.set_physics_process(false)
	var origin: Array = city["spawn"]
	var road_center := Vector2(origin[0]-28.28,origin[1]+28.28)
	var road_side := Vector2(0.70710678,0.70710678)
	var start := road_center-road_side*7.0
	player.global_position = grounded(start.x,start.y,0.15)
	player.velocity = Vector3.ZERO
	for i in range(12):
		await get_tree().physics_frame
		player.velocity.y = -1
		player.move_and_slide()
	var road_pass := await _verify_walk(Vector3(road_side.x,0,road_side.y),175)
	road_pass = await _verify_walk(Vector3(-road_side.x,0,-road_side.y),175) and road_pass
	if not road_pass:
		errors.append("Capsule could not cross and return from Hillview road shoulder")
	player.global_position = saved_point
	player.set_physics_process(true)
	for i in range(16):
		await get_tree().physics_frame
	var ground_y: float = player.global_position.y
	player.jump_requested = true
	for i in range(10):
		await get_tree().physics_frame
	var jump_pass: bool = player.global_position.y > ground_y + 0.30
	if not jump_pass:
		errors.append("Survivor jump did not clear the ground")
	player.set_physics_process(false)
	player.global_position = cache_object.global_position + Vector3.BACK
	interact()
	var loot_pass: bool = player.armed and player.dressings == 1 and player.medkits == 1 and not loot_available
	if not loot_pass:
		errors.append("Crowbar cache or healing inventory did not activate")
	player.global_position = sedan.global_position+Vector3.RIGHT*2.0
	interact()
	var sedan_pass := driving
	var car_origin := sedan.global_position
	var throttle := InputEventKey.new()
	throttle.physical_keycode = KEY_W
	throttle.pressed = true
	Input.parse_input_event(throttle)
	for i in range(32):
		await get_tree().physics_frame
	var release := throttle.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	sedan_pass = sedan_pass and sedan.global_position.distance_to(car_origin) > 0.24
	for i in range(36):
		await get_tree().physics_frame
	interact()
	sedan_pass = sedan_pass and not driving
	if not sedan_pass:
		errors.append("Sedan boarding or exit did not complete")
	var door_pass := false
	for hinge: Node3D in special_doors:
		if String(hinge.name) == "HINGE_Door":
			player.global_position = hinge.global_position+Vector3.BACK
			interact()
			await get_tree().create_timer(0.42).timeout
			door_pass = absf(hinge.rotation.y) > 1.0 and absf(hinge.rotation.x) < 0.01
			break
	if not door_pass:
		errors.append("Shop door did not swing on its vertical hinge")
	var entry_tests := {}
	for site_key: String in ["apartment","shop"]:
		var site: Node3D = interactive_sites[site_key]
		var hinge: Node3D = site.get_node("HINGE_Lobby" if site_key == "apartment" else "HINGE_Door")
		var center_x := 0.0 if site_key == "apartment" else -0.14
		player.global_position = site.to_global(Vector3(center_x,0.10,-1.8))
		player.velocity = Vector3.ZERO
		if not door_states.get(hinge,false):
			interact()
			await get_tree().create_timer(0.42).timeout
		var forward := site.global_basis.z.normalized()
		var entered := await _verify_walk(forward,61,2.8,3.7)
		entry_tests[site_key] = entered and site.to_local(player.global_position).z > 0.8
		if not entry_tests[site_key]:
			print("ENTRY DEBUG ", site_key, " position=", site.to_local(player.global_position), " hinge=", hinge.rotation, " floor=", player.is_on_floor())
			for i in player.get_slide_collision_count():
				var contact: KinematicCollision3D = player.get_slide_collision(i)
				print("ENTRY CONTACT ", contact.get_collider(), " ", contact.get_collider_shape(), " ", contact.get_normal())
			errors.append(site_key + " entry blocked under capsule physics")
	var apartment: Node3D = interactive_sites["apartment"]
	player.global_position = apartment.to_global(Vector3(-1,0.13,8.82))
	player.velocity = Vector3.ZERO
	var stair_pass := await _verify_walk(apartment.global_basis.z.normalized(),78,2.65,4.4)
	stair_pass = stair_pass and apartment.to_local(player.global_position).y > 1.45
	if not stair_pass:
		print("STAIR DEBUG ",apartment.to_local(player.global_position)," floor=",player.is_on_floor())
		for i in player.get_slide_collision_count():
			var contact: KinematicCollision3D = player.get_slide_collision(i)
			print("STAIR CONTACT ",contact.get_collider_shape()," ",contact.get_normal())
		errors.append("Apartment stair collision did not reach the mid-landing")
	print("KALDRAN_VERIFY ", JSON.stringify({"districts":city["districts"].size(),"landmarks":city["points"].size(),"footprints":city["footprints"],
		"pack_count":pack_index.size(),"tiles_loaded":tiles.size(),"doors":special_doors.size(),"terrain_hit":not hit.is_empty(),
		"bridges":city["bridge_count"],"road_walk":road_pass,"jump":jump_pass,"loot":loot_pass,"sedan":sedan_pass,"door":door_pass,"entries":entry_tests,"stairs":stair_pass,"errors":errors}))
	get_tree().quit(0 if errors.is_empty() else 1)


func _verify_walk(direction: Vector3, frames: int, minimum := 12.0, speed := 4.9) -> bool:
	var start: Vector3 = player.global_position
	for i in range(frames):
		await get_tree().physics_frame
		player.velocity = direction * speed + Vector3.DOWN * 1.8
		player.move_and_slide()
	return (player.global_position-start).dot(direction) > minimum and player.is_on_floor()


func _verify_sites() -> void:
	var unreachable := []
	travelling = true
	for point: Array in city["points"]:
		var landing: Vector3 = await _safe_landing(point)
		if not landing.is_finite():
			unreachable.append(point[0])
			continue
		player.global_position = landing
		print("KALDRAN_SITE ",point[0]," ",point[1]," ",landing)
	print("KALDRAN_SITES ",JSON.stringify({"landmarks":city["points"].size(),"verified":city["points"].size()-unreachable.size(),"missing":unreachable}))
	get_tree().quit(0 if unreachable.is_empty() else 1)
