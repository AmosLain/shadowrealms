extends SceneTree

const TICK := 1.0/60.0
var game
var failures := 0

func _initialize():
	call_deferred("run")

func check(ok: bool, description: String):
	if ok: print("PASS ", description)
	else:
		push_error(description)
		failures += 1

func fresh(role: String):
	game.selected = role
	game.begin()
	return game.hero

func apex(release: bool) -> float:
	var h = fresh("warden")
	h.command("jump")
	var peak := 0.0
	for frame in 75:
		if release and frame==4: h.release_jump()
		h.step(TICK,Vector2.ZERO)
		peak=maxf(peak,h.lift)
	return peak

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	var low:=apex(true)
	var high:=apex(false)
	check(low>25 and high>low+40, "tap and hold have distinct jump arcs")
	for role in game.Rules.HEROES:
		var h=fresh(role)
		var origin:Vector2=h.position
		var victim=game.spawn("brute", origin+Vector2(-40 if role=="warden" else 80,0))
		game.enemies.append(victim)
		h.command("jump")
		if role=="swift": h.command("attack")
		for i in 12: h.step(TICK,Vector2.ZERO)
		if role!="swift": h.command("attack")
		h.step(TICK,Vector2.ZERO)
		check(h.move==game.Rules.AIR_ATTACK[role],"jump strike for "+role)
		if role=="warden":
			check(victim.hp==victim.max_hp and h.lift>0,"plunge waits for landing")
		for i in 45:
			h.step(TICK,Vector2.ZERO)
			game.step_objects(TICK)
		check(victim.hp<victim.max_hp,role+" aerial move hits a live hurtbox")
		if role=="swift": check(h.position.x>origin.x+80,"gale carries hero forward")
	var h=fresh("warden")
	game.drop(h.position,"ember")
	game.step_objects(TICK)
	check(h.attack_damage(16)==24,"ember pickup raises strike damage")
	game.pause_game()
	game._physics_process(2.0)
	check(h.ember_time==game.Rules.EMBER_SECONDS,"pause freezes ember duration")
	game.pause_game()
	for i in 725: h.step(TICK,Vector2.ZERO)
	check(h.attack_damage(16)==16,"ember expires")
	var brute=game.spawn("brute",h.position-Vector2(140,0))
	game.enemies.append(brute)
	brute.step(TICK,Vector2.ZERO)
	check(brute.move=="fault","brute chooses ground wave at range")
	game.strike(brute)
	h.lift=58
	for i in 85: game.step_objects(TICK)
	check(h.hp==h.max_hp,"ground wave passes below jumper")
	h.lift=0
	game.strike(brute)
	for i in 85: game.step_objects(TICK)
	check(h.hp==h.max_hp-17,"ground wave punishes standing in lane")
	var raider=game.spawn("raider",h.position-Vector2(45,0))
	raider.pattern=1
	raider.step(TICK,Vector2.ZERO)
	h.invincible=0
	h.lift=68
	game.strike(raider)
	check(raider.move=="hook" and h.hp==h.max_hp-31,"rising hook catches airborne hero")
	game.free()
	await process_frame
	quit(1 if failures else 0)
