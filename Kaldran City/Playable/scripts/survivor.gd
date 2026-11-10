extends CharacterBody3D

var city: Node3D
var camera: Camera3D
var look := Node3D.new()
var arm := SpringArm3D.new()
var avatar: Node3D
var animator: AnimationPlayer
var weapon: Node3D
var health := 100
var dressings := 0
var medkits := 0
var armed := false
var yaw := -0.78
var pitch := -0.22
var attack_time := 0.0
var attack_used := false
var jump_requested := false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1|4
	floor_snap_length = 0.46
	floor_max_angle = deg_to_rad(48)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.875
	add_child(shape)
	avatar = city._asset("0326", self)
	if avatar:
		avatar.position.y = -float(city.catalog["0326"]["bounds"][1])
		avatar.rotation.y = yaw
		animator = avatar.find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	look.name = "Look"
	look.position = Vector3(0,1.46,0)
	add_child(look)
	arm.name = "Arm"
	arm.collision_mask = 1|4
	arm.spring_length = 3.75
	arm.margin = 0.22
	arm.add_excluded_object(get_rid())
	look.add_child(arm)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.far = 11500.0
	camera.fov = 70
	camera.current = true
	arm.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func equip_loot() -> void:
	armed = true
	dressings += 1
	medkits += 1
	if not weapon and avatar:
		var holder := Node3D.new()
		var skeleton := avatar.find_children("*", "Skeleton3D", true, false)
		if not skeleton.is_empty():
			var rig: Skeleton3D = skeleton.front()
			var hand := -1
			for i in rig.get_bone_count():
				var tag := rig.get_bone_name(i).to_lower()
				if "hand" in tag and (tag.ends_with(".r") or "right" in tag or tag.ends_with("_r")):
					hand = i
					break
			if hand >= 0:
				var attachment := BoneAttachment3D.new()
				attachment.bone_idx = hand
				rig.add_child(attachment)
				attachment.add_child(holder)
			else:
				avatar.add_child(holder)
				holder.position = Vector3(0.39,0.91,-0.08)
		else:
			avatar.add_child(holder)
		weapon = city._asset("crowbar", holder)
		if weapon:
			weapon.rotation_degrees = Vector3(90,0,-14)


func take_damage(amount: int) -> void:
	if city.driving:
		return
	health = maxi(0,health-amount)
	if health == 0:
		health = 100
		global_position = city.saved_point
		velocity = Vector3.ZERO
		city.announce("Recovered at the last checkpoint")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not city.driving:
		yaw -= event.relative.x * 0.0026
		pitch = clampf(pitch - event.relative.y * 0.0026,-1.04,0.48)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_M:
				city.toggle_map()
			KEY_C:
				city.cycle_camera()
			KEY_ESCAPE:
				if city.map_open:
					city.toggle_map()
				else:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_E:
				if not city.map_open:
					city.interact()
			KEY_SPACE:
				jump_requested = not city.driving and not city.map_open
			KEY_H:
				if health < 100 and not city.map_open:
					if dressings > 0:
						dressings -= 1
						health = mini(100,health+30)
						city.announce("Field dressing applied")
					elif medkits > 0:
						medkits -= 1
						health = mini(100,health+65)
						city.announce("Medkit applied")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not city.map_open:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif armed and attack_time <= 0.0 and not city.driving:
			attack_time = 0.6
			attack_used = false
			_play("Crowbar_Swing")


func _play(clip: String) -> void:
	if animator == null:
		return
	for name: String in animator.get_animation_list():
		if name.to_lower().ends_with(clip.to_lower()):
			if animator.current_animation != name or not animator.is_playing():
				animator.play(name,0.15)
			return


func _physics_process(delta: float) -> void:
	if city.driving or city.travelling or city.camera_index >= 0:
		jump_requested = false
		return
	look.rotation.y = yaw
	arm.rotation.x = pitch
	var input := Vector2.ZERO
	if not city.map_open and city.camera_index < 0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input.x = float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
		input.y = float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var direction := (Basis(Vector3.UP,yaw) * Vector3(input.x,0,input.y)).normalized()
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT)
	var speed := 6.9 if sprint else 4.1
	velocity.x = move_toward(velocity.x, direction.x*speed, delta*31)
	velocity.z = move_toward(velocity.z, direction.z*speed, delta*31)
	if is_on_floor():
		velocity.y = 5.5 if jump_requested else -0.7
	else:
		velocity.y -= 15.0*delta
	jump_requested = false
	move_and_slide()
	if avatar and direction.length_squared() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	if attack_time > 0:
		attack_time -= delta
		if attack_time < 0.35 and not attack_used:
			attack_used = true
			var forward := -look.global_basis.z
			for target in get_tree().get_nodes_in_group("infected"):
				var offset: Vector3 = target.global_position-global_position
				if offset.length() < 2.45 and offset.normalized().dot(forward) > 0.05:
					target.take_hit(42)
	else:
		_play(("Jump" if velocity.y > 0 else "Fall") if not is_on_floor() else
			(("Run" if sprint else "Walk") if input.length_squared() > 0.1 else "Idle"))
