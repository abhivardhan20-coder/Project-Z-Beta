extends RefCounted

var entries: Dictionary
var scenes: Dictionary = {}
var textures: Dictionary = {}
var static_meshes: Dictionary = {}


func _init() -> void:
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))


func texture(path: String) -> Texture2D:
	if textures.has(path):
		return textures[path]
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var status := image.load_jpg_from_buffer(bytes) if path.ends_with(".jpg") else image.load_png_from_buffer(bytes)
	if status != OK:
		push_error("Could not decode " + path)
		return null
	image.generate_mipmaps()
	var result := ImageTexture.create_from_image(image)
	textures[path] = result
	return result


func instantiate(key: String) -> Node3D:
	var row: Dictionary = entries[key]
	var scene := _scene(row["path"])
	if scene == null:
		return null
	var root := scene.instantiate() as Node3D
	for relative: String in row.get("children", {}):
		var child_scene := _scene(row["children"][relative])
		var anchor := root.get_node_or_null(relative)
		if anchor and child_scene:
			anchor.add_child(child_scene.instantiate())
	return root


func bounds(key: String) -> AABB:
	var a: Array = entries[key]["bounds"]
	var lo := Vector3(a[0], a[1], a[2])
	var hi := Vector3(a[3], a[4], a[5])
	return AABB(lo, hi-lo)


func static_mesh(key: String) -> ArrayMesh:
	if static_meshes.has(key):
		return static_meshes[key]
	var source := instantiate(key)
	if source == null:
		return null
	var surfaces := {}
	_append_surfaces(source,Transform3D.IDENTITY,surfaces)
	var mesh := ArrayMesh.new()
	for tool: SurfaceTool in surfaces.values():
		tool.commit(mesh)
	source.free()
	static_meshes[key] = mesh
	return mesh


func _append_surfaces(node: Node3D,parent: Transform3D,surfaces: Dictionary) -> void:
	var pose := parent*node.transform
	if node is MeshInstance3D and node.mesh:
		_append_mesh(node,pose,surfaces)
	for child in node.get_children():
		if child is Node3D:
			_append_surfaces(child,pose,surfaces)


func _append_mesh(node: MeshInstance3D,pose: Transform3D,surfaces: Dictionary) -> void:
	for index in node.mesh.get_surface_count():
		var material := node.get_active_material(index)
		if not surfaces.has(material):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(material)
			surfaces[material] = tool
		surfaces[material].append_from(node.mesh,index,pose)


func batch_vehicle(model: Node3D) -> void:
	var groups := {}
	var originals: Array[MeshInstance3D] = []
	_vehicle_branch(model,model,Transform3D.IDENTITY,groups,originals)
	for anchor: Node3D in groups:
		var mesh := ArrayMesh.new()
		for tool: SurfaceTool in groups[anchor].values():
			tool.commit(mesh)
		var draw := MeshInstance3D.new()
		draw.mesh = mesh
		anchor.add_child(draw)
	for node: MeshInstance3D in originals:
		if node.get_child_count() == 0:
			node.queue_free()
		else:
			node.hide()


func _vehicle_branch(node: Node3D,anchor: Node3D,parent: Transform3D,groups: Dictionary,originals: Array[MeshInstance3D]) -> void:
	var pose := parent*node.transform
	var label := String(node.name)
	if label == "HINGE_DOOR_FL" or label.begins_with("HINGE_WHEEL_"):
		anchor = node
		pose = Transform3D.IDENTITY
	if node is MeshInstance3D and node.mesh:
		if not groups.has(anchor):
			groups[anchor] = {}
		_append_mesh(node,pose,groups[anchor])
		originals.append(node)
	for child in node.get_children():
		if child is Node3D:
			_vehicle_branch(child,anchor,pose,groups,originals)


func _scene(path: String) -> PackedScene:
	if scenes.has(path):
		return scenes[path]
	if not (path.ends_with(".glb") or path.ends_with(".gltf")):
		var resource := load(path) as PackedScene
		scenes[path] = resource
		return resource
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path,state) != OK:
		push_error("Cannot load " + path)
		return null
	var root := document.generate_scene(state)
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var fallback_materials := {}
	if root is MeshInstance3D:
		meshes.append(root)
	for node in meshes:
		var mesh := node.mesh as ArrayMesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as StandardMaterial3D
			if material and material.normal_enabled and (mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_TANGENT) == 0:
				if not fallback_materials.has(material):
					var fallback := material.duplicate() as StandardMaterial3D
					fallback.normal_enabled = false
					fallback_materials[material] = fallback
				mesh.surface_set_material(surface, fallback_materials[material])
	var scene := PackedScene.new()
	var status := scene.pack(root)
	root.free()
	if status != OK:
		return null
	scenes[path] = scene
	return scene
