extends Node3D

const MODELS := preload("res://scripts/neighborhood/neighborhood_assets.gd")
const CATALOG := preload("res://scripts/neighborhood/neighborhood_catalog.gd")
const INTERACTION := preload("res://scripts/neighborhood/neighborhood_interaction.gd")
const APARTMENT := "res://assets/buildings/points_of_interest/pz_032_midrise_apartment_shell/"
const STOREFRONT := "res://assets/buildings/modular_architecture/pz_013_brick_storefront_facade/PROJECT_Z_BrickStorefront.glb"
const CURB_KIT := "res://assets/roads/streets/pz_042_sidewalk_curb_and_ramp_kit/"
const PROPS := "res://assets/pilot/hillview/"
const BENCH := "res://assets/props/interiors_and_street_props/pz_122_street_bench_and_trash_can/PZ_StreetBench.glb"
const SHELF := "res://assets/props/interiors_and_street_props/pz_119_supermarket_shelf_kit/PZ_Market_Stocked_Shelf_2m.glb"
const DINING_TABLE := "res://assets/props/interiors_and_street_props/pz_115_dining_table_and_chair/PZ_Dining_Kitchen_Table.glb"

# Measured against the installed PZ-042 ramp and the two original facade openings.
const PAVEMENT_Y := 0.15
const FACADE_Z := 4.75
const SIDEWALK_LEFT := -4.0
const SIDEWALK_RIGHT := 29.0
const CURB_DEPTH := 0.245
const SHOP_X := -0.156
const LOBBY_X := 10.82
const STOREY_HEIGHT := 3.15
const STOREYS := 3
const STAIR_SHIFT := 7.4
const STAIR_FRONT := 9.95
const STAIR_BACK := 14.24
const STAIR_LEFT := 0.6
const STAIR_RIGHT := 4.33

var models: MODELS
var palette: Dictionary


func build(model_library: MODELS, materials: Dictionary) -> void:
	models = model_library
	palette = materials
	_build_sidewalk()
	_build_lobby()
	_build_shop()
	_build_street_dressing()


func _build_sidewalk() -> void:
	var start := SIDEWALK_LEFT
	for opening in [SHOP_X, LOBBY_X]:
		_build_curb_run(start, opening - 1.0)
		# The PZ-042 module rises along local -Z. Its low end meets the road.
		var ramp := _model(CURB_KIT + "PZ_Ramp_Crosswalk_2x2.glb", Vector3(opening + 1.0, 0.0, 0.0), PI)
		_mesh_collision(ramp, ["Monolithic_Ramp"])
		start = opening + 1.0
	_build_curb_run(start, SIDEWALK_RIGHT)
	_paving(SIDEWALK_LEFT, SIDEWALK_RIGHT, 2.0, FACADE_Z)


func _build_curb_run(start: float, finish: float) -> void:
	var cursor := start
	while cursor < finish - 0.001:
		var length := minf(2.0, finish - cursor)
		var curb := _model(CURB_KIT + "PZ_Curb_2m.glb", Vector3(cursor, 0.0, CURB_DEPTH))
		curb.scale.x = length / 2.0
		_mesh_collision(curb, ["Curb_Stone"])
		cursor += length
	_paving(start, finish, CURB_DEPTH, 2.0)


func _paving(left: float, right: float, front: float, back: float) -> void:
	_solid_box(Vector3((left + right) * 0.5, PAVEMENT_Y - 0.14, (front + back) * 0.5),
		Vector3(right - left, 0.28, back - front), palette["pavement"])


