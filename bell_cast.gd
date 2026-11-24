extends Node3D

var art:=preload("res://workshop.gd").new()
var tongue:Node3D
var body:Node3D
var eyelids:Array[Node3D]=[]
var eyes:Array[Node3D]=[]
var wake:=0.0

func _ready()->void:
	body=art.group(self)
	var profile:Array[Vector2]=[Vector2(.66,.04),Vector2(.76,.075),Vector2(.77,.15),Vector2(.68,.22),Vector2(.55,.44),Vector2(.47,.75),Vector2(.42,1.03),Vector2(.35,1.12),Vector2(.19,1.18),Vector2(.02,1.18),Vector2(.02,1.10),Vector2(.32,1.05),Vector2(.39,.93),Vector2(.49,.44),Vector2(.66,.04)]
	var surf:=SurfaceTool.new();surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in profile.size()-1:
		for j in 48:
			for pair:Vector2i in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
				var v:=profile[i+pair.x];var az:float=TAU*(j+pair.y)/48.
				surf.add_vertex(Vector3(v.x*cos(az),v.y,v.x*sin(az)))
	surf.generate_normals()
	var hull:=MeshInstance3D.new();body.add_child(hull);hull.mesh=surf.commit()
	var bronze:=StandardMaterial3D.new();bronze.albedo_color=Color("#799384");bronze.metallic=.45;bronze.roughness=.36;bronze.cull_mode=BaseMaterial3D.CULL_DISABLED;hull.material_override=bronze
	for v:Vector2 in [Vector2(.755,.13),Vector2(.586,.38),Vector2(.453,.85),Vector2(.425,1.)]:
		art.ring(body,Vector3.UP*v.y,v.x,.023,"#d7ad66")
	for j in 12:
		var az:=TAU*j/12.;var leaf:=art.ball(body,Vector3(.50*cos(az),.65,.50*sin(az)),Vector3(.058,.16,.058),"#d8ba78")
		leaf.rotation.z=.24*cos(az)
	var crown:=art.ring(body,Vector3.UP*1.30,.17,.052,"#9f804f");crown.rotation.x=PI*.5
	face_panel(0.);face_panel(-PI*.5)
	tongue=art.group(body,Vector3.UP*.94)
	art.beam(tongue,Vector3.ZERO,Vector3.DOWN*.83,.043,"#6f5439");art.ball(tongue,Vector3.DOWN*.88,Vector3(.23,.28,.23),"#d29b56")


func face_panel(az:float)->void:
	var seat:=art.group(body);seat.rotation.y=az
	var mask:=art.group(seat,Vector3(0,.63,.524));mask.rotation.x=.26
	var plate:=art.ball(mask,Vector3.ZERO,Vector3(.45,.47,.079),"#59796f")
	plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	art.ball(mask,Vector3(0,-.002,.048),Vector3(.27,.34,.095),"#bb9962")
	art.ball(mask,Vector3(0,-.018,.103),Vector3(.050,.087,.043),"#cfae71")
	art.beam(mask,Vector3(-.037,-.084,.081),Vector3(.036,-.084,.081),.010,"#725e4b")
	for side in [-1.,1.]:
		var lid:=art.group(mask,Vector3(side*.065,.043,.091));eyelids.append(lid)
		art.beam(lid,Vector3(-.038,0,0),Vector3(.037,.005*side,0),.012,"#795e44")
		var eye:=art.ball(mask,Vector3(side*.065,.042,.088),Vector3(.052,.035,.018),"#68ae9a");eyes.append(eye)
		var ear:=art.ring(mask,Vector3(side*.145,.021,.057),.059,.017,"#d2ac6e")
		ear.rotation=Vector3(PI*.5,.12*side,0);ear.scale.x=.69
		for j in 3:
			var leaf:=art.ball(mask,Vector3(side*(.135+j*.029),.096+j*.031,.033),Vector3(.094,.035,.027),"#c5ab71")
			leaf.rotation.z=side*(.68-j*.10)

func answer(amount:float,dt:float)->void:
	wake=lerpf(wake,clampf(amount,0.,1.),1.-exp(-dt*11.))
	for j in eyes.size():
		eyes[j].visible=wake>.055;eyes[j].scale.y=.035*maxf(.07,wake)
		eyelids[j].position.y=.043+.024*wake
