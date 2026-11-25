extends RefCounted

var valley
var a:=preload("res://workshop.gd").new()
var craft:=preload("res://coastal_craft.gd").new()
var rng:=RandomNumberGenerator.new()
var chime_wheels:Array[Node3D]=[]
var wind_flags:Array[Node3D]=[]
var foglights:Array[Node3D]=[]
var fog_x:Array[float]=[]
var verge_lights:Array[OmniLight3D]=[]
const FOG_HERM:=1366.
var herm_inlay:=StandardMaterial3D.new()
var herm_voice:=AudioStreamPlayer3D.new()
var herm_wave:=-999.
var grass_wave:=ShaderMaterial.new()
var fork_cloths:Array[MeshInstance3D]=[]
var echo_pennants:Array[Node3D]=[]
var pennant_stations:Array[float]=[]
var foundry_lantern:Node3D
var daughter:Node3D
var skiff:Node3D
var jar:Node3D
var mended_rim:Node3D
var clay_light:Node3D
var arch_eye:Node3D
var flock:Array[Node3D]=[]
var wings:Array[Node3D]=[]
const STRAIT:=369.
const FIELD:=169.
const HORN:=1112.

func build(v)->void:
	valley=v;rng.seed=606297
	horizon();terraces();stoneway();villages();foundry();harbor();wind_posts();listening_bend();memorial();verge_life();shore_grass();loading_alley()
func anchor(x:float,z:float,old:=false)->Node3D:return valley.site(valley.road(x,old,z))
func batch(n:Node3D,far:=310.)->void:
	craft.batch(n)
	for mesh in n.get_children():mesh.visibility_range_end=far;mesh.visibility_range_end_margin=35.
func horizon()->void:
	# Long continuous silhouettes fill the horizon even on the outward corners.
	for back in [-1.,1.]:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var ridge:=PackedVector3Array()
		for x in range(-344,1960,34):
			var coast:float=valley.center(clampf(x,0.,valley.END));var wave:=sin(x*.011+back*.7);var r:float=absf(sin(x*.0045+back))
			for j in 4:
				var distance:float=[100.,180.,265.,450.][j] if back<0. else [155.,255.,335.,570.][j]
				var elev:float=[-15.,48.+22*wave,67.+57*r+17*wave,-23.][j] if back<0. else [-24.,-18.,26.+31*r+15*wave,-26.][j]
				var py:float=valley.altitude(clampf(x,0.,valley.END))*(.7 if back<0. else .19)+elev
				ridge.append(Vector3(x,py,coast+back*(distance+16*wave)))
		for i in range(ridge.size()-4):
			if i%4==3:continue
			for tri in [[i,i+4,i+1],[i+1,i+4,i+5]]:
				var norm:Vector3=(ridge[tri[1]]-ridge[tri[0]]).cross(ridge[tri[2]]-ridge[tri[0]]).normalized()
				if norm.y<0:norm=-norm
				for j in tri:st.set_normal(norm);st.add_vertex(ridge[j])
		var m:=MeshInstance3D.new();m.mesh=st.commit();m.material_override=a.material("#657f7e" if back<0 else "#849e9a");m.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;valley.add_child(m)
	var cloud_mesh:=SphereMesh.new();cloud_mesh.radial_segments=10;cloud_mesh.rings=4
	var clouds:Array[Transform3D]=[]
	for i in 120:
		var x:=rng.randf_range(-400,1800);var z:=rng.randf_range(-490,490);var y:=rng.randf_range(155,250)
		var w:=rng.randf_range(18,68)
		for l in 3:clouds.append(valley.xf(Vector3(x+l*w*.58,y+sin(l*2.)*w*.07,z+l*4),Vector3(w,.13*w,w*.5)))
	valley.scatter(cloud_mesh,clouds,"#dadbd0");valley.get_child(-1).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func terraces()->void:
	# Shared meshes keep hundreds of hand-placed terraces inexpensive.
	var olive:=SphereMesh.new();olive.radial_segments=9;olive.rings=4
	var foliage:Array[Transform3D]=[];var light:Array[Transform3D]=[];var timber:Array[Transform3D]=[];var walls:Array[Transform3D]=[];var cypress:Array[Transform3D]=[]
	for district:Vector2 in [Vector2(64,244),Vector2(464,554),Vector2(728,956),Vector2(1340,1520)]:
		for x in range(int(district.x),int(district.y),11):
			for row in 4:
				var side:=(-1. if int(district.x)%3==1 else 1.)
				var p:Vector2=valley.road(x+rng.randf_range(-1.2,1.2),side>0,side*(10.+row*8.)+rng.randf_range(-1.1,1.1));var at:Vector3=valley.surface(p);var h:=rng.randf_range(2.6,4.6)
				timber.append(valley.xf(at+Vector3.UP*h*.30,Vector3(.38,h*.63,.37),rng.randf()*PI))
				for j in 4:
					var az:=j*TAU/4.+x*.05;var canopy:Vector3=at+Vector3(cos(az)*h*.20,h*(.65+.07*sin(az)),sin(az)*h*.20)
					(light if j==1 else foliage).append(valley.xf(canopy,Vector3(h*.77,h*.59,h*.65),az))
				if row==0 and x%3==0:cypress.append(valley.xf(valley.surface(p+Vector2(3.1,1.5))+Vector3.UP*3.,Vector3(1.6,7.,1.55)))
		for x in range(int(district.x),int(district.y),3):
			var p:Vector2=valley.road(x,false,-7.8);var q:Vector2=valley.road(x+3,false,-7.8)
			var u:Vector3=valley.surface(p);var v:Vector3=valley.surface(q)
			var tr:=Transform3D.IDENTITY.looking_at((v-u).normalized(),Vector3.UP).scaled_local(Vector3(.76,rng.randf_range(.63,.94),u.distance_to(v)*.99))
			tr.origin=(u+v)*.5+Vector3.UP*.28;walls.append(tr)
	valley.scatter(olive,foliage,"#48654f");valley.scatter(olive,light,"#728969");valley.scatter(BoxMesh.new(),timber,"#745a47");valley.scatter(olive,cypress,"#2d584a");valley.scatter(BoxMesh.new(),walls,"#998c71")