func _build_lobby() -> void:
	var base := Vector3(8.0, PAVEMENT_Y, FACADE_Z)
	var plaster := StandardMaterial3D.new()
	plaster.albedo_color = Color("#c2beb3")
	plaster.roughness = 0.85
	for level in STOREYS:
		var floor_origin := base + Vector3.UP * STOREY_HEIGHT * level
		var story := "Ground" if level == 0 else "Repeatable"
		var file := "GroundLobby_Storey" if level == 0 else "TypicalStorey_Repeatable"
		var floor_model := _model(APARTMENT + "PZ_Midrise_" + file + ".glb", floor_origin)
		floor_model.name = "HillviewFloor%d" % (level + 1)
		if level == 0:
			var hinge := floor_model.find_child("Story_Ground_GroundLobbyEntrance_HINGE_PIVOT", true, false) as Node3D
			# The source previews this leaf open. Reset it against the storey's axes.
			hinge.global_basis = floor_model.global_basis
			_entry("HillviewLobbyDoor", "apartment lobby door", hinge,
				Vector3(LOBBY_X, PAVEMENT_Y, FACADE_Z + 0.11), 1.34, 2.36)
		else:
			floor_model.find_child("Story_Repeatable_StructuralFloorSlab*", true, false).hide()
			floor_model.find_child("Story_Repeatable_StairFrontConnectionDeck", true, false).hide()
			_apartment_slab(floor_origin, plaster)
		_finish_lobby_floor(floor_model, story, floor_origin)
		_relocate_stairs(floor_model, story, floor_origin, level < STOREYS - 1, plaster)
		_stair_enclosure(floor_origin, plaster, level == STOREYS - 1)
		_mesh_collision(floor_model, ["Wall", "Slab", "Floor", "Surface", "Pane", "Partition",
			"Divider", "Separation", "BedroomSide", "BathroomSide", "OfficeSide", "BathSide",
			"KitchenCounterBlock", "Door_Leaf", "Casing", "SlidingGlassLeaf", "SlidingLeaf",
			"Guardrail", "CantileverDeck", "HalfLevelTurningLanding"])
		_furnish_apartment_floor(floor_origin, level)
	var roof := _model(APARTMENT + "PZ_Midrise_RoofCap.glb", base + Vector3.UP * STOREY_HEIGHT * STOREYS)
	_mesh_collision(roof, ["Slab", "Parapet"])


func _finish_lobby_floor(floor_model: Node3D, story: String, at: Vector3) -> void:
	var original := floor_model.find_child("Story_" + story + "_CoreCorridorSurface", true, false) as MeshInstance3D
	var tiles := original.get_active_material(0).duplicate() as BaseMaterial3D
	tiles.uv1_triplanar = true
	original.hide()
	_solid_box(at + Vector3(2.64, 0.013, 4.65), Vector3(4.84, 0.026, 8.86), tiles)


func _apartment_slab(at: Vector3, material: Material) -> void:
	# Replace the prefab's front stair/elevator openings with one rear stairwell.
	for rect: Rect2 in [
		Rect2(0.0, 0.0, 20.0, STAIR_FRONT),
		Rect2(0.0, STAIR_BACK, 20.0, 16.0 - STAIR_BACK),
		Rect2(0.0, STAIR_FRONT, STAIR_LEFT, STAIR_BACK - STAIR_FRONT),
		Rect2(STAIR_RIGHT, STAIR_FRONT, 20.0 - STAIR_RIGHT, STAIR_BACK - STAIR_FRONT),
	]:
		var center := rect.get_center()
		_solid_box(at + Vector3(center.x, -0.1, center.y), Vector3(rect.size.x, 0.2, rect.size.y), material)


func _relocate_stairs(floor_model: Node3D, story: String, at: Vector3, has_next_floor: bool, material: Material) -> void:
	var prefix := "Story_" + story + "_ElevatorAndUStair_"
	floor_model.find_child(prefix + "Doors", true, false).hide()
	var core := floor_model.find_child(prefix + "Core", true, false) as Node3D
	for node in core.get_children():
		var part := node as Node3D
		var name_string := String(part.name)
		if has_next_floor and ("Flight_" in name_string or "TurningLanding" in name_string or
				"Handrail" in name_string or "LandingInnerGuardRail" in name_string):
			part.position.z += STAIR_SHIFT
		else:
			part.hide()
	if has_next_floor:
		# The treads stay visible. A continuous surface supports the player capsule.
		_stair_ramp(at + Vector3(0.75, 0.0, STAIR_FRONT - 0.06),
			at + Vector3(0.75, STOREY_HEIGHT * 0.5, 13.19), 1.41, material)
		var upper_tread := at + Vector3(2.77, STOREY_HEIGHT, STAIR_FRONT + 0.32)
		_stair_ramp(at + Vector3(2.77, STOREY_HEIGHT * 0.5, 13.19),
			upper_tread, 1.41, material)
		_stair_surface(upper_tread, upper_tread - Vector3.BACK * 0.36, 1.41)
		for x in [0.69, 2.47, 4.24]:
			_solid_box(at + Vector3(x, 1.28, 11.52), Vector3(0.09, 2.54, 3.25))


func _stair_ramp(start: Vector3, finish: Vector3, width: float, material: Material) -> void:
	_stair_surface(start, finish, width)
	var side := Vector3.RIGHT * width
	var flight := finish - start
	var underside := BoxMesh.new()
	underside.size = Vector3(width, 0.13, flight.length())
	var lining := MeshInstance3D.new()
	lining.mesh = underside
	lining.material_override = material
	lining.position = (start + finish + side) * 0.5 - Vector3.UP * 0.11
	lining.rotation.x = atan2(-flight.y * signf(flight.z), absf(flight.z))
	add_child(lining)


