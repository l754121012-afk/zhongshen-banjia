extends Node3D

const POINTS := [Vector2(19.1,15.6),Vector2(10.3,15.8),Vector2(2.3,18.1),Vector2(-5.7,20.7)]
var craft:=preload("res://workshop.gd").new()
var lamps:Array[Node3D]=[]
var lenses:Array[StandardMaterial3D]=[]
var brightness:=PackedFloat32Array([0.,0.,0.,0.])
var circles:Array[MeshInstance3D]=[]
var echo_colors:Array[StandardMaterial3D]=[]
var brass_fins:Array[Node3D]=[]
var bell_delay:=0.38
var wave:=-1.
var starts:Array[float]=[]
var answered:=false
var reply:=AudioStreamPlayer3D.new()
var reflector:Node3D
var base_fog:=0.
var clock:=0.

func build(quay:Node3D,environment:Environment)->void:
	base_fog=environment.fog_density
	for i in POINTS.size():
		var pt:Vector2=POINTS[i]
		var n:=craft.group(self,Vector3(pt.x,.04,pt.y+1.7));lamps.append(n)
		craft.cyl(n,Vector3.UP*.12,.49,.36,.28,"#355658",14)
		craft.ring(n,Vector3.UP*.24,.44,.046,"#cb9b5e")
		for side in [-1,1]:
			craft.beam(n,Vector3(side*.36,.25,0),Vector3(side*.13,1.02,0),.034,"#b68d58")
		var pennant:=craft.group(n,Vector3(0,1.55,0));brass_fins.append(pennant)
		craft.beam(pennant,Vector3.ZERO,Vector3.UP*.48,.025,"#ad8c59")
		var blade:=craft.ball(pennant,Vector3(.14,.30,0),Vector3(.33,.15,.039),"#68aaa3")
		blade.rotation.z=.21
		craft.beam(n,Vector3.UP*.30,Vector3.UP*1.20,.042,"#9f815e")
		craft.cyl(n,Vector3.UP*1.04,.21,.22,.09,"#a08758",12)
		var glass:=craft.ball(n,Vector3.UP*1.23,Vector3(.32,.37,.32),"#ffd28a")
		var material:=StandardMaterial3D.new();glass.material_override=material
		material.emission_enabled=true;material.emission=Color("#ffc478");lenses.append(material)
		craft.cyl(n,Vector3.UP*1.46,.05,.26,.15,"#446869",12)
		var water_ring:=craft.ring(self,Vector3(pt.x,-.41,pt.y+1.7),.8,.025,"#f6c782")
		var ink:=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		water_ring.material_override=ink;water_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		circles.append(water_ring);echo_colors.append(ink)
	add_child(reply);reply.position=quay.position+Vector3.UP*2.
	reply.stream=preload("res://audio/bronze_reply.wav");reply.unit_size=18.;reply.max_distance=95.

func call_from(p:Vector2)->void:
	wave=0.;answered=false;starts.clear()
	bell_delay=clampf(p.distance_to(POINTS[-1])/34.,.32,.92)
	for point:Vector2 in POINTS:starts.append(bell_delay+.12+point.distance_to(POINTS[-1])/18.)

func tick(dt:float,p:Vector2,works:int,environment:Environment)->void:
	clock+=dt
	var corridor:=1.-smoothstep(6.,16.,absf(p.y-16.))
	environment.fog_enabled=true;environment.fog_density=base_fog+corridor*.019
	if wave>=0.:
		wave+=dt
		if wave>bell_delay and not answered:answered=true;reply.play()
		if wave>9.:wave=-1.
	for i in lamps.size():
		var light:=0.
		if wave>=0.:light=smoothstep(starts[i],starts[i]+.22,wave)*(1.-smoothstep(5.8,8.8,wave))
		if works==3:light=maxf(light,.52)
		lenses[i].albedo_color=Color("#716957").lerp(Color("#ffe4a3"),light)
		lenses[i].emission_energy_multiplier=2.6*light
		lamps[i].rotation.z=.05*sin(clock*1.5+i)
		var elapsed:=wave-starts[i] if wave>=0. else -1.
		circles[i].visible=elapsed>=0. and elapsed<1.46
		if circles[i].visible:
			var u:=elapsed/1.46
			circles[i].scale=Vector3.ONE*(.4+3.0*u)
			echo_colors[i].albedo_color=Color(.96,.81,.55,(1.-u)*.84)
		brass_fins[i].rotation.y=.32*sin(clock*1.42+i)
		brightness[i]=light

func swing_bell(bell:Node3D,dt:float)->void:
	if not is_instance_valid(bell):return
	var t:=wave-bell_delay
	var ring:=exp(-t*1.65) if t>=0. else 0.
	bell.body.rotation.z=.164*sin(t*10.5)*ring
	bell.tongue.rotation.z=-.33*sin(t*10.5-.29)*ring
	bell.answer(ring,dt)

func reflect_lights(water:ShaderMaterial)->void:
	water.set_shader_parameter("mirror_on",is_instance_valid(reflector))
	for i in POINTS.size():
		var pt:Vector2=POINTS[i]+Vector2(0,1.7)
		water.set_shader_parameter("pilot_"+str(i),Vector3(pt.x,pt.y,brightness[i]))


func mount_mirror(quay:Node3D)->void:
	if is_instance_valid(reflector):return
	var mount:=craft.group(quay,Vector3(3.36,.20,-1.19))
	craft.cyl(mount,Vector3.UP*.12,.30,.35,.24,"#526d69",16)
	craft.beam(mount,Vector3.UP*.20,Vector3.UP*1.42,.065,"#b29463")
	reflector=craft.group(mount,Vector3.UP*1.40)
	reflector.look_at(Vector3(-4.,.30,19.),Vector3.UP,true)
	var plate:=craft.cyl(reflector,Vector3.ZERO,.39,.42,.10,"#a88755",36);plate.rotation.x=PI/2.
	var pane:=craft.ball(reflector,Vector3(0,0,.065),Vector3(.67,.67,.08),"#8fbcc4")
	var silver:=StandardMaterial3D.new();silver.albedo_color=Color("#aac6bc");silver.emission_enabled=true;silver.emission=Color("#ffe39b");silver.emission_energy_multiplier=.78;silver.metallic=.65;silver.roughness=.24;pane.material_override=silver
	var edge:=craft.ring(reflector,Vector3(0,0,.074),.37,.032,"#d4af6b");edge.rotation.x=PI/2.
	for side in [-1,1]:craft.ball(reflector,Vector3(side*.40,0,0),Vector3.ONE*.12,"#b7995b")
