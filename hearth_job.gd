extends "res://zephyr_job.gd"
const COAL:=Vector2(66,15)
var iron:=preload("res://hearth_art.gd").new()
var stove:Node3D
var used_coal:=false
var sparks:Array[Node3D]=[]
var dock_front:Node3D
var oven_time:=0.
var new_baker:Node3D
var dock_basket:Node3D
var cloth_frame:Node3D
var advance_rang:=false
func _ready()->void:
	land.harbour_end=true
	super()
	land.dressing.wheat_material.set_shader_parameter("port_cut",true)
	wind_job=false;charge=94;bell_returned=true;land.miller.hide()
	skin.hide();cord.hide();branch_mesh.hide();cab_bell.hide()
	stove=iron.build(freight)
	land.tower_root.hide();route_events.bell.hide();passenger.hide()
	dock_front=art.group(land,land.surface(Terrain.TOWER))
	var c:=preload("res://coastal_craft.gd").new()
	c.villa(dock_front,Vector3(2,0,-4),6.8,4.4,-PI/2,1)
	c.cloth(dock_front,Vector3(-2,2.8,-4),4.2,Bay.BLUE)
	build_berth(c)
	for i in 13:art.box(dock_front,Vector3(-3+i*.54,.05,2.9),Vector3(.52,.12,3.35),Art.WOOD)
	for z in [-1,1]:art.column(dock_front,Vector3(-3.9,0,z*2),3.8)
	art.beam(dock_front,Vector3(-3.9,3.75,-2.4),Vector3(-3.9,3.75,2.4),.15,Art.WOOD)
	new_baker=art.courier(dock_front);land.people.costume(new_baker,"baker");new_baker.position=Vector3(-4.9,0,-2.1);new_baker.rotation.y=-1.3
	dock_basket=art.group(dock_front,Vector3(-5,1.02,-2.9))
	art.box(dock_front,Vector3(-5,.91,-2.9),Vector3(1.60,.14,1.15),Art.WOOD)
	for j in 5:land.people.loaf(dock_basket,Vector3((j%3-1)*.4,0,j/3*.4)).scale=Vector3.ONE*.76
	dock_basket.hide()
	cloth_frame=art.group(dock_front,Vector3(-4.2,3.5,0))
	c.cloth(cloth_frame,Vector3.ZERO,4.5,Bay.BLUE);cloth_frame.scale.z=.12
	land.label(dock_front,Vector3(-4,4.85,0),"潮汐船坞 · 蓝棚灶台",.014)
	var shed:=art.group(land,land.surface(COAL)+Vector3(0,0,2.7))
	c.cloth(shed,Vector3.UP*2.5,3.4,Art.WOOD)
	for i in 8:art.ball(shed,Vector3(i%3*.33,.24+i/3*.20,0),Vector3(.58,.49,.63),"#4c4b46",true)
	land.label(shed,Vector3.UP*2.95,"歪烟囱炭棚 · 停稳 E 添炭",.011)
	art.cyl(shed,Vector3(1.45,2.36,0),.28,.21,4.7,Art.WOOD).rotation.z=.16
	for i in 9:sparks.append(art.ball(freight,Vector3.ZERO,Vector3.ONE*.06,"#f8b04a",true))
	land.label(land,land.surface(START_BAG)+Vector3.UP*2.15,"伊娅的旧灶",.009)
	for sign_node:Label3D in land.find_children("*","Label3D",true,false):
		if sign_node.text.contains("米拉") or sign_node.text.contains("采风") or sign_node.text.contains("借风") or sign_node.text.contains("风铃"):sign_node.hide()
	land.people.costume(land.apprentice,"baker");land.label(land.apprentice,Vector3.UP*2.25,"面包师　伊娅",.009)
	var kitchen:=land.node_at(START_BAG+Vector2(-.44,-1.88))
	art.box(kitchen,Vector3(0,.58,0),Vector3(2.8,1.16,.68),"#a77752")
	land.obstacle(START_BAG+Vector2(-.44,-1.88),Vector2(2.8,.68))
	for j in 3:land.people.loaf(kitchen,Vector3((j-1)*.73,1.17,0))
	art.beam(kitchen,Vector3(-1.55,0,0),Vector3(-1.55,3.1,0),.10,Art.WOOD)
	var warn:=land.node_at(Vector2(21.2,-4.2));art.column(warn,Vector3.ZERO,2.75)
	land.label(warn,Vector3.UP*3.15,"前方横穿货车",.013)
	update_ui()
