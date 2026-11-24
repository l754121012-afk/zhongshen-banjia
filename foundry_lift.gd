extends Node3D

var art:=preload("res://workshop.gd").new()
var hand:Node3D
var loads:Array[Node3D]=[]
var ropes:Array[MeshInstance3D]=[]
var pennant:Node3D
var drum:Node3D
var ripples:Array[Node3D]=[]
var signal_lamp:Node3D
var catch_light:Node3D
var pulleys:Array[Node3D]=[]
var delivery_piece:Node3D
var receiver:Node3D
var flames:Array[MeshInstance3D]=[]
var cinders:Array[Node3D]=[]
var hearth_glow:OmniLight3D
var elapsed:=0.
var patina:="#488276"
var copper:="#ae6c46"
var brass:="#deb56c"

func build(yard:Node3D)->void:
	yard.add_child(self);position=Vector3(-10.65,0.,-5.55);rotation.y=-.61
	var limestone:=preload("res://coastal_craft.gd").new().mineral("#c0a788","#8c7564")
	var pier:=art.box(self,Vector3(-1.7,1.08,-.2),Vector3(3.1,2.16,4.),"#ab9271");pier.material_override=limestone
	art.box(self,Vector3(-1.7,2.21,-.2),Vector3(3.35,.18,4.23),"#d6be99")
	for z in [-1.4,1.4]:
		art.beam(self,Vector3(-2.35,2.25,z),Vector3(-2.35,5.28,z),.13,"#825c42")
		art.beam(self,Vector3(-2.35,3.65,z),Vector3(.48,5.03,z),.10,"#a07850")
		art.beam(self,Vector3(-2.68,5.12,z),Vector3(.61,5.12,z),.14,"#78563e")
	art.beam(self,Vector3(.25,5.12,-1.63),Vector3(.25,5.12,1.63),.14,brass)
	drum=art.group(self,Vector3(-1.64,3.26,-.46))
	var hub:=art.cyl(drum,Vector3.ZERO,.27,.27,1.21,"#775742");hub.rotation.x=PI/2
	for j in 8:art.ring(drum,Vector3(0,0,j*.105-.36),.29,.038,"#ad8c62").rotation.x=PI/2
	hand=art.courier(self,true);hand.position=Vector3(-2.2,2.30,.71);hand.rotation.y=PI*.5
	preload("res://zephyr_people.gd").new().costume(hand,"miller")
	pennant=art.group(self,Vector3(-.47,4.74,1.43));art.box(pennant,Vector3(.37,-.18,0),Vector3(.77,.40,.046),"#b95e42")
	for i in 2:
		var z:float=[1.12,-1.12][i]
		var wheel:=art.group(self,Vector3(.25,4.94,z));pulleys.append(wheel)
		var sheave:=art.cyl(wheel,Vector3.ZERO,.24,.24,.16,brass,24);sheave.rotation.z=PI/2
		for q in 4:
			var spoke:=art.box(wheel,Vector3(.088,0,0),Vector3(.024,.38,.037),"#725337");spoke.rotation.x=PI*q/4.
		art.beam(self,Vector3(.25,5.2,z),Vector3(.25,4.94,z),.076,patina)
		art.beam(self,Vector3(.18,5.05,z),Vector3(-1.6,3.5,z),.032,"#b39a6e")
		var basket:=art.group(self);loads.append(basket)
		art.cyl(basket,Vector3.UP*.16,.56,.67,.33,"#7c5139",28);weave(basket)
		for j in 3:art.ring(basket,Vector3.UP*(.08+j*.12),.57+.045*j,.032,"#d3ae79")
		for j in 12:
			var az:=TAU*j/12.;art.beam(basket,Vector3(.55*cos(az),0,.55*sin(az)),Vector3(.66*cos(az),.37,.66*sin(az)),.027,"#79533c")
		for j in 3:
			var az:=TAU*j/3.;art.beam(basket,Vector3(.62*cos(az),.36,.62*sin(az)),Vector3.UP*1.1,.028,"#b29a70")
			var ingot:=art.box(basket,Vector3(.21*cos(az),.36,.20*sin(az)),Vector3(.55,.22,.28),copper);ingot.rotation.y=az
		var ribbon:=art.group(basket,Vector3(.1,.37,.62));ribbon.rotation.x=.04
		var dyed:="#547d78" if i==0 else "#c15739"
		art.box(ribbon,Vector3(0,.045,0),Vector3(.44,.12,.13),dyed)
		for end in [-1,1]:
			var tail:=art.box(ribbon,Vector3(end*.11,-.16,.013),Vector3(.15,.39,.053),dyed);tail.rotation.z=end*.12
		ropes.append(art.cyl(self,Vector3.ZERO,.032,.032,1.,"#826a4c"))
		art.box(self,Vector3(.25,.10,z),Vector3(1.45,.18,1.39),patina)
		suspend(i,0.)
	for j in 3:
		var ring:=art.ring(self,Vector3.ZERO,.65,.029,brass);ring.rotation.x=PI/2;ripples.append(ring);ring.hide()
	signal_lamp=art.ball(self,Vector3(-1.1,3.1,1.4),Vector3(.25,.37,.24),"#ffcd6b")
	catch_light=art.group(self,Vector3(.23,.22,-.88));art.ring(catch_light,Vector3.ZERO,.65,.035,brass);catch_light.hide()
	receiver=art.courier(self);receiver.position=Vector3(1.62,.05,1.1);receiver.rotation.y=-1.45
	smith(receiver)
	delivery_piece=art.group(receiver.get_node("ArmL"),Vector3(0,-.35,.16));art.cyl(delivery_piece,Vector3.ZERO,.19,.23,.13,copper);art.ring(delivery_piece,Vector3.UP*.077,.19,.022,brass);delivery_piece.hide()
	receiver.position.x=1.39;receiver.position.z=1.89
	add_foundry_details();kiln(yard)

