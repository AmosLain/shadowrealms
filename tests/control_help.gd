extends SceneTree

var errors:=0

func _initialize(): call_deferred("run")

func check(ok:bool, description:String):
	if ok: print("PASS ",description)
	else:
		errors+=1
		push_error(description)

func run():
	var game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	var ui=game.ui
	var args:=OS.get_cmdline_user_args()
	for use_touch in [false,true]:
		ui.touch_controls=use_touch
		for hero in ["warden","seer","swift"]:
			game.selected=hero
			game.begin()
			check(ui.touch.visible==use_touch,"controls use the selected input scheme")
			game.pause_game()
			await process_frame
			var help:Label
			var resume:Button
			for child in ui.panel.get_children():
				if child is Button and child.text=="Resume": resume=child
				if child is Label and child.text.contains("midair"): help=child
			if not is_instance_valid(help) or not is_instance_valid(resume):
				check(false,"pause help and Resume button exist")
				continue
			var words:=help.text
			check(words.contains("left stick") if use_touch else words.contains("WASD"),"pause shows movement for the active device")
			check(words.contains("ATTACK") if use_touch else words.contains("Press J"),"pause shows the correct attack control")
			check(words.contains("Shoulder charge")== (hero=="warden"),"shoulder instructions belong to Orra")
			check(words.contains({"warden":"plunge","seer":"rain embers","swift":"dive forward"}[hero]),"pause describes the selected aerial attack")
			var bounds:=help.get_rect()
			check(bounds.end.x<575 and bounds.end.y<resume.position.y,"instructions fit inside the panel and above Resume")
			if not args.is_empty() and hero=="warden":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(args[0].path_join("pause-touch.png" if use_touch else "pause-keyboard.png"))
	game.free()
	await process_frame
	quit(1 if errors else 0)
