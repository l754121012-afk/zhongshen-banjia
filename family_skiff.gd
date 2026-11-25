extends RefCounted

var art:=preload("res://workshop.gd").new()
var sail:MeshInstance3D
var sign:Node3D

func build(parent:Node3D,trade_color:=Color.TRANSPARENT)->void:
	var hull:=SurfaceTool.new();hull.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		for j in 12:
			for c:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var u:float=(i+c.x)/24.;var a:=PI*(j+c.y)/12.
				var bow:=pow(absf(2.*u-1.),2.8);var width:=.89*pow(maxf(.003,sin(PI*u)),.69)
				hull.set_color(Color("#637f76") if j<2 or j>9 else (Color("#915c42") if j%2 else Color("#a67956")))
				hull.add_vertex(Vector3((u-.5)*5.65,.30+.37*bow-.83*sin(a),width*cos(a)))
	hull.generate_normals()
	var skin:=MeshInstance3D.new();skin.mesh=hull.commit();var m:=StandardMaterial3D.new();m.vertex_color_use_as_albedo=true;m.roughness=.82;m.cull_mode=BaseMaterial3D.CULL_DISABLED;skin.material_override=m;parent.add_child(skin)
	art.box(parent,Vector3(0,.26,0),Vector3(3.54,.14,1.33),"#ad8762")
	art.beam(parent,Vector3(.46,.30,0),Vector3(.46,4.08,0),.067,"#8b6a47")
	art.beam(parent,Vector3(-1.49,2.35,.04),Vector3(1.44,4.00,.04),.052,"#aa8152")
	for side in [-1.,1.]:
		art.beam(parent,Vector3(.46,3.95,0),Vector3(side*2.46,.54,.19),.014,"#baad89")
		for i in 14:
			var a:=i/14.;var b:=(i+1)/14.
			art.beam(parent,rail(a,side),rail(b,side),.041,"#d4a367")
	var cloth:=SurfaceTool.new();cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 14:
		for j in 12:
			for c:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var u:float=(i+c.x)/14.;var v:float=(j+c.y)/12.
				var top:=Vector3(lerpf(-1.45,1.40,u),lerpf(2.35,3.97,u),.04)
				var foot:=Vector3(lerpf(-1.17,.92,u),lerpf(1.18,1.43,u),.14)
				var vertex:=top.lerp(foot,v);vertex.z+=.34*sin(PI*u)*sin(PI*v)
				var color:=Color("#c35e46")
				if j in [2,4]:color=Color("#f3cf9d")
				elif j>=9:color=Color("#943e33")
				elif i%4==0:color=Color("#b7513e")
				if trade_color.a>0.:
					color=trade_color.lightened(.19) if i in [4,9] else trade_color.darkened(.09 if j>=9 else 0.)
				cloth.set_color(color);cloth.add_vertex(vertex)
	cloth.generate_normals();sail=MeshInstance3D.new();sail.mesh=cloth.commit();sail.material_override=m;parent.add_child(sail)
	sign=art.group(parent,Vector3(1.8,.50,0))
	art.beam(sign,Vector3.ZERO,Vector3.UP*.70,.033,"#8d7251")
	var bulb:=art.ball(sign,Vector3.UP*.65,Vector3(.22,.28,.22),"#ffcc81")
	var glass:=StandardMaterial3D.new();glass.albedo_color=Color("#ffdda3");glass.emission_enabled=true;glass.emission=Color("#ffc46e");glass.emission_energy_multiplier=1.6;bulb.material_override=glass

func rail(u:float,side:float)->Vector3:
	return Vector3((u-.5)*5.65,.315+.37*pow(absf(2.*u-1.),2.8),side*.89*pow(maxf(.003,sin(PI*u)),.69))

