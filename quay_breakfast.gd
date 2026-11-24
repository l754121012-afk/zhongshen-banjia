extends Node3D

const INN:=Vector2i(0,4)
const CREW:=Vector2i(4,2)
const PANTRY:=Vector3(2.05,1.15,13.22)
var art:=preload("res://workshop.gd").new()
var people:=preload("res://zephyr_people.gd").new()
var lifting:=false
var lift_time:=0.
var lift_dock
var lift_from:=Vector3.ZERO
var worker_from:=Vector3.ZERO
var pulley:MeshInstance3D
var salute_left:=0.
var guest_focus:=Vector3.ZERO
var carried:=false
var basket:Node3D
var stations:Array[Node3D]=[]
var actors:Array[Node3D]=[]
var plates:Array[Node3D]=[]
var signs:Array[Label3D]=[]
var rings:Array[Node3D]=[]
var steam:Array[Node3D]=[]

func build(dock)->void:
	pulley=art.cyl(self,Vector3.ZERO,.025,.025,1.,"#816744",6);pulley.hide()
	basket=art.group(self,PANTRY)
	art.cyl(basket,Vector3(0,.12,0),.30,.39,.24,"#a97948",12)
	for j in 3:
		art.ring(basket,Vector3.UP*(.04+j*.08),.32+j*.025,.023,"#d0a26a")
	var handle:=art.ring(basket,Vector3(0,.29,0),.29,.038,"#b78c59")
	handle.rotation.x=PI/2
	for j in 2:
		var loaf:=people.loaf(basket,Vector3((j-.5)*.24,.2,.02))
		loaf.scale=Vector3.ONE*.64;loaf.rotation.y=1.05
	for j in 3:
		var wisp:=art.ball(basket,Vector3.ZERO,Vector3(.036,.095,.038),"#f9e7c5",true)
		steam.append(wisp)
	art.box(self,PANTRY-Vector3.UP*.11,Vector3(1.13,.17,.76),"#ae815c")
	for x in [-.40,.40]:
		art.box(self,PANTRY+Vector3(x,-.61,0),Vector3(.11,1.,.57),"#82664e")
	for i in 2:
		var cell:=INN if i==0 else CREW
		var side:=-1. if i==0 else 1.
		var color:="#c58b4e" if i==0 else "#427f8a"
		var c:Vector3=dock.cell_world(cell)
		var station:=art.group(self,c+Vector3(side*.77,0,-.32));stations.append(station)
		var actor:=art.courier(station);actor.scale=Vector3.ONE*.82;actor.rotation.y=-side*.85;actors.append(actor)
		people.costume(actor,"priest" if i==0 else "miller")
		var table:=art.group(station,Vector3(-side*.12,0,1.04))
		art.box(table,Vector3.UP*.56,Vector3(1.1,.13,.62),"#b49876")
		art.box(table,Vector3.UP*.32,Vector3(.83,.49,.45),color)
		var bowl:=art.cyl(table,Vector3.UP*.69,.18,.23,.12,"#d7c7a9")
		var bread:=people.loaf(bowl,Vector3.UP*.07);bread.scale=Vector3.ONE*.65;plates.append(bread)
		rings.append(art.ring(self,c+Vector3.UP*.13,.56,.042,color))
		signs.append(dock.text_world(station,Vector3(0,2.0,0),"",Color("#ffe3ab") if i==0 else Color("#bce5df"),.008))

func refresh(stock:int,inn:bool,crew:bool)->void:
	basket.visible=carried or stock>0
	for i in 2:
		var fed:=inn if i==0 else crew
		plates[i].visible=fed
		rings[i].visible=carried and not fed
		signs[i].text=("客舍跑堂" if i==0 else "码头工班")+(" · 已开席" if fed else (" · 等早饭" if carried else ""))
		signs[i].visible=carried or fed

func return_basket(stock:int,inn:bool,crew:bool)->void:
	carried=false
	if basket.get_parent()!=self:basket.reparent(self,false)
	basket.position=PANTRY;basket.rotation=Vector3.ZERO
	refresh(stock,inn,crew)