func suspend(i:int,u:float)->void:
	var z:=1.12 if i==0 else -1.12
	var floor_y:=lerpf(3.47,.23,smoothstep(0.,1.,u))
	loads[i].position=Vector3(.25,floor_y,z)
	var hook:=floor_y+1.1
	ropes[i].position=Vector3(.25,(5.12+hook)*.5,z);ropes[i].scale.y=maxf(.12,5.12-hook)

func animate(phase:String,t:float,worked:bool,blessed:bool)->void:
	var first:=1. if worked else 0.
	var second:=1. if blessed else 0.
	if phase=="first_drop":first=clampf((t-1.)/1.85,0.,1.)
	if phase=="mountain":second=clampf((t-1.15)/1.70,0.,1.)
	suspend(0,first);suspend(1,second)
	var conducting:=phase in ["first_drop","mountain"] and t>.68 and t<2.97
	hand.get_node("ArmR").rotation.x=-1.12+.52*sin(t*8.) if conducting else -.2
	drum.rotation.z=(first+second)*TAU*2
	for i in pulleys.size():pulleys[i].rotation.x=(first if i==0 else second)*TAU*2.2
	pennant.rotation.z=-.09+.34*sin(t*7.) if conducting else -.12
	var reach:=smoothstep(1.72,2.78,t)*(1.-smoothstep(3.,3.9,t)) if phase in ["first_drop","mountain"] else 0.
	receiver.get_node("ArmR").rotation.x=-.23-reach*1.05
	receiver.get_node("ArmL").rotation.x=-.21-reach*.83
	var transfer:=smoothstep(2.65,3.72,t) if phase=="mountain" else (1. if blessed else 0.)
	delivery_piece.visible=blessed and (phase!="mountain" or t>2.73)
	receiver.position=Vector3(1.39,.05,1.89).lerp(Vector3(1.18,.05,-1.65),smoothstep(.78,2.6,t) if phase=="mountain" else (1. if blessed else 0.))
	receiver.position.x+=transfer*.76
	receiver.get_node("LegL").rotation.x=sin(t*8.)*.34 if phase=="mountain" and t>.78 and t<2.55 else 0.
	receiver.get_node("LegR").rotation.x=-receiver.get_node("LegL").rotation.x
	receiver.rotation.y=-1.45+smoothstep(.18,1.1,t)*.85 if phase=="silence" else -1.45
	signal_lamp.visible=conducting;catch_light.visible=second>.94
	for i in ripples.size():
		var u:float=t-i*.16
		ripples[i].visible=phase in ["first_drop","mountain"] and u>=.1 and u<1.26
		if ripples[i].visible:
			ripples[i].position=Vector3(5.7,2.35,-.5).lerp(Vector3(-1.,3.62,.6),u/1.26)
			ripples[i].rotation.y=1.38;ripples[i].scale=Vector3.ONE*(.43+u*.75)


