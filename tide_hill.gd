extends Node3D

signal hit(loss:float,reason:String)
signal arrived
signal post_marked
signal cargo_cue(id:String)
const Catch:=preload("res://cargo_catch.gd")
const Art=preload("res://workshop.gd")
const DockArt=preload("res://tide_art.gd")
const Town=preload("res://district.gd")
const FORK:=Vector3(218,6.6,5)
const JOIN:=Vector3(236,10.2,23)
const FINISH:=Vector3(215,15,46)
const POST:=Vector3(252,8.2,6)
const START:=Vector3(186,3.55,-3)
const ENTRY:=[START,Vector3(193,3.64,-3),Vector3(202,3.8,-4),Vector3(210,4.5,-3),FORK]
const BYPASS:=[FORK,Vector3(225,7,-1),Vector3(237,7,-4),Vector3(248,7.9,-1),POST,Vector3(252,8.8,15),Vector3(246,9.4,22),JOIN]
const LAST:=[JOIN,Vector3(240,10.8,32),Vector3(239,11.4,42),Vector3(233,12.2,49),Vector3(226,13.5,51),FINISH]
const BRIDGE_HALF:=12.728
const ROAD_HALF:=4.35
var art:=Art.new()
var craft:=preload("res://coastal_craft.gd").new()
var rail_struck:=false
var design:=DockArt.new()
var town:=Town.new()
var routes:Array[PackedVector3Array]=[]
var span:Node3D
var needles:Array[Node3D]=[]
var post_lamp:Node3D
var dust:Array[Node3D]=[]
var runner:Node3D
var mill_sails:Node3D
var dispatch:Node3D
var gatehouse:Node3D
var wheels:Array[Node3D]=[]
var van:Node3D
var cargo:Node3D
var pos:=Vector2(186,-3)
var altitude:=3.55
var heading:=0.0
var speed:=0.0
var clock:=0.0
var lateral:=0.0
var tilt:=0.0
var tilt_speed:=0.0
var bump_lock:=0.0
var slide_side:=0
var catch_left:=0.0
var brace_left:=0.0
var mark:=false
var crossed:=false
var travel:=0.0
var bridge_used:=false
var heavy:=false
var active:=false
var nearest_lane:=0
var inside_bridge:=false
var on_summit:=false
var view_heading:=0.0
var color_font:=preload("res://harbour_fonts.gd").body()

func xz(p:Vector3)->Vector2:return Vector2(p.x,p.z)

func smooth_nodes(anchors:Array)->PackedVector3Array:
	var curve:=Curve3D.new()
	curve.bake_interval=1.55
	for i in anchors.size():
		var left:Vector3=anchors[maxi(i-1,0)]
		var right:Vector3=anchors[mini(i+1,anchors.size()-1)]
		var tang:Vector3=(right-left)*0.12
		curve.add_point(anchors[i],-tang,tang)
	return curve.get_baked_points()

func surface_route(points:PackedVector3Array,half:float,depth:float,tint:String,shoulder:float=0.0)->void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left:=PackedVector3Array();var right:=PackedVector3Array()
	for i in points.size():
		var along:Vector3=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		var side:=Vector3(-along.z,0,along.x).normalized()
		left.append(points[i]+side*(shoulder-half)+Vector3.UP*depth)
		right.append(points[i]+side*(shoulder+half)+Vector3.UP*depth)
	for i in points.size()-1:
		for v:Vector3 in [left[i],right[i],left[i+1],right[i],right[i+1],left[i+1]]:
			st.set_normal(Vector3.UP);st.add_vertex(v)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	var mat:=art.material(tint).duplicate() as StandardMaterial3D
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=preload("res://harbour_materials.gd").sample(2,tint,4.2,true,.66) if half>3.0 else mat;add_child(mesh)

func label(p:Node3D,at:Vector3,s:String)->void:
	var l:=Label3D.new();l.text=s;l.font=color_font;l.font_size=27;l.pixel_size=0.014
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.modulate=Color("#ffecca");l.outline_modulate=Color("#26434b");l.outline_size=7
	p.add_child(l);l.position=at

