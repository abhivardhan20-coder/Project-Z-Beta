extends Control

const INK := Color("#e9ece5")
const ACCENT := Color("#e4bf74")
const DIM := Color("#a8b5b7")
var city: Node3D
var hover := ""
var mission := 0
var map_rect := Rect2()
var river_sections: Array[Array] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for chunk: Dictionary in city.city["chunks"].values():
		for route: Array in chunk["routes"]:
			if route[0] == "WESTFLOW":
				river_sections.append(route[3])


func _xy(x: float, z: float) -> Vector2:
	return map_rect.position + Vector2(x+4000.0,z+4000.0) * (map_rect.size.x/8000.0)


func _draw() -> void:
	if city == null:
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#101923f5"))
	var side := minf(size.y-105,size.x*0.64)
	map_rect = Rect2(Vector2(34,69),Vector2(side,side))
	draw_rect(map_rect,Color("#253c3d"))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(34,39),"K A L D R A N   /   C I T Y   A T L A S",HORIZONTAL_ALIGNMENT_LEFT,-1,24,INK)
	draw_string(font,map_rect.end+Vector2(-18,28),"N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ACCENT)
	var colors := [Color("#345149"),Color("#364c43"),Color("#424f44"),Color("#3c4b4a"),Color("#3f5653")]
	var index := 0
	for district: Array in city.city["districts"]:
		var poly := PackedVector2Array()
		for p: Array in district[4]:
			poly.append(_xy(p[0],p[1]))
		if poly.size() > 3:
			poly.resize(poly.size()-1)
			draw_colored_polygon(poly,colors[index % colors.size()])
			poly.append(poly[0])
			draw_polyline(poly,Color("#728476"),0.6,true)
		index += 1
	for water: Array in city.city["lakes"]:
		var poly := PackedVector2Array()
		for p: Array in water[0]:
			poly.append(_xy(p[0],p[1]))
		draw_colored_polygon(poly,Color("#5b8996"))
	for section: Array in river_sections:
		draw_line(_xy(section[0][0],section[0][1]),_xy(section[1][0],section[1][1]),Color("#5b8996"),2.6,true)
	for route: Array in city.city["paths"]:
		var line := PackedVector2Array()
		for p: Array in route[3]:
			line.append(_xy(p[0],p[1]))
		var color := Color("#b7a981") if route[1] == "expressway" else Color("#849092")
		if route[1] == "rail":
			color = Color("#aa8c82")
		if route[1] == "runway":
			color = Color("#bfc7c1")
		draw_polyline(line,color,2.4 if route[1] in ["expressway","runway"] else 1.15,true)
	var missions: Array = city.city["missions"]
	var active: Dictionary = missions[mission]
	var positions := {}
	for point: Array in city.city["points"]:
		positions[point[0]] = _xy(point[2],point[3])
	var links := PackedVector2Array()
	for id: String in active["point_ids"]:
		links.append(positions[id])
	draw_polyline(links,Color("#e0ae5f83"),3.0,true)
	for point: Array in city.city["points"]:
		var color := INK if hover == point[0] else ACCENT
		draw_circle(positions[point[0]],7.0 if hover == point[0] else 4.2,color)
		draw_string(font,positions[point[0]]+Vector2(6,-5),point[0],HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
	var location: Vector3 = city.player.global_position
	draw_circle(_xy(location.x,location.z),6.0,Color("#81e2df"))
	var left := map_rect.end.x+29
	draw_string(font,Vector2(left,97),"64 km²  ·  21 districts  ·  24 sites",HORIZONTAL_ALIGNMENT_LEFT,-1,20,INK)
	draw_string(font,Vector2(left,128),"Click a site to travel. M to close.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,DIM)
	draw_string(font,Vector2(left,185),"FIELD ROUTE %d / %d  ·  TAB TO CHANGE" % [mission+1,missions.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,15,ACCENT)
	draw_string(font,Vector2(left,216),active["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,22,INK)
	var y := 256.0
	for id: String in active["point_ids"]:
		for p: Array in city.city["points"]:
			if p[0] == id:
				var check := "✓" if city.missions_done.has(id) else "○"
				draw_string(font,Vector2(left,y),"%s  %s  %s" % [check,id,p[1]],HORIZONTAL_ALIGNMENT_LEFT,-1,16,DIM)
		y += 28
	for p: Array in city.city["points"]:
		if p[0] == hover:
			draw_string(font,Vector2(left,y+44),"%s · %s" % [p[0],p[1]],HORIZONTAL_ALIGNMENT_LEFT,-1,19,ACCENT)
			break


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = ""
		var distance := 13.0
		for point: Array in city.city["points"]:
			var d: float = event.position.distance_to(_xy(point[2],point[3]))
			if d < distance:
				hover = point[0]
				distance = d
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for point: Array in city.city["points"]:
			if point[0] == hover:
				city.travel(point)
				accept_event()
				return


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		mission = (mission+1) % city.city["missions"].size()
		queue_redraw()
		get_viewport().set_input_as_handled()
