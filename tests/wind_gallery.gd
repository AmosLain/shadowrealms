extends SceneTree

const Crosswind=preload("res://scripts/crosswind.gd")
var game
var failures:=0

func _initialize(): call_deferred("run")

func check(ok:bool,message:String):
	if ok: print("PASS ",message)
	else:
		failures+=1
		push_error(message)

func gallery_wind():
	for hazard in game.get_node("Floor").get_children():
		if hazard is Crosswind: return hazard
	return null

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	for stage in game.Rules.GATES.size():
		game.begin(stage)
		check(gallery_wind()==null,"approach has no wind at gate %d"%stage)
		game.start_wave()
		check((gallery_wind()!=null)==(stage==4),"wind belongs only to Wind Gallery gate %d"%stage)

	game.begin(4)
	game.hero.position.x=game.Rules.GATES[4]-230
	game._physics_process(1./60.)
	var wind=gallery_wind()
	check(wind!=null and wind.phase=="warning","walking into the gate starts a visible warning")
	var x:float=game.hero.position.x
	game.hero.position.y=350.
	game.pause_game()
	var paused:float=wind.remaining
	game._physics_process(.8)
	check(wind.remaining==paused and game.hero.position.x==x,"pause suspends warning and displacement")
	game.pause_game()
	wind.step(wind.WARNING-.01)
	check(game.hero.position.x==x and wind.phase=="warning","telegraph precedes all motion")
	var e=game.enemies[0]
	var grounded=game.enemies[1]
	var chime=game.enemies[2]
	var safe=game.enemies[3]
	e.position=Vector2(x,350)
	e.lift=wind.CLEARANCE
	grounded.position=Vector2(x,350)
	chime.position=Vector2(x,350)
	safe.position=Vector2(x,403)
	wind.step(.01+wind.PULSE)
	var travel:float=wind.PULSE*wind.FORCE
	check(is_equal_approx(game.hero.position.x-x,travel) and is_equal_approx(grounded.position.x-x,travel),"pulse shifts grounded fighters by 56 pixels")
	check(e.position.x==x and chime.position.x==x and safe.position.x==x,"jump, shelter and anchored chimes resist the gale")
	game.hero.position=Vector2(game.left_bound+4,444)
	wind.step(wind.REST+wind.WARNING+wind.PULSE)
	check(game.hero.position.x==game.left_bound,"opposite gust uses the front lane and stops at arena edge")
	wind.step(wind.REST)
	game.hero.position=Vector2(game.right_bound-4,350)
	wind.step(wind.WARNING+wind.PULSE)
	check(game.hero.position.x==game.right_bound,"east gust respects the opposite arena edge")
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():
		game.begin(4)
		game.start_wave()
		wind=gallery_wind()
		wind.step(wind.WARNING+.19)
		game.hero.position=Vector2(game.Rules.GATES[4],420)
		game.scroll=game.hero.position.x-480.
		game.road.position.x=-game.scroll
		game.get_node("Floor").position.x=-game.scroll
		game.landscape.scroll=game.scroll
		game.landscape.queue_redraw()
		game.ui.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_jpg(args[0],.88)==OK,"graphical evidence saved")
	for enemy in game.enemies: enemy.queue_free()
	game.enemies.clear()
	game._physics_process(1./60.)
	check(not game.locked and gallery_wind()==null,"clearing the gate removes the gust")
	game.begin(4)
	game.start_wave()
	game.begin(0)
	check(gallery_wind()==null,"retrying elsewhere removes the previous gallery hazard")
	game.free()
	await process_frame
	quit(1 if failures else 0)
