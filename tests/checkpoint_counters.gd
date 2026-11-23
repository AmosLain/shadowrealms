extends SceneTree

var failures:=0
var path:=OS.get_temp_dir().path_join("shadow-realms-counter-%d.cfg"%OS.get_process_id())

func _initialize(): call_deferred("run")

func check(ok:bool, description:String):
	if ok: print("PASS ",description)
	else:
		failures+=1
		push_error(description)

func scene():
	var game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=path
	root.add_child(game)
	game.set_physics_process(false)
	return game

func run():
	var game=scene()
	game.selected="swift"
	game.begin()
	game.start_wave()
	for enemy in game.enemies: enemy.queue_free()
	game.enemies.clear()
	game.counters=3
	game._physics_process(1./60.)
	check(game.checkpoint==1,"wave clear reaches checkpoint")
	game.free()
	game=scene()
	game.resume_journey()
	check(game.selected=="swift" and game.checkpoint==1 and game.counters==3,"fresh scene recovers banked counters")
	game.counters+=2
	game.ui.menu("lost")
	for child in game.ui.panel.get_children():
		if child is Button and child.text=="Retry encounter": child.pressed.emit()
	check(game.counters==3,"retry discards only counters earned after checkpoint")
	game.begin()
	check(game.counters==0,"new run starts a fresh count")
	var old:=ConfigFile.new()
	old.set_value("journey","role","seer")
	old.set_value("journey","gate",3)
	old.save(path)
	game.resume_journey()
	check(game.selected=="seer" and game.checkpoint==3 and game.counters==0,"legacy saves continue")
	game.free()
	DirAccess.remove_absolute(path)
	await process_frame
	quit(1 if failures else 0)
