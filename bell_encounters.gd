extends RefCounted

const HERD:=189.
const FORD:=381.
const ROCKS:=[327.,702.,949.,1228.]
var game
var land
var art:=preload("res://workshop.gd").new()
var goats:Array[Node3D]=[]
var herd_age:=-1.
var herd_called:=false
var herd_passed:=false
var ford_crossed:=false
var rocks:Array[Node3D]=[]
var rubble:Array[Node3D]=[]
var rock_age:PackedFloat32Array=[]
var rock_hit:Array[bool]=[]
var splashes:Array[Node3D]=[]
var spray_age:=2.
var at_spray:=Vector3.ZERO
var splintered:=false
var birds:Array[Node3D]=[]
var starting:Array[Vector3]=[]

func make_goat(parent:Node3D,i:int)->Node3D:
	var n:=art.group(parent);var white:="#d7ccae" if i%3 else "#967a5f"
	art.ball(n,Vector3(0,.74,0),Vector3(1.16,.70,.60),white,true)
	art.ball(n,Vector3(.53,1.,0),Vector3(.48,.46,.41),white,true)
	art.ball(n,Vector3(.73,.97,0),Vector3(.21,.18,.25),"#6c5a48",true)
	for side in [-1,1]:
		var ear:=art.ball(n,Vector3(.47,1.12,side*.25),Vector3(.26,.12,.18),white,true);ear.rotation.z=.18
		art.beam(n,Vector3(.46,1.16,side*.13),Vector3(.34,1.46,side*.21),.059,"#786a53");art.beam(n,Vector3(.34,1.46,side*.21),Vector3(.18,1.41,side*.28),.041,"#786a53")
		art.ball(n,Vector3(.62,1.09,side*.19),Vector3(.072,.075,.055),"#3b3b32")
	for j in 4:
		var leg:=art.group(n,Vector3((.33 if j<2 else -.34),.62,.18 if j%2 else -.18));leg.name="Hoof"+str(j)
		art.beam(leg,Vector3.ZERO,Vector3(.04,-.56,0),.062,white);art.box(leg,Vector3(.05,-.55,0),Vector3(.14,.15,.14),"#61594b")
	art.cyl(n,Vector3(.47,.70,0),.13,.075,.20,"#bf9750")
	n.scale=Vector3.ONE*(.77+i%3*.15);return n
func build(owner_node)->void:
	game=owner_node;land=game.land
	for i in 7:
		var goat:=make_goat(land,i);goats.append(goat);update_goat(i,0.,0.)
	var shepherd:=art.courier(land);shepherd.position=land.surface(land.road(HERD,false,7.4));shepherd.rotation.y=PI*.5
	art.beam(shepherd,Vector3(.64,0,.15),Vector3(.60,1.74,.11),.032,"#766147")
	for x:float in ROCKS:
		var p:Vector2=land.road(x,false,-8.)
		var rock:=art.ball(land,land.surface(p)+Vector3.UP*1.2,Vector3(2.2,1.82,1.66),"#9a8c7d",true);rocks.append(rock);rock_age.append(-1.);rock_hit.append(false)
		var grit:=art.group(land);rubble.append(grit)
		for j in 5:art.ball(grit,Vector3.ZERO,Vector3.ONE*.20,"#b4a184",true)
		grit.hide()
		var crag:Node3D=land.site(p);land.craft.outcrop(crag,Vector3(-2.,1.,-2.2),Vector3(6.,5.5,5.),int(x))
	# A shallow rock shelf leaves a visibly drier, slower crossing on the left.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-23,23):
		for off:Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(-1,1),Vector2i(-1,1),Vector2i(1,0),Vector2i(1,1)]:
			var lateral:=float(z+off.y);var x:=FORD+lateral*.51+sin(lateral*.33)*1.4+off.x*(2.9+1.1*sin(lateral*.18))
			var p:Vector2=land.road(x,false,lateral);st.set_normal(Vector3.UP);st.add_vertex(land.surface(p)+Vector3.UP*.087)
	var pool:=MeshInstance3D.new();pool.mesh=st.commit();var mat:=ShaderMaterial.new();mat.shader=preload("res://tide_sea.gdshader");pool.material_override=mat;land.add_child(pool)
	for i in 16:
		var p:Vector2=land.road(FORD-6.+i*.77,false,-3.95+sin(i*.8)*.85)
		art.ball(land,land.surface(p)+Vector3.UP*.045,Vector3(1.5,.21,1.1),"#a49d89",true)
	for i in 12:
		var drop:=art.ball(land,Vector3.ZERO,Vector3.ONE,"#b8ded6",true);drop.hide();splashes.append(drop)
	for i in 13:
		var b:=art.group(land);var p:=Vector3.ZERO
		for side in [-1,1]:
			var wing:=art.box(b,Vector3(.01,.03,.27*side),Vector3(.17,.045,.59),"#e8debc");wing.rotation.x=side*.22
		art.ball(b,Vector3.ZERO,Vector3(.32,.12,.12),"#a8a192")
		birds.append(b);starting.append(p);b.hide()
