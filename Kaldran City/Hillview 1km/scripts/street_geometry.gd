extends RefCounted

const HALF := 500.0
const GRID := 251
const STEP := 4.0
const GROUND = preload("res://scripts/ground.gdshader")

# Horizontal streets use (start X, end X, centre Z, paved width).
# Vertical streets use (start Z, end Z, centre X, paved width).
const EAST_WEST := [
	[-430.0,427.0,0.0,8.0], [-248.0,302.0,-105.0,6.6],
	[-245.0,145.0,92.0,6.0], [-160.0,145.0,214.0,5.5],
]
const NORTH_SOUTH := [
	[-212.0,214.0,-158.0,6.5], [-105.0,92.0,27.0,7.2],
	[-185.0,300.0,145.0,6.8], [-105.0,0.0,300.0,5.5],
]
const PADS := [
	[-52.0,24.0,7.0,22.0], [-16.0,19.0,8.0,16.0],
	[72.0,-45.0,50.0,31.0], [-84.0,-27.0,45.0,17.0],
	[-26.0,-24.0,37.0,15.0], [71.0,27.0,43.0,19.0],
	[114.0,-27.0,25.0,16.0], [255.0,21.0,38.0,17.0],
	[-184.0,169.0,27.0,23.0],
]

var host: Node3D
var terrain := PackedFloat32Array()
var overlays: Dictionary = {}
var materials: Dictionary = {}
var walkway_paths: Array[Array] = []


func _init(world: Node3D) -> void:
	host = world


func _natural(x: float, z: float) -> float:
	var south := pow(maxf(0.0,(z-33.0)/467.0),1.42) * 77.0
	var north := pow(maxf(0.0,(-z-106.0)/394.0),1.53) * 51.0
	var rise := smoothstep(175.0,470.0,absf(z))
	var west := smoothstep(-170.0,-500.0,x) * 16.0 * smoothstep(45.0,330.0,absf(z))
	var relief := (sin(x*0.019+z*0.007)*4.4+cos(z*0.021-x*0.011)*3.1)*rise
	return -x*0.029+z*0.003+south+north+west+relief


func _elevation(x: float,z: float) -> float:
	var height := _natural(x,z)
	for pad: Array in PADS:
		var dx: float = absf(x-pad[0])-pad[2]*0.5
		var dz: float = absf(z-pad[1])-pad[3]*0.5
		var d := maxf(dx,dz)
		var target := _natural(pad[0],pad[1])
		height = lerpf(height,target,1.0-smoothstep(0.0,6.0,d))
	# Taper the verges into the road grade, including each cross street.
	for road: Array in EAST_WEST:
		if x >= road[0]-7 and x <= road[1]+7:
			var near := 1.0-smoothstep(road[3]*0.5+2.6,road[3]*0.5+11.0,absf(z-road[2]))
			height = lerpf(height,_natural(x,road[2]),near)
	for road: Array in NORTH_SOUTH:
		if z >= road[0]-7 and z <= road[1]+7:
			var near := (1.0-smoothstep(road[3]*0.5+2.0,road[3]*0.5+8.0,absf(x-road[2]))) * smoothstep(8,19,absf(z))
			height = lerpf(height,_natural(road[2],z),near)
	return height


func bake() -> void:
	terrain.resize(GRID*GRID)
	for row in GRID:
		for col in GRID:
			terrain[row*GRID+col] = _elevation(col*STEP-HALF,row*STEP-HALF)


func height(x: float, z: float) -> float:
	var px := clampf((x+HALF)/STEP,0,GRID-1.0001)
	var pz := clampf((z+HALF)/STEP,0,GRID-1.0001)
	var ix := int(px)
	var iz := int(pz)
	var u := px-ix
	var v := pz-iz
	var at := iz*GRID+ix
	if u+v < 1.0:
		return terrain[at]*(1-u-v)+terrain[at+1]*u+terrain[at+GRID]*v
	return terrain[at+GRID+1]*(u+v-1)+terrain[at+1]*(1-v)+terrain[at+GRID]*(1-u)


func position(x: float, z: float, lift := 0.0) -> Vector3:
	return Vector3(x,height(x,z)+lift,z)


