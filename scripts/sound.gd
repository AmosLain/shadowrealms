extends Node
var bank: Dictionary={}
var voices: Array=[]
var silent_driver := false
var drums:AudioStreamPlayer
var slot:=0
var muted:=false
func _ready():
	silent_driver = AudioServer.get_driver_name()=="Dummy"
	var cfg:=ConfigFile.new()
	if cfg.load("user://sound.cfg")==OK: muted=cfg.get_value("audio","muted",false)
	for name_id in ["swing","impact","magic","pickup","wind","bell","vent"]:
		bank[name_id]=synthesize(name_id)
	for i in 6:
		var voice:=AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var melody=music_stem(preload("res://audio/vigil.ogg"),-13.)
	if not silent_driver: melody.play()
	drums=music_stem(preload("res://audio/siege.ogg"),-60.)
	if not silent_driver: drums.play()
	var amb:=AudioStreamPlayer.new()
	add_child(amb)
	amb.stream=bank.wind
	amb.volume_db=-14
	if not silent_driver: amb.play()
	AudioServer.set_bus_mute(0,muted)
func music_stem(stream: AudioStreamOggVorbis, volume:float) -> AudioStreamPlayer:
	var voice:=AudioStreamPlayer.new()
	stream.loop=true
	voice.stream=stream
	voice.volume_db=volume
	add_child(voice)
	return voice

func _process(dt):
	var arena=get_parent()
	var target:float=-12. if arena.level_state=="play" and arena.locked else -60.
	drums.volume_db=move_toward(drums.volume_db,target,26.*dt)

func toggle():
	muted=not muted
	AudioServer.set_bus_mute(0,muted)
	var cfg:=ConfigFile.new()
	cfg.set_value("audio","muted",muted)
	cfg.save("user://sound.cfg")
func play(id:String):
	if silent_driver: return
	slot=(slot+1)%voices.size()
	voices[slot].stream=bank[id]
	voices[slot].volume_db=-10
	voices[slot].play()
func synthesize(id:String) -> AudioStreamWAV:
	var wav:=AudioStreamWAV.new()
	wav.mix_rate=22050
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	var length:float={"swing":.18,"impact":.25,"magic":.64,"pickup":.44,"wind":3.,"bell":.72,"vent":.48}[id]
	var count:=int(wav.mix_rate*length)
	var raw:=PackedByteArray()
	raw.resize(count*2)
	var noise:=RandomNumberGenerator.new()
	noise.seed=537
	var low:=0.
	for i in count:
		var t:=float(i)/wav.mix_rate
		var u:=float(i)/count
		var n:=noise.randf_range(-1,1)
		low=lerpf(low,n,.075)
		var v:=0.
		match id:
			"swing": v=(n*.3+low)*sin(PI*u)*exp(-2.*u)
			"impact": v=(low*2.+sin(400.*t+4.*sin(28.*t))*.6)*exp(-7.*u)
			"magic": v=(sin(1200.*t+80.*t*t)+sin(1800.*t+210.*t*t))*.35*sin(PI*u)*exp(-2.*u)
			"pickup": v=sin(TAU*(420. if u<.4 else 630.)*t)*sin(PI*u)*.42
			"bell": v=(sin(TAU*294*t)+.45*sin(TAU*723*t)+.25*sin(TAU*1087*t))*.40*exp(-5.*u)
			"vent": v=(n*.22+low*1.6)*sin(PI*u)*exp(-1.1*u)
			"wind": v=(low*.8+sin(TAU*49*t)*.16+sin(TAU*73*t)*.10)*(.5+.5*sin(PI*u))
		raw.encode_s16(i*2,int(clampf(v,-1.,1.)*25000))
	wav.data=raw
	if id=="wind":
		wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
		wav.loop_end=count
	return wav


func _exit_tree():
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream=null
