extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var town=load("res://vineyard.tscn").instantiate();root.add_child(town)
	for i in 4:await process_frame
	var label:String=town.board.continuation.text
	var event:=InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
	await process_frame
	var boat=town.dock_order
	var mode:=OS.get_cmdline_user_args()[0]
	var ok:=false
	if is_instance_valid(boat):
		match mode:
			"clay":ok=boat.works==2 and boat.lantern_crate.visible and boat.pos.distance_to(boat.PORTS[3])<4.
			"passenger":ok=boat.worker_signed and boat.worker_aboard and boat.worker.visible and boat.pos.distance_to(boat.PORTS[3])<4.
			"mirror":ok=town.worker_runs==2 and town.quay_mirror and boat.mirror_built and boat.pilots.reflector!=null
	print("COLD ",mode," ",ok," / ",label," / wallet ",town.wind_wallet)
	town.queue_free();await process_frame;await create_timer(.25).timeout;quit(0 if ok else 1)
