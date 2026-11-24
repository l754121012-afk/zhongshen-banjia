extends SceneTree
var errs:=0
func ck(b:bool,s:String)->void:
	print("PASS " if b else "FAIL ",s);if not b:errs+=1
func boot():
	var base=load("res://vineyard.tscn").instantiate();root.add_child(base)
	for i in 4:await process_frame
	return base
func _initialize()->void:call_deferred("run")
func run()->void:
	var base=await boot()
	var order=base.dock_order
	order.stage="drive";order.pos=order.land.road(575.,true);order.learned=true;order.packed=true;order.hp=76.;order.attach_bed();order.save()
	order.queue_free();base.queue_free();await process_frame;await process_frame
	base=await boot();order=base.dock_order
	ck(order.stage=="drive" and order.pos.distance_to(order.land.road(575.,true))<1. and order.hp==76. and order.packed and order.learned,"restore with position health padding and learned call")
	order.stage="ledger";order.blessing=true;order.save();order.settle(true);order.left_dock.emit(0);await process_frame;await process_frame
	var wallet:int=base.wind_wallet;ck(base.bell_done and base.bell_padding and base.bell_blessed and wallet>0,"ledger persisted shared world")
	base.book_select(7);order=base.dock_order;order.stage="ledger";order.settle(true);order.action();order._physics_process(.74);await process_frame;await process_frame
	ck(base.wind_wallet==wallet,"replay does not pay twice")
	var n=base.dock_order;ck(n.bell_boarding and n.pos.distance_to(n.BERTH)<5.2,"invitation opens night at blue quay");n.speed=0.;n.port=-1;n._physics_process(.016);n.use()
	ck(n.bell_answered and base.bell_letter==1 and n.family_letter.get_parent()==n.boat,"night bell and return letter onboard")
	n.left_dock.emit(0);await process_frame;await process_frame;base.book_select(2);n=base.dock_order
	ck(n.letter_stage==1 and n.family_letter.get_parent()==n.boat,"letter preserved across night shifts")
	n.pos=n.PORTS[3];n.port=3;n.speed=0.;n.use();n.use()
	ck(base.bell_letter==2 and base.wind_wallet==wallet+5,"letter delivered at kiln, once-only payment")
	n.left_dock.emit(0);await process_frame;base.health=100.;base.warn_damage("测试",10.);ck(is_equal_approx(base.health,92.),"permanent padding reduces wine order impact")
	base.queue_free();await process_frame;quit(errs)