func prompt(dock)->String:
	var c:Vector2i=dock.player_cell
	if c.y==6 and c.x in [1,3] and dock.meal_stock>0 and not carried:return "E 领一篮热面包　 Q 随夜船出港"
	if not carried:return ""
	if c==INN and not dock.table_inn:return "E 给客舍跑堂 · 往后每篮早餐多收 3 枚"
	if c==CREW and not dock.table_crew:return "E 给码头工班 · 往后解缆前可请人装压舱铁"
	return ""

func interact(dock)->bool:
	var c:Vector2i=dock.player_cell
	if not carried:
		if dock.meal_stock<=0 or c.y!=6 or c.x not in [1,3]:return false
		carried=true;basket.reparent(dock.courier,false);basket.position=Vector3(0,.87,.45)
		refresh(dock.meal_stock,dock.table_inn,dock.table_crew)
		dock.sound.play_cue("grab");dock.message("伊娅：「头一炉刚好一篮。先送给谁，你来定。」",3.7);return true
	if c not in [INN,CREW]:return false
	var inn:=c==INN
	if (inn and dock.table_inn) or (not inn and dock.table_crew):
		dock.message("这一桌已开席 · 热篮留给另一桌",2.0);return true
	if inn:dock.table_inn=true
	else:dock.table_crew=true
	dock.meal_stock-=1
	dock.table_served.emit("inn" if inn else "crew")
	return_basket(dock.meal_stock,dock.table_inn,dock.table_crew)
	dock.sound.play_cue("win")
	dock.message("跑堂：「这炉我天天订，每篮再添三枚！」" if inn else "工头：「以后把镜车装好来喊我，压舱铁我们来绑！」",4.5)
	salute_left=3.8;guest_focus=stations[0 if inn else 1].position+Vector3.UP
	if dock.table_inn and dock.table_crew:
		dock.public_quay.set_feast(true);dock.feast_view=4.15
		dock.message("两桌合席 · 街坊在木阶旁立起了谷神长桌",4.3)
	var actor:=actors[0 if inn else 1]
	var nod:=create_tween()
	nod.tween_property(actor,"rotation:x",.20,.22);nod.tween_property(actor,"rotation:x",0.,.42)
	return true

func lift(dock)->void:
	lifting=true;lift_dock=dock;lift_time=0.
	lift_from=dock.ballast.global_position;worker_from=actors[1].global_position
	dock.ballast.reparent(self,true);pulley.show()

func stop_lift()->void:
	if lifting:
		actors[1].global_position=worker_from
		actors[1].get_node("ArmR").rotation.x=0.
	lifting=false;pulley.hide()

func _physics_process(delta:float)->void:
	salute_left=maxf(0.,salute_left-delta)
	if not lifting:return
	lift_time+=delta
	var u:=clampf(lift_time/1.85,0.,1.)
	var end:Vector3=lift_dock.truck.to_global(Vector3(-2.23,1.1,-.13))
	var arc:=sin(u*PI)
	var p:=lift_from.lerp(end,smoothstep(0.,1.,u))+Vector3.UP*arc*3.7
	lift_dock.ballast.global_position=p
	pulley.global_position=p+Vector3.UP*1.6;pulley.scale.y=3.2
	actors[1].get_node("ArmR").rotation.x=-.85-arc*.42
	if u>=1.:
		stop_lift();lift_dock.spare_loaded=true;lift_dock.history.clear();lift_dock.sync_carts(true)
		lift_dock.sound.play_cue("snap");lift_dock.message("压舱铁就位 · E 解缆，重载更抗侧流",2.5)

func _process(_delta:float)->void:
	if not is_visible_in_tree() or basket==null or not basket.visible:return
	var t:=Time.get_ticks_msec()*.001
	for i in steam.size():
		var f:=fmod(t*.74+i/3.,1.)
		steam[i].position=Vector3(sin(f*4.+i)*.09,.40+.31*f,(i-1)*.07)
		steam[i].scale=Vector3(.045,.14,.045)*sin(f*PI)
