extends Node3D

const END:=1584.
const FORK:=504.
const JOIN:=1024.
const WATCH:=784.
const CAMP:=584.
const PLATEAU:=1196.
var a:=preload("res://workshop.gd").new()
var craft:=preload("res://coastal_craft.gd").new()
var architecture:=preload("res://tide_art.gd").new()
var solids:Array[Vector3]=[]
var stations:Dictionary={}
var beacons:Array[Node3D]=[]
var beacon_points:Array[Vector2]=[]
var signs:Array[Label3D]=[]
var terrain_rows:Dictionary[int,PackedVector2Array]={}
var terrain_material:=ShaderMaterial.new()
var waters:Node3D
var ferry:Node3D
var boat_from:Vector3
var flag:Node3D
var far_lamp:Node3D
var helper:Node3D
var elder:Node3D
var cup:Node3D
var apprentice:Node3D
var captain:Node3D
var frame:Node3D
var harbor_frame:Node3D
var near_trees:Array[Transform3D]=[]
var trunks:Array[Transform3D]=[]
var stone_transforms:Array[Transform3D]=[]
var grasses:Array[Transform3D]=[]
var waystones:Array[Transform3D]=[]
var rng:=RandomNumberGenerator.new()
var t:=0.

func center(x:float)->float:
	var entry:=smoothstep(20.,122.,x)*(1.-smoothstep(END-130.,END-22.,x))
	return entry*(34.*sin(x*.013)+16.*sin(x*.029)+5.*sin(x*.053))
func branch(x:float)->float:
	var fork:=smoothstep(FORK,FORK+105.,x)*(1.-smoothstep(JOIN-115.,JOIN,x))
	return center(x)+fork*(54.+19.*sin((x-FORK)*.021))
func altitude(x:float)->float:
	return 13.+57.*(1.-smoothstep(100.,436.,x))+43.*smoothstep(436.,680.,x)*(1.-smoothstep(888.,1112.,x))+37.*smoothstep(1048.,1140.,x)*(1.-smoothstep(1240.,1420.,x))-11.*smoothstep(1408.,1544.,x)+4.*sin(x*.016)*smoothstep(0.,80.,x)*(1.-smoothstep(1480.,1564.,x))
# The outer rut has settled into the hillside on the first descent.
func crossfall(x:float)->float:
	return -.105*smoothstep(73.,94.,x)*(1.-smoothstep(144.,165.,x))

func ground(p:Vector2)->float:
	var h:=natural_ground(p)
	if absf(p.x-1112.)<15.:
		var terrace:=road(1112.,false,6.6)
		var w:=1.-smoothstep(4.,13.,p.distance_to(terrace))
		h=lerpf(h,natural_ground(terrace),w)
	return h

func natural_ground(p:Vector2)->float:
	var x:=p.x
	var z:=p.y-center(x)
	var split:=branch(x)-center(x)
	var old_weight:=smoothstep(4.,maxf(8.,split*.80),z)*smoothstep(5.,65.,split)
	var depression:=old_weight*13.*smoothstep(FORK,FORK+200.,x)*(1.-smoothstep(JOIN-230.,JOIN,x))
	var d:=minf(absf(z),absf(z-split))
	var bank:=smoothstep(5.3,26.,d)
	var h:=crossfall(x)*clampf(z,-7.,7.)*(1.-smoothstep(10.,24.,d))+altitude(x)-depression+bank*(3.*sin(x*.024+z*.075)+3.8*sin(z*.064)+2.)
	h+=smoothstep(36.,118.,-z)*(25.+14.*sin(x*.012)+9.*sin(z*.058))
	h-=smoothstep(28.,125.,z-split)*(18.+12.*sin(x*.008))
	h=lerpf(h,altitude(END)-.42,smoothstep(END-55.,END-24.,x)*smoothstep(2.,7.,p.y))
	return lerpf(h,-5.2,smoothstep(END-85.,END-25.,x)*smoothstep(12.,20.,p.y))