func build_road(points:PackedVector3Array,kind:int)->void:
	surface_route(points,ROAD_HALF+0.4,-0.04,"#968570")
	surface_route(points,ROAD_HALF,0,"#c9ab83" if kind==0 else "#cab78f")
	for signum in [-1,1]:
		surface_route(points,0.10,0.014,"#f0ddae",signum*(ROAD_HALF-0.35))
	for flank in [-1,1]:
		var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var outer:=PackedVector3Array()
		for i in points.size():
			var d:Vector3=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
			outer.append(points[i]+Vector3(-d.z,0,d.x).normalized()*(ROAD_HALF+0.40)*float(flank)-Vector3.UP*0.06)
		for i in outer.size()-1:
			var a:=outer[i];var b:=outer[i+1];var c:=Vector3(a.x,-1.35,a.z);var e:=Vector3(b.x,-1.35,b.z)
			var sn:Vector3=(b-a).cross(Vector3.DOWN).normalized()*float(-flank)
			for v:Vector3 in [a,b,c,c,b,e]:mesh.set_normal(sn);mesh.add_vertex(v)
		var wall:=MeshInstance3D.new();wall.mesh=mesh.commit();wall.material_override=craft.mineral("#b29c7f","#8e7e68");add_child(wall)
	for i in range(1,points.size()-1,4):
		var at:=points[i]
		var forward:Vector3=(points[i+1]-points[i-1]).normalized()
		var side:=Vector3(-forward.z,0,forward.x).normalized()
		for flank in [-1,1]:
			var base:Vector3=at+side*(flank*(ROAD_HALF+0.45))
			if flank==1 and i%8==1 and (kind!=1 or i>2):
				var rail:=art.box(self,base+Vector3.UP*0.38,Vector3(2.75,0.70,0.47),DockArt.SALT)
				rail.rotation.y=-atan2(forward.z,forward.x)
		if i%12==1 and at.x>209:
			var tree_at:=at-side*(ROAD_HALF+0.77)
			art.cypress(self,tree_at,1.4+(i%7)*0.11)

func build_span()->void:
	var mid:Vector3=(FORK+JOIN)/2
	var base:=art.group(self,mid)
	base.rotation.y=-PI/4
	span=art.group(base)
	art.box(span,Vector3.DOWN*0.21,Vector3(BRIDGE_HALF*2+0.4,0.42,6.25),Art.WOOD)
	for j in 24:
		var plank:=art.box(span,Vector3(-BRIDGE_HALF+0.53+j*1.065,0.025,0),Vector3(1.0,0.09,6.1),Art.WOOD)
		plank.material_override=preload("res://harbour_materials.gd").sample(1,"#a47756" if j%3 else "#b7895e",6.3,false,.72)
	for z in [-3.05,3.05]:
		art.beam(span,Vector3(-BRIDGE_HALF,0.78,z),Vector3(BRIDGE_HALF,0.78,z),0.066,Art.WOOD)
		for x in [-12.3,-8.0,-4.0,0.0,4.0,8.0,12.3]:
			art.box(span,Vector3(x,0.43,z),Vector3(0.17,0.96,0.17),DockArt.BRASS)
		art.box(base,Vector3(0,-4.8,z),Vector3(3.1,10,1.4),DockArt.STONE)
		var hub:=art.cyl(base,Vector3(0,0.1,z),0.92,0.92,0.32,DockArt.BRASS)
		hub.rotation.x=PI/2
		var needle:=art.group(base,Vector3(0,0.1,z+signf(z)*0.27))
		art.box(needle,Vector3.UP*0.39,Vector3(0.14,0.80,0.14),DockArt.INK)
		needles.append(needle)
	label(self,FORK+Vector3(-1,3.7,1),"木衡桥 ↗　 村道 →")
	span.rotation.z=atan2(JOIN.y-FORK.y,BRIDGE_HALF*2)

func banner(point:Vector3,txt:String,tint:String)->Node3D:
	var root:=art.group(self,point)
	for x in [-1.3,1.3]:art.beam(root,Vector3(x,0,0),Vector3(x,2.4,0),0.11,Art.WOOD)
	art.box(root,Vector3(0,1.83,0),Vector3(2.9,0.67,0.21),tint)
	label(root,Vector3.UP*2.86,txt)
	return root

