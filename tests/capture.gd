extends SceneTree
# Run with a graphical renderer. Pass the destination directory after --.
func _initialize(): call_deferred("run")
func run():
	var args:=OS.get_cmdline_user_args()
	if args.is_empty(): quit(2); return
	var game=load("res://scenes/Keep.tscn").instantiate()
	root.add_child(game)
	game.begin()
	game.hero.position=Vector2(411,397)
	game.start_wave()
	game.enemies[0].position=Vector2(489,403)
	game.enemies[1].position=Vector2(610,368)
	game.hero.command("attack")
	for i in 10: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("combat.png"))
	game.set_physics_process(false)
	game.ui.visible=false
	game.landscape.visible=false
	game.road.visible=false
	var refs:=Node2D.new()
	root.add_child(refs)
	var role_names:=["warden","seer","swift","raider","brute","cultist","headsman"]
	for i in range(role_names.size()):
		var actor=game.spawn(role_names[i],Vector2.ZERO)
		actor.reparent(refs)
		actor.position=Vector2(54+i*137,344)
		actor.scale=Vector2.ONE*1.08
		var label:=Label.new()
		label.text=role_names[i].to_upper()
		label.position=Vector2(23+i*137,374)
		refs.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("cast.png"))
	refs.free()
	game.free()
	await process_frame
	quit()

