extends Node3D

var craft:=preload("res://workshop.gd").new()
var rain:MultiMeshInstance3D
var cloud:=Node3D.new()
var drops:Array[Vector3]=[]
var wind_socks:Array[Node3D]=[]
var intensity:=0.
var front:=Vector2.ZERO
var wetness:=0.
var time:=0.
var wind:=0.
var ambient:AudioStreamPlayer3D
var world_env:Environment
var sun:DirectionalLight3D
var base_fog:Color
var base_sun:Color

func prepare(g)->void:
	add_child(cloud)
	var rng:=RandomNumberGenerator.new();rng.seed=7514
	for j in 12:
		var x:=rng.randf_range(-11.,11.);var z:=rng.randf_range(-6.,6.)
		var lump:=craft.ball(cloud,Vector3(x,rng.randf_range(-.65,.70),z),Vector3(6.+rng.randf()*5.,2.65+rng.randf()*1.75,5.2+rng.randf()*3.),"#aab6bd" if j%3 else "#b4c2c5",true)
		lump.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var box:=BoxMesh.new();box.size=Vector3(.025,.61,.025)
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color(.68,.8,.82,.49);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;box.material=mat
	var pool:=MultiMesh.new();pool.transform_format=MultiMesh.TRANSFORM_3D;pool.mesh=box
	pool.instance_count=200;rain=MultiMeshInstance3D.new();rain.multimesh=pool;rain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain.custom_aabb=AABB(Vector3(-18,-1,-14),Vector3(36,22,28));add_child(rain)
	for j in pool.instance_count:drops.append(Vector3(rng.randf_range(-14.,14.),rng.randf_range(0.,14.),rng.randf_range(-8.,8.)))
	for x in [57.,103.,127.]:
		var point:Vector3=g.land.surface(Vector2(x,g.land.cove_path(x)-3.5))
		craft.beam(self,point,point+Vector3.UP*3.24,.052,"#85694b")
		var sock:=craft.group(self,point+Vector3.UP*3.1);wind_socks.append(sock)
		for j in 5:
			var bit:=craft.cyl(sock,Vector3(.15+j*.25,0,0),.24-j*.028,.24-j*.028,.28,"#bb674d" if j%2 else "#dec8a6",10)
			bit.rotation.z=PI/2
	ambient=AudioStreamPlayer3D.new();ambient.stream=preload("res://audio/spring_flow.wav");ambient.max_distance=20.;ambient.unit_size=9.;ambient.pitch_scale=1.49;add_child(ambient)
	for item in g.get_children():
		if item is WorldEnvironment:world_env=item.environment;base_fog=world_env.fog_light_color
		if item is DirectionalLight3D:sun=item;base_sun=sun.light_color
	cloud.hide();rain.hide()

func tick(dt:float,g,on:bool)->void:
	if not on:
		if cloud.visible:
			cloud.hide();rain.hide();ambient.stop()
			world_env.fog_light_color=base_fog;sun.light_color=base_sun
		intensity=0.;wetness=0.;return
	time+=dt
	front=Vector2(82.+sin(time*.046+.44)*23.,23.+sin(time*.078+.22)*8.)
	cloud.show();cloud.position=Vector3(front.x,19.+sin(time*.21)*.3,front.y)
	var d:=Vector2((g.pos.x-front.x)/1.35,g.pos.y-front.y).length()
	intensity=1.-smoothstep(5.,13.,d)
	wetness=move_toward(wetness,intensity,dt*(.87 if intensity>wetness else .22))
	world_env.fog_light_color=base_fog.lerp(Color("#9baeb9"),intensity*.63)
	sun.light_color=base_sun.lerp(Color("#b2d0dd"),intensity*.48)
	wind=.48+.34*sin(time*.53)
	for j in wind_socks.size():
		wind_socks[j].rotation=Vector3(0,.24*sin(time*.62+j),-.31+wind*.38+.06*sin(time*4.2+j))
	rain.visible=d<32.
	if rain.visible:
		rain.position=Vector3(front.x,g.land.ground(front),front.y)
		var slant:=Basis(Vector3.FORWARD,-.15-wind*.08)
		for j in drops.size():
			var v:=drops[j];var h:=fposmod(v.y-time*13.7,14.)
			rain.multimesh.set_instance_transform(j,Transform3D(slant,Vector3(v.x+h*.20,h,v.z)))
	if intensity>.12:
		ambient.position=g.truck.position;ambient.volume_db=lerpf(-29.,-13.,intensity)
		if not ambient.playing:ambient.play()
	elif ambient.playing:ambient.stop()
