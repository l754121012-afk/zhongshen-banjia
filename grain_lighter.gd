extends Node3D

const Art=preload("res://workshop.gd")
const Mooring:=Vector2(7,-19)
const TOW_LENGTH:=5.7
var art:=Art.new()
var hull:Node3D
var bowflag:Node3D
var sacks:Array[Node3D]=[]
var ropes:Array[MeshInstance3D]=[]
var rope_material:=StandardMaterial3D.new()
var velocity:=Vector2.ZERO
var location:=Mooring
var yaw:=PI
var towing:=false
var alongside:=false
var impacts:=0
var strain:=0.
var bump_left:=0.
var mooring_age:=-1.
var mooring_from:=Vector2.ZERO
var mooring_to:=Vector2.ZERO
var mooring_yaw:=0.
var drift:=0.
var lantern:OmniLight3D
var shed:Node3D

func _ready()->void:
	hull=art.group(self)
	build_hull()
	art.box(hull,Vector3.UP*.26,Vector3(4.42,.26,1.94),"#ad865c")
	for side in [-1,1]:
		art.beam(hull,Vector3(-2.18,.64,side*.92),Vector3(2.18,.64,side*.92),.092,"#397b7c")
		art.beam(hull,Vector3(2.18,.64,side*.92),Vector3(2.85,.84,0),.092,"#397b7c")
		for x in [-1.75,0,1.78]:art.beam(hull,Vector3(x,.25,side*.92),Vector3(x,.68,side*.92),.047,"#a8784b")
	for j in 7:
		var pack:=art.group(hull,Vector3(-1.49+(j%3)*.91,.47+(j/6)*.55,-.39+(j/3%2)*.77))
		art.ball(pack,Vector3.UP*.27,Vector3(.92,.65,.73),"#d4be8f" if j%2 else "#ae9870",true)
		art.beam(pack,Vector3(-.35,.54,0),Vector3(.33,.54,0),.032,"#756046")
		sacks.append(pack)
	art.beam(hull,Vector3(-1.68,.40,0),Vector3(-1.68,3.24,0),.058,"#a37d51")
	bowflag=art.group(hull,Vector3(-1.68,2.87,0))
	for i in 5:
		art.box(bowflag,Vector3(.12+i*.17,-.08*i,.04*sin(i*.8)),Vector3(.18,.34-.035*i,.038),"#b65e3f" if i%2 else "#dbc799")
	var house:=art.group(hull,Vector3(1.64,.58,0));art.beam(house,Vector3.ZERO,Vector3.UP*1.3,.052,"#8d6a41")
	var glow:=art.ball(house,Vector3(.12,1.13,0),Vector3(.39,.48,.39),"#ffbf66",true)
	var lightmat:=StandardMaterial3D.new();lightmat.albedo_color=Color("#ffc173");lightmat.emission_enabled=true;lightmat.emission=Color("#ffbd64");glow.material_override=lightmat
	lantern=OmniLight3D.new();house.add_child(lantern);lantern.position=Vector3.UP*1.2;lantern.light_color=Color("#ffbd6c");lantern.light_energy=1.4;lantern.omni_range=5.
	rope_material.albedo_color=Color("#c8a476")
	for j in 4:
		var mesh:=CylinderMesh.new();mesh.top_radius=.045;mesh.bottom_radius=.045;mesh.height=1.;mesh.radial_segments=6;mesh.rings=0
		var segment:=MeshInstance3D.new();segment.mesh=mesh;segment.material_override=rope_material;add_child(segment);ropes.append(segment);segment.hide()
	place()

