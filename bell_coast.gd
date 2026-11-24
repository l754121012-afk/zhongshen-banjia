extends RefCounted

var valley
var a:=preload("res://workshop.gd").new()
var craft:=preload("res://coastal_craft.gd").new()
var rng:=RandomNumberGenerator.new()
var chime_wheels:Array[Node3D]=[]
var wind_flags:Array[Node3D]=[]
var foglights:Array[Node3D]=[]
var fog_x:Array[float]=[]
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
	horizon();terraces();stoneway();villages();foundry();harbor();wind_posts();memorial();verge_life();loading_alley()
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
	for info:Vector2 in [Vector2(140,5.9),Vector2(296,-6.8),Vector2(495,7.4),Vector2(524,6.5),Vector2(579,7.),Vector2(652,-6.),Vector2(708,-6.),Vector2(808,-7.),Vector2(880,-6.6),Vector2(980,6.7),Vector2(1120,7.),Vector2(1276,-7.)]:
		var p:=anchor(info.x,info.y,info.y>0.)
		a.beam(p,Vector3.ZERO,Vector3.UP*3.54,.073,"#826945")
		var arm:=a.group(p,Vector3.UP*3.28);wind_flags.append(arm)
		for j in 3:
			var strip:=a.box(arm,Vector3(.47+j*.44,-.10-j*.075,0),Vector3(.52,.48-.105*j,.045),"#b76040" if info.y>0 else "#587b83");strip.rotation.z=-.09*j
	for x in range(1272,1568,37):
		var p:=anchor(x,6.2 if x%2==0 else -6.2)
		a.cyl(p,Vector3.UP*.72,.35,.25,1.45,"#a59172");a.cyl(p,Vector3.UP*1.55,.23,.42,.35,"#766649")
		var lamp:=a.ball(p,Vector3.UP*1.94,Vector3(.48,.77,.48),"#ffe8a3",true)
		var emit:=StandardMaterial3D.new();emit.albedo_color=Color("#efbd77");emit.emission_enabled=true;emit.emission=Color("#ffc883");emit.emission_energy_multiplier=2.2;lamp.material_override=emit;lamp.hide();foglights.append(lamp);fog_x.append(float(x))
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

func animate(t:float,p:Vector2,foghorn:float,blessed:bool)->void:
	for n in chime_wheels:n.rotation.x=t*.54
	for i in wind_flags.size():wind_flags[i].rotation.y=.34*sin(t*2.2+i)+.23*sin(t*3.7+i*.3)
	for i in fog_x.size():
		var lit:bool=fog_x[i]<foghorn and fog_x[i]>foghorn-235.
		foglights[i].visible=lit
		if lit:foglights[i].scale.y=.75+.12*sin(t*7.+i)
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


