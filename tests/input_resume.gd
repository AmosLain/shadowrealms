extends SceneTree

var errors:=0
var game

func _initialize(): call_deferred("run")

func verify(ok:bool, description:String):
	if ok: print("PASS ",description)
	else:
		errors+=1
		push_error(description)

func touch(index:int, p:Vector2, pressed:bool):
	var event:=InputEventScreenTouch.new()
	event.index=index
	event.position=p
	event.pressed=pressed
	game.ui.touch._input(event)

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.begin()
	game.set_physics_process(false)
	var pad=game.ui.touch
	var hero=game.hero
	pad.visible=true
	touch(0,pad.ORIGIN+Vector2(32,0),true)
	touch(1,pad.BUTTONS.jump,true)
	touch(2,pad.BUTTONS.jump,true)
	touch(1,pad.BUTTONS.jump,false)
	verify(not hero.jump_held and pad.finger==0,"original jump finger still owns release while moving")
	touch(2,pad.BUTTONS.jump,false)
	touch(3,pad.BUTTONS.attack,true)
	game.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	verify(game.level_state=="pause" and game.touch_vector==Vector2.ZERO and pad.finger==-1,"focus loss pauses and releases the stick")
	game.pause_game()
	hero.step(1./60.,Vector2.ZERO)
	verify(hero.state=="idle" and hero.rise==0 and hero.run_dir==0,"resume ignores queued pre-pause jump and strike")
	hero.command("attack")
	hero.step(1./60.,Vector2.ZERO)
	verify(hero.move=="cut","fresh input works on resume")
	game.free()
	await process_frame
	quit(1 if errors else 0)
