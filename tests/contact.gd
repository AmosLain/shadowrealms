extends SceneTree

var game
var errors := 0

func _initialize(): call_deferred("run")

func verify(ok:bool, description:String):
	if ok: print("PASS ",description)
	else:
		errors+=1
		push_error(description)

func opponent(kind:String, offset:Vector2):
	var enemy=game.spawn(kind,game.hero.position+offset)
	game.enemies.append(enemy)
	return enemy

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	for side in [-1,1]:
		game.begin()
		var hero=game.hero
		hero.face=side
		var near=opponent("raider",Vector2(12*side,0))
		var far=opponent("raider",Vector2(34*side,0))
		near.invincible=.2
		far.face=side
		hero.start_move("shoulder")
		verify(game.shoulder_hit(hero) and far.state=="down" and near.hp==near.max_hp,"charge reaches vulnerable opponent behind invulnerable target")
		far.rig.draw_frame()
		verify(signf(far.rig.rotation)==side,"fall follows contact from behind")
		far.elapsed=.67
		far.rig.draw_frame()
		verify(absf(far.rig.rotation)<.02,"surviving target recovers before control returns")
	game.begin()
	var h=game.hero
	var boss=opponent("cantor",Vector2(16,0))
	opponent("chime",Vector2(110,0))
	h.start_move("shoulder")
	verify(not game.shoulder_hit(h) and boss.hp==boss.max_hp and h.impact_hold==0.,"warded target gives no damage confirmation")
	game.begin()
	h=game.hero
	var e=opponent("brute",Vector2(42,0))
	h.combo=2
	h.start_move("return")
	h.step(.11,Vector2.ZERO)
	verify(h.impact_hold>0 and e.impact_hold==h.impact_hold,"confirmed follow-up holds only the participants")
	var contact_time:float=h.elapsed
	h.command("attack")
	h.step(.016,Vector2.ZERO)
	verify(h.elapsed==contact_time and h.buffer==.32,"freeze preserves buffered follow-up")
	for i in 25: h.step(1./60.,Vector2.ZERO)
	verify(h.move=="cleave","buffered input executes after recovery")
	game.begin()
	h=game.hero
	opponent("raider",Vector2(42,80))
	h.start_move("return")
	h.step(.11,Vector2.ZERO)
	verify(h.impact_hold==0.,"adjacent lane whiff has no hit stop")
	game.free()
	await process_frame
	quit(1 if errors else 0)
