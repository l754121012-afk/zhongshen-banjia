extends Node3D

const Art=preload("res://workshop.gd")
const Night=preload("res://night_art.gd")
var art:=Art.new()
var night:=Night.new()
var face:=preload("res://harbour_fonts.gd").body()
var lights:Array[Node3D]=[]
var patrons:Array[Node3D]=[]
var mill_hand:Node3D
var hand_sack:Node3D
var sack_rows:Array[Node3D]=[]
var grain_stack:Node3D
var feast:Node3D
func set_feast(play_music:=false)->void:
	if not is_instance_valid(feast):
		feast=preload("res://quay_feast.gd").new();add_child(feast);feast.position=Vector3(6.1,.02,0)
	if play_music:feast.unveil()
var sheaf:Node3D
var stars:Array[Node3D]=[]
var oven_installed:=true
var kettle:Node3D
const END_OF_SHIFT:=8.6
var stair_worker:Node3D
var apprentice:Node3D
var lunch_pail:Node3D
var pail_cloth:Node3D
var worker_grip:Node3D
var apprentice_grip:Node3D
var local_worker:Node3D
var keeper:Node3D
var handlight:Node3D
var keeper_taper:MeshInstance3D
var baker_taper:MeshInstance3D
var reflections:Array[Node3D]=[]
var windows:Array[Node3D]=[]
var wooden_sign:Node3D
var marquee:Node3D
var baker:Node3D
var torch:Node3D
var signboard:Label3D
var plaque:Label3D
var lampholder:Node3D

func lantern(parent:Node3D,at:Vector3)->Node3D:
	return preload("res://votive_lamp.gd").build(parent,at,art)

func waterfront()->void:
	var craft:=preload("res://coastal_craft.gd").new()
	# A stepped breakwater joins the market to the houses above the tidal quay.
	art.box(self,Vector3(0,-.67,7.2),Vector3(22,2.35,9.4),"#9b8772")
	for i in 19:
		art.box(self,Vector3((i-9)*1.14,.41,2.6),Vector3(1.11,.40,1.03),"#b5a081")
	for i in 3:
		var x:float=(i-1)*6.8
		craft.villa(self,Vector3(x,.5,7.5+i%2),5.55,3.35+i%2*.9,PI,1+i%2)
		for side in [-1,1]:
			var glow:=art.box(self,Vector3(x+side*1.7205,.5+(3.35+i%2*.9)*.69,5.45+i%2),Vector3(.50,.78,.045),"#e8b473")
			glow.material_override=night.emission("#edb66a",.65);windows.append(glow)
	for j in [-1,1]:
		art.beam(self,Vector3(j*4.2,.48,3.98),Vector3(j*4.2,4.68,3.98),.075,"#786342")
	for x in [-8.8,8.2]:
		art.cypress(self,Vector3(x,.53,5.1),1.42)
	marquee=art.group(self,Vector3(0,.52,3.98))
	for j in 9:
		var x:float=(j-4)*.94
		var y:=3.36+.036*x*x
		art.beam(marquee,Vector3(x-.48,y+.02,0),Vector3(x+.48,y+.02,0),.025,"#655b45")
		night.glow(marquee,Vector3(x,y-.13,0),Vector3(.18,.28,.18),"#ffcc80",1.3)