func build_berth(c)->void:
	var quayside:=art.group(dock_front)
	design.water(quayside,Vector3(12.25,-.78,-2),Vector3(20.6,.32,22.8),"#2a6370","#72a49d")
	for edge in [-13.4,9.4]:
		art.box(quayside,Vector3(12,-1.12,edge),Vector3(20.7,2.43,.61),"#a5967c")
	art.box(quayside,Vector3(22.55,-1.24,-2),Vector3(.58,2.54,23.),"#a9967d")
	for k in 21:
		var z:float=k-12.
		art.box(quayside,Vector3(1.40,-1.78,z),Vector3(1.68,3.65,.985),"#aa9377" if k%3 else "#b29c80")
		art.box(quayside,Vector3(1.40,.12,z),Vector3(1.91,.17,.99),"#ccb994")
		if k%4==0:
			art.cyl(quayside,Vector3(1.8,.47,z),.14,.12,.67,"#544d45",10)
			art.ring(quayside,Vector3(1.80,.57,z),.16,.035,"#a88558")
	for j in 3:
		var barge:=art.group(quayside,Vector3(5.6+j*3.6,-.61,-10+j*6.1))
		barge.rotation.y=-.18+j*.17
		art.ball(barge,Vector3.ZERO,Vector3(2.5,1.38,7.1),"#76543d",true)
		art.box(barge,Vector3.UP*.55,Vector3(1.81,.18,4.74),"#b18f62")
		art.beam(barge,Vector3.UP*.5,Vector3.UP*8.3,.09,"#75533d")
		art.beam(barge,Vector3(0,7.45,-1.65),Vector3(0,7.45,1.64),.074,"#876741")
		for k in 8:
			art.box(barge,Vector3(.16*sin(k*.46),5.61,(k-3.5)*.39),Vector3(.085,3.56,.40),Bay.BLUE if (k+j)%4==0 else "#d9be91")
		art.beam(barge,Vector3.UP*7.9,Vector3(0,.63,2.88),.035,"#ab9169")
	art.box(quayside,Vector3(-1.6,.10,0),Vector3(5.15,.20,8.2),"#ad9778")
	c.barrel(quayside,Vector3(-.41,.21,2.93),.91);c.barrel(quayside,Vector3(.50,.21,2.76),.82)
	for j in 3:art.crate(quayside,Vector3(-1.6+j*.92,.21,3.45),.91)
func begin_load()->void:
	super();tell("伊娅：「把铁把顺过门，再往踏板上走。炉心还有火。」",3)
func do_use()->void:
	if stage=="drive" and pos.distance_to(Terrain.MILL_PORT)>=6.8 and pos.distance_to(COAL)>=5.8:
		tell("伊娅：「海边的炭棚还有一筐炭，蓝棚下就是新家。」",2.5);return
	if stage=="drive" and pos.distance_to(COAL)<5.8 and absf(speed)<2:
		if not used_coal:charge=minf(100,charge+46);used_coal=true;audio.play_cue("load");tell("炭筐已空 · 炉心重新亮起",2.4)
		else:tell("炭棚的筐已经空了")
		return
	super()
func jump()->void:
	if not airborne:super()
func hurt(amount:float,reason:String)->void:
	if cooldown<=0:charge=maxf(0,charge-amount*1.55)
	super(amount,reason)
func draw_charge(before:Vector2,dt:float)->void:
	var exposure:=1.-smoothstep(6,17,-pos.y)
	var cross:=Wind.pressure(pos,time)*exposure
	var brake:=Input.is_key_pressed(KEY_S) and speed>5
	charge=maxf(0,charge-before.distance_to(pos)*(.075+.34*cross)-dt*(3.1 if brake else .0))
func update_cargo(_dt:float)->void:
	if stove==null:return
	iron.glow(charge,time)
	for i in sparks.size():
		var u:=fposmod(time*1.4+i*.113,1)
		sparks[i].visible=stage=="drive" and charge>15 and Wind.pressure(pos,time)>.26
		sparks[i].position=Vector3(-.48+u*.49,.70+u*.77,u*1.36+sin(i)*.12);sparks[i].scale=Vector3.ONE*.055*(1-u)
func retry_from_bank()->void:
	super();charge=94;used_coal=false;advance_rang=false;cab_bell.hide();tell("伊娅把备用炉装上了车")
func damage_fee()->int:
	if health<60:return 34
	return 15 if health<90 else 0
func settle_delivery()->void:
	if assessed:return
	if health<30:enter("broken");statement.show();statement.text="炉身破裂 · R 重新运送";return
	signed_level=2 if charge>=55 else 1
	gross=60+(18 if signed_level==2 else 0)+pad_tip-damage_fee()
	assessed=true;order_signed.emit(signed_level,gross,floori(charge),"潮汐船坞")
	freight.global_position=dock_front.to_global(Vector3(-3.9,.14,-1.45));freight.rotation.y=.3
	dock_basket.visible=signed_level==2;audio.play_cue("win");enter("awaken");tell("伊娅揭开炉门 · 第一篮出炉" if signed_level==2 else "伊娅开始劈柴 · 完成下一单后出炉",3.5)