func _stair_surface(start: Vector3, finish: Vector3, width: float) -> void:
	var side := Vector3.RIGHT * width
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(PackedVector3Array([start, start + side, finish,
		start + side, finish + side, finish]))
	_add_collider(Vector3.ZERO, shape)


func _stair_enclosure(at: Vector3, plaster: Material, top_floor: bool) -> void:
	var wall_height := STOREY_HEIGHT - 0.18
	for x in [STAIR_LEFT - 0.08, STAIR_RIGHT + 0.08]:
		_solid_box(at + Vector3(x, wall_height * 0.5, (STAIR_FRONT + STAIR_BACK) * 0.5),
			Vector3(0.16, wall_height, STAIR_BACK - STAIR_FRONT), plaster)
	_solid_box(at + Vector3(2.49, wall_height * 0.5, STAIR_BACK + 0.08),
		Vector3(4.55, wall_height, 0.16), plaster)
	_solid_box(at + Vector3(4.73, wall_height * 0.5, STAIR_FRONT + 0.08),
		Vector3(0.66, wall_height, 0.16), plaster)
	_solid_box(at + Vector3((STAIR_LEFT + STAIR_RIGHT) * 0.5, 2.71, STAIR_FRONT + 0.08),
		Vector3(STAIR_RIGHT - STAIR_LEFT, 0.47, 0.16), plaster)
	if top_floor:
		_solid_box(at + Vector3(1.66, 0.54, STAIR_FRONT), Vector3(2.13, 1.08, 0.12), palette["trim"])


func _furnish_apartment_floor(at: Vector3, level: int) -> void:
	for spot: Vector2 in [Vector2(2.8, 3.3), Vector2(2.6, 8.1), Vector2(7.5, 8.0),
			Vector2(12.2, 8.0), Vector2(17.0, 8.0), Vector2(9.4, 3.0), Vector2(15.6, 3.2),
			Vector2(8.4, 12.0), Vector2(16.4, 12.5)]:
		var fixture := at + Vector3(spot.x, 2.91, spot.y)
		_solid_box(fixture, Vector3(0.72, 0.06, 0.30), palette["ceiling_light"])
		_room_light(fixture - Vector3.UP * 0.16, 0.85, 4.9)
	_room_light(at + Vector3(2.47, 2.6, 13.1), 0.85, 5.4)
	var sofa := _model(CATALOG.PATHS["sofa"], at + Vector3(11.68, 0.025, 2.45), PI / 2.0)
	_mesh_collision(sofa, ["Sofa", "Seat", "Armrest", "Cushion"])
	var bed := _model(CATALOG.PATHS["bed"], at + Vector3(17.76, 0.025, 1.58))
	_mesh_collision(bed, ["Frame", "Mattress", "Bed"])
	var rear_sofa := _model(CATALOG.PATHS["sofa"], at + Vector3(5.76, 0.025, 10.75), -PI / 2.0)
	_mesh_collision(rear_sofa, ["Sofa", "Seat", "Armrest", "Cushion"])
	var table := _model(DINING_TABLE, at + Vector3(15.2, 0.025, 10.65))
	_mesh_collision(table, ["Table"])
	if level == 0:
		var bench := _model(BENCH, at + Vector3(0.77, 0.025, 4.1), PI / 2.0)
		_mesh_collision(bench, ["Seat", "Back", "Leg", "Support"])
	_solid_box(at + Vector3(2.48, 2.68, STAIR_FRONT - 0.016),
		Vector3(1.8, 0.26, 0.04), palette["dark"])
	var sign := Label3D.new()
	sign.text = "STAIRS   /   LEVEL %02d" % (level + 1)
	sign.font_size = 52
	sign.pixel_size = 0.0035
	sign.outline_size = 5
	sign.modulate = Color("#e9d8aa")
	sign.position = at + Vector3(2.48, 2.68, STAIR_FRONT - 0.04)
	sign.rotation.y = PI
	add_child(sign)