func grain_received()->void:
	if is_instance_valid(grain_stack):return
	grain_stack=art.group(self,Vector3(2.7,.20,-.89))
	for j in 6:
		var pos:=Vector3((j%3-1)*.62,(j/3)*.45+.20,0)
		sack_rows.append(art.ball(grain_stack,pos,Vector3(.70,.52,.66),"#c8b184",true))
		art.box(grain_stack,pos+Vector3.UP*.22,Vector3(.36,.06,.04),"#81684b")
	# A votive sheaf is hoisted at the waterfront when the first grain lands.
	sheaf=art.group(self,Vector3(3.43,2.40,.81))
	var disk:=art.cyl(sheaf,Vector3.ZERO,.54,.54,.12,"#35675f",32);disk.rotation.x=PI/2
	var reverse_edge:=art.ring(sheaf,Vector3(0,0,.09),.50,.038,"#d6ad65");reverse_edge.rotation.x=PI/2
	var edge:=art.ring(sheaf,Vector3(0,0,-.09),.50,.038,"#d6ad65");edge.rotation.x=PI/2
	for side in [-1.,0.,1.]:
		var stalk:=art.group(sheaf,Vector3(0,-.29,-.13));stalk.rotation.z=-side*.40
		art.beam(stalk,Vector3.ZERO,Vector3(0,.68,0),.024,"#d8b878")
		for j in 3:
			for sign_x in [-1.,1.]:
				var ear:=art.ball(stalk,Vector3(sign_x*.060,.31+j*.10,0),Vector3(.073,.15,.052),"#ead099",true)
				ear.rotation.z=-sign_x*.44
		var reverse:=stalk.duplicate() as Node3D
		sheaf.add_child(reverse);reverse.position.z=.13
	art.beam(self,Vector3(3.43,.24,.89),Vector3(3.43,3.14,.89),.061,"#97744c")
	for j in 15:
		var seed:=night.glow(self,Vector3.ZERO,Vector3(.066,.13,.055),"#f7ce77",1.25)
		stars.append(seed);seed.hide()
	var pallet:=art.box(grain_stack,Vector3(0,-.02,0),Vector3(2.25,.12,.94),"#806447")
func unload_from(t:float,barge:Node3D)->void:
	if grain_stack==null:grain_received()
	if mill_hand==null:
		mill_hand=art.courier(self);preload("res://zephyr_people.gd").new().costume(mill_hand,"miller")
		mill_hand.scale=Vector3.ONE*.88
		hand_sack=art.ball(mill_hand,Vector3(0,1.08,.47),Vector3(.78,.60,.61),"#c3aa7c",true)
	plaque.visible=t>5.65
	var lift:=smoothstep(2.1,4.75,t)
	sheaf.position.y=1.22+1.18*lift;sheaf.scale=Vector3.ONE*(.75+.25*lift)
	for j in stars.size():
		var f:=clampf((t-2.3-j*.062)/1.75,0.,1.)
		stars[j].visible=f>0. and f<1.
		if stars[j].visible:
			var ang:=j*2.40+f*1.28
			stars[j].position=sheaf.position+Vector3(cos(ang)*(.46+f*.46),-.54+f*2.00,sin(ang)*.54)
			stars[j].scale=Vector3(.085,.18,.065)*sin(f*PI)
	var phase:=clampf(t-1.0,0.,4.65)
	var u:=fmod(phase,1.55)/1.55
	var row:=mini(2,floori(phase/1.55))
	var from:=to_local(barge.hull.to_global(Vector3(-.4,.48,0)))
	var target:=Vector3(2.55,.18,-.55)
	var carrying:=u<.72
	mill_hand.position=from.lerp(target,smoothstep(0.,.71,u)) if carrying else target.lerp(from,smoothstep(.72,1.,u))
	mill_hand.rotation.y=atan2(target.x-from.x,target.z-from.z)+(0. if carrying else PI)
	mill_hand.position.y+=absf(sin(u*TAU*4.))*.065
	mill_hand.get_node("LegR").rotation.x=.42*sin(u*TAU*4.)
	mill_hand.get_node("LegL").rotation.x=-.42*sin(u*TAU*4.)
	mill_hand.get_node("ArmR").rotation.x=-.9 if carrying else -.20
	mill_hand.get_node("ArmL").rotation.x=-.9 if carrying else -.20
	hand_sack.visible=carrying and t>1.
	for j in sack_rows.size():sack_rows[j].visible=j<row*2+(2 if u>.66 else 0) or t>5.65
	for j in barge.sacks.size():barge.sacks[j].visible=j>=row*2+(2 if carrying else 0) and t<5.65
	if t>5.65:
		mill_hand.position=target;hand_sack.hide();mill_hand.rotation.y=-.7
		mill_hand.get_node("ArmR").rotation.x=-.18;mill_hand.get_node("ArmL").rotation.x=-.18
		mill_hand.get_node("LegR").rotation.x=0;mill_hand.get_node("LegL").rotation.x=0

