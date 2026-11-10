extends RefCounted

var world: Node3D
var player: CharacterBody3D
var checks: Dictionary = {}
var details: Array[String] = []


func run(stage: Node3D) -> void:
	world = stage
	player = world.player
	var units := world.get_tree().get_nodes_in_group("infected")
	for unit in units:
		unit.set_physics_process(false)
	await _frames(16)
	_check("start_floor",player.is_on_floor(),str(player.global_position))
	_check("rig_and_crowbar_socket",player.animator != null)
	_check("layout_size",world.streets.terrain.size() == 251*251)
	var floor_hits := 0
	for z: float in [-480,-325,-170,-80,0,80,170,325,480]:
		for x: float in [-480,-325,-170,-80,0,80,170,325,480]:
			var point: Vector3 = world.at(x,z)
			var hit := _ray(point+Vector3.UP*0.25,point-Vector3.UP*0.45)
			if not hit.is_empty() and absf(Vector3(hit["position"]).y-point.y)<0.12:
				floor_hits += 1
	_check("81_terrain_samples",floor_hits==81,"%d / 81" % floor_hits)
	_check("edge_collision",not _ray(world.at(497,-392,1.0),world.at(503,-392,1.0)).is_empty())

	player.set_physics_process(false)
	await _settle(world.at(-118,-7.7,0.08))
	var crossed := await _walk(Vector3.BACK,205)
	var back := await _walk(Vector3.FORWARD,205)
	_check("road_both_directions",crossed>14.4 and back>14.4,"%0.2f / %0.2f m" % [crossed,back])
	await _settle(world.at(27,-8.2,0.08))
	var intersection := await _walk(Vector3.BACK,210)
	_check("junction_crossing",intersection>14.9,"%.2f m" % intersection)

	await _settle(world.at(75,-17.1,0.08))
	var fence := await _walk(Vector3.FORWARD,83)
	_check("fence_blocks",fence>1.4 and player.position.z>-19.85,"z %.2f" % player.position.z)
	await _settle(world.at(50.6,-16.1,0.08))
	await _walk(Vector3.FORWARD,117)
	_check("park_gate_clear",player.position.z < -22.3,"z %.2f" % player.position.z)

	var shop: Node3D = world.sites["shop"]
	var apartment: Node3D = world.sites["apartment"]
	await _settle(shop.to_global(Vector3(-0.14,0.09,-1.55)))
	await _walk(Vector3.BACK,54)
	_check("closed_shop_door_blocks",shop.to_local(player.position).z<0.0,str(shop.to_local(player.position)))
	for row: Array in [["shop",shop,"HINGE_Door",-0.14],["apartment",apartment,"HINGE_Lobby",0.0]]:
		var site: Node3D = row[1]
		var hinge: Node3D = site.get_node(row[2])
		await _settle(site.to_global(Vector3(row[3],0.13,-1.43)))
		world.interact()
		await _frames(28)
		_check(row[0]+"_door_swings_vertically_hinged",absf(hinge.rotation.y)>1.3 and absf(hinge.rotation.x)<0.001,str(hinge.rotation))
		await _walk(Vector3.BACK,80)
		_check(row[0]+"_entry",site.to_local(player.position).z>2.7,str(site.to_local(player.position)))
		await _walk(Vector3.FORWARD,80)
		_check(row[0]+"_exit",site.to_local(player.position).z<-0.8,str(site.to_local(player.position)))
	await _settle(apartment.to_global(Vector3(-1,0.18,8.87)))
	await _walk(Vector3.BACK,65)
	var landing := apartment.to_local(player.position)
	_check("apartment_stair_first_landing",landing.y>1.46 and landing.z>11.2 and landing.z<13.0,str(landing))
	await _walk(Vector3.RIGHT,26)
	await _walk(Vector3.FORWARD,75)
	var upper := apartment.to_local(player.position)
	_check("apartment_upper_floor_reachable",upper.y>3.17 and upper.z<8.7,str(upper))

	await _settle(world.at(-69.1,7.15,0.08))
	player.set_physics_process(true)
	var floor_y := player.position.y
	player.jump_requested = true
	await _frames(12)
	_check("jump_from_sidewalk",player.position.y-floor_y>0.55,"%.2f m" % (player.position.y-floor_y))
	player.set_physics_process(false)

	var case: Node3D = world.pickups[0]["node"]
	await _settle(case.global_position+Vector3(-0.72,0.09,0))
	world.interact()
	_check("search_and_equip",world.objective==1 and player.armed and player.weapon!=null and player.dressings==1,str(world._focus()))
	player.health = 58
	player._unhandled_input(_key(KEY_H,true))
	_check("healing",player.health==88 and player.dressings==0,"%d HP" % player.health)
	var kit: Node3D = world.pickups[1]["node"]
	await _settle(kit.global_position+Vector3(0.30,0.09,-0.95))
	world.interact()
	_check("market_pickup",world.objective==2 and player.medkits==1,str(world._focus()))
	var aid: Node3D = world.pickups[3]["node"]
	await _settle(aid.global_position+Vector3(0.0,0.12,-0.95))
	world.interact()
	_check("aid_delivery",world.objective==3,str(world._focus()))

	await _settle(world.at(-70,10.2,0.08))
	player.set_physics_process(true)
	player.yaw = -PI*0.5
	var target: CharacterBody3D = units[0]
	target.position = player.position+Vector3.RIGHT*1.62
	await _frames(3)
	player.swing()
	await _frames(20)
	_check("crowbar_hits_infected",target.health<100,str(target.health))
	var before: int = player.health
	target.position = player.position+Vector3.RIGHT*1.03
	target.delay = 0.0
	target.set_physics_process(true)
	await _frames(8)
	_check("infected_melee_damage",player.health<before,"%d → %d HP" % [before,player.health])
	target.set_physics_process(false)
	player.set_physics_process(false)

	var seat: CharacterBody3D = world.sedan
	await _settle(seat.to_global(Vector3(-1.9,0.1,-0.27)))
	world.interact()
	var entered: bool = world.driving and seat.occupied
	var origin := seat.global_position
	Input.parse_input_event(_key(KEY_W,true))
	await _frames(56)
	Input.parse_input_event(_key(KEY_W,false))
	var distance := seat.global_position.distance_to(origin)
	var moved: bool = distance>1.60 and seat.wheels.size()==4 and seat.steering.size()==2
	Input.parse_input_event(_key(KEY_SPACE,true))
	await _frames(37)
	Input.parse_input_event(_key(KEY_SPACE,false))
	world.interact()
	_check("sedan_enter_drive_brake_exit",entered and moved and not world.driving and player.visible,"%.2f m / speed %.2f" % [distance,seat.speed_mps])
	world.toggle_map()
	_check("field_map_opens",world.map_open and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	world.toggle_map()
	print("HILLVIEW_VERIFY ",JSON.stringify({"checks":checks,"details":details,"passed":not checks.values().has(false)}))
	world.get_tree().quit(1 if checks.values().has(false) else 0)


func _key(code: Key, down: bool) -> InputEventKey:
	var input := InputEventKey.new()
	input.physical_keycode = code
	input.pressed = down
	return input


func _ray(from: Vector3,to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	return world.get_world_3d().direct_space_state.intersect_ray(query)


func _check(name: String,ok: bool,detail := "") -> void:
	checks[name] = ok
	if not detail.is_empty():
		details.append(name+" "+detail)


func _frames(count: int) -> void:
	for i in count:
		await world.get_tree().physics_frame


func _settle(where: Vector3) -> void:
	player.position = where
	player.velocity = Vector3.ZERO
	for i in 14:
		await world.get_tree().physics_frame
		player.velocity = Vector3.DOWN*1.35
		player.move_and_slide()


func _walk(axis: Vector3,count: int,speed := 4.65) -> float:
	var start := player.position
	for i in count:
		await world.get_tree().physics_frame
		player.velocity = axis*speed+Vector3.DOWN
		player.move_and_slide()
	return (player.position-start).dot(axis)
