extends SceneTree

const DT:=1./60.
var game
var errors:=0

func _initialize(): call_deferred("run")
func check(ok:bool,msg:String):
	if ok: print("PASS ",msg)
	else:
		errors+=1
		push_error(msg)

func tap(side:int):
	var e:=InputEventAction.new()
	e.action="right" if side==1 else "left"
	e.pressed=true
	game._unhandled_input(e)

func trial(side:int,lane:float) -> float:
	game.begin()
	var hero=game.hero
	hero.position.x=450
	var axis:=Vector2(side,0)
	tap(side)
	hero.step(DT,axis)
	check(hero.run_dir==0,"first tap walks")
	hero.step(DT,Vector2.ZERO)
	tap(side)
	for i in 5: hero.step(DT,axis)
	check(hero.run_dir==side and hero.run_distance>=18,"second tap builds momentum")
	var start:Vector2=hero.position
	var enemy=game.spawn("raider",start+Vector2(side*104,lane))
	game.enemies.append(enemy)
	hero.command("attack")
	hero.step(DT,axis)
	check(hero.move=="shoulder","running Strike selects shoulder")
	for i in 40:
		hero.step(DT,-axis)
		if enemy.hp<enemy.max_hp: enemy.step(DT,Vector2.ZERO)
	if lane==0:
		check(enemy.hp==enemy.max_hp-22 and (enemy.position.x-start.x)*side>144,"hit once and shove away")
	else: check(enemy.hp==enemy.max_hp and hero.state!="attack","miss clears lane and recovers")
	return (hero.position.x-start.x)*side

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	var hit:=trial(1,0)
	trial(-1,0)
	check(trial(1,40)>hit+35,"whiff travels farther than contact")
	game.begin()
	var h=game.hero
	tap(1)
	for i in 20: h.step(DT,Vector2.ZERO)
	tap(1)
	check(h.run_dir==0,"late tap walks")
	h.command("attack")
	h.step(DT,Vector2.ZERO)
	check(h.move=="cut","standing Strike retains first cut")
	game.begin()
	h=game.hero
	var t=game.ui.touch
	t.visible=true
	var event:=InputEventScreenTouch.new()
	event.index=1
	event.position=t.ORIGIN+Vector2(39,0)
	event.pressed=true
	t._input(event)
	event.pressed=false
	t._input(event)
	event.pressed=true
	t._input(event)
	for i in 5: h.step(DT,game.touch_vector)
	event.index=2
	event.position=t.BUTTONS.attack
	t._input(event)
	h.step(DT,game.touch_vector)
	check(h.move=="shoulder","touch stick and independent Strike finger")
	game.selected="swift"
	game.begin()
	tap(1)
	tap(1)
	check(game.hero.run_dir==0,"run belongs to Orra")
	game.free()
	await process_frame
	quit(1 if errors else 0)
