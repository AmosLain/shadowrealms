extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")

func check(ok:bool, msg:String):
	if ok: print("PASS ",msg)
	else:
		failures+=1
		push_error(msg)

func run():
	var game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	for gate in [0,5]:
		game.begin(gate)
		game.start_wave()
		for enemy in game.enemies: enemy.free()
		game.enemies.clear()
		game.hero.damage(999,0,false)
		game._physics_process(1./60.)
		check(game.locked and game.checkpoint==gate and game.level_state=="play","death animation keeps gate %d pending"%gate)
		for tick in 80: game._physics_process(1./60.)
		check(game.level_state=="lost" and game.checkpoint==gate,"defeat keeps gate %d available to retry"%gate)
	game.free()
	await process_frame
	quit(1 if failures else 0)