func build_land() -> void:
	var ground := ShaderMaterial.new()
	ground.shader = GROUND
	ground.set_shader_parameter("earth",host.library.texture("res://content/surfaces/0302.png"))
	ground.set_shader_parameter("turf",host.library.texture("res://content/polyhaven/leafy_grass.jpg"))
	for tz in range(10):
		for tx in range(10):
			var verts := PackedVector3Array()
			var norms := PackedVector3Array()
			var cols := PackedColorArray()
			var ids := PackedInt32Array()
			for j in range(26):
				for i in range(26):
					var gx := tx*25+i
					var gz := tz*25+j
					var x := gx*STEP-HALF
					var z := gz*STEP-HALF
					var at := gz*GRID+gx
					var dy_x := terrain[gz*GRID+mini(gx+1,250)]-terrain[gz*GRID+maxi(gx-1,0)]
					var dy_z := terrain[mini(gz+1,250)*GRID+gx]-terrain[maxi(gz-1,0)*GRID+gx]
					verts.append(Vector3(x,terrain[at],z))
					norms.append(Vector3(-dy_x,STEP*2.0,-dy_z).normalized())
					var variation := (sin(x*0.056+cos(z*0.028))*cos(z*0.051))*0.023
					var grass := Color(0.146+variation,0.196+variation,0.081+variation*0.58)
					var dry := Color(0.246,0.225,0.130)
					var rock := clampf((absf(dy_x)+absf(dy_z))/3.1,0,0.58)
					cols.append(grass.lerp(dry,rock))
			for j in 25:
				for i in 25:
					var a := j*26+i
					ids.append_array(PackedInt32Array([a,a+1,a+26,a+1,a+27,a+26]))
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_NORMAL] = norms
			arrays[Mesh.ARRAY_COLOR] = cols
			arrays[Mesh.ARRAY_INDEX] = ids
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var node := MeshInstance3D.new()
			node.name = "Ground_%02d_%02d" % [tx,tz]
			node.mesh = mesh
			node.material_override = ground
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			host.land.add_child(node)
			node.create_trimesh_collision()
	for sign: float in [-1.0,1.0]:
		host.solid(host.land,Vector3(500*sign,50,0),Vector3(1,230,1001))
		host.solid(host.land,Vector3(0,50,500*sign),Vector3(1001,230,1))


func _surface(key: String) -> SurfaceTool:
	if not overlays.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		overlays[key] = tool
	return overlays[key]


func quad(key: String, a: Vector2, b: Vector2, c: Vector2, d: Vector2, lift: float) -> void:
	var tool := _surface(key)
	for p: Vector2 in [a,b,c,b,d,c]:
		var px := position(p.x,p.y,lift)
		tool.set_normal(Vector3.UP)
		tool.set_uv(p / (2.0 if key == "asphalt" else 3.0))
		tool.add_vertex(px)


func rectangle(key: String, x0: float, z0: float, x1: float, z1: float, lift: float, cell := 4.0) -> void:
	if x1-x0 < 0.03 or z1-z0 < 0.03:
		return
	var cols := maxi(1,ceili((x1-x0)/cell))
	var rows := maxi(1,ceili((z1-z0)/cell))
	for j in rows:
		for i in cols:
			var left := lerpf(x0,x1,float(i)/cols)
			var right := lerpf(x0,x1,float(i+1)/cols)
			var near := lerpf(z0,z1,float(j)/rows)
			var far := lerpf(z0,z1,float(j+1)/rows)
			quad(key,Vector2(left,near),Vector2(right,near),Vector2(left,far),Vector2(right,far),lift)