func breakfast_stall(stock:bool)->void:
	var counter:=art.group(self,Vector3(-2.95,.17,.87))
	art.box(counter,Vector3.UP*.47,Vector3(1.62,.94,.61),"#88603f")
	art.box(counter,Vector3.UP*.97,Vector3(1.75,.11,.70),"#d1ae75")
	for i in (5 if stock else 2):
		preload("res://zephyr_people.gd").new().loaf(counter,Vector3((i%3-1)*.46,1.02,(i/3-.5)*.28)).scale=Vector3.ONE*.65
func build(lit:bool)->void:
	for i in 5:
		var tread:=art.box(self,Vector3(.1,.05+i*.075,1.5+i*.28),Vector3(3.3,.25,.38),"#b4a48e")
		tread.material_override=preload("res://harbour_materials.gd").sample(0,"#b4a48e",4.,true,.58)
		art.box(self,Vector3(.1,.174+i*.075,1.35+i*.28),Vector3(3.26,.016,.046),"#bba88d")
	if marquee==null:
		art.box(self,Vector3(.1,.31,3.30),Vector3(3.35,.41,1.14),"#aa977e")
	for i in 21:
		art.box(self,Vector3((i-10)*.41,.04,0),Vector3(.398,.25,3.2),"#af926e" if i%3 else "#c1a27e")
	for x in [-3.8,-1.,1.3,3.8]:
		art.cyl(self,Vector3(x,-.45,1.32),.14,.21,2.1,"#74614c")
	for z in [-1.27,1.27]:art.beam(self,Vector3(-4.25,-.18,z),Vector3(4.25,-.18,z),.13,"#705b47")
	preload("res://coastal_craft.gd").new().cloth(self,Vector3(-2.08,3.23,-.9),3.2,"#366f82")
	for x in [-3.52,-.62]:art.beam(self,Vector3(x,0,-.76),Vector3(x,3.28,-.76),.075,"#785a3e")
	kettle=art.group(self,Vector3(-2.95,.18,-.3))
	if oven_installed:
		var oven:=preload("res://hearth_art.gd").new();oven.build(kettle);oven.glow(80,0)
	else:
		art.cyl(kettle,Vector3.UP*.36,.28,.42,.72,"#915a3f",12)
		art.ring(kettle,Vector3.UP*.72,.36,.06,"#ca9558")
		night.glow(kettle,Vector3.UP*.76,Vector3(.53,.23,.53),"#ea964c",.8)
	baker=art.courier(self);preload("res://zephyr_people.gd").new().costume(baker,"baker")
	baker_taper=art.cyl(baker,Vector3.ZERO,.029,.022,1.,"#9a7953",8)
	torch=night.glow(baker,Vector3(.46,1.25,.35),Vector3(.14,.35,.14),"#ffad50",1.4)
	keeper=art.courier(self);preload("res://zephyr_people.gd").new().costume(keeper,"miller")
	keeper_taper=art.cyl(keeper,Vector3.ZERO,.028,.022,1.,"#a5865e",8)
	handlight=night.glow(keeper,Vector3(-.41,1.26,.23),Vector3(.13,.32,.13),"#efb259",1.3)
	for i in 3:
		var here:=Vector3(-.28+i*1.60,.18,.1)
		art.cyl(self,here+Vector3.UP*.49,.24,.35,.99,"#c4a885",10)
		var lamp:=lantern(self,here+Vector3.UP*.98)
		if i==0:lampholder=lamp
		var flame:=art.group(self,here+Vector3.UP*1.78)
		night.glow(flame,Vector3.ZERO,Vector3(.65,.48,.65),"#ffbd64",1.65)
		var light:=OmniLight3D.new();flame.add_child(light);light.light_color=Color("#ffb661");light.light_energy=2.1;light.omni_range=5.6
		lights.append(flame)
		var shimmer:=art.group(self,Vector3(here.x,-.055,-1.88));reflections.append(shimmer)
		for j in 4:
			var ripple:=night.glow(shimmer,Vector3(sin(j*2.)*.13,0,-j*.25),Vector3(.34-j*.044,.014,.09),"#ca975e",.54)

		var guest:=art.courier(self);preload("res://zephyr_people.gd").new().costume(guest,"priest" if i%2 else "miller");patrons.append(guest)
	wooden_sign=art.group(self,Vector3(-2.06,2.75,-1.0))
	art.box(wooden_sign,Vector3.ZERO,Vector3(2.55,.47,.10),"#4b503f")
	for dx in [-1.10,1.10]:art.beam(self,Vector3(-2.06+dx,2.96,-1.0),Vector3(-2.06+dx,3.25,-.92),.024,"#ab9469")
	signboard=night.label(wooden_sign,Vector3(0,0,-.061),"今日收市",face,"#ffdf9c")
	signboard.pixel_size=.008;signboard.billboard=BaseMaterial3D.BILLBOARD_DISABLED;signboard.rotation.y=PI
	signboard.double_sided=false;signboard.outline_size=2
	var sign_reverse:=night.label(wooden_sign,Vector3(0,0,.061),"等末班船",face,"#ffdf9c")
	sign_reverse.pixel_size=.008;sign_reverse.billboard=BaseMaterial3D.BILLBOARD_DISABLED;sign_reverse.rotation.z=PI
	sign_reverse.double_sided=false;sign_reverse.outline_size=2
	plaque=night.label(self,Vector3(.0,2.85,0),"伊娅　·　窑工　·　船夫　·　西湾搬家公司",face,"#ffe6b6")
	plaque.pixel_size=.0068
	stair_worker=art.courier(self)
	people_costume_for_steps()
	stair_pose(1. if lit else 0.,0.)
	animate(END_OF_SHIFT if lit else -1.)

