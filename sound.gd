extends Node

var bg:=AudioStreamPlayer.new()
var voices: Array[AudioStreamPlayer]=[]
var bank: Dictionary={}
var active_music: String=""
var next_voice:=0

func _ready() -> void:
	add_child(bg)
	bg.volume_db=-12
	for i in 6:
		var voice:=AudioStreamPlayer.new()
		add_child(voice)
		voice.volume_db=-4
		voices.append(voice)
	for s in ["yard","road","foot","grab","drop","load","bonk","start","page","engine","wind","land","win","warn","snap","buckle"]:
		var clip: AudioStreamWAV=load("res://audio/"+s+".wav")
		if clip and s in ["yard","road"]:
			clip.loop_mode=AudioStreamWAV.LOOP_FORWARD
			clip.loop_end=int(clip.get_length()*clip.mix_rate)
		bank[s]=clip

func play_cue(id: String) -> void:
	if not bank.has(id): return
	var voice:=voices[next_voice]
	next_voice=(next_voice+1)%voices.size()
	voice.stream=bank[id]
	voice.play()

func set_scene(s: String) -> void:
	var key:="road" if s=="road" else "yard"
	if key==active_music: return
	active_music=key
	bg.stream=bank[key]
	bg.play()

func stop_all() -> void:
	bg.stop()
	bg.stream=null
	for voice in voices:
		voice.stop()
		voice.stream=null
	bank.clear()

func _exit_tree() -> void:
	stop_all()

func set_quiet(value: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),value)



