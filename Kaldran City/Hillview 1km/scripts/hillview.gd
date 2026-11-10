extends Node3D

const LIBRARY = preload("res://scripts/asset_library.gd")
const STREETS = preload("res://scripts/street_geometry.gd")
const LAYOUT = preload("res://scripts/hillview_layout.gd")
const SURVIVOR = preload("res://scripts/survivor.gd")
const INFECTED = preload("res://scripts/infected.gd")
const SEDAN = preload("res://scripts/sedan.gd")
const HUD = preload("res://scripts/hillview_hud.gd")
const QA = preload("res://scripts/hillview_qa.gd")

var library: LIBRARY
var catalog: Dictionary
var streets: STREETS
var land := Node3D.new()
var paving := Node3D.new()
var structures := Node3D.new()
var materials: Dictionary = {}
var scenery: Dictionary = {}
var doors: Array[Node3D] = []
var open_doors: Dictionary = {}
var door_tweens: Dictionary = {}
var sites: Dictionary = {}
var pickups: Array[Dictionary] = []
var player: CharacterBody3D
var sedan: CharacterBody3D
var saved_point := Vector3.ZERO
var map_open := false
var driving := false
var cache_lid: Node3D
var objective := 0
var hud: Control


func _ready() -> void:
	library = LIBRARY.new()
	catalog = library.entries
	land.name = "HillviewTerrain"
	paving.name = "StreetsAndPaths"
	structures.name = "AuthoredDistrict"
	add_child(land)
	add_child(paving)
	add_child(structures)
	_lighting()
	_make_materials()
	streets = STREETS.new(self)
	streets.materials = materials
	streets.bake()
	streets.build_land()
	streets.build_streets()
	LAYOUT.new(self).build()
	streets.finish()
	_backdrop()
	_install_sites()
	_encounter()
	_flush_scenery()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.world = self
	canvas.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	announce("Search the roadside supply case.")
	var args := OS.get_cmdline_user_args()
	if "--verify-hillview" in args:
		await QA.new().run(self)
	else:
		for arg: String in args:
			if arg.begins_with("--capture="):
				_capture(arg.trim_prefix("--capture="),args)


func _lighting() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var air := ShaderMaterial.new()
	air.shader = preload("res://scripts/sky.gdshader")
	air.set_shader_parameter("cloud_density",library.texture("res://content/surfaces/0274.png"))
	sky.sky_material = air
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9bacc4")
	env.ambient_light_energy = 0.57
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#9caeb8")
	env.fog_density = 0.00069
	env.fog_sky_affect = 0.19
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.85
	env.adjustment_contrast = 1.09
	env.ssao_enabled = true
	env.ssao_radius = 1.45
	env.ssao_intensity = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25,-137,0)
	light.light_color = Color("#ffe0b8")
	light.light_energy = 1.38
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	light.directional_shadow_max_distance = 82.0
	add_child(light)