func build_streets() -> void:
	for road: Array in EAST_WEST:
		var lo: float = road[0]
		var hi: float = road[1]
		var z: float = road[2]
		var w: float = road[3]*0.5
		rectangle("asphalt",lo,z-w,hi,z+w,0.036)
		var breaks := [Vector2(lo,lo)]
		for cross: Array in NORTH_SOUTH:
			if cross[0]-3.8 <= z and cross[1]+3.8 >= z and cross[2] > lo and cross[2] < hi:
				breaks.append(Vector2(cross[2]-cross[3]*0.5-3.1,cross[2]+cross[3]*0.5+3.1))
		breaks.append(Vector2(hi,hi))
		breaks.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
		for i in range(breaks.size()-1):
			var a: float = breaks[i].y
			var b: float = breaks[i+1].x
			for sign: float in [-1.0,1.0]:
				var edge := z+sign*w
				rectangle("paving",a,minf(edge,edge+sign*3.5),b,maxf(edge,edge+sign*3.5),0.050)
				rectangle("curb",a,edge-0.11,b,edge+0.11,0.059)
				rectangle("gutter",a,edge-sign*0.27-0.14,b,edge-sign*0.27+0.14,0.044)
			if z == 0.0:
				var x := a+1.0
				while x+2.1 < b:
					rectangle("yellow",x,z-0.053,x+2.1,z+0.053,0.053)
					x += 5.6
	for road: Array in NORTH_SOUTH:
		var lo: float = road[0]
		var hi: float = road[1]
		var x: float = road[2]
		var w: float = road[3]*0.5
		var sections := [Vector2(lo,lo)]
		for cross: Array in EAST_WEST:
			if cross[0] <= x and cross[1] >= x and cross[2] >= lo and cross[2] <= hi:
				sections.append(Vector2(cross[2]-cross[3]*0.5,cross[2]+cross[3]*0.5))
		sections.append(Vector2(hi,hi))
		sections.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x)
		for i in range(sections.size()-1):
			var a: float = sections[i].y
			var b: float = sections[i+1].x
			rectangle("asphalt",x-w,a,x+w,b,0.036)
			for sign: float in [-1.0,1.0]:
				var edge := x+sign*w
				rectangle("paving",minf(edge,edge+sign*3.2),a+2.1,maxf(edge,edge+sign*3.2),b-2.1,0.051)
				rectangle("curb",edge-0.10,a+2.1,edge+0.10,b-2.1,0.059)
	# Shared level corners and pedestrian crossings.
	for x: float in [-158.0,27.0,145.0]:
		for x_sign: float in [-1.0,1.0]:
			for z_sign: float in [-1.0,1.0]:
				var a := x+x_sign*4.25
				var b := x+x_sign*7.0
				rectangle("paving",minf(a,b),minf(z_sign*4.0,z_sign*7.5),maxf(a,b),maxf(z_sign*4.0,z_sign*7.5),0.047)
		for x_side: float in [-1.0,1.0]:
			for j in 9:
				var z := -3.78+j*0.88
				var edge := x+x_side*4.55
				var stop := x+x_side*6.65
				rectangle("white",minf(edge,stop),z,maxf(edge,stop),z+0.41,0.057)
		for z_side: float in [-1.0,1.0]:
			for i in 8:
				var dx := -3.36+i*0.89
				var edge := z_side*4.38
				var stop := z_side*6.41
				rectangle("white",x+dx,minf(edge,stop),x+dx+0.40,maxf(edge,stop),0.057)
	for block: Array in [[-98.0,-22.0,-61.0,-7.4],[-55.0,7.5,-9.0,13.7],[41.0,-12.0,105.0,-7.2],
		[65.0,-56.0,81.0,-37.0],[53.0,-28.0,60.0,-23.0],[81.0,-28.0,88.0,-23.0],[241.0,7.5,271.0,36.0]]:
		rectangle("plaza",block[0],block[1],block[2],block[3],0.052)
	_walk([[50.6,-8.0],[50.6,-29.0],[61.0,-57.0],[77.0,-67.0],[96.3,-53.0],[96.3,-8.0]],2.6,"park")
	_walk([[-158.0,214.0],[-183.0,230.0],[-207.0,251.0],[-239.0,287.0],[-273.0,319.0],[-321.0,342.0]],2.8,"park")
	_walk([[-426.0,0.0],[-451.0,27.0],[-462.0,78.0],[-448.0,125.0],[-415.0,165.0],[-385.0,192.0],[-310.0,204.0],[-246.0,213.0],[-160.0,214.0]],2.7,"park")
	_walk([[145.0,299.0],[176.0,324.0],[205.0,347.0],[274.0,372.0],[346.0,383.0],[412.0,381.0]],2.5,"park")


func _walk(points: Array, width: float, key: String) -> void:
	walkway_paths.append(points)
	for i in range(points.size()-1):
		var a := Vector2(points[i][0],points[i][1])
		var b := Vector2(points[i+1][0],points[i+1][1])
		var sections := maxi(1,ceili(a.distance_to(b)/2.5))
		var side := Vector2(-(b-a).y,(b-a).x).normalized()*width*0.5
		for s in sections:
			var start := a.lerp(b,float(s)/sections)
			var end := a.lerp(b,float(s+1)/sections)
			quad(key,start-side,end-side,start+side,end+side,0.042)


func finish() -> void:
	for key: String in overlays:
		var surface: SurfaceTool = overlays[key]
		if key == "asphalt" or key == "paving":
			surface.generate_tangents()
		var node := MeshInstance3D.new()
		node.name = key.capitalize()
		node.mesh = surface.commit()
		node.material_override = materials[key]
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		host.paving.add_child(node)