func arc(p:Node3D,center:Vector3,r:float,d:float)->void:
	var col:="#bba68a"
	for flank in [-1,1]:
		a.box(p,center+Vector3(0,1.55,flank*(r+.43)),Vector3(d,3.1,.86),col)
		a.box(p,center+Vector3(0,3.06,flank*(r+.43)),Vector3(d+.18,.24,1.16),"#d4c1a0")
	for j in 15:
		var az:float=(j+.5)*PI/15.;var rr:=r+.42
		var block:=a.box(p,center+Vector3(0,3.2+rr*sin(az),rr*cos(az)),Vector3(d+.05,.88,rr*PI/15.*1.1),"#c9b496" if j%3 else "#a99b86")
		block.rotation.x=PI*.5-az
	a.box(p,center+Vector3(0,4.1+r,0),Vector3(d+.28,.35,(r+.86)*2.),"#ab9374")
func stoneway()->void:
	for x in [294.,335.,404.,1072.,1125.,1284.]:
		var cut:=anchor(x,-15.)
		for k in 5:
			var q:=Vector3(float(k-2)*8.,4.+(k%2)*2.,-4.-absf(2-k)*1.6)
			var world:=Vector2(cut.global_position.x+q.x,cut.global_position.z+q.z)
			var depth:=11.+(k%3)*4.
			# Seat the whole cliff foot into the downhill side of the cut.
			var foot:float=valley.ground(world)
			for sx in [-6.5,6.5]:
				for sz in [-4.,4.]:foot=minf(foot,valley.ground(world+Vector2(sx,sz)))
			q.y=foot-cut.global_position.y+depth*.29
			craft.outcrop(cut,q,Vector3(16.,depth,9.+(k%2)*6.),int(x)+k)
		batch(cut,410.)
	var crossing:=anchor(416,0)
	for k in range(-3,4):arc(crossing,Vector3(0,-.3,k*11.4),4.85,2.35)
	batch(crossing,470.)
	var ruin:=anchor(1068,-12.)
	for k in range(0,3):arc(ruin,Vector3(k*1.6,0,-k*8.55),3.42,2.2)
	batch(ruin,410.)
	for x in range(299,440,19):
		var bank:=anchor(x,10.+rng.randf_range(1.,4.))
		craft.outcrop(bank,Vector3(0,1.6,0),Vector3(8.,4.,5.),x);batch(bank,190.)