func _material(color: Color, roughness: float, image := "", normals := "", project := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if not image.is_empty():
		mat.albedo_texture = library.texture(image)
	if not normals.is_empty():
		mat.normal_texture = library.texture(normals)
		mat.normal_enabled = mat.normal_texture != null
		mat.normal_scale = 0.48
	if project > 0:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE*project
	return mat


func _make_materials() -> void:
	var external := "res://content/polyhaven/"
	var local := "res://content/surfaces/"
	var pavement := external+"concrete_pavement_03.jpg" if FileAccess.file_exists(external+"concrete_pavement_03.jpg") else local+"0288.png"
	var road := external+"asphalt_track.jpg" if FileAccess.file_exists(external+"asphalt_track.jpg") else local+"0268.png"
	materials["asphalt"] = _material(Color("#91918d"),0.78,road,external+"asphalt_track_normal.jpg")
	materials["paving"] = _material(Color("#acaba4"),0.91,pavement)
	materials["curb"] = _material(Color("#a5a59b"),0.93,local+"0288.png", "",0.45)
	materials["gutter"] = _material(Color("#585d55"),0.83,external+"worn_asphalt.jpg")
	materials["plaza"] = _material(Color("#b6afa1"),0.94,pavement)
	materials["park"] = _material(Color("#a99d81"),0.92,external+"grass_path_2.jpg")
	materials["yellow"] = _material(Color("#bd9c58"),0.76)
	materials["white"] = _material(Color("#c9c6b7"),0.76)
	materials["brick"] = _material(Color("#b99e88"),0.91,external+"brick_wall_001.jpg",external+"brick_wall_001_normal.jpg",0.41)
	materials["stone"] = _material(Color("#bdb3a2"),0.87,local+"0285.png","",0.39)
	materials["plaster"] = _material(Color("#a7a89c"),0.90,local+"0288.png","",0.43)
	materials["foundation"] = _material(Color("#88857a"),0.92,local+"0288.png","",0.55)
	materials["coping"] = _material(Color("#a9a394"),0.92,local+"0288.png","",0.47)
	materials["roof"] = _material(Color("#515554"),0.91,local+"0293.png","",0.34)
	materials["frame"] = _material(Color("#3d4b4f"),0.68)
	materials["glass"] = _material(Color("#445a63"),0.29,local+"0286.png","",0.37)
	materials["glass"].metallic = 0.38
	materials["glass_warm"] = _material(Color("#b29468"),0.39)
	materials["glass_warm"].emission_enabled = true
	materials["glass_warm"].emission = Color("#cb975e")
	materials["glass_warm"].emission_energy_multiplier = 0.38


func at(x: float,z: float,lift := 0.0) -> Vector3:
	return streets.position(x,z,lift)


func _asset(key: String,parent: Node3D) -> Node3D:
	var result := library.instantiate(key)
	if result:
		parent.add_child(result)
	return result


func solid(parent: Node3D,at_position: Vector3,dimensions: Vector3,angle := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at_position
	body.rotation.y = angle
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


func prop(key: String,x: float,z: float,degrees: float,scale_factor: float,blocks: bool) -> Node3D:
	var bounds := library.bounds(key)
	var model := _asset(key,structures) if key == "0328" else Node3D.new()
	if key != "0328":
		structures.add_child(model)
	var center := bounds.get_center()
	var low := Vector3(center.x,bounds.position.y,center.z)
	model.scale = Vector3.ONE*scale_factor
	model.rotation.y = deg_to_rad(degrees)
	model.position = at(x,z,0.018)-model.basis*low
	model.set_meta("asset",key)
	if key != "0328":
		_record_scenery(key,x,z,model.transform)
	if key in ["0021","0147","0237"]:
		var source := library.instantiate(key)
		_collision_parts(source,model,Transform3D.IDENTITY,key)
		source.free()
	elif blocks:
		var size := bounds.size
		size.x = maxf(0.16,size.x*0.93)
		size.z = maxf(0.16,size.z*0.88)
		solid(model,center,size)
	return model


func _collision_parts(source: Node3D,anchor: Node3D,parent: Transform3D,key: String) -> void:
	var pose := parent*source.transform
	if source is MeshInstance3D:
		var label := String(source.name).to_lower()
		var collidable := false
		match key:
			"0021":
				collidable = "glass" in label or "squarepost" in label or "bench_slats" in label
			"0147":
				collidable = "deck_walkable" in label or "wall_canvas" in label or "cot_frame" in label or "table_top" in label
			"0237":
				collidable = "chute" in label or "climber_platform" in label or "slide_platform" in label
		if collidable:
			var shape: ConcavePolygonShape3D = source.mesh.create_trimesh_shape()
			if shape:
				shape.backface_collision = true
				var body := StaticBody3D.new()
				body.transform = pose
				var collider := CollisionShape3D.new()
				collider.shape = shape
				body.add_child(collider)
				anchor.add_child(body)
	for child in source.get_children():
		if child is Node3D:
			_collision_parts(child,anchor,pose,key)


func tree(key: String,x: float,z: float,size: float) -> void:
	var variant := key
	if x < -152 or x > 113:
		variant = "alder_far" if key == "alder" else "plane_far"
	prop(variant,x,z,0,size,false)
	solid(structures,at(x,z,0.93),Vector3(0.47,1.86,0.47))


func wood(key: String,x: float,z: float,size: float) -> void:
	var bounds := library.bounds(key)
	var angle := sin(x*1.7+z*1.3)*PI
	var basis := Basis(Vector3.UP,angle).scaled_local(Vector3.ONE*size)
	var origin := at(x,z)-basis*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	_record_scenery(key,x,z,Transform3D(basis,origin))
	solid(structures,at(x,z,0.8),Vector3(0.38,1.6,0.38))


func _record_scenery(key: String,x: float,z: float,pose: Transform3D) -> void:
	var cell := "%s:%d:%d" % [key,floori(x/90),floori(z/90)]
	if not scenery.has(cell):
		scenery[cell] = {"key":key,"poses":[],"shadow":absf(z)<107 and absf(x)<155}
	scenery[cell]["poses"].append(pose)


func _flush_scenery() -> void:
	for item: Dictionary in scenery.values():
		var mesh := library.static_mesh(item["key"])
		if mesh and mesh.get_surface_count() > 0:
			instances(structures,mesh,item["poses"],item["shadow"])
	scenery.clear()


func instances(parent: Node3D,mesh: Mesh,transforms: Array,shadows: bool) -> void:
	var batch := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i,transforms[i])
	batch.multimesh = mm
	if not shadows:
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(batch)


func sign(words: String,where: Vector3,degrees: float,pixel: float,freestanding: bool) -> void:
	var basis := Basis(Vector3.UP,deg_to_rad(degrees)+PI)
	var plaque := Label3D.new()
	plaque.text = words
	plaque.pixel_size = pixel
	plaque.font_size = 24
	plaque.outline_size = 6
	plaque.modulate = Color("#f5e4bc")
	plaque.outline_modulate = Color("#212d2e")
	plaque.position = where+basis.z*0.055
	plaque.basis = basis
	plaque.no_depth_test = false
	plaque.double_sided = false
	structures.add_child(plaque)
	var span := ThemeDB.fallback_font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x*pixel+0.26
	var height := pixel*33+0.13
	var panel := BoxMesh.new()
	panel.size = Vector3(span,height,0.09)
	panel.material = materials["frame"]
	instances(structures,panel,[Transform3D(basis,where)],true)
	if freestanding:
		var posts := BoxMesh.new()
		var y := where.y-at(where.x,where.z).y
		posts.size = Vector3(0.067,maxf(0.4,y),0.067)
		posts.material = materials["frame"]
		var foot := where-Vector3.UP*y*0.51
		instances(structures,posts,[Transform3D(basis,foot+basis.x*span*0.34),Transform3D(basis,foot-basis.x*span*0.34)],true)


func _backdrop() -> void:
	for row: Array in [[-2800,-3480,177,0.86],[920,-4110,164,0.93],[4270,-3900,147,0.89]]:
		var model := _asset("0001",land)
		if model:
			model.position = Vector3(row[0],-18,row[1])
			model.rotation.y = deg_to_rad(row[2])
			model.scale = Vector3.ONE*float(row[3])


func _install_sites() -> void:
	for data: Array in [["apartment",-52.0,13.0],["shop",-16.0,13.0]]:
		var site := _asset(data[0],structures)
		assert(site != null)
		site.position = at(data[1],data[2],0.025)
		sites[data[0]] = site
		for node in site.find_children("HINGE*", "Node3D", true, false):
			doors.append(node)
			var internal: bool = data[0] == "apartment" and node.name != "HINGE_Lobby"
			open_doors[node] = internal
			node.rotation.y = 1.66 if internal else 0.0
			for body in node.find_children("*","AnimatableBody3D",true,false):
				body.sync_to_physics = false
		if data[0] == "apartment":
			var paving_shape := site.get_node("COL_Structure/COL_EntryPaving") as CollisionShape3D
			var longer := paving_shape.shape.duplicate() as BoxShape3D
			longer.size.z += 0.50
			paving_shape.shape = longer
			paving_shape.position.z += 0.25
		else:
			site.get_node("VIS_Shutter_Closed").hide()
			site.get_node("VIS_Shutter_Raised").show()
			site.get_node("COL_Shutter/CollisionShape3D").disabled = true
		_entry_ramp(site)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffd6a0")
		lamp.light_energy = 1.25
		lamp.omni_range = 6.1
		lamp.position = Vector3(0,2.72,2.3)
		site.add_child(lamp)


func _entry_ramp(site: Node3D) -> void:
	var outer := site.position.z-5.4
	var entry := site.position.z-1.95
	var rise := site.position.y-at(site.position.x,outer).y
	var length := entry-outer
	var body := solid(site,Vector3(0,-rise*0.5-0.077,-3.675),Vector3(2.25,0.15,sqrt(length*length+rise*rise)))
	body.rotation.x = -atan2(rise,length)
	var mesh := BoxMesh.new()
	mesh.size = body.get_child(0).shape.size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = materials["paving"]
	body.add_child(node)


func _encounter() -> void:
	saved_point = at(-69.2,7.12,0.08)
	player = SURVIVOR.new()
	player.city = self
	player.position = saved_point
	add_child(player)
	sedan = SEDAN.new()
	sedan.world = self
	sedan.position = at(-57.3,2.52,0.055)
	sedan.rotation.y = -PI*0.5
	add_child(sedan)
	var supply := prop("0328",-65.2,8.8,0,1,false)
	var hinge := supply.find_child("SOCKET_LidHinge",true,false) as Node3D
	cache_lid = _asset("cache_lid",hinge if hinge else supply)
	_pickup("cache","Search supply case",supply,false)
	var shop := sites["shop"] as Node3D
	var medical := _asset("medkit",shop)
	medical.position = Vector3(-0.75,0.08,3.68)
	_pickup("market","Collect the market medical kit",medical,true)
	var apartment := sites["apartment"] as Node3D
	var dress := _asset("dressing",apartment)
	dress.position = Vector3(0.77,0.12,5.15)
	_pickup("apartment","Take a field dressing",dress,true)
	var aid := prop("crate",253.7,20.0,0,0.83,false)
	_pickup("aid","Deliver the medical kit",aid,false)
	for p: Vector2 in [Vector2(84,-46),Vector2(105,-68),Vector2(199,-12),Vector2(239,21)]:
		var unit := INFECTED.new()
		unit.city = self
		unit.position = at(p.x,p.y,0.06)
		add_child(unit)


func _pickup(key: String,caption: String,node: Node3D,hide_on_use: bool) -> void:
	pickups.append({"key":key,"caption":caption,"node":node,"hide":hide_on_use,"used":false})


func _focus() -> Dictionary:
	var result := {}
	var best := 2.30
	var from := player.global_position+Vector3.UP*0.58
	for row: Dictionary in pickups:
		if row["used"]:
			continue
		var anchor: Vector3 = row["node"].global_position+Vector3.UP*0.36
		var distance := from.distance_to(anchor)
		if distance < best and _visible(from,anchor):
			best = distance
			result = row
	for door: Node3D in doors:
		var distance := from.distance_to(door.global_position+Vector3.UP*0.55)
		if distance < best:
			best = distance
			result = {"key":"door","node":door,"caption":"Close door" if open_doors[door] else "Open door"}
	var handle: Vector3 = sedan.to_global(Vector3(-1.27,0.68,-0.28))
	if from.distance_to(handle) < minf(2.15,best) and absf(sedan.speed_mps)<0.72 and _visible(from,handle):
		result = {"key":"sedan","caption":"Enter sedan"}
	return result


func _visible(from: Vector3,to: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(from,to,1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or Vector3(hit["position"]).distance_to(to)<0.22


func interact() -> void:
	if driving:
		_exit_sedan()
		return
	var focus := _focus()
	if focus.is_empty():
		return
	match focus["key"]:
		"door":
			set_door(focus["node"],not open_doors[focus["node"]])
		"sedan":
			_enter_sedan()
		"cache":
			player.equip_loot()
			objective = maxi(1,objective)
			if cache_lid:
				create_tween().tween_property(cache_lid,"rotation:x",1.15,0.30)
			_use(focus,"Crowbar and field dressing collected.")
		"market":
			if objective < 1:
				announce("Search the roadside case first.")
				return
			player.medkits += 1
			objective = maxi(2,objective)
			_use(focus,"Medical kit recovered. Head east to the aid station.")
		"apartment":
			player.dressings += 1
			_use(focus,"Field dressing collected.")
		"aid":
			if objective < 2:
				announce("Recover the medical kit from Northline Market first.")
				return
			objective = 3
			saved_point = player.global_position
			_use(focus,"Supplies delivered. Hillview route secured.")


func _use(entry: Dictionary,text: String) -> void:
	entry["used"] = true
	if entry["hide"]:
		entry["node"].hide()
	announce(text)


func set_door(door: Node3D,value: bool) -> void:
	open_doors[door] = value
	if door_tweens.has(door):
		door_tweens[door].kill()
	var angle := -1.65 if door.name in ["HINGE_Door","HINGE_Lobby"] else 1.66
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	door_tweens[door] = tween
	tween.tween_property(door,"rotation:y",angle if value else 0.0,0.35)


func _enter_sedan() -> void:
	driving = true
	sedan.occupied = true
	player.velocity = Vector3.ZERO
	player.collision_layer = 0
	player.collision_mask = 0
	player.hide()
	sedan.camera.make_current()
	sedan.swing_driver_door()
	announce("WASD to drive. Space to brake. Stop to exit.")


func _exit_sedan() -> void:
	if absf(sedan.speed_mps)>0.72:
		announce("Stop the sedan before exiting.")
		return
	var shape := CapsuleShape3D.new()
	shape.height = 1.75
	shape.radius = 0.29
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1|4
	query.exclude = [sedan.get_rid(),player.get_rid()]
	for side: float in [-1,1]:
		var door_pos: Vector3 = sedan.to_global(Vector3(side*2.0,0,-0.22))
		var ground := at(door_pos.x,door_pos.z,0.06)
		query.transform = Transform3D(Basis.IDENTITY,ground+Vector3.UP*0.96)
		if not _visible(sedan.global_position+Vector3.UP,ground+Vector3.UP):
			continue
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			player.global_position = ground
			player.collision_layer = 2
			player.collision_mask = 1|4
			player.show()
			player.camera.make_current()
			sedan.occupied = false
			driving = false
			sedan.swing_driver_door()
			return
	announce("Both sides are blocked.")


func toggle_map() -> void:
	map_open = not map_open
	if map_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		player.recapture_mouse()
	hud.queue_redraw()


func announce(text: String) -> void:
	if hud:
		hud.notice(text)


func _physics_process(_delta: float) -> void:
	if driving:
		player.global_position = sedan.global_position
	elif player and player.global_position.y < -38.0:
		player.global_position = saved_point
		player.velocity = Vector3.ZERO


func _capture(path: String,args: PackedStringArray) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.yaw = -1.50
	player.pitch = -0.115
	if "--map" in args:
		toggle_map()
	if "--park-view" in args:
		_preview_view(at(47,-12,3.0),at(78,-53,1.0))
	if "--market-view" in args:
		_preview_view(at(-27,2.6,2.4),at(-18,13,2.2))
	var status := await _save_view(path,3.0)
	if "--gallery" in args and status == OK:
		var stem := path.get_basename()
		_preview_view(at(-27,2.6,2.4),at(-18,13,2.2))
		status = await _save_view(stem+"-market.png",1.25)
		_preview_view(at(47,-12,3.0),at(78,-53,1.0))
		status = maxi(status,await _save_view(stem+"-park.png",1.25))
		toggle_map()
		status = maxi(status,await _save_view(stem+"-map.png",0.45))
	get_tree().quit(status)


func _preview_view(eye: Vector3,target: Vector3) -> void:
	var view := Camera3D.new()
	add_child(view)
	view.global_position = eye
	view.look_at(target)
	view.fov = 64
	view.far = 7600
	view.make_current()


func _save_view(path: String,delay: float) -> int:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var status := get_viewport().get_texture().get_image().save_png(path)
	print("HILLVIEW_CAPTURE ",status," ",path," fps=",Engine.get_frames_per_second(),
		" draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return status