# Interpolate the same two triangles used by the landscape. On distant hills the
# mesh is coarse, so analytic heights would leave small houses and trees floating.
func surface(p:Vector2)->Vector3:
	var x:=floori(p.x/5.)*5
	if not terrain_rows.has(x) or not terrain_rows.has(x+5):return Vector3(p.x,ground(p),p.y)
	var a:PackedVector2Array=terrain_rows[x]
	var b:PackedVector2Array=terrain_rows[x+5]
	var t:float=(p.x-x)/5.
	var lo:=0;var hi:=a.size()-1
	while hi-lo>1:
		var mid:=floori((lo+hi)*.5)
		if lerpf(a[mid].x,b[mid].x,t)<=p.y:lo=mid
		else:hi=mid
	var low_z:=lerpf(a[lo].x,b[lo].x,t)
	var high_z:=lerpf(a[hi].x,b[hi].x,t)
	if p.y<low_z or p.y>high_z:return Vector3(p.x,ground(p),p.y)
	var diagonal:=lerpf(a[hi].x,b[lo].x,t)
	var h:float
	if p.y<=diagonal:
		var w:float=(p.y-low_z)/maxf(.00001,a[hi].x-a[lo].x)
		h=lerpf(a[lo].y,b[lo].y,t)+w*(a[hi].y-a[lo].y)
	else:
		var w:float=(high_z-p.y)/maxf(.00001,b[hi].x-b[lo].x)
		h=lerpf(a[hi].y,b[hi].y,t)+w*(b[lo].y-b[hi].y)
	return Vector3(p.x,h,p.y)
func road(x:float,old:=false,lateral:=0.)->Vector2:return Vector2(x,(branch(x) if old else center(x))+lateral)
func region(x:float)->int:
	if x<280.:return 0
	if x<FORK:return 1
	if x<JOIN:return 2
	if x<1312.:return 3
	return 4
func road_dist(p:Vector2)->float:return minf(absf(p.y-center(p.x)),absf(p.y-branch(p.x)))
func valid(p:Vector2)->bool:
	if p.x< -16. or p.x>END+18. or p.y<center(p.x)-40. or p.y>branch(p.x)+43.:return false
	for obstacle in solids:
		if absf(obstacle.x-p.x)<obstacle.y and Vector2(obstacle.x,obstacle.z).distance_squared_to(p)<obstacle.y*obstacle.y:return false
	return true
func tint(p:Vector2)->Color:
	var d:=road_dist(p)
	var palette:=[Color("#94a56b"),Color("#c6ac77"),Color("#a8ac82"),Color("#848c81"),Color("#bbaf83")]
	var c:Color=palette[region(p.x)]
	c=c.lightened(.075*(1.+sin(p.x*.049+p.y*.055)))
	var track:=Color("#d1b689") if absf(p.y-center(p.x))<absf(p.y-branch(p.x))+.1 else Color("#c5a77f")
	return c.lerp(track,1.-smoothstep(3.3,6.,d))

func mesh_strip(x0:int,x1:int)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts:=0
	var rowsize:=0
	for x in range(x0,x1+1,5):
		var z0:=center(x);var z1:=branch(x)
		var across:Array[float]=[-180.,-100.,-55.,-30.,-17.,-9.,-5.,-3.6,0.,3.6,5.,8.]
		for k in range(1,9):across.append(8.+maxf(0.,z1-z0-16.)*k/9.)
		var side:=maxf(z1-z0,16.)
		for add:float in [-8.,-5.,-3.6,0.,3.6,5.,9.,16.,26.,42.,64.,110.,190.]:across.append(side+add)
		rowsize=across.size()
		var samples:=PackedVector2Array()
		for off in across:
			var pt:=Vector2(x,z0+off)
			var pos:=Vector3(pt.x,ground(pt),pt.y)
			samples.append(Vector2(pt.y,pos.y))
			var n:=Vector3(ground(pt-Vector2(.5,0))-ground(pt+Vector2(.5,0)),1.,ground(pt-Vector2(0,.5))-ground(pt+Vector2(0,.5))).normalized()
			st.set_normal(n);st.set_uv(Vector2(pt.y-z0,pt.y-z1));st.add_vertex(pos)
			verts+=1
		terrain_rows[x]=samples
	for i in range(verts-rowsize):
		if i%rowsize==rowsize-1:continue
		for idx in [i,i+rowsize,i+1,i+1,i+rowsize,i+rowsize+1]:st.add_index(idx)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	mesh.material_override=terrain_material;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mesh)

func xf(at:Vector3,scale3:Vector3,yaw:=0.)->Transform3D:
	return Transform3D(Basis(Vector3.UP,yaw).scaled(scale3),at)
