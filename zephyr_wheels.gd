extends RefCounted
const Art=preload("res://workshop.gd")
var a:=Art.new()
var puffs:Array[MeshInstance3D]=[]
var marks:Array[MeshInstance3D]=[]
var ages:=PackedFloat32Array()
var mark_ages:=PackedFloat32Array()
var drift:Array[Vector3]=[]
var puff_index:=0
var mark_index:=0
var distance:=0.
var trace_distance:=0.
var job
func build(owner_job)->void:
	job=owner_job
	for i in 20:
		var n:=a.ball(job,Vector3.ZERO,Vector3.ONE*.1,"#b3a077",true)
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;n.hide();puffs.append(n);ages.append(2.);drift.append(Vector3.ZERO)
	for i in 36:
		var n:=a.box(job,Vector3.ZERO,Vector3(.62,.012,.12),"#9b8564")
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;n.hide();marks.append(n);mark_ages.append(9.)
func airborne()->void:
	distance=0;trace_distance=0
func update(dt:float,meters:float,kind:int)->void:
	distance+=meters;trace_distance+=meters
	var emits:bool=not job.airborne and absf(job.speed)>3.3 and kind!=3
	if emits and distance>(.74 if kind==2 else .99):
		distance=0
		for s in [-1,1]:
			var n:=puffs[puff_index];var foot:Vector3=job.truck.to_global(Vector3(-1.94,.25,s*1.03))
			n.position=foot;ages[puff_index]=0.;drift[puff_index]=Vector3(-cos(job.heading)*.45,.51,sin(job.heading)*.45)+Vector3(.14,.04,.32)*s
			n.show();puff_index=(puff_index+1)%puffs.size()
	if emits and trace_distance>.77 and kind in [1,2]:
		trace_distance=0.
		for s in [-1,1]:
			var n:=marks[mark_index];var foot:Vector3=job.truck.to_global(Vector3(-2.25,0,s*1.03));var p:=Vector2(foot.x,foot.z)
			var g:float=job.land.ground(p)
			var tangent:=Vector3(cos(job.heading),0,-sin(job.heading))
			var road_normal:=Vector3(job.land.ground(p-Vector2.RIGHT*.48)-job.land.ground(p+Vector2.RIGHT*.48),.96,job.land.ground(p-Vector2.DOWN*.48)-job.land.ground(p+Vector2.DOWN*.48)).normalized()
			var side:=tangent.cross(road_normal).normalized();var front:=road_normal.cross(side).normalized()
			n.position=Vector3(foot.x,g+.043,foot.z);n.basis=Basis(front,road_normal,side).scaled_local(Vector3(.60,.013,.115));n.show()
			mark_ages[mark_index]=0.;mark_index=(mark_index+1)%marks.size()
	for i in puffs.size():
		if not puffs[i].visible:continue
		ages[i]+=dt;var t:=ages[i]/.78;var n:=puffs[i]
		if t>=1:n.hide();continue
		n.position+=drift[i]*dt;n.scale=Vector3(1.3,.70,.83)*(.04+.24*sin(t*PI))
	for i in marks.size():
		if not marks[i].visible:continue
		mark_ages[i]+=dt
		if mark_ages[i]>7.0:marks[i].hide()