func villages()->void:
	for info:Vector3 in [Vector3(49,19,4),Vector3(158,-28,3),Vector3(472,28,5),Vector3(664,-34,4),Vector3(788,27,3),Vector3(1004,-35,3),Vector3(1348,-28,3),Vector3(1532,-17,6)]:
		for i in int(info.z):
			var x:=info.x+(i%3)*12.+rng.randf_range(-2.,2.);var s:=signf(info.y)
			var n:=anchor(x,info.y+s*floori(i/3.)*12.,info.x==788)
			var width:=rng.randf_range(4.5,7.7)
			var villa:=craft.villa(n,Vector3.ZERO,width,rng.randf_range(2.8,5.2),rng.randf_range(-.3,.3),i%3)
			var floor_y:=n.global_position.y
			for sx in [-.5,.5]:
				for sz in [-.36,.36]:
					var corner:=villa.to_global(Vector3(sx*width,0.,sz*width))
					floor_y=minf(floor_y,valley.surface(Vector2(corner.x,corner.z)).y)
			var plinth_height:=n.global_position.y-floor_y+.46
			a.box(villa,Vector3(0,-plinth_height*.5,0),Vector3(width+.08,plinth_height,width*.70+.09),"#b9a687")
			if i==0:craft.plant(n,Vector3(2.8,0,3.3),int(x));a.jar(n,Vector3(-2.4,0,3.),.74,"#b36e52")
			batch(n,340.)
	for info:Vector2 in [Vector2(84,23),Vector2(632,-27),Vector2(892,18),Vector2(1468,-24)]:
		var m:=anchor(info.x,info.y,info.x==892);a.cyl(m,Vector3.UP*3.,1.8,1.21,6.,"#d7c9a8");a.cyl(m,Vector3.UP*6.38,1.74,.12,1.1,"#a66349")
		var sails:=a.group(m,Vector3(-1.45,4.74,0));chime_wheels.append(sails)
		for j in 7:
			var arm:=a.group(sails);arm.rotation.x=TAU*j/7.
			a.beam(arm,Vector3.ZERO,Vector3(0,2.88,0),.047,"#815f48");a.box(arm,Vector3(0,1.76,.22),Vector3(.07,1.62,.51),"#e5d8b9")
	var shrine:=anchor(1192,19);craft.temple(shrine,Vector3.ZERO);batch(shrine,510.)

func foundry()->void:
	var yard:Node3D=valley.stations.yard
	var workshop:=a.group(yard);var back:=Vector3(-5,0,-10)
	var lining:=a.box(workshop,back+Vector3(0,.30,-.12),Vector3(6.5,.6,1.8),"#a98a67");lining.material_override=craft.mineral("#b8a083","#8e7661")
	for k in [0,2]:
		var at:=back+Vector3(-2.38+k*2.25,.6,0.)
		a.cyl(workshop,at+Vector3.UP*.44,.59,.52,.88,"#75614e")
		a.ring(workshop,at+Vector3.UP*.88,.51,.042,"#c19e63")
		a.cyl(workshop,at+Vector3.UP*.89,.43,.43,.018,"#553d31")
	for i in 8:
		var p:=Vector3(-8.8+i*.45,.2,-7.9);a.cyl(workshop,p,.2,.25,.38,"#9c7c52")
	for z in [-10.,-7.,-3.,1.]:
		var wall:=a.box(workshop,Vector3(-9.,.65,z),Vector3(.72,1.3,3.),"#bea787");wall.material_override=craft.mineral("#bea787","#8d7863")
	batch(workshop,210.)
	var warm:=a.group(yard,Vector3(-5,1.23,-9.25));foundry_lantern=a.ball(warm,Vector3.ZERO,Vector3(.6,.6,.2),"#eac17a")
	# The wings printed on the lading seal flank the foundry gate.
	for z in [-6.52,-3.48]:
		a.ring(yard,Vector3(-.5,3.45,z),.29,.045,"#ad945f").rotation.x=PI*.5