func _ready()->void:
	routes=[smooth_nodes(ENTRY),smooth_nodes([FORK,JOIN]),smooth_nodes(BYPASS),smooth_nodes(LAST)]
	for i in [0,2,3]:build_road(routes[i],i)
	build_span()
	for pair in [[Vector3(240,1,2),Vector3(30,12,28)],[Vector3(246,2.3,15),Vector3(25,13,22)],[Vector3(225,2.5,41),Vector3(35,21,27)],[Vector3(210,4.3,48),Vector3(26,20,22)]]:
		craft.outcrop(self,pair[0],pair[1],int(Vector3(pair[0]).x))
	craft.hill_village(self)
	mill_sails=get_node(get_meta("mill_sails_path"))
	gatehouse=banner(POST+Vector3(3.1,0.1,1),"蓝门邮站","#3c7081")
	post_lamp=design.light_stone(gatehouse,Vector3.UP*2.45,Vector3.ONE*0.58,DockArt.BRASS)
	runner=art.courier(gatehouse);runner.position=Vector3(-1.3,0,0.7);runner.rotation.y=-PI*0.46
	dispatch=art.crate(gatehouse,Vector3(-0.6,0,0.7),0.72)
	banner(FINISH+Vector3(0,0.04,2.9),"北岬灯室",DockArt.BLUE)
	for i in 6:
		var cloud:=art.ball(self,Vector3.ZERO,Vector3(0.52,0.30,0.4),"#c9ae8c",true)
		cloud.hide();dust.append(cloud)

func begin(truck:Node3D,lens:Node3D,is_heavy:bool)->void:
	van=truck;cargo=lens;heavy=is_heavy
	van.reparent(self,true);van.get_node("Driver").show()
	wheels.clear()
	for n:Node3D in van.get_tree().get_nodes_in_group("wheels"):
		if van.is_ancestor_of(n):wheels.append(n)
	active=true;reset_drive(true)

func reset_drive(full:bool)->void:
	pos=xz(START);altitude=START.y;speed=0;heading=0;view_heading=0
	lateral=0;tilt=0;tilt_speed=0;inside_bridge=false;on_summit=false;nearest_lane=0
	slide_side=0;catch_left=0;brace_left=0;bump_lock=0
	rail_struck=false
	if full:
		mark=false;crossed=false;bridge_used=false;travel=0;clock=0
		dispatch.show();post_lamp.material_override=design.glow(DockArt.BRASS)
	if is_instance_valid(van):place_truck(0,0,1)

func nearest(p:Vector2)->Dictionary:
	var best:=INF
	var out:={"center":START,"lane":0,"gap":0.0,"along":Vector2.RIGHT}
	for idx in routes.size():
		var path:=routes[idx]
		for i in path.size()-1:
			var a:=xz(path[i]);var b:=xz(path[i+1])
			var k:=clampf((p-a).dot(b-a)/maxf(0.00001,a.distance_squared_to(b)),0,1)
			var pt:Vector3=path[i].lerp(path[i+1],k)
			var sq:=p.distance_squared_to(xz(pt))
			if sq<best:
				best=sq;out={"center":pt,"lane":idx,"gap":sqrt(sq),"along":a.direction_to(b)}
	return out

func brace()->void:
	if catch_left<=0.:return
	brace_left=Catch.DURATION;catch_left=0.;cargo_cue.emit("grab")

func use()->String:
	if pos.distance_to(xz(FINISH))<5.4:
		if absf(speed)>2.0:return "先刹车，停在灯室交接台前"
		active=false;arrived.emit();return ""
	if pos.distance_to(xz(POST))<5.4 and not mark:
		if absf(speed)>2.5:return "慢行靠近蓝门，再请邮差盖戳"
		mark=true;dispatch.hide();post_lamp.material_override=design.glow(DockArt.SIGNAL)
		post_marked.emit();return "蓝门盖戳 · 加赏 11 枚"
	return "灯室在山顶；蓝门邮站可选停靠"

func place_truck(slope:float,turn:float,dt:float)->void:
	van.position=Vector3(pos.x,altitude+0.07,pos.y)
	van.rotation=Vector3(-turn*clampf(speed*0.005,-0.05,0.05),-heading,slope)
	cargo.position.z=0.16+lateral
	cargo.rotation.x=-lateral*0.21
	for w in wheels:w.rotate_z(-speed*dt*1.15)
	for i in dust.size():
		dust[i].visible=absf(speed)>5.0 and not inside_bridge
		if dust[i].visible:
			var life:=fposmod(clock*2+i/6.0,1)
			var v:=Vector2.from_angle(heading)
			var p:=pos-v*(2.2+life*2.4)+Vector2(-v.y,v.x)*((i%2)*2-1)*0.78
			dust[i].position=Vector3(p.x,altitude+0.14+life*0.55,p.y)
			dust[i].scale=Vector3.ONE*(0.14+life*0.27)