func update_goat(i:int,u:float,t:float)->void:
	var q:=clampf((u-.28*i)/4.3,0.,1.);var start:=Vector2(HERD+(i%3-1)*1.85+(i/3)*1.33,-8.-i%2*.96)
	var offset:=start+Vector2(sin(q*PI+.74*i)*q*1.65,17.*smoothstep(0.,1.,q))
	var p:Vector2=land.road(offset.x,false,offset.y);var mv:bool=q>.005 and q<.995
	goats[i].position=land.surface(p)+Vector3.UP*(absf(sin(t*7.4+i))*.12 if mv else 0.)
	goats[i].rotation.y=-PI*.5+.35*cos(t*.75+i) if mv else -.9+.31*sin(t*.27+i)
	for j in 4:goats[i].get_node("Hoof"+str(j)).rotation.z=sin(t*8.+i+j*2.42)*(.44 if mv else .035)
func on_echo()->void:
	if absf(game.pos.x-HERD)<79. and not herd_passed:
		herd_called=true;herd_age=maxf(1.,herd_age);game.tell("头羊认出了铃音。牧人举起手杖，让羊群先把车道让出来。",4.)
	for i in ROCKS.size():
		if rock_age[i]<0. and ROCKS[i]-game.pos.x>0. and ROCKS[i]-game.pos.x<72. and land.road_dist(game.pos)<22. and not game.old_road:
			rock_age[i]=0.;game.tell("钟声震松了岩石。前面有落石，慢一点。",4.,2)
func active_rock()->int:
	for i in ROCKS.size():
		if rock_hit[i] or rock_age[i]<0. or rock_age[i]>7.7:continue
		var dx:float=ROCKS[i]-game.pos.x
		if dx>=-1. and dx<43. and absf(game.pos.y-land.center(ROCKS[i]))<32.:return i
	return -1

func damage(amount:float,words:String)->void:
	var loss:=amount*(.78 if game.packed or game.fitted else 1.)
	game.hp=maxf(0.,game.hp-loss);game.speed*=.47;game.velocity*=.63;game.swing_v+=.92;game.slip=clampf(game.slip+.29,-.83,.83);game.shake=.35;game.hit_lock=1.2;game.audio.play_cue("bonk");game.tell(words+"　·　钟身 −%d"%roundi(loss),3.,3);game.save()