func people_costume_for_steps()->void:
	preload("res://zephyr_people.gd").new().costume(stair_worker,"miller")
	worker_grip=art.group(stair_worker.get_node("ArmR"),Vector3(.02,-.45,.12))
	apprentice=art.courier(self);apprentice.scale=Vector3.ONE*.73
	preload("res://bell_household.gd").new().dress(apprentice)
	var hood:=art.ball(apprentice,Vector3(0,1.87,-.05),Vector3(.91,.48,.71),"#688c83",true)
	hood.rotation.z=.12
	apprentice_grip=art.group(apprentice.get_node("ArmL"),Vector3(0,-.44,.12))
	lunch_pail=art.group(self)
	art.cyl(lunch_pail,Vector3.DOWN*.10,.16,.20,.28,"#a86a41",12)
	pail_cloth=art.group(lunch_pail,Vector3.UP*.055)
	art.cyl(pail_cloth,Vector3.ZERO,.213,.19,.065,"#d5a45d",12)
	var wrap:=art.box(pail_cloth,Vector3(0,.035,0),Vector3(.31,.04,.22),"#a94e3b")
	wrap.rotation.y=.28
	art.box(wrap,Vector3(.065,.025,0),Vector3(.034,.015,.22),"#efc98d")
	for side in [-1,1]:art.beam(lunch_pail,Vector3(.16*side,.03,0),Vector3(.12*side,.22,0),.018,"#946843")
	art.beam(lunch_pail,Vector3(-.12,.22,0),Vector3(.12,.22,0),.023,"#b68d58")