func scatter(mesh:Mesh,poses:Array[Transform3D],color:String)->void:
	if poses.is_empty():return
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=mesh;batch.instance_count=poses.size()
	for j in poses.size():batch.set_instance_transform(j,poses[j])
	var item:=MultiMeshInstance3D.new();item.multimesh=batch;item.material_override=a.material(color);add_child(item)
func populate()->void:
	var pine:=SphereMesh.new();pine.radial_segments=7;pine.rings=3
	var bark:=CylinderMesh.new();bark.radial_segments=6
	var rock:=SphereMesh.new();rock.radial_segments=6;rock.rings=3
	var post:=BoxMesh.new()
	for x in range(16,int(END),6):
		var side:float=rng.randf_range(9.,69.)*(1. if rng.randf()>.50 else -1.)
		var p:=road(x,side>0.,side);var h:=rng.randf_range(2.5,6.1)
		if road_dist(p)<8. or (absf(x-WATCH)<28 or absf(x-CAMP)<30 or x>END-70):continue
		var here:=surface(p)
		if region(x) in [0,2,4] or rng.randf()>.77:
			near_trees.append(xf(here+Vector3.UP*h*.61,Vector3(h*.32,h,h*.35)))
			trunks.append(xf(here+Vector3.UP*h*.18,Vector3(.25,h*.33,.25)))
		else:
			var span:=rng.randf_range(1.8,7.3)
			stone_transforms.append(xf(here,Vector3(span,span*rng.randf_range(.65,1.8),span*.93),rng.randf()*TAU))
		for k in 2:
			var patch:=road(x+k*2.,k==1,rng.randf_range(6.,11.)*(1. if k==1 else -1.))
			grasses.append(xf(surface(patch)+Vector3.UP*.17,Vector3(1.2,.43,.9)))
	for x in range(28,int(END),23):
		for side in [-1.,1.]:
			var point:=road(x,side>0.,side*5.9)
			waystones.append(xf(surface(point)+Vector3.UP*.46,Vector3(.30,.92,.32)))
	scatter(pine,near_trees,"#51745e");scatter(bark,trunks,"#86674f");scatter(rock,stone_transforms,"#a19986");scatter(pine,grasses,"#839861");scatter(post,waystones,"#d8c6a1")

func text3(parent:Node3D,pos:Vector3,words:String,size_px:=.010)->Label3D:
	var l:=Label3D.new();parent.add_child(l);l.position=pos;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.text=words;l.font=preload("res://harbour_fonts.gd").body();l.font_size=30;l.pixel_size=size_px;l.modulate=Color("#ffe9b6");l.outline_size=8;return l
func block(p:Vector2,r:float)->void:solids.append(Vector3(p.x,r,p.y))
func site(p:Vector2)->Node3D:return a.group(self,surface(p))
func frameset(parent:Node3D,at:Vector3)->Node3D:
	var mount:=a.group(parent,at)
	for side in [-1,1]:
		a.beam(mount,Vector3(0,0,side*1.47),Vector3(0,4.3,side*1.47),.18,"#795b43")
		for x in [-1,1]:a.beam(mount,Vector3(x*.84,0,side*1.47),Vector3(0,2.2,side*1.47),.09,"#ad8b58")
	a.beam(mount,Vector3(0,4.33,-1.73),Vector3(0,4.33,1.73),.22,"#99714a")
	return mount