func weave(basket:Node3D)->void:
	var weave_mesh:=SurfaceTool.new();weave_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 7:
		var height:=.056+row*.047
		for j in 96:
			for corner:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var az:=TAU*(j+corner.x)/96.
				var r:=.565+height*.32+.012*sin(az*18+row*PI)
				weave_mesh.set_normal(Vector3(cos(az),-.17,sin(az)).normalized())
				weave_mesh.add_vertex(Vector3(r*cos(az),height+corner.y*.028,r*sin(az)))
	var item:=MeshInstance3D.new();item.mesh=weave_mesh.commit()
	var fiber:=art.material("#cfa67b").duplicate() as StandardMaterial3D
	fiber.cull_mode=BaseMaterial3D.CULL_DISABLED;item.material_override=fiber;basket.add_child(item)

func add_foundry_details()->void:
	var decor:=art.group(self)
	var kit:=preload("res://coastal_craft.gd").new()
	var stone:=kit.mineral("#b0997c","#82715e")
	for step in 6:
		var rise:float=(step+1)*.36
		var stair:=art.box(decor,Vector3(-3.5,rise*.5,-3.95+step*.45),Vector3(1.15,rise,.48),"#b29a7b");stair.material_override=stone
	for z in [-1.45,1.45]:
		for h in [2.6,4.77]:
			art.box(decor,Vector3(-2.35,h,z),Vector3(.38,.12,.38),patina)
			art.ball(decor,Vector3(-2.35,h,z+.20),Vector3(.09,.09,.06),brass,true)
	art.beam(decor,Vector3(-3.22,2.94,-1.74),Vector3(-.24,2.94,-1.74),.065,"#866e55")
	for x in [-3.2,-1.75,-.25]:art.beam(decor,Vector3(x,2.25,-1.74),Vector3(x,3.,-1.74),.065,"#79634c")
	for j in 6:
		var tip:=Vector3(-2.92+j*.18,2.35,-1.1)
		art.box(decor,tip,Vector3(.15,.13,.47),copper)
	art.crate(decor,Vector3(-2.97,2.3,-.82),.64)
	# Dies on the workbench show what comes down in the two baskets.
	var bench:=Vector3(1.72,0,-2.)
	for dx in [-.64,.64]:
		for dz in [-.31,.31]:art.box(decor,bench+Vector3(dx,.44,dz),Vector3(.10,.88,.11),"#825f44")
	art.box(decor,bench+Vector3.UP*.93,Vector3(1.6,.17,.85),"#c19d70")
	for j in 3:art.cyl(decor,bench+Vector3((j-1)*.43,1.09,0),.16,.21,.14,copper,18)
	kit.batch(decor)


func smith(actor:Node3D)->void:
	var cloth:=art.material("#5a6870")
	for n:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var key:=String(n.name).trim_prefix("body_").trim_prefix("head_")
		if key in ["B95747","BC5849","E7D8B9"]:n.hide()
		if key=="267A73":n.material_override=cloth
	art.ball(actor,Vector3(0,1.77,-.075),Vector3(.79,.45,.62),"#53473d")
	var kerchief:=art.cyl(actor,Vector3(0,1.81,-.02),.40,.38,.13,"#ac694e",20);kerchief.scale.z=.79
	art.box(actor,Vector3(0,.94,.25),Vector3(.53,.66,.059),"#916448")
	for sign_x in [-1.,1.]:art.beam(actor,Vector3(sign_x*.14,1.24,.27),Vector3(sign_x*.26,1.37,.01),.025,"#b19669")
	art.box(actor,Vector3(.09,.83,.282),Vector3(.20,.18,.029),"#705742")