func stair_pose(crossing:float,reach:float,pass_pail:=0.)->void:
	var stride:=sin(crossing*TAU*2.)
	stair_worker.position=Vector3(.77-.07*reach,lerpf(.18,.62,crossing)+absf(stride)*.045,lerpf(1.22,2.82,crossing)+.07*reach)
	stair_worker.rotation=Vector3(-.09*reach,lerpf(-.14*reach,1.23,smoothstep(.66,1.,crossing)),0.)
	stair_worker.get_node("LegR").rotation.x=-.68*reach+.54*stride
	stair_worker.get_node("LegL").rotation.x=-.54*stride
	stair_worker.get_node("ArmR").rotation.x=lerpf(-.38,-1.16,smoothstep(.82,1.,crossing))+.52*pass_pail
	stair_worker.get_node("ArmL").rotation.z=-.18-.57*reach
	var step_out:=smoothstep(.53,1.,crossing)
	apprentice.position=Vector3(lerpf(2.06,1.57,step_out),.62+.035*absf(sin(step_out*TAU)),lerpf(3.13,3.01,step_out))
	apprentice.rotation.y=-1.86
	apprentice.get_node("ArmR").rotation.z=.18+.85*reach-.42*pass_pail
	apprentice.get_node("ArmL").rotation.x=-.22-.93*step_out+.29*pass_pail
	apprentice.get_node("LegL").rotation.x=sin(step_out*TAU)*.44
	apprentice.get_node("LegR").rotation.x=-sin(step_out*TAU)*.44
	lunch_pail.scale=Vector3.ONE*1.28
	pail_cloth.rotation.z=-.20*pass_pail
	lunch_pail.global_position=worker_grip.global_position.lerp(apprentice_grip.global_position,pass_pail)+Vector3.DOWN*.19

func seat_regular()->void:
	if local_worker!=null:return
	local_worker=art.courier(self);preload("res://zephyr_people.gd").new().costume(local_worker,"miller")
	local_worker.position=Vector3(3.72,.18,-.50);local_worker.rotation.y=-1.42
	var meal:=preload("res://zephyr_people.gd").new().loaf(local_worker,Vector3(0,1.12,.45))
	meal.scale=Vector3.ONE*.6
	local_worker.get_node("ArmR").rotation.x=-1.12
func animate(t:float)->void:
	if marquee!=null:marquee.visible=t>3.4
	for j in windows.size():windows[j].visible=t>2.3+j*.32
	baker.position=Vector3(lerpf(-2.1,-.70,smoothstep(.0,1.03,t)),.18,-.40)
	var crossing:=smoothstep(1.26,1.87,t)+smoothstep(1.94,2.50,t)
	keeper.position=Vector3(-.72+crossing*1.57,.18,-.54)
	var tending:=smoothstep(.40,.96,t)*(1.-smoothstep(1.36,1.9,t))
	baker.get_node("ArmR").rotation.x=-.25-tending*1.05
	keeper.get_node("ArmR").rotation.x=-.25-smoothstep(.86,1.21,t)*(1.-smoothstep(2.65,3.1,t))
	carry_flame(baker,baker_taper,torch,lights[0],tending,t>=0. and t<1.8)
	carry_flame(keeper,keeper_taper,handlight,lights[clampi(roundi(crossing),0,2)],1.,t>=1.26 and t<2.90)
	lampholder.visible=t>=0
	for i in 3:
		lights[i].visible=t>=1.25+i*.64
		reflections[i].visible=lights[i].visible
		var u:=smoothstep(2.3+i*.39,4.8+i*.24,t)
		patrons[i].visible=u>0
		patrons[i].position=Vector3(lerpf(4.05,1.25-i*1.45,u),.18+sin(u*PI*8)*.05,.88)
	wooden_sign.rotation.x=PI*smoothstep(2.15,2.75,t)
	if t>=0.:stair_pose(smoothstep(4.95,6.72,t),0.,smoothstep(6.73,7.32,t))
	plaque.visible=t>4.5

func carry_flame(person:Node3D,stick:MeshInstance3D,flame:Node3D,wick:Node3D,reach:float,lit:bool)->void:
	stick.visible=lit;flame.visible=lit
	if not lit:return
	var grasp:=person.to_local(person.get_node("ArmR").to_global(Vector3(.0,-.36,.11)))
	var toward:=grasp.direction_to(person.to_local(wick.global_position))
	var tip:=grasp+Vector3(.08,.82,.25).lerp(toward*.89,reach)
	flame.position=tip
	stick.position=(grasp+tip)*.5
	stick.quaternion=Quaternion(Vector3.UP,grasp.direction_to(tip))
	stick.scale.y=grasp.distance_to(tip)
