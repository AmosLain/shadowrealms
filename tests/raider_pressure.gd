extends SceneTree

const STEP:=1./60.
var game
var failures:=0

func _initialize(): call_deferred("run")

func check(ok:bool, message:String):
	if ok: print("PASS ",message)
	else:
		failures+=1
		push_error(message)

func spawn_raider(offset:Vector2):
	var unit=game.spawn("raider",game.hero.position+offset)
	game.enemies.append(unit)
	return unit

func trial(side:int, lane:float):
	game.begin()
	game.hero.position=Vector2(420,lane)
	game.hero.invincible=60.
	var lead=spawn_raider(Vector2(45*side,0))
	var flank=spawn_raider(Vector2(60*side,0))
	var maximum_lane_change:=0.
	var overlapping_windups:=false
	for tick in 330:
		lead.step(STEP,Vector2.ZERO)
		flank.step(STEP,Vector2.ZERO)
		if lead.state=="attack" and not lead.did_hit:
			if flank.state=="attack" and not flank.did_hit: overlapping_windups=true
			maximum_lane_change=maxf(maximum_lane_change,absf(flank.position.y-lane))
	check(not overlapping_windups,"one raider telegraphs at a time")
	check(maximum_lane_change>=17.,"supporting raider moves into another lane")
	check(lead.pattern>=2 and flank.pattern>=2,"both raiders take repeated turns attacking")

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	trial(1,332.)
	trial(-1,461.)
	game.begin()
	game.hero.position=Vector2(420,395)
	var lead=spawn_raider(Vector2(45,0))
	var flank=spawn_raider(Vector2(60,0))
	lead.step(STEP,Vector2.ZERO)
	lead.damage(3,20,false)
	flank.step(STEP,Vector2.ZERO)
	check(flank.move=="jab","interrupting the lead immediately frees its opening")
	game.free()
	await process_frame
	quit(1 if failures else 0)