func tick(dt:float)->void:
	var x:float=game.pos.x;var t:float=game.elapsed
	if absf(x-HERD)<91.:
		if herd_age<0. and x>HERD-44.:herd_age=0.;game.tell("牧人举起杖。羊群正要横过下坡路。",3.8);game.one_shot(1,1.33,-13.)
		if herd_age>=0.:herd_age+=dt*(1.85 if herd_called else 1.)
		for i in goats.size():
			update_goat(i,maxf(0.,herd_age),t)
			var gp:=goats[i].position
			if not herd_passed and absf(game.speed)>3.0 and Vector2(gp.x,gp.z).distance_to(game.pos)<2.45:
				herd_passed=true;damage(4.5,"牲口猛地回头，你急刹避让")
		if herd_age>8.:herd_passed=true
	if absf(x-FORD)<39.:
		var lateral:float=game.pos.y-land.center(x);var stream_x:=FORD+lateral*.51+sin(lateral*.33)*1.4
		if not ford_crossed and absf(x-stream_x)<2.95:
			ford_crossed=true;at_spray=land.surface(game.pos);spray_age=0.;game.audio.play_cue("land")
			if absf(game.speed)>5.6 and lateral>-2.7:damage(6.,"车轮拍进浅溪，钟杠撞上栏杆")
			else:game.tell("轮子咬住露出水面的石板，铜钟平稳过了浅滩。",3.)
		elif not ford_crossed and x>FORD-38. and not (game.visited&4):
			game.visited|=4;game.tell("水从车辙上淌过去。靠左的石板高一些，也可以减速涉水。",4.)
	if spray_age<1.:
		spray_age+=dt
		for i in splashes.size():
			var u:=spray_age;var az:=i*TAU/splashes.size()
			splashes[i].visible=u<.92;splashes[i].position=at_spray+Vector3(cos(az)*(1.+u*3.2),.38+sin(u*PI)*(1.+(i%3)*.31),sin(az)*(1.+u*2.1));splashes[i].scale=Vector3.ONE*maxf(.01,(1.-u)*.22)
	for i in ROCKS.size():
		var rx:float=ROCKS[i]
		if absf(x-rx)>85. or absf(game.pos.y-land.center(rx))>55.:continue
		if rock_age[i]<0. and x>rx-38.:
			rock_age[i]=0.;game.tell("山上掉石头了！看前面的路，准备刹车。",3.,2);game.audio.play_cue("warn")
		if rock_age[i]<0.:continue
		rock_age[i]+=dt
		var u:=clampf((rock_age[i]-1.2)/6.6,0.,1.);var side:float=lerpf(-8.2,10.,u)
		var rp:Vector2=land.road(rx+sin(u*3.2)*2.6,false,side)
		rocks[i].position=land.surface(rp)+Vector3.UP*(.79+absf(sin(u*12.5))*(1.-u)*1.07);rocks[i].rotation=Vector3(6.8*u,1.4*u,3.5*u)
		var grit:Node3D=rubble[i];grit.visible=u<.99;grit.position=rocks[i].position-Vector3.UP*.55
		if grit.visible:
			for j in grit.get_child_count():grit.get_child(j).position=Vector3(sin(j*7.)*(.3+u*.7),absf(sin(t*5.+j))*.36,cos(j*6.)*.55)
		if not rock_hit[i] and rp.distance_to(game.pos)<2.3 and (absf(game.speed)>1.7 or u<.98):
			rock_hit[i]=true;damage(13.,"迎面滚石砸上货架")
	update_birds(t,x)
func update_birds(t:float,x:float)->void:
	var base_x:=landmark(x)
	if base_x<0.:
		for bird in birds:bird.hide()
		return
	for i in birds.size():
		var wave:=t*.66+i*.61;var s:float=base_x+cos(wave*.31)*16.+(i%5-2)*2.5
		var p:Vector2=land.road(s,false,9.+sin(wave*.44)*11.+i*.59)
		var b:=birds[i];b.show();b.position=land.surface(p)+Vector3.UP*(6.6+sin(wave*.5)*1.8+i*.29);b.rotation.y=-wave*.39
		b.get_child(0).rotation.x=.42*sin(t*5.1+i);b.get_child(1).rotation.x=-.42*sin(t*5.1+i)
func landmark(x:float)->float:
	for center:float in [212.,467.,926.,1196.,1496.]:
		if absf(x-center)<95.:return center
	return -1.
func snapshot()->Dictionary:return {"herd":herd_passed,"called":herd_called,"ford":ford_crossed,"ages":Array(rock_age),"hits":rock_hit.duplicate()}
func restore(data:Dictionary)->void:
	herd_passed=data.get("herd",false);herd_called=data.get("called",false);herd_age=9. if herd_passed else -1.;ford_crossed=data.get("ford",false)
	for i in ROCKS.size():
		if data.get("ages",[]).size()>i:rock_age[i]=data.ages[i];rock_hit[i]=data.hits[i]


