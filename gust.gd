extends Node3D
var radius:=0.38
var reach:=3.0
var age:=0.0
var duration:=1.0
var geom:=ImmediateMesh.new()
var model:=MeshInstance3D.new()
var paint:=StandardMaterial3D.new()

func start(parent: Node3D, origin: Vector3, dir: Vector3, size: float, life: float) -> void:
	parent.add_child(self)
	position=origin
	basis=Basis(Quaternion(Vector3.RIGHT,dir.normalized()))
	reach=size
	duration=life
	radius=clampf(size*0.13,0.25,0.57)
	paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.vertex_color_use_as_albedo=true
	paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	model.mesh=geom
	model.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(model)
	draw_ribbons()

func advance(dt: float) -> bool:
	age+=dt
	if age>=duration:
		queue_free()
		return false
	draw_ribbons()
	return true

func draw_ribbons() -> void:
	geom.clear_surfaces()
	var envelope:=minf(1.0,age*8.0+0.06)*minf(1.0,(duration-age)*3.0)
	for strand in 4:
		geom.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP,paint)
		var start:=fmod(age*(0.57+0.09*strand)+0.21*strand,0.63)
		for k in 18:
			var part:=k/17.0
			var u:=start+part*0.39
			var a:=u*6.85-age*6.0+strand*PI/2.0
			var r:=radius*(0.15+u)
			var center:=Vector3(u*reach,sin(a)*r+u*0.16,cos(a)*r)
			var thickness:=(0.009+0.035*sin(part*PI))*envelope
			var col:=Color("#e0f5e5") if strand%2==0 else Color("#9cdbcb")
			col.a=envelope*(0.42+sin(part*PI)*0.51)
			geom.surface_set_color(col)
			geom.surface_add_vertex(center+Vector3(0,thickness,0))
			geom.surface_set_color(col)
			geom.surface_add_vertex(center-Vector3(0,thickness,0))
		geom.surface_end()