func harbor()->void:
	var port:Node3D=valley.stations.port;var docks:=a.group(port)
	for side in [-1.,1.]:
		for k in 5:
			var x:float=side*(6.+k*2.2);a.cyl(docks,Vector3(x,-.16,16.6),.17,.19,2.55,"#796451")
			a.ring(docks,Vector3(x,.85,16.6),.195,.029,"#bba27b")
	for k in 4:
		craft.barrel(docks,Vector3(-5.-k%2*1.3,0.,11.+k/2),.78);a.crate(docks,Vector3(4.+k*.88,.18,12.),.83)
	craft.cloth(docks,Vector3(-5,3.3,4.2),4.2,"#b56645")
	for side in [-1,1]:a.beam(docks,Vector3(-5+side*2,0,4.4),Vector3(-5+side*2,3.35,4.4),.077,"#866c4e")
	batch(docks,235.)
	daughter=a.courier(port,true);daughter.position=Vector3(-4,0,10.4);daughter.rotation.y=-PI*.6
	preload("res://bell_household.gd").new().dress(daughter)
	skiff=a.group(port,Vector3(36,-.74,48))
	preload("res://family_skiff.gd").new().build(skiff)
	var passenger:=a.courier(skiff);passenger.position=Vector3(-.85,.32,.03);passenger.scale=Vector3.ONE*.72
	skiff.hide()