func _build_shop() -> void:
	# PZ-013 is authored Z-up. Rotate its street face toward the pilot road.
	var shop := _model(STOREFRONT, Vector3(0.0, PAVEMENT_Y - 0.06, FACADE_Z), PI)
	shop.name = "HillviewShopfront"
	shop.basis = shop.basis * Basis(Vector3.RIGHT, -PI / 2.0)
	var shutter := shop.find_child("PIVOT_Shutter_Curtain_SlideUp", true, false) as Node3D
	shutter.hide()
	var hinge := shop.find_child("PIVOT_Door_HingeRight", true, false) as Node3D
	_entry("HillviewShopDoor", "shop door", hinge,
		Vector3(SHOP_X, PAVEMENT_Y, FACADE_Z + 0.055), 0.892, 2.40)
	_mesh_collision(shop, ["Brick", "Glass", "Frame", "Reveal", "KickPlinth"])
	var middle := FACADE_Z + 3.65
	var height := PAVEMENT_Y + 1.78
	for side in [-1.0, 1.0]:
		_solid_box(Vector3(side * 2.89, height, middle), Vector3(0.22, 3.56, 7.3), palette["house_masonry"])
	_solid_box(Vector3(0.0, height, FACADE_Z + 7.19), Vector3(6.0, 3.56, 0.22), palette["house_masonry"])
	_solid_box(Vector3(0.0, PAVEMENT_Y + 3.64, middle), Vector3(6.28, 0.18, 7.55), palette["roof_a"])
	_solid_box(Vector3(0.0, PAVEMENT_Y - 0.14, middle), Vector3(6.0, 0.28, 7.3), palette["pavement"])
	var shelf := _model(SHELF, Vector3(1.78, PAVEMENT_Y, FACADE_Z + 4.7), -PI / 2.0)
	_mesh_collision(shelf, ["Shelf", "Frame"])
	_room_light(Vector3(0.0, PAVEMENT_Y + 2.9, middle))


func _entry(node_name: String, title: String, leaf: Node3D, at: Vector3, width: float, height: float) -> void:
	var interaction := INTERACTION.new()
	interaction.name = node_name
	interaction.kind = INTERACTION.Kind.HINGE
	interaction.label_text = title
	interaction.position = at
	add_child(interaction)
	# Animate about a vertical Godot axis regardless of the source's orientation.
	var pivot := Node3D.new()
	interaction.add_child(pivot)
	pivot.global_position = leaf.global_position
	leaf.reparent(pivot, true)
	interaction.panels.append(pivot)
	interaction.hinge_open_angle = -PI / 2.0
	interaction.blocker = _solid_box(at + Vector3.UP * height * 0.5, Vector3(width, height, 0.14))


func _build_street_dressing() -> void:
	var bench_at := Vector3(16.8, PAVEMENT_Y, 3.8)
	var bench := _model(BENCH, bench_at, PI)
	_mesh_collision(bench, ["Seat", "Back", "Leg", "Support"])
	_model(PROPS + "KAL-01_v03_Draped_Jacket.glb", bench_at + Vector3(0.45, 0.13, 0.01), PI)
	var suitcase := _model(PROPS + "KAL-01_v03_Suitcase_Open_Hero.glb", Vector3(7.3, PAVEMENT_Y, 3.3), 0.42)
	_mesh_collision(suitcase, ["MAT_Suitcase"])
	var bicycle := _model(PROPS + "KAL-01_v03_Bicycle_Fallen_Hero.glb", Vector3(20.8, PAVEMENT_Y - 0.018, 1.25), 0.27)
	_mesh_collision(bicycle, ["MAT_Rubber", "MAT_PaintedMetal"])
	var sign := Label3D.new()
	sign.text = "HILLVIEW STEPS"
	sign.font_size = 48
	sign.outline_size = 5
	sign.pixel_size = 0.004
	sign.modulate = Color("#d7c39d")
	sign.position = Vector3(LOBBY_X + 2.0, PAVEMENT_Y + 2.7, FACADE_Z - 0.23)
	sign.rotation.y = PI
	add_child(sign)


func _room_light(at: Vector3, energy: float = 1.25, reach: float = 6.2) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color("#f7d9b0")
	light.light_energy = energy
	light.omni_range = reach
	add_child(light)


func _model(path: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var instance := models.instantiate(path)
	instance.position = at
	instance.rotation.y = yaw
	add_child(instance)
	return instance


func _mesh_collision(model: Node3D, solid_parts: Array[String]) -> void:
	var triangles := PackedVector3Array()
	var inverse := global_transform.affine_inverse()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if not part.is_visible_in_tree():
			continue
		for pattern in solid_parts:
			if pattern in String(part.name):
				triangles.append_array((inverse * part.global_transform) * part.mesh.get_faces())
				break
	if triangles.is_empty():
		push_error("Missing Hillview collision mesh parts in " + String(model.name))
		return
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(triangles)
	_add_collider(Vector3.ZERO, shape)


func _solid_box(at: Vector3, size: Vector3, material: Material = null) -> StaticBody3D:
	if material:
		var box := BoxMesh.new()
		box.size = size
		var visible_box := MeshInstance3D.new()
		visible_box.mesh = box
		visible_box.material_override = material
		visible_box.position = at
		add_child(visible_box)
	var shape := BoxShape3D.new()
	shape.size = size
	return _add_collider(at, shape)


func _add_collider(at: Vector3, shape: Shape3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body
