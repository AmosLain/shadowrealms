extends SceneTree

# Optional graphical run: pass an existing output directory after -- to capture
# the same controlled hit and whiff used by the assertions.
const STEP := 1./60.
var game
var errors := 0

func _initialize(): call_deferred("run")

func verify(ok:bool, description:String):
	if ok: print("PASS ",description)
	else:
		push_error(description)
		errors+=1

func run():
	game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	var args:=OS.get_cmdline_user_args()
	for trial in ["hit","miss","left","lane"]:
		game.begin()
		game.ui.visible=false
		var h=game.hero
		h.position=Vector2(390,405)
		var dir:float=-1. if trial=="left" else 1.
		h.face=int(dir)
		var e=game.spawn("raider",h.position+Vector2(dir*(146 if trial=="miss" else 106),39 if trial=="lane" else 0))
		e.face=-int(dir)
		game.enemies.append(e)
		var held:=0
		var contact_frame:=-1
		var origin:Vector2=h.position
		var enemy_origin:Vector2=e.position
		h.command("attack")
		for tick in 45:
			var prior:float=h.elapsed
			var was_held:bool=h.impact_hold>0.
			h.step(STEP,Vector2.ZERO)
			if e.hp<e.max_hp:
				if contact_frame<0: contact_frame=game.Rules.cut_frame(h.elapsed)
				if e.state=="hurt": e.step(STEP,Vector2.ZERO)
			if was_held and is_equal_approx(prior,h.elapsed): held+=1
			if not args.is_empty() and trial in ["hit","miss"]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().get_region(Rect2i(292,235,328,206)).save_png(args[0].path_join("%s%02d.png"%[trial,tick]))
		verify(is_equal_approx((h.position.x-origin.x)*dir,17.),trial+" completes the planted step")
		if trial in ["hit","left"]:
			verify(e.max_hp-e.hp==16 and contact_frame in [1,2],trial+" damages once on a blade pose")
			verify(held==3 and (e.position.x-enemy_origin.x)*dir>6.,trial+" holds contact and recoils away")
		else: verify(e.hp==e.max_hp and held==0,trial+" has uninterrupted recovery")
	game.free()
	await process_frame
	quit(1 if errors else 0)