func wind_posts()->void:
	# Two material trails continue down opposite sides of the fork.
	for station:float in [511.,531.,552.,579.,612.]:
		var high:=anchor(station,-5.65)
		a.cyl(high,Vector3.UP*.46,.37,.30,.94,"#b4a998",8)
		a.cyl(high,Vector3.UP*1.02,.34,.30,.20,"#f2e7c5",8)
		a.cyl(high,Vector3.UP*1.27,.29,.21,.32,"#b9ac91",8)
		if station==511.:continue
		var low:=anchor(station,5.9,true)
		var mast:=a.group(low);mast.rotation.y=-.35
		a.beam(mast,Vector3.ZERO,Vector3.UP*3.3,.067,"#8b6d4d")
		var cloth:=fork_panel(mast)
		fork_cloths.append(cloth)
	for info:Vector2 in [Vector2(140,5.9),Vector2(296,-6.8),Vector2(495,7.4),Vector2(524,6.5),Vector2(579,7.),Vector2(652,-6.),Vector2(708,-6.),Vector2(808,-7.),Vector2(880,-6.6),Vector2(980,6.7),Vector2(1120,7.),Vector2(1276,-7.)]:
		var p:=anchor(info.x,info.y,info.y>0.)
		a.beam(p,Vector3.ZERO,Vector3.UP*3.54,.073,"#826945")
		var arm:=a.group(p,Vector3.UP*3.28);wind_flags.append(arm)
		for j in 3:
			var strip:=a.box(arm,Vector3(.47+j*.44,-.10-j*.075,0),Vector3(.52,.48-.105*j,.045),"#b76040" if info.y>0 else "#587b83");strip.rotation.z=-.09*j
	# A soft scattering halo keeps distant lanterns distinguishable from roadside stone.
	var haze_texture:=GradientTexture2D.new()
	haze_texture.width=96;haze_texture.height=96
	haze_texture.fill=GradientTexture2D.FILL_RADIAL
	haze_texture.fill_from=Vector2(.5,.5);haze_texture.fill_to=Vector2(1.,.5)
	var stop:=Gradient.new()
	stop.offsets=PackedFloat32Array([0.,.12,.32,.64,1.])
	stop.colors=PackedColorArray([Color(1.,.92,.66,.88),Color(1.,.76,.39,.60),Color(1.,.66,.28,.26),Color(.98,.59,.21,.07),Color(.94,.51,.18,0.)])
	haze_texture.gradient=stop
	for x in range(1232,1580,19):
		var p:=anchor(x,5.6)
		a.cyl(p,Vector3.UP*.72,.35,.25,1.45,"#a59172");a.cyl(p,Vector3.UP*1.55,.23,.42,.35,"#766649")
		a.cyl(p,Vector3.UP*1.81,.29,.37,.12,"#bb8a55",10)
		for side in [-1.,1.]:
			a.beam(p,Vector3(side*.32,1.82,0),Vector3(side*.24,2.36,0),.037,"#8e704e")
		a.cyl(p,Vector3.UP*2.39,.08,.38,.20,"#92744d",10)
		var lamp:=a.ball(p,Vector3.UP*2.08,Vector3(.68,1.0,.68),"#ffe8a3",true)
		var emit:=StandardMaterial3D.new();emit.albedo_color=Color("#efbd77");emit.emission_enabled=true;emit.emission=Color("#ffc883");emit.emission_energy_multiplier=2.2;lamp.material_override=emit;lamp.hide();foglights.append(lamp);fog_x.append(float(x))
		var halo:=Sprite3D.new()
		lamp.add_child(halo);halo.texture=haze_texture;halo.pixel_size=.105
		halo.billboard=BaseMaterial3D.BILLBOARD_ENABLED;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var pool:=OmniLight3D.new()
		p.add_child(pool);pool.position=Vector3(-.3,1.95,-.35)
		pool.light_color=Color("#ffbd74");pool.light_energy=3.35;pool.omni_range=8.4;pool.hide()
		verge_lights.append(pool)
		if fog_x.size()%3==1:
			var tangent:Vector2=valley.road(x+8.)-valley.road(x)
			var mast:=a.group(p,Vector3.UP*2.58);mast.rotation.y=-tangent.angle()
			a.beam(mast,Vector3.DOWN*.26,Vector3.UP*.20,.038,"#856b49")
			var ribbon:=a.group(mast,Vector3.UP*.12)
			for strip in 4:
				var cloth:=a.box(ribbon,Vector3(.23+strip*.43,-.045*strip*strip,0),Vector3(.48,.27-strip*.03,.04),"#eed8a1" if strip!=2 else "#bf7650")
				cloth.rotation.z=-.13*strip
			echo_pennants.append(ribbon);pennant_stations.append(x)
func listening_bend()->void:
	var site:=anchor(FOG_HERM,-12.)
	herm_inlay.albedo_color=Color("#9b895e");herm_inlay.metallic=.49;herm_inlay.roughness=.58
	herm_inlay.emission_enabled=true;herm_inlay.emission=Color("#ffc270");herm_inlay.emission_energy_multiplier=0.
	var statue:=preload("res://listening_herm.gd").new().build(site,Vector3.ZERO,-.98,2.5,herm_inlay)
	site.add_child(herm_voice);herm_voice.position=statue.position+Vector3.UP*7.6
	herm_voice.stream=preload("res://audio/clay_answer.wav");herm_voice.pitch_scale=.73;herm_voice.unit_size=22.;herm_voice.max_distance=112.;herm_voice.volume_db=-4.5
	for i in 4:
		var base:=a.box(site,Vector3(1.8+i*.29,.06-i*.055,.56),Vector3(1.02,.26,2.9-i*.18),"#ad997b")
		base.rotation.y=-.17
	valley.block(valley.road(FOG_HERM,false,-12.),2.3)

func fork_panel(mast:Node3D)->MeshInstance3D:
	var cloth:=MeshInstance3D.new()
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in 6:
		for corner:Vector2 in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
			var u:float=(j+corner.x)/6.
			surface.set_color(Color("#e8d4a6") if j==1 else Color("#ac4a38"))
			surface.add_vertex(Vector3(2.1*u,-.61*corner.y*(1.-.69*u)-.14*u,sin(u*TAU)*.17))
	surface.generate_normals();cloth.mesh=surface.commit()
	var dye:=StandardMaterial3D.new()
	dye.vertex_color_use_as_albedo=true;dye.vertex_color_is_srgb=true;dye.cull_mode=BaseMaterial3D.CULL_DISABLED
	cloth.material_override=dye;mast.add_child(cloth);cloth.position.y=3.24
	return cloth