func build_hull()->void:
	# Seven transverse frames define a shallow working boat with a raised prow.
	var stations:=[Vector3(-2.88,.18,.40),Vector3(-2.38,.78,.15),Vector3(-1.45,1.07,.02),Vector3(0,1.13,0),Vector3(1.45,1.06,.05),Vector3(2.38,.72,.29),Vector3(2.95,.06,.65)]
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var palette:=[Color("#4b4e45"),Color("#6c5343"),Color("#89684a"),Color("#337d7b")]
	var heights:=[-.54,-.34,-.03,.29,.51]
	var widths:=[.13,.65,.91,1.,1.02]
	for side in [-1,1]:
		for j in stations.size()-1:
			var a:Vector3=stations[j];var b:Vector3=stations[j+1]
			for k in 4:
				var points:PackedVector3Array=[]
				for frame:Vector3 in [a,b]:
					for level in [k,k+1]:
						points.append(Vector3(frame.x,heights[level]+frame.z,side*frame.y*float(widths[level])))
				for vertex in ([0,1,3,0,3,2] if side<0 else [0,3,1,0,2,3]):
					mesh.set_color(palette[k].lightened(.025*(j%2)));mesh.add_vertex(points[vertex])
			art.beam(hull,Vector3(a.x,a.z+.52,side*a.y),Vector3(b.x,b.z+.52,side*b.y),.035,"#d0aa71")
			if j>0:
				art.beam(hull,Vector3(a.x,.20,side*a.y*.85),Vector3(a.x,a.z+.48,side*a.y*.95),.035,"#997049")
	mesh.generate_normals()
	var outer:=MeshInstance3D.new();outer.mesh=mesh.commit();hull.add_child(outer)
	var paint:=StandardMaterial3D.new();paint.vertex_color_use_as_albedo=true;paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.roughness=.84;outer.material_override=paint
	for j in 10:
		var x:float=(j-4.5)*.41
		art.box(hull,Vector3(x,.406,0),Vector3(.39,.027,1.84),"#ab8964" if j%2 else "#b6956d")
	for side in [-1,1]:
		art.box(hull,Vector3(-.87,.06,side*1.12),Vector3(.88,.34,.03),"#345e58")
		for k in 4:
			art.beam(hull,Vector3(-1.16+k*.10,-.05,side*1.15),Vector3(-1.05+k*.10,.17,side*1.15),.017,"#d2b377")
	for h in 3:art.ring(hull,Vector3(1.9,.48+h*.036,-.53),.22+.024*h,.029,"#c8aa79")
	for j in 5:
		art.box(hull,Vector3(-1.52+j*.15,1.04,-.33),Vector3(.16,.075,.94),"#64898b" if j%2 else "#a8b9ac").rotation.x=.12

func moor_to(dock:Vector2)->void:
	set_tow(false);mooring_age=0.;mooring_from=location;mooring_to=dock;mooring_yaw=yaw
	velocity=Vector2.ZERO

func place()->void:
	hull.position=Vector3(location.x,.12,location.y)
	hull.rotation.y=-yaw

func set_tow(on:bool)->void:
	towing=on
	for segment in ropes:segment.visible=on

func tick(dt:float,stern:Vector2,forward:Vector2,rocks:Array[Vector3],t:float)->bool:
	var hit:=false
	bump_left=maxf(0.,bump_left-dt)
	if towing:
		var diff:=stern-location
		var direction:=diff.normalized()
		var pull:=maxf(0.,diff.length()-TOW_LENGTH)
		strain=clampf(pull/2.5,0.,1.)
		velocity+=direction*pull*8.9*dt
		velocity*=exp(-dt*.87)
		location+=velocity*dt
		for rock in rocks:
			var center:=Vector2(rock.x,rock.z)
			var radius:=rock.y+1.12
			if location.distance_to(center)<radius:
				var outward:=center.direction_to(location)
				location=center+outward*radius
				var approach:float=-velocity.dot(outward)
				if approach>1.9 and bump_left<=0.:
					impacts=mini(3,impacts+1);bump_left=2.;hit=true;drift=.23
				velocity+=outward*maxf(0.,approach)*1.12
		if direction.length_squared()>.1:yaw=lerp_angle(yaw,direction.angle(),1.-exp(-dt*2.4))
		var tail:=Vector3(stern.x,.58,stern.y)
		var tip:=Vector3(location.x+cos(yaw)*2.55,.81,location.y+sin(yaw)*2.55)
		for i in 4:
			var a:=float(i)/4.;var b:=float(i+1)/4.
			var p:=tail.lerp(tip,a)-Vector3.UP*sin(PI*a)*(.04+.46*(1.-strain))
			var q:=tail.lerp(tip,b)-Vector3.UP*sin(PI*b)*(.04+.46*(1.-strain))
			var v:=q-p
			ropes[i].position=(p+q)*.5;ropes[i].quaternion=Quaternion(Vector3.UP,v.normalized());ropes[i].scale.y=maxf(.01,v.length())
		rope_material.albedo_color=Color("#d2ba87").lerp(Color("#be734a"),strain)
	else:
		strain=0.
		if mooring_age>=0.:
			mooring_age+=dt
			var weight:=smoothstep(0.,2.35,mooring_age)
			location=mooring_from.lerp(mooring_to,weight);yaw=lerp_angle(mooring_yaw,.82*PI,weight)
			if mooring_age>=2.35:mooring_age=-1.
	place()
	drift=move_toward(drift,0.,dt*.23)
	hull.rotation.x=.043*sin(t*1.6)+drift*sin(t*9.4)
	hull.position.y+=.055*sin(t*1.18)
	bowflag.rotation.y=.16*sin(t*2.7)
	for i in sacks.size():sacks[i].rotation.z=drift*sin(t*6.+i)
	return hit
