extends CharacterBody3D

var world: Node3D
var camera: Camera3D
var wheels: Array[Node3D] = []
var steering: Array[Node3D] = []
var door: Node3D
var speed_mps := 0.0
var steer_angle := 0.0
var door_animation: Tween
var occupied := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1|2
	floor_snap_length = 0.66
	floor_max_angle = deg_to_rad(41)
	var shell: Node3D = world._asset("0164",self)
	for side: String in ["FL","FR","RL","RR"]:
		var wheel := shell.find_child("HINGE_WHEEL_"+side,true,false) as Node3D
		if wheel:
			wheels.append(wheel)
		var pivot := shell.find_child("HINGE_STEER_"+side,true,false) as Node3D
		if pivot:
			steering.append(pivot)
	door = shell.find_child("HINGE_DOOR_FL",true,false) as Node3D
	world.library.batch_vehicle(shell)
	var shape := CollisionShape3D.new()
	var chassis := BoxShape3D.new()
	chassis.size = Vector3(1.84,1.26,4.61)
	shape.position.y = 0.65
	shape.shape = chassis
	add_child(shape)
	var arm := SpringArm3D.new()
	arm.position = Vector3(0,1.55,0.25)
	arm.rotation.x = -0.21
	arm.spring_length = 6.6
	arm.collision_mask = 1
	arm.margin = 0.32
	add_child(arm)
	camera = Camera3D.new()
	camera.fov = 71
	camera.far = 7700
	arm.add_child(camera)


func swing_driver_door() -> void:
	if door == null:
		return
	if door_animation:
		door_animation.kill()
	door_animation = create_tween()
	door_animation.tween_property(door,"rotation:y",-1.09,0.25)
	door_animation.tween_interval(0.2)
	door_animation.tween_property(door,"rotation:y",0.0,0.27)


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var wheel_input := 0.0
	var braking := false
	if occupied and not world.map_open:
		throttle = float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
		wheel_input = float(Input.is_physical_key_pressed(KEY_A))-float(Input.is_physical_key_pressed(KEY_D))
		braking = Input.is_physical_key_pressed(KEY_SPACE)
	var target := throttle*(16.5 if throttle >= 0 else 4.2)
	var traction := 5.0 if absf(target) > 0.1 else 8.5
	if braking:
		target = 0.0
		traction = 23.0
	speed_mps = move_toward(speed_mps,target,traction*delta)
	steer_angle = move_toward(steer_angle,wheel_input*0.43,delta*1.95)
	rotation.y += steer_angle * clampf(speed_mps/5.0,-2.2,2.2)*delta
	for wheel: Node3D in wheels:
		wheel.rotate_x(-speed_mps*delta/0.335)
	for pivot: Node3D in steering:
		pivot.rotation.y = steer_angle
	var motion := -global_basis.z*speed_mps
	velocity.x = motion.x
	velocity.z = motion.z
	velocity.y = -1.3 if is_on_floor() else velocity.y-16.0*delta
	move_and_slide()
	if is_on_wall() and absf(speed_mps) > 0.4:
		speed_mps *= 0.53