func memorial()->void:
	var altar:=anchor(HORN,6.6);craft.outcrop(altar,Vector3(1.24,.14,-1.73),Vector3(3.8,1.73,2.4),88)
	a.cyl(altar,Vector3(0,-.25,-.4),1.63,1.75,.55,"#a2977c",14)
	for i in 4:
		var stone:=a.box(altar,Vector3(-1.04-i*.48,-.055,1.09+i*.16),Vector3(.70,.13,.51),"#baa88a");stone.rotation.y=.16*i
	var plinth:=a.box(altar,Vector3(0,.6,-.5),Vector3(1.7,1.2,1.3),"#ada48d")
	plinth.material_override=craft.mineral("#c7b590","#98846c")
	var relic:=preload("res://bell_relic.gd").new()
	jar=relic.make_horn(altar);jar.position=Vector3(0,2.03,-.45);jar.rotation=Vector3(-.24,-.30,-.08)
	mended_rim=relic.shard(jar);mended_rim.hide()
	for side in [-1.,1.]:a.beam(altar,Vector3(side*.56,1.18,-.52),Vector3(side*.40,1.70,-.46),.061,"#a68a60")
	for i in 5:
		var px:float=(-1.58-i*.25) if i<3 else (1.45+(i-3)*.38)
		var h:=.86+i*.12
		var tube:=a.cyl(altar,Vector3(px,h*.5,-.66),.15,.21,h,"#ba8962");tube.rotation.z=-.31+.15*i
		a.cyl(altar,Vector3(px-sin(tube.rotation.z)*h*.5,h-.01,-.66),.16,.16,.02,"#6a5347")
	clay_light=a.ring(altar,Vector3(0,2.1,-.5),.53,.028,"#ffdfa4");clay_light.hide()

func animate(t:float,p:Vector2,foghorn:float,blessed:bool,echo_age:=10.,echo_start:=-999.)->void:
	var wave_front:=echo_start+maxf(0.,echo_age-.22)*108. if echo_start>0. and echo_age<2.35 else -999.
	grass_wave.set_shader_parameter("wave_front",wave_front)
	var traveled:=wave_front-FOG_HERM
	var resonance:float=smoothstep(-2.,3.,traveled)*(1.-smoothstep(14.,89.,traveled)) if echo_start<=FOG_HERM else 0.
	herm_inlay.emission_energy_multiplier=resonance*(2.9 if blessed else 1.85)
	if herm_wave<FOG_HERM and wave_front>=FOG_HERM and echo_start<FOG_HERM:
		herm_voice.play()
	herm_wave=wave_front
	grass_wave.set_shader_parameter("wave_strength",1.-smoothstep(1.95,2.35,echo_age))
	for n in chime_wheels:n.rotation.x=t*.54
	for i in fork_cloths.size():
		fork_cloths[i].rotation.y=.34*sin(t*2.4-i*.93)
		fork_cloths[i].rotation.x=.15*sin(t*3.1-i)
	for i in wind_flags.size():wind_flags[i].rotation.y=.34*sin(t*2.2+i)+.23*sin(t*3.7+i*.3)
	for i in fog_x.size():
		var lit:bool=fog_x[i]<foghorn and fog_x[i]>foghorn-235.
		foglights[i].visible=lit
		verge_lights[i].visible=lit and absf(p.x-fog_x[i])<40.
		if lit:
			var behind:float=wave_front-fog_x[i]
			var crest:float=(1.-smoothstep(0.,24.,behind)) if behind>=0. and echo_start<=fog_x[i] else 0.
			foglights[i].scale=Vector3(.52,.65,.52)*(1.+.52*crest+.06*sin(t*4.+i))
	for i in echo_pennants.size():
		var past:float=wave_front-pennant_stations[i]
		var ringing:=smoothstep(-8.,8.,past)*(1.-smoothstep(30.,95.,past))
		var ribbon:=echo_pennants[i]
		ribbon.rotation.z=lerpf(-.95,-.04,ringing)+sin(t*5.+i)*(.035+.13*ringing)
	clay_light.visible=blessed;clay_light.rotation.y=t;mended_rim.visible=blessed



