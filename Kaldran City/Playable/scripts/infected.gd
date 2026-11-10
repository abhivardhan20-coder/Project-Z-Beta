extends CharacterBody3D

var city: Node3D
var rig: Node3D
var animator: AnimationPlayer
var health := 100
var delay := 0.0
var dead := false
var origin: Vector3


func _ready() -> void:
	origin = position
	collision_layer = 4
	collision_mask = 1|2|4
	floor_snap_length = 0.35
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.29
	capsule.height = 1.73
	collision.shape = capsule
	collision.position.y = 0.86
	add_child(collision)
	rig = city._asset("0327", self)
	if rig:
		rig.position.y = -float(city.catalog["0327"]["bounds"][1])
		var players := rig.find_children("*","AnimationPlayer",true,false)
		if not players.is_empty():
			animator = players.front()
	add_to_group("infected")
	_play("Idle")


func _play(clip: String) -> void:
	if animator == null:
		return
	for name: String in animator.get_animation_list():
		if name.to_lower().ends_with(clip.to_lower()):
			if animator.current_animation != name:
				animator.play(name,0.18)
			return


func take_hit(amount: int) -> void:
	if dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		_play("Death")
		remove_from_group("infected")
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
	else:
		_play("HitReaction")
		delay = 0.36


func _physics_process(delta: float) -> void:
	if city.player == null or city.map_open:
		return
	var gap: Vector3 = city.player.global_position-global_position
	var range_m := Vector2(gap.x,gap.z).length()
	if range_m > 95:
		return
	var direction := Vector3(gap.x,0,gap.z).normalized()
	delay = maxf(delay-delta,0)
	var speed := 0.0
	if range_m < 34 and absf(gap.y) < 3.0 and not city.driving:
		if rig:
			rig.rotation.y = lerp_angle(rig.rotation.y,atan2(-direction.x,-direction.z),delta*10)
		if range_m > 1.32:
			speed = 1.7 if delay < 0.05 else 0.7
			_play("Chase")
		elif delay <= 0:
			_play("Attack")
			city.player.take_damage(12)
			delay = 1.25
	else:
		_play("Idle")
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	velocity.y = -1.0 if is_on_floor() else velocity.y-15.0*delta
	move_and_slide()
	if position.y < origin.y-45.0:
		position = origin
		velocity = Vector3.ZERO