func draw_camera(dt:float)->void:
	super(dt)
	if stage in ["signed","awaken"] and dock_front!=null:
		var point:=dock_front.global_position+Vector3(-3.2,1.53,-.9)
		var offset:=Vector3(-10.6,5.5,7.5)
		cam.transform=cam.transform.interpolate_with(Transform3D(Basis.looking_at(-offset,Vector3.UP),point+offset),1.-exp(-dt*13))
func bill()->void:
	enter("signed");statement.show()
	statement.text="蓝棚灶台 · 搬迁签收\n\n%s　炉身 %d%%\n搬迁运费 60　热炉赏金 %d　软垫 %d　破损扣费 %d\n本次入账 %d 枚\n\nE 返港，在经营簿派货"%["热炉到站 · 第一篮已备好" if signed_level==2 else "冷炉到站 · 再完成一单即可出炉",floori(health),18 if signed_level==2 else 0,pad_tip,damage_fee(),gross]
func _unhandled_key_input(e:InputEvent)->void:
	if e is InputEventKey and e.pressed and e.keycode in [KEY_TAB,KEY_B,KEY_M]:return
	if e is InputEventKey and e.pressed and e.keycode==KEY_Q and stage=="offer":tell("伊娅：「炉子还能烧，我想让码头也吃上热面包。」");return
	super(e)
func update_ui()->void:
	super()
	if stage=="drive" and pos.distance_to(COAL)<5.8 and absf(speed)<2.:objective.text="E 添炭"
	if stage=="drive" and pos.x>18 and pos.x<26 and not advance_rang:
		advance_rang=true;audio.play_cue("buckle");tell("前方横风口 · 看旗，减速让空车先过",2.1)
	if stage=="awaken" and cloth_frame!=null:
		cloth_frame.scale.z=.12+.88*smoothstep(.2,2.4,phase_time)
		new_baker.get_node("ArmR").rotation.x=-.6-.5*sin(phase_time*2)
	if stage=="broken":statement.text="炉身开裂 · 无法签收\nR 从风坊带货重运　 Esc 回港"
	if notify_text.contains("囊体"):
		notify_text=notify_text.replace("囊体","炉身");action.text=notify_text
	if stage=="drive" and notify_text.contains("风囊"):notify_text="炉身碰撞 · 火星散落";action.text=notify_text
	if stage=="drive" and notify_text.contains("布袋"):notify_text="伊娅：「墙后背风，沿海近路可添炭。」";action.text=notify_text
	title.text="搬走最后一座灶火　/　"+("潮汐船坞" if pos.x>85 else "西湾海岸")
	objective.text="把伊娅的炉子送到船坞 · 火候达到 55 可立即开炉"
	guide.text={"offer":"E 接委托　 Q 问伊娅　 Esc 返港","load":"WASD 搬运　 Q 转铁把　 E 装车","drive":"W S 驾驶　 A D 转向　 E 停车交接或添炭","crane":"A D 移吊车　 空格 脱钩","broken":"R 重运　 Esc 回港"}.get(stage,"")
	if stage=="offer":action.text="E 接下搬炉委托";seal.hide()
	if stage=="strap":action.text="系紧炉身";action.show()
	if stage=="awaken":objective.text="伊娅揭开新家的炉门"
	if stage=="drive" and notify_text.contains("风"): 
		if notify_text.contains("采风") or notify_text.contains("风囊"):notify_time=0
	if stage=="drive" and pos.x>84 and pos.distance_to(Terrain.MILL_PORT)<6.8:action.text="E 系索卸炉" if absf(speed)<1.9 else "S 刹车 · 在灶台旁停稳"
	if stage=="drive":
		if pos.distance_to(COAL)<5.8:objective.text="炭棚 · 停稳后按 E 添炭" if not used_coal else "炭筐已空 · 沿山坡驶向船坞"
		elif pos.x>35 and pos.x<85:objective.text="石巷背风　/　沿海近路可下谷添炭"
		if notify_time<=0 and pos.distance_to(Terrain.MILL_PORT)>6.8:action.hide()
	if bag_tag.visible:
		bag_tag.text="炉火 %d　·　%s"%[floori(charge),"金焰" if charge>=55 else ("红炭" if charge>15 else "暗炭")]
		if health<90:bag_tag.text+="　炉身 %d%%"%floori(health)
		if stage=="drive" and (catch_window>0 or correction>0):bag_tag.text+="　"+Catch.instruction(catch_window,correction)
