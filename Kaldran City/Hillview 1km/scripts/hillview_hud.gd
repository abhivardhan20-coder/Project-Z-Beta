extends Control

const STREETS = preload("res://scripts/street_geometry.gd")
const LAYOUT = preload("res://scripts/hillview_layout.gd")
const PAPER := Color("#e7e7d9")
const SOFT := Color("#b2bdb9")
const GOLD := Color("#e8bc7e")
const PANEL := Color("#101b22e9")
const BORDER := Color("#425357")
const TASKS := [
	["Roadside case","Search the supply case beside the pavement."],
	["Northline Market","Recover the medical kit inside the market."],
	["Emergency aid station","Take the kit east to the aid tent."],
	["Route secured","Explore Hillview or return to the overlook."],
]

var world: Node3D
var alert := ""
var alert_until := 0
var last_redraw := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func notice(text: String) -> void:
	alert = text
	alert_until = Time.get_ticks_msec()+4050
	queue_redraw()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now-last_redraw >= 40:
		last_redraw = now
		queue_redraw()


func _line(at: Vector2,text: String,points: int,ink := PAPER) -> void:
	draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,points,ink)


func _center(y: float,text: String,points: int,ink := PAPER) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x
	_line(Vector2((size.x-width)*0.5,y),text,points,ink)


func _card(rect: Rect2) -> void:
	draw_rect(rect,PANEL)
	draw_rect(rect,BORDER,false,1.0)


func _draw() -> void:
	if not is_instance_valid(world.player):
		return
	if world.map_open:
		_map()
		return
	var left := Rect2(Vector2(26,24),Vector2(248,75))
	_card(left)
	draw_rect(Rect2(left.position,Vector2(3,75)),GOLD)
	_line(Vector2(41,52),"P R O J E C T   Z",24)
	_line(Vector2(41,77),"KALDRAN  /  HILLVIEW STEPS",13,GOLD)
	var card_x := size.x-344.0
	_card(Rect2(Vector2(card_x,24),Vector2(318,101)))
	var task: Array = TASKS[world.objective]
	_line(Vector2(card_x+16,47),"FIELD OBJECTIVE",12,GOLD)
	_line(Vector2(card_x+16,74),task[0],20)
	_line(Vector2(card_x+16,99),task[1],13,SOFT)
	var panel_y := size.y-106.0
	_card(Rect2(Vector2(26,panel_y),Vector2(242,82)))
	_line(Vector2(41,panel_y+25),"HEALTH    %03d / 100" % world.player.health,16)
	draw_rect(Rect2(Vector2(42,panel_y+35),Vector2(210,7)),Color("#293b42"))
	var health_color := Color("#abc4a0") if world.player.health > 28 else Color("#bd6d59")
	draw_rect(Rect2(Vector2(42,panel_y+35),Vector2(2.10*world.player.health,7)),health_color)
	_line(Vector2(41,panel_y+62),"DRESSINGS  %02d     MEDKITS  %02d" % [world.player.dressings,world.player.medkits],13,SOFT)
	var x := size.x-418.0
	_card(Rect2(Vector2(x,size.y-89.0),Vector2(392,65)))
	if world.driving:
		_line(Vector2(x+14,size.y-63),"%02d km/h    WASD DRIVE     SPACE BRAKE" % roundi(absf(world.sedan.speed_mps)*3.6),14)
		_line(Vector2(x+14,size.y-42),"E EXIT AT REST      M MAP",13,SOFT)
	else:
		_line(Vector2(x+14,size.y-63),"WASD MOVE    SHIFT SPRINT    SPACE JUMP",14)
		_line(Vector2(x+14,size.y-42),"E INTERACT     LMB SWING     H HEAL     M MAP",13,SOFT)
	var focus: Dictionary = {} if world.driving else world._focus()
	var command: String = focus.get("caption","")
	if world.driving and absf(world.sedan.speed_mps)<0.72:
		command = "Exit sedan"
	if not command.is_empty():
		var y := size.y*0.735
		_card(Rect2(Vector2(size.x*0.5-170,y-26),Vector2(340,39)))
		_center(y,"[ E ]   "+command,17,GOLD)
	if Time.get_ticks_msec() < alert_until:
		_center(size.y*0.84,alert,18)


func _point(x: float,z: float,rect: Rect2) -> Vector2:
	return rect.position+Vector2(x+500,z+500)*rect.size.x/1000.0


func _map() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#101c24fa"))
	var side := minf(size.y-134,size.x*0.61)
	var rect := Rect2(Vector2(43,79),Vector2(side,side))
	draw_rect(rect,Color("#304038"))
	for belt: Array in [[-500,-500,500,-226],[-500,302,500,500]]:
		var corner := _point(belt[0],belt[1],rect)
		draw_rect(Rect2(corner,_point(belt[2],belt[3],rect)-corner),Color("#273932"))
	var park := _point(43,-75,rect)
	draw_rect(Rect2(park,_point(104,-20,rect)-park),Color("#59714e"))
	for i in range(11):
		var step := i*side/10
		draw_line(rect.position+Vector2(step,0),rect.position+Vector2(step,side),Color("#577165"),0.6)
		draw_line(rect.position+Vector2(0,step),rect.position+Vector2(side,step),Color("#577165"),0.6)
	for building: Array in LAYOUT.BUILDINGS:
		var size_on_map := Vector2(building[2],building[3])*side/1000.0
		var p := _point(building[0],building[1],rect)
		draw_rect(Rect2(p-size_on_map*0.5,size_on_map),Color("#9d9d8c"))
	for road: Array in STREETS.EAST_WEST:
		draw_line(_point(road[0],road[2],rect),_point(road[1],road[2],rect),Color("#d2c5a4"),4.0,true)
	for road: Array in STREETS.NORTH_SOUTH:
		draw_line(_point(road[2],road[0],rect),_point(road[2],road[1],rect),Color("#d2c5a4"),3.0,true)
	for trail: Array in world.streets.walkway_paths:
		var points := PackedVector2Array()
		for p: Array in trail:
			points.append(_point(p[0],p[1],rect))
		draw_polyline(points,Color("#a9b690"),1.7,true)
	var number := 1
	for site: Array in LAYOUT.LANDMARKS:
		var p := _point(site[2],site[3],rect)
		draw_circle(p,5.2,GOLD)
		_line(p+Vector2(7,-5),str(number),13)
		number += 1
	var current: Vector3 = world.player.global_position
	draw_circle(_point(current.x,current.z,rect),5.7,Color("#73d6d5"))
	draw_rect(rect,BORDER,false,1.0)
	_line(Vector2(43,48),"H I L L V I E W   /   F I E L D   M A P",25)
	_line(Vector2(44,rect.end.y+26),"0                     100 m    ·    north up",13,SOFT)
	var start := rect.end.x+33
	_line(Vector2(start,103),"1 KM × 1 KM",20,GOLD)
	_line(Vector2(start,133),"Landmarks",16)
	number = 1
	for site: Array in LAYOUT.LANDMARKS:
		_line(Vector2(start,155+28*number),"%d   %s" % [number,site[1]],16,SOFT)
		number += 1
	_line(Vector2(start,340),"CURRENT OBJECTIVE",13,GOLD)
	_line(Vector2(start,365),TASKS[world.objective][0],18)
	_line(Vector2(start,398),"M or Esc to return",14,SOFT)
