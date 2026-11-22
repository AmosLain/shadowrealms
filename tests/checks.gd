extends SceneTree
var game
var failures:=0
func _initialize(): call_deferred("run")
func check(ok:bool,msg:String):
	if not ok:
		push_error(msg)
		failures+=1
	else: print("PASS ",msg)
func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	root.add_child(game)
	game.begin()
	game.set_physics_process(false)
	var h=game.hero
	var e=game.spawn("raider",h.position+Vector2(60,-70))
	game.enemies.append(e)
	h.start_move("cut")
	game.strike(h)
	check(e.hp==e.max_hp,"separate depth lanes miss")
	e.position.y=h.position.y
	h.step(.14,Vector2.ZERO)
	check(e.hp==e.max_hp-16,"active blade intersects hurtbox")
	e.invincible=0
	h.step(.05,Vector2.ZERO)
	check(e.hp==e.max_hp-16,"one damage event per swing")
	h.state="idle"
	h.mana=0
	h.command("magic")
	h.step(.01,Vector2.ZERO)
	check(h.state=="idle","empty magic resource")
	var t=game.ui.touch
	t.visible=true
	var finger:=InputEventScreenTouch.new()
	finger.pressed=true
	finger.index=5
	finger.position=t.ORIGIN+Vector2(40,0)
	t._input(finger)
	finger.index=7
	finger.position=t.BUTTONS.attack
	t._input(finger)
	check(game.touch_vector.x>.5 and h.queued=="attack","independent movement and attack fingers")
	finger.pressed=false
	t._input(finger)
	check(game.touch_vector.x>.5,"releasing attack preserves joystick")
	finger.index=5
	t._input(finger)
	check(game.touch_vector==Vector2.ZERO,"movement finger release")
	game.drop(h.position,"health")
	h.hp=30
	game.step_objects(.016)
	check(h.hp==82,"health pickup")
	game.checkpoint=1
	h.damage(1000,0,false)
	for i in 80: game._physics_process(1./60)
	check(game.level_state=="lost","knockout opens retry screen")
	for child in game.ui.panel.get_children():
		if child is Button and child.text=="Retry encounter":
			child.pressed.emit()
			break
	check(game.level_state=="play" and game.checkpoint==1 and game.hero.hp==150,"current encounter restored")
	game.free()
	await process_frame
	quit(1 if failures else 0)

