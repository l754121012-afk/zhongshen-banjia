extends RefCounted

const CUT_SHADER:=preload("res://porter_cutaway.gdshader")
const RADIUS_SCALE:=2.5
var nearby:Array[MeshInstance3D]=[]
var original:Dictionary={}
var materials:Dictionary={}
var surfaces:Dictionary={}

func collect(root:Node3D,courier:Node3D,truck:Node3D)->void:
	for part:MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if not part.mesh or courier.is_ancestor_of(part): continue
		var box:AABB=part.global_transform*part.get_aabb()
		if box.size.y<0.10 or box.get_longest_axis_size()>38: continue
		if box.grow(28).has_point(truck.global_position): nearby.append(part)

func cut_material(source:StandardMaterial3D)->ShaderMaterial:
	if materials.has(source): return materials[source]
	var mat:=ShaderMaterial.new()
	mat.shader=CUT_SHADER
	mat.set_shader_parameter("radius_scale",RADIUS_SCALE)
	mat.set_shader_parameter("tint",source.albedo_color)
	if source.albedo_texture: mat.set_shader_parameter("paint",source.albedo_texture)
	mat.set_shader_parameter("roughness",source.roughness)
	mat.set_shader_parameter("metallic",source.metallic)
	materials[source]=mat
	return mat

func open_part(part:MeshInstance3D)->void:
	var override:=part.material_override
	if override:
		if not override is StandardMaterial3D: return
		original[part]=[override]
		part.material_override=cut_material(override)
		return
	var saved:Array=[null]
	for i in part.mesh.get_surface_count():
		saved.append(part.get_surface_override_material(i))
		var source:=part.get_active_material(i)
		if source is StandardMaterial3D:
			part.set_surface_override_material(i,cut_material(source))
	original[part]=saved

func close_part(part:MeshInstance3D)->void:
	var saved:Array=original[part]
	part.material_override=saved[0]
	for i in range(1,saved.size()): part.set_surface_override_material(i-1,saved[i])
	original.erase(part)

func update(cam:Camera3D,courier:Node3D)->void:
	var feet:=courier.global_position
	var eye:=cam.global_position
	var center:=feet+Vector3.UP*0.91
	# Require coverage from the cap to both boots, including the visible sides of the torso.
	var probes:Array[Vector3]=[]
	for point:Vector3 in [Vector3(0,1.98,0),Vector3(-0.32,1.72,0),Vector3(0.32,1.72,0),
			Vector3(-0.38,1.10,0),Vector3(0,1.05,0),Vector3(0.38,1.10,0),
			Vector3(0,0.56,0),Vector3(-0.19,0.12,0.04),Vector3(0.19,0.12,0.04)]:
		var world:=courier.to_global(point)
		probes.append(world+world.direction_to(eye)*0.14)
	var candidates:Array[MeshInstance3D]=[]
	for part in nearby:
		if not part.is_visible_in_tree(): continue
		var bounds:AABB=part.global_transform*part.get_aabb()
		if bounds.end.y<feet.y+0.08 or bounds.grow(1.5*RADIUS_SCALE).intersects_segment(eye,center)==null: continue
		candidates.append(part)
		if probes.is_empty(): continue
		var local_eye:=part.to_local(eye)
		var local_box:=part.get_aabb()
		for i in range(probes.size()-1,-1,-1):
			var target:=part.to_local(probes[i])
			if local_box.intersects_segment(local_eye,target)==null: continue
			if not surfaces.has(part.mesh):
				surfaces[part.mesh]=part.mesh.generate_triangle_mesh()
			var geometry:TriangleMesh=surfaces[part.mesh]
			if geometry and not geometry.intersect_segment(local_eye,target).is_empty():
				probes.remove_at(i)
	if not probes.is_empty(): candidates.clear()
	for part in original.keys():
		if not candidates.has(part): close_part(part)
	for part in candidates:
		if not original.has(part): open_part(part)
	for mat:ShaderMaterial in materials.values():
		mat.set_shader_parameter("subject",center)
		mat.set_shader_parameter("actor_floor",feet.y)
		mat.set_shader_parameter("camera_eye",eye)

func clear()->void:
	for part in original.keys():
		if is_instance_valid(part): close_part(part)
	nearby.clear()
	materials.clear()
	surfaces.clear()
