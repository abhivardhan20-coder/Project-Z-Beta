extends RefCounted

const NET = preload("res://scripts/chain_link.gdshader")

# Fronts face their street. The market and furnished apartment occupy the
# reserved slots on the south side of the high street.
const BUILDINGS := [
	[-203,-27,28,20,3,180,"stone"], [-184,-62,21,17,4,90,"brick"],
	[-128,-24,32,20,4,180,"brick"], [-92,-28,27,18,3,180,"plaster"],
	[-53,-24,31,17,5,180,"stone"], [-18,-25,31,19,4,180,"brick"],
	[119,-28,25,17,4,180,"stone"], [168,-27,29,18,5,180,"brick"],
	[205,-25,29,17,3,180,"plaster"], [242,-27,26,20,3,180,"brick"],
	[278,-27,26,19,4,180,"stone"], [326,-29,30,20,3,180,"brick"],
	[-201,25,31,18,3,0,"plaster"], [-118,29,35,21,4,0,"stone"],
	[-77,27,32,20,4,0,"brick"], [-36,26,19,17,3,0,"plaster"],
	[2,24,19,15,4,0,"brick"], [69,26,41,20,4,0,"brick"],
	[116,23,29,18,3,0,"stone"], [176,25,29,18,4,0,"plaster"],
	[213,25,30,18,3,0,"brick"], [299,28,31,18,3,0,"stone"],
	[338,26,30,19,2,0,"plaster"],
	[-212,-80,31,18,3,180,"brick"], [-119,-80,29,18,3,180,"stone"],
	[-80,-78,25,19,4,180,"plaster"], [-39,-78,32,18,3,180,"brick"],
	[5,-79,31,17,3,180,"stone"], [173,-81,32,18,3,180,"brick"],
	[214,-82,30,17,4,180,"plaster"], [256,-80,30,18,3,180,"stone"],
	[-219,113,30,20,3,0,"brick"], [-125,113,31,20,3,0,"stone"],
	[-84,114,29,20,3,0,"plaster"], [-43,113,29,20,4,0,"brick"],
	[-3,114,29,20,3,0,"stone"], [56,115,35,19,4,0,"plaster"],
	[108,113,32,20,3,0,"brick"], [-126,236,31,20,2,0,"stone"],
	[-75,236,28,21,3,0,"plaster"], [-28,236,27,20,2,0,"brick"],
	[38,236,30,20,3,0,"stone"], [94,235,27,20,2,0,"plaster"],
]

const LANDMARKS := [
	["market","Northline Market",-16.0,13.0],
	["apartment","Hillview Apartments",-52.0,13.0],
	["park","Juniper Park",73.0,-55.0],
	["aid","Emergency Aid Station",256.0,23.0],
	["lookout","West Ridge Overlook",-320.0,342.0],
]

var host: Node3D
var batches: Dictionary = {}
var fence_material: ShaderMaterial


func _init(world: Node3D) -> void:
	host = world


func build() -> void:
	fence_material = ShaderMaterial.new()
	fence_material.shader = NET
	for row: Array in BUILDINGS:
		_building(row)
	_place_models()
	_park()
	_greens()
	_overlook()
	_finish_boxes()


