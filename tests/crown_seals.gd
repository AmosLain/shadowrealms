extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://scenes/Keep.tscn").instantiate()
	game.save_path=""
	root.add_child(game)
	game.set_physics_process(false)
	game.begin(5)
	game.start_wave()
	var links=game.ward_links
	var failures:=0
	for count in [2,1,0]:
		if count<2: links.seals[count].damage(999,0,false)
		game.ui.refresh()
		var expected:Array=["Dodge the chord. Strike between peals.","Break the last bell seal","Break the two bell seals"]
		if game.ui.hint.text==expected[count] and links.cantor.damage(1,0,false)==(count==0):
			print("PASS live seals and HUD agree at ",count)
		else:
			push_error("Seal count and vulnerability disagree at %d"%count)
			failures+=1
	game.free()
	await process_frame
	quit(1 if failures else 0)