func verge_life()->void:
	var patterns:Dictionary={}
	for name in ["tree_oak","tree_small","plant_bushDetailed","grass_large","flower_redA","flower_purpleA","flower_yellowB","rock_smallB"]:
		patterns[name]=[]
	for x in range(30,int(valley.END)-40,4):
		var side:=1. if rng.randf()>.5 else -1.
		var old:bool=side>0. and x>valley.FORK and x<valley.JOIN
		var place:Vector2=valley.road(x+rng.randf_range(-1.6,1.6),old,side*rng.randf_range(5.5,10.2))
		var pack:="grass_large"
		if valley.region(x) in [1,3] and rng.randf()>.4:pack="rock_smallB"
		elif sin(x*.043)>.36:pack="flower_redA" if x<560 else ("flower_purpleA" if x<1080 else "flower_yellowB")
		elif rng.randf()>.78:pack="plant_bushDetailed"
		var h:=rng.randf_range(.33,.82) if pack!="plant_bushDetailed" else rng.randf_range(.9,1.5)
		for j in 3:
			var patch:=place+Vector2(rng.randf_range(-1.5,1.5),rng.randf_range(-1.7,1.7))
			patterns[pack].append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*h),valley.surface(patch)))
		if x%3==0:
			var tree_x:float=x+rng.randf_range(-3.,3.);var p:Vector2=valley.road(tree_x,old,side*rng.randf_range(11.,37.))
			if absf(x-valley.CAMP)<20. or absf(x-valley.WATCH)<21.:continue
			var tree:="tree_small" if valley.region(x)==3 or rng.randf()<.22 else "tree_oak"
			var height:=rng.randf_range(3.25,6.3)
			patterns[tree].append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*height),valley.surface(p)))
	for key:String in patterns:
		var source:=a.prop(valley,"garden/"+key,Vector3.ZERO,1.)
		for node:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
			# Copy overrides into the shared mesh resource once for this species.
			var model:=node.mesh.duplicate() as Mesh
			for j in model.get_surface_count():
				var mat:=node.get_surface_override_material(j)
				if mat:
					var original:=node.mesh.surface_get_material(j)
					if original and original.resource_name=="leafsGreen":mat=a.material("#45724e" if key=="tree_oak" else "#668257")
					elif original and original.resource_name=="woodBark":mat=a.material("#795d46")
					model.surface_set_material(j,mat)
			var arr:MultiMesh=MultiMesh.new();arr.transform_format=MultiMesh.TRANSFORM_3D;arr.mesh=model;arr.instance_count=patterns[key].size()
			var local:=source.global_transform.affine_inverse()*node.global_transform
			for j in arr.instance_count:arr.set_instance_transform(j,patterns[key][j]*local)
			var n:=MultiMeshInstance3D.new();n.multimesh=arr;valley.add_child(n)
			if not key.begins_with("tree"):n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		source.free()