func _piece(key: String, at: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	if not batches.has(key):
		batches[key] = []
	batches[key].append(Transform3D(basis.scaled_local(size),at))


func _building(row: Array) -> void:
	var x: float = row[0]
	var z: float = row[1]
	var width: float = row[2]
	var depth: float = row[3]
	var floors: int = row[4]
	var angle := deg_to_rad(row[5])
	var basis := Basis(Vector3.UP,angle)
	var lot := host.at(x,z,-0.54) as Vector3
	var height := floors*3.05 + 0.45
	_piece(row[6],lot+Vector3.UP*(height*0.5),Vector3(width,height,depth),basis)
	host.solid(host.structures,lot+Vector3.UP*height*0.5,Vector3(width,height,depth),angle)
	_piece("foundation",lot+Vector3.UP*0.87,Vector3(width+0.16,1.65,depth+0.16),basis)
	_piece("coping",lot+Vector3.UP*height,Vector3(width+0.36,0.24,depth+0.36),basis)
	_piece("roof",lot+Vector3.UP*(height+0.45)+basis*Vector3(width*0.20,0,depth*0.1),Vector3(3.15,0.98,2.25),basis)
	for side: float in [-1.0,1.0]:
		for story in floors:
			var y := 2.00+story*3.05
			var front := side*(depth*0.5+0.035)
			_piece("coping",lot+basis*Vector3(0,y-1.14,front),Vector3(width+0.20,0.15,0.26),basis)
			var count := maxi(3,roundi(width/3.9))
			for i in count:
				var dx := ((i+0.5)/count-0.5)*width
				var glass := "glass_warm" if (int(x)+i*7+story*3) % 17 == 0 else "glass"
				_piece("frame",lot+basis*Vector3(dx,y,front),Vector3(2.24,1.84,0.10),basis)
				_piece(glass,lot+basis*Vector3(dx,y,front+side*0.075),Vector3(2.08,1.66,0.08),basis)
				_piece("frame",lot+basis*Vector3(dx,y,front+side*0.133),Vector3(0.066,1.70,0.037),basis)
				_piece("coping",lot+basis*Vector3(dx,y-0.94,front+side*0.12),Vector3(2.38,0.11,0.31),basis)
				if side < 0.0 and story > 0 and (i+story+int(absf(x))) % 5 == 0:
					_piece("coping",lot+basis*Vector3(dx,y-1.06,front-0.58),Vector3(2.74,0.16,1.22),basis)
					_piece("frame",lot+basis*Vector3(dx,y-0.56,front-1.14),Vector3(2.68,0.043,0.055),basis)
					for bar in 9:
						_piece("frame",lot+basis*Vector3(dx-1.24+bar*0.31,y-0.80,front-1.14),Vector3(0.035,0.55,0.035),basis)
			var bays := maxi(2,roundi(depth/5.0))
			for j in bays:
				var along := ((j+0.5)/bays-0.5)*depth
				var edge := side*(width*0.5+0.03)
				_piece("frame",lot+basis*Vector3(edge,y,along),Vector3(0.09,1.72,1.97),basis)
				_piece("glass",lot+basis*Vector3(edge+side*0.062,y,along),Vector3(0.08,1.55,1.79),basis)
	_piece("frame",lot+basis*Vector3(0,1.68,-depth*0.5-0.11),Vector3(1.62,2.60,0.13),basis)
	_piece("coping",lot+basis*Vector3(0,3.23,-depth*0.5-0.73),Vector3(3.45,0.20,1.43),basis)


func _place_models() -> void:
	for row: Array in [
		["0082",-198,-54,90,0.81], ["apartment_block",-120,-151,180,0.80],
		["0082",83,-129,180,0.88], ["0082",199,-126,0,0.81],
		["0082",-209,152,0,0.78], ["0082",60,166,180,0.77],
		["0087",-74,-15,180,0.91], ["0088",-105,-12.9,180,0.88],
		["0021",-37,-9.8,180,0.91], ["0021",113,9.4,0,0.86],
		["0147",254,22,0,1], ["0154",245,10.6,-90,0.97],
		["0156",-38,-12.1,180,0.86], ["0156",261,17,0,0.81],
		["backpack",-39,-12.7,143,0.94], ["backpack",258.3,21,54,0.87],
		["0165",-108,2.6,90,0.99], ["0164",88,-2.8,90,1],
		["0164",157,2.65,-88,0.98], ["0165",284,-2.7,91,1],
		["0187",99,-37,180,1], ["0243",77,-66,0,0.60],
		["0197",-91,-9.2,180,0.72], ["0197",2,-9.1,0,0.82],
		["0197",-42,9.5,0,0.58], ["0202",-24,11.1,0,0.79],
		["0203",-3,8.9,0,0.79], ["0203",51,-16.0,0,0.86],
		["0181",-48,8.9,0,0.92], ["0181",107,-43,90,1],
		["0181",258,20,90,0.82], ["wheel_stop",239,12,0,1],
		["tape",263.0,16.5,0,0.89],
	]:
		host.prop(row[0],row[1],row[2],row[3],row[4],row[0] in ["0082","apartment_block","0087","0088","0021","0154","0164","0165","0197","0181","0187"])
	for x: float in [-214,-180,-132,-99,-62,-29,9,56,94,126,174,208,243,275,313,350]:
		host.prop("0180",x,-7.9,180,0.88,false)
	for x: float in [-192,-141,-91,-42,10,55,103,170,225,275,328]:
		host.prop("0180",x,7.9,0,0.86,false)
	for x: float in [-158,27,145]:
		host.prop("0024",x-5.1,-5.9,180,0.86,false)
		host.prop("0024",x+5.1,6.1,0,0.86,false)
	for x: float in [240,243,246,269,272,275]:
		host.prop("0195",x,4.7,0,1,false)
	for x: float in [247,250,254,258,262,266]:
		host.prop("0183",x,12.9,0,1,false)
	if host.library.entries.has("online_bench"):
		host.prop("online_bench",44,-17.0,90,0.91,true)
		host.prop("online_bench",77,-76.0,180,0.91,true)
		host.prop("online_bench",-65,-9.5,180,0.90,true)
	host.sign("NORTHLINE MARKET",host.at(-16,12.73,2.80),0,0.016,false)
	host.sign("HILLVIEW  /  16–22",host.at(-52,12.72,2.66),0,0.015,false)
	host.sign("JUNIPER PARK",host.at(47,-19.0,1.38),180,0.015,true)
	host.sign("EMERGENCY AID",host.at(253,15.1,1.90),0,0.019,true)
	host.sign("ROAD CLOSED",host.at(420.6,0,1.48),90,0.021,true)
	_barrier(421.0,-4.1,421.0,4.1)
	_barrier(306.0,-105.0,306.0,-101.3)


func _barrier(ax: float, az: float, bx: float, bz: float) -> void:
	var middle := host.at((ax+bx)*0.5,(az+bz)*0.5,0.56) as Vector3
	var axis := Vector2(bx-ax,bz-az)
	var angle := atan2(axis.x,axis.y)
	var basis := Basis(Vector3.UP,angle)
	_piece("coping",middle,Vector3(0.43,1.1,axis.length()),basis)
	host.solid(host.structures,middle,Vector3(0.43,1.1,axis.length()),angle)


func _park() -> void:
	host.prop("0237",73,-46.5,0,1,false)
	# The entry gaps are aligned with the paths from the street.
	for span: Array in [
		[43,-20,49,-20], [52.2,-20,94.7,-20], [97.9,-20,104,-20],
		[43,-20,43,-75], [104,-20,104,-75], [43,-75,104,-75],
	]:
		_fence(span)
	for planter: Array in [[55,-32],[92,-32],[51,-57],[99,-60],[61,-71],[92,-71]]:
		host.prop("0203",planter[0],planter[1],180,0.84,false)
	for item: Array in [[57,-25,0],[85,-25,0],[101,-52,90],[47,-47,90]]:
		host.prop("0181",item[0],item[1],item[2],0.91,true)
	host.prop("0202",56,-52,90,0.88,false)
	host.prop("0202",91,-49,90,0.88,false)


func _fence(span: Array) -> void:
	var a := Vector2(span[0],span[1])
	var b := Vector2(span[2],span[3])
	var segments := maxi(1,ceili(a.distance_to(b)/3.0))
	var delta := (b-a).normalized()
	var angle := atan2(delta.x,delta.y)
	var basis := Basis(Vector3.UP,angle)
	for i in segments:
		var start := a.lerp(b,float(i)/segments)
		var end := a.lerp(b,float(i+1)/segments)
		var length := start.distance_to(end)
		var mid := (start+end)*0.5
		var ground := host.at(mid.x,mid.y) as Vector3
		host.solid(host.structures,ground+Vector3.UP*0.77,Vector3(0.12,1.54,length),angle)
		var panel := QuadMesh.new()
		panel.size = Vector2(length,1.32)
		var instance := MeshInstance3D.new()
		instance.mesh = panel
		instance.material_override = fence_material
		instance.rotation.y = angle+PI*0.5
		instance.position = ground+Vector3.UP*0.76
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		host.structures.add_child(instance)
		for y: float in [0.13,1.46]:
			_piece("frame",ground+Vector3.UP*y,Vector3(0.043,0.046,length),basis)
		_piece("frame",host.at(start.x,start.y,0.77),Vector3(0.065,1.54,0.065))
	_piece("frame",host.at(b.x,b.y,0.77),Vector3(0.065,1.54,0.065))


func _greens() -> void:
	for x: float in [-204,-176,-141,-108,-77,-52,-21,5,43,68,94,122,168,193,220,249,276,306,343]:
		host.tree("alder" if int(x) % 2 == 0 else "0198",x,-10.2,0.59+float(absi(int(x))%6)*0.045)
	for x: float in [-205,-171,-140,-111,-87,-64,-29,-6,53,78,109,131,173,204,224,285,323]:
		host.tree("0198",x,10.2,0.62+float(absi(int(x))%4)*0.045)
	for pos: Vector2 in [Vector2(47,-68),Vector2(54,-35),Vector2(58,-64),Vector2(65,-32),
		Vector2(91,-37),Vector2(96,-69),Vector2(93,-60),Vector2(73,-68),Vector2(96,-27),Vector2(78,-35)]:
		host.tree("alder",pos.x,pos.y,0.74)
	for row in 6:
		for col in 28:
			var x := -457.0+col*33.6+sin(float(row*7+col)*2.73)*9.0
			var z := -249.0-row*41.0+cos(col*1.8+row)*12.0
			var species := "pine_far" if (col+row) % 4 else "fir_far"
			if row < 2:
				species = "pine_mid" if (col+row)%4 else "fir_mid"
			host.wood(species,x,z,0.65+float((col+row*3)%7)*0.092)
	for row in 5:
		for col in 26:
			var x := -465.0+col*37.0+cos(row*6.3+col*2.4)*12.0
			var z := 309.0+row*35.0+sin(col*2.12+row)*13.0
			if absf(x-145.0)<12 or (x < -255 and absf(z-335.0) < 16):
				continue
			host.wood("fir_far" if col % 4 == 0 else "pine_far",x,z,0.68+float((col+row)%7)*0.077)
	for z: float in [121,157,190,225,266,303,353,393,430]:
		host.wood("pine_far", -465,z,0.98)
		host.wood("fir_far", 464,z,0.92)


func _overlook() -> void:
	host.prop("0003",-331,352,42,1.17,true)
	host.prop("0003",-305,356,24,0.83,true)
	host.prop("0181",-319,344,180,1,true)
	host.prop("0181",-313,341,170,1,true)
	host.sign("WEST RIDGE OVERLOOK",host.at(-319,338,1.55),0,0.016,true)
	_barrier(-325,344,-313,347)


func _finish_boxes() -> void:
	for key: String in batches:
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		box.material = host.materials[key]
		host.instances(host.structures,box,batches[key],key in ["brick","stone","plaster","coping","roof"])