func build_sites()->void:
	var yard:=site(road(0));stations.yard=yard;frame=frameset(yard,Vector3(-3,0,-5))
	craft.villa(yard,Vector3(-19,0,-14),7.,4.4,.2,1)
	for z in [-6.52,-3.48]:
		a.column(yard,Vector3(-.5,0,z),3.)
	a.beam(yard,Vector3(-.5,3.15,-6.52),Vector3(-.5,3.15,-3.48),.25,"#ac8163")
	apprentice=a.courier(yard,true);apprentice.position=Vector3(-5.76,0,-5.98);apprentice.rotation.y=.54
	preload("res://zephyr_people.gd").new().costume(apprentice,"miller")
	var camp:=site(road(CAMP,true,10.));stations.camp=camp
	craft.cloth(camp,Vector3(0,3.3,-.8),4.2,"#b96846")
	for x in [-1.9,1.9]:a.beam(camp,Vector3(x,0,-.7),Vector3(x,3.34,-.7),.09,"#77614b")
	craft.barrel(camp,Vector3(1.8,0,1.8),.8);a.crate(camp,Vector3(-1.2,0,0),1.2)
	helper=a.courier(camp,true);helper.position=Vector3(.46,0,.2)
	var watch:=site(road(WATCH,true,8.6));stations.watch=watch
	a.box(watch,Vector3(0,.10,0),Vector3(6,.3,4),"#c5ad88")
	a.box(watch,Vector3(0,.81,0),Vector3(2.6,.24,.7),"#926f4a")
	for x in [-.99,.99]:a.box(watch,Vector3(x,.42,0),Vector3(.17,.7,.53),"#7b634e")
	elder=a.courier(watch,true);elder.position=Vector3(-.2,.17,-.86);elder.rotation.y=PI
	preload("res://zephyr_people.gd").new().costume(elder,"priest")
	cup=a.group(elder,Vector3(-.29,1.06,.41))
	a.cyl(cup,Vector3(0,-.02,0),.13,.17,.26,"#9aaba5")
	a.cyl(cup,Vector3.UP*.115,.152,.152,.013,"#564b41")
	a.ring(cup,Vector3.UP*.122,.161,.015,"#e1c084")
	a.ring(cup,Vector3(-.16,.02,0),.081,.022,"#a79f85").rotation.x=PI/2
	var spoon:=a.group(elder.get_node("ArmR"),Vector3(0,-.43,.08))
	a.beam(spoon,Vector3(-.02,0,0),Vector3(-.42,.04,.04),.019,"#bc9d73")
	a.ball(spoon,Vector3(-.44,.045,.04),Vector3(.15,.061,.12),"#c0aea0")
	for side in [-1.,1.]:
		var tuft:=a.ball(elder,Vector3(side*.12,1.405,.31),Vector3(.24,.082,.10),"#c3b39b")
		tuft.rotation.z=side*.16
	var port:=site(road(END));stations.port=port;harbor_frame=frameset(port,Vector3(1.8,0,6.5))
	for j in 4:
		craft.villa(port,Vector3((j-1)*9.2,0,-11.-j%2*3),6.6,3.5+j%3,PI*.87,j%3)
	for j in 27:a.box(port,Vector3((j-13)*.65,-.12,12.5),Vector3(.63,.28,8.6),"#ac8967")
	var tower:=a.group(port,Vector3(19,0,8.3));a.cyl(tower,Vector3.UP*3.1,1.8,1.26,6.2,"#d5bf9b")
	far_lamp=a.ball(tower,Vector3.UP*6.9,Vector3(1.1,1.35,1.1),"#ffcf72",true)
	for j in 5:a.column(port,Vector3(-7.+j*4.,-.6,16.8),1.55)
	ferry=a.group(port);boat_from=Vector3(28.,-.7,52.)
	architecture.make_ferry(ferry)
	captain=a.courier(ferry,true);preload("res://bell_household.gd").new().dress(captain,true);captain.position=Vector3(1.,.2,0);captain.rotation.y=-PI/2
	ferry.position=boat_from
	var basin:=a.box(port,Vector3(11,-1.,59.),Vector3(102.,.20,88.),"#5798a1")
	var sea_mat:=ShaderMaterial.new();sea_mat.shader=preload("res://tide_sea.gdshader");basin.material_override=sea_mat
	for point:float in [65.,FORK-9.,FORK+95.,FORK+105.,WATCH-65.,WATCH+65.,JOIN+45.,PLATEAU+180.,END-50.]:
		var old:bool=point>FORK and point<JOIN
		var p:=road(point,old,7.);var shrine:=site(p)
		a.column(shrine,Vector3.ZERO,1.48);a.cyl(shrine,Vector3.UP*1.72,.39,.54,.4,"#9a785b")
		var glow:=a.ball(shrine,Vector3.UP*2.12,Vector3(.52,.71,.52),"#e8b467",true);beacons.append(glow);beacon_points.append(p);block(p,.68)
func build()->void:
	rng.seed=31644;terrain_material.shader=preload("res://bell_ground.gdshader")
	for x in range(-30,int(END)+30,150):mesh_strip(x,x+150)
	populate();build_sites()
	waters=a.box(self,Vector3(END*.5,-4.,128),Vector3(END*2.+600,.4,344),"#478e96")
	var wave:=ShaderMaterial.new();wave.shader=preload("res://tide_sea.gdshader");waters.material_override=wave