func shore_grass()->void:
	# One small clump is instanced in windrows on the sea road and on the exposed ridge.
	var tufts:=SurfaceTool.new();tufts.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stem in 13:
		var az:=stem*2.39996
		var base:=Vector3(cos(az)*.45,0.,sin(az)*.60)
		var spread:=Vector3(cos(az)*.54,0.,sin(az)*.61)
		var width:=Vector3(-sin(az),0.,cos(az))*.050
		var height:=.62+.42*absf(sin(az*2.3))
		for row in 5:
			for corner:Vector2 in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
				var u:float=(row+corner.y)/5.
				var center:=base+Vector3.UP*(height*u)+spread*u*u
				var edge:float=(corner.x*2.-1.)*(.24+.76*sin(u*PI)) if u<.99 else 0.
				tufts.set_uv(Vector2(0.,u));tufts.set_normal(Vector3.UP)
				tufts.set_color(Color("#455d49").lerp(Color("#a7a67e"),u).srgb_to_linear())
				tufts.add_vertex(center+width*edge)
		if stem%3:continue
		var plume:=base+Vector3.UP*height+spread
		for corner:Vector2 in [Vector2(-1,0),Vector2(0,1),Vector2(1,0),Vector2(-1,0),Vector2(1,0),Vector2(0,-.8)]:
			tufts.set_uv(Vector2(1,1));tufts.set_color(Color("#c4b991").srgb_to_linear());tufts.set_normal(Vector3.UP)
			tufts.add_vertex(plume+width*corner.x+Vector3(.085,.134,.025)*corner.y)
	var transforms:Array[Transform3D]=[]
	var grass_rng:=RandomNumberGenerator.new();grass_rng.seed=53117
	for span:Vector2i in [Vector2i(515,649),Vector2i(1230,1548)]:
		for x in range(span.x,span.y,2):
			for side:float in [-1.,1.]:
				var density:=.52+.32*sin(x*.09+side)+.10*cos(x*.19)
				if grass_rng.randf()>density:continue
				for cluster in grass_rng.randi_range(2,5):
					var sx:float=x+grass_rng.randf_range(-1.3,1.3)
					var width:=grass_rng.randf_range(4.8,11.8)
					if sx<650. and side>0.:continue
					var foot:Vector2=valley.road(sx,false,width*side)
					var angle:float=(valley.road(sx+1.)-valley.road(sx)).angle()
					var scale:=grass_rng.randf_range(.70,1.35)
					var basis:=Basis(Vector3.UP,-angle+grass_rng.randf_range(-.3,.3)).scaled(Vector3.ONE*scale)
					transforms.append(Transform3D(basis,valley.surface(foot)-Vector3.UP*.04))
	var mesh:=tufts.commit()
	grass_wave.shader=preload("res://bell_shore_grass.gdshader")
	var tiles:Dictionary[int,Array]={}
	for transform in transforms:
		var index:=floori(transform.origin.x/64.)
		if not tiles.has(index):tiles[index]=[]
		tiles[index].append(transform)
	for index in tiles:
		var group:Array=tiles[index]
		var center:Vector3=group[group.size()/2].origin
		var foliage:=MultiMesh.new();foliage.transform_format=MultiMesh.TRANSFORM_3D;foliage.mesh=mesh
		foliage.instance_count=group.size()
		for i in group.size():
			var transform:Transform3D=group[i];transform.origin-=center
			foliage.set_instance_transform(i,transform)
		var patch:=MultiMeshInstance3D.new();patch.multimesh=foliage;patch.material_override=grass_wave
		patch.position=center;patch.visibility_range_end=190.;patch.visibility_range_end_margin=20.
		patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;valley.add_child(patch)


func loading_alley()->void:
	var yard:Node3D=valley.stations.yard;var root:=a.group(yard)
	for span:Vector2 in [Vector2(-11.7,-6.75),Vector2(-3.25,5.7)]:
		var mid:=(span.x+span.y)*.5
		var wall:=a.box(root,Vector3(-.5,.53,mid),Vector3(.49,1.06,span.y-span.x),"#b09e7f");wall.material_override=craft.mineral("#c6b38f","#8e8067")
		a.box(root,Vector3(-.5,1.12,mid),Vector3(.65,.15,span.y-span.x+.05),"#cca982")
	for j in 15:
		var u:float=j/14.;var slat:=a.box(root,Vector3(1.04+u*3.45,.09+u*1.06,0),Vector3(.239,.11,2.35),"#ae8763" if j%3 else "#b59368");slat.rotation.z=.30
	for z in [-.91,.91]:a.beam(root,Vector3(.89,.02,z),Vector3(4.6,1.1,z),.1,"#805f49")
	batch(root,130.)