func kiln(yard:Node3D)->void:
	var k:=art.group(yard,Vector3(-5.,0,-10.95))
	var kit:=preload("res://coastal_craft.gd").new()
	var body:=art.group(k)
	var pale:=kit.mineral("#c3a78c","#a0886e")
	var hotbrick:=kit.mineral("#a16d51","#745440")
	var block:=art.box(body,Vector3(0,1.27,-.39),Vector3(2.77,2.55,1.65),"#a77851");block.material_override=hotbrick
	var flue:=art.cyl(body,Vector3(0,3.25,-.5),.78,.42,1.86,"#c2aa8c");flue.material_override=pale
	art.cyl(body,Vector3(0,4.49,-.5),.43,.48,.77,"#a88266");art.ring(body,Vector3(0,4.89,-.5),.46,.055,"#796656")
	var mouth:=art.ball(body,Vector3(0,1.11,.459),Vector3(1.68,1.75,.11),"#533a30");mouth.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for j in 11:
		var ang:=PI*(j+.5)/11.
		var brick:=art.box(body,Vector3(.89*cos(ang),1.10+.91*sin(ang),.51),Vector3(.26,.33,.25),"#b08a65" if j%3 else "#c19b77");brick.rotation.z=ang-PI*.5
	for side in [-1.,1.]:art.box(body,Vector3(side*.89,.79,.49),Vector3(.30,.69,.24),"#b58e6a")
	art.box(body,Vector3(0,.52,.69),Vector3(2.32,.21,.74),"#8e755e")
	for j in 4:
		var bar:=art.cyl(body,Vector3((j-1.5)*.26,.68,.62),.092,.089,.75,"#5f4a3c");bar.rotation.x=.93
	for j in 5:
		var x:=1.43+j*.27
		art.beam(body,Vector3(x,1.97,.42),Vector3(x,1.11,.50),.022,"#705e4b")
		if j%2==0:art.box(body,Vector3(x,1.09,.50),Vector3(.18,.08,.10),"#596367")
	art.beam(body,Vector3(1.28,1.95,.40),Vector3(2.68,1.95,.40),.063,"#a17f57")
	kit.batch(body)
	var glow:=StandardMaterial3D.new();glow.albedo_color=Color("#e98d4c");glow.emission_enabled=true;glow.emission=Color("#ee8548");glow.emission_energy_multiplier=1.52
	for j in 7:
		var f:=art.ball(k,Vector3((j-3)*.172,.77,.58),Vector3(.21,.38,.14),"#ffb966",true);f.material_override=glow;flames.append(f)
	for j in 6:
		var c:=art.ball(k,Vector3.ZERO,Vector3.ONE*.028,"#fcc882",true);c.material_override=glow;cinders.append(c)
	hearth_glow=OmniLight3D.new();k.add_child(hearth_glow);hearth_glow.position=Vector3(0,.98,.88);hearth_glow.light_color=Color("#ffa75d");hearth_glow.omni_range=5.;hearth_glow.light_energy=.77

func fire_tick(dt:float)->void:
	elapsed+=dt
	for j in flames.size():
		var s:=sin(elapsed*4.6+j*2.7)*.12+sin(elapsed*2.6-j*.91)*.07
		flames[j].scale.y=.39+s;flames[j].position.y=.78+s*.32
	for j in cinders.size():
		var u:=fmod(elapsed*.63+j*.169,1.)
		cinders[j].position=Vector3(.33*sin(j*2.+u*4.),.90+u*.57,.60+.15*sin(j+.57*u))
		cinders[j].scale=Vector3.ONE*(.008+.025*sin(PI*u))
	hearth_glow.light_energy=.73+.094*sin(elapsed*4.7)


func echo_bluff(land)->void:
	var kit:=preload("res://coastal_craft.gd").new()
	var ridge:=art.group(land)
	for j in 8:
		var p:=Vector2(-39.+j*5.4,-33.-2.2*sin(j*.8))
		var center:Vector3=land.surface(p);var h:=9.+3.7*sin(j*.83)
		kit.outcrop(ridge,center+Vector3.UP*h*.32,Vector3(12.2,h,8.6),463+j)
		if j%2==0:art.cypress(ridge,center+Vector3(.7,h*.76,-.7),1.6+.21*j)
	# A pair of broken listening galleries gives the workshop a recognizable skyline.
	for j in 2:
		var p:=Vector2(-17.+5.5*j,-34.)
		var root:=art.group(ridge,land.surface(p)+Vector3.UP*(8. if j==0 else 6.8))
		var sill:=art.box(root,Vector3(0,-.22,0),Vector3(4.07,.46,2.65),"#a7977d");sill.material_override=kit.mineral("#b9a68b","#96846c")
		kit.outcrop(root,Vector3(0,-3.8,0),Vector3(8.8,8.4,6.8),501+j)
		for side in [-1.,1.]:art.column(root,Vector3(side*1.38,0,0),2.6)
		for k in 11:
			var az:float=(k+.5)*PI/11.
			var stone:=art.box(root,Vector3(1.40*cos(az),2.68+1.39*sin(az),0),Vector3(.48,.39,.76),"#c6b399" if k%3 else "#b2a388");stone.rotation.z=az+PI*.5
	kit.batch(ridge)
	for mesh in ridge.get_children():mesh.visibility_range_end=250.;mesh.visibility_range_end_margin=30.