func tick(dt:float,gas:float,turn:float)->void:
	clock+=dt
	mill_sails.rotation.x=clock*0.61
	bump_lock=maxf(0,bump_lock-dt)
	catch_left=maxf(0.,catch_left-dt)
	var brake:=Input.is_key_pressed(KEY_SPACE)
	if brake:speed=move_toward(speed,0,dt*12.6)
	elif gas>0:speed=move_toward(speed,10 if heavy else 11.5,dt*3.7)
	elif gas<0:speed=move_toward(speed,-3.0,dt*(8.8 if speed>0 else 3.1))
	else:speed=move_toward(speed,0,dt*1.6)
	heading+=turn*dt*(0.50+minf(absf(speed)/5,1)*0.73)*clampf(speed*1.7,-1,1)
	var dir:=Vector2.from_angle(heading)
	var p:=pos+dir*speed*dt
	var ref:=nearest(p)
	var center:Vector3=ref.center
	var gap:float=ref.gap
	var lane:int=ref.lane
	var side_limit:=2.58 if lane==1 else ROAD_HALF-0.32
	var before:=pos
	if gap>side_limit:
		p=xz(center)+(p-xz(center)).normalized()*side_limit
		if gap>side_limit+0.042 and absf(speed)>4.8 and bump_lock<=0:
			hit.emit(4+absf(speed)*0.46,"擦撞石垣");bump_lock=1.1;speed*=0.53
	pos=p;travel+=before.distance_to(pos);nearest_lane=lane
	var projection:float=(pos-xz((FORK+JOIN)/2)).dot(Vector2(1,1).normalized())
	inside_bridge=lane==1 and absf(projection)<BRIDGE_HALF-0.65
	var target:=clampf(-projection*0.008,-0.095,0.095)*(1.25 if heavy else 1.0) if inside_bridge else 0.0
	tilt_speed+=(target-tilt)*dt*8.0;tilt_speed*=exp(-dt*1.65);tilt+=tilt_speed*dt
	span.rotation.z=atan2(JOIN.y-FORK.y,BRIDGE_HALF*2)+tilt
	for n in needles:n.rotation.z=-tilt*4.2
	if inside_bridge:
		bridge_used=true
		if absf(projection)<3.2 and absf(speed)>7.6 and bump_lock<=0:
			hit.emit(9.0 if heavy else 7.0,"冲过摇桥支点");bump_lock=1.5
	if bridge_used and lane==3:crossed=true
	var target_height:=center.y+(projection*sin(tilt) if inside_bridge else 0.0)
	var rise:=target_height-altitude
	var slope:=clampf(atan2(rise,maxf(0.05,absf(speed)*dt))*signf(speed),-0.24,0.24)
	altitude=move_toward(altitude,target_height,dt*12)
	var drift:float=-turn*speed*absf(speed)*.0043+sin(clock*2.7)*absf(tilt)
	var side:=int(signf(drift))
	if catch_left<=0. and brace_left<=0. and (side!=slide_side or absf(drift)<.08):slide_side=0
	if slide_side==0 and absf(speed)>.5 and Catch.reaches_rail(.84-lateral*side,absf(drift),0.,.10):
		slide_side=side;catch_left=Catch.WINDOW;cargo_cue.emit("buckle")
	lateral=clampf(lateral+drift*dt,-.84,.84)
	if absf(lateral)>0.825 and absf(speed)>5.6 and not rail_struck and catch_left<=0 and brace_left<=0:
		rail_struck=true
		if bump_lock<=0:hit.emit(3.5,"镜芯碰到车帮");bump_lock=0.8
	if absf(lateral)<0.50:rail_struck=false
	if brace_left>0:
		lateral=move_toward(lateral,0,Catch.grip_step(minf(dt,brace_left)));brace_left=maxf(0,brace_left-dt)
	view_heading=lerp_angle(view_heading,heading,1-exp(-dt*4.5))
	on_summit=pos.distance_to(xz(FINISH))<5.4
	place_truck(lerpf(van.rotation.z,slope,1-exp(-dt*4)),turn,dt)

