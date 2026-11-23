extends CanvasLayer
const Touch=preload("res://scripts/touch.gd")
const Actor=preload("res://scripts/fighter.gd")
const Rules=preload("res://scripts/rules.gd")
var arena
var panel: Control
var hud: Control
var touch
var hero_name:Label
var buff:Label
var hp: ProgressBar
var mp: ProgressBar
var boss: ProgressBar
var boss_name: Label
var place: Label
var hint: Label
var serif:=SystemFont.new()
var gold:=Color("#dfbe85")
var ivory:=Color("#f2e8cd")
func setup(level):
	arena=level
	serif.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	hud=Control.new()
	add_child(hud)
	panel=Control.new()
	add_child(panel)
	touch=Touch.new()
	touch.arena=arena
	touch.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(touch)
	box(hud,18,18,269,76,Color("#192329e8"))
	hero_name=label(hud,"ORRA VENN",33,24,18,ivory,true)
	buff=label(hud,"",33,93,16,gold)
	hp=bar(33,53,235,9,Color("#c56b55"))
	mp=bar(33,68,190,6,Color("#6eccc4"))
	place=label(hud,"",323,22,21,ivory,true)
	hint=label(hud,"",324,51,14,gold)
	button(hud,"Ⅱ",891,18,51,arena.pause_game)
	boss_name=label(hud,"",322,85,14,ivory)
	boss=bar(323,109,319,7,Color("#c88558"))

func style(c: Color,border:Color=Color.TRANSPARENT):
	var s:=StyleBoxFlat.new()
	s.bg_color=c
	s.border_color=border
	s.set_border_width_all(1 if border.a>0 else 0)
	s.corner_radius_top_left=2
	s.corner_radius_bottom_right=2
	return s

func box(parent,x,y,w,h,c):
	var rect:=ColorRect.new()
	rect.position=Vector2(x,y)
	rect.size=Vector2(w,h)
	rect.color=c
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func label(parent,words,x,y,points,c,display:=false) -> Label:
	var l:=Label.new()
	l.text=words
	l.position=Vector2(x,y)
	l.add_theme_color_override("font_color",c)
	l.add_theme_constant_override("outline_size",3)
	l.add_theme_color_override("font_outline_color",Color("#202329"))
	l.add_theme_font_size_override("font_size",points)
	if display: l.add_theme_font_override("font",serif)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(parent,words,x,y,w,callback):
	var b:=Button.new()
	b.text=words
	b.position=Vector2(x,y)
	b.size=Vector2(w,44)
	b.add_theme_stylebox_override("normal",style(Color("#223536f2"),Color("#8b826b")))
	b.add_theme_stylebox_override("hover",style(Color("#335150"),gold))
	b.add_theme_stylebox_override("pressed",style(Color("#456564"),gold))
	b.add_theme_color_override("font_color",ivory)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func bar(x,y,w,h,c) -> ProgressBar:
	var b:=ProgressBar.new()
	b.position=Vector2(x,y)
	b.show_percentage=false
	b.add_theme_stylebox_override("background",style(Color("#26292c")))
	b.add_theme_stylebox_override("fill",style(c))
	hud.add_child(b)
	b.size=Vector2(w,h)
	return b

func menu(which:String):
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	hud.visible=which=="play"
	touch.visible=hud.visible and DisplayServer.is_touchscreen_available()
	touch.reset()
	panel.visible=which!="play"
	if not panel.visible: return
	box(panel,0,0,960,540,Color(.04,.065,.08,.33))
	box(panel,28,38,547,463,Color("#131e24ee"))
	box(panel,53,74,47,3,gold)
	label(panel,"C I N D E R   K E E P     /     I",54,86,14,gold)
	match which:
		"title":
			label(panel,"Shadow Realms",50,125,54,ivory,true)
			label(panel,"THE ASH CAUSEWAY",55,210,20,gold)
			label(panel,"The bell has called the dead home.\nCross the foundry. Silence the choir at its crown.",55,257,19,ivory)
			button(panel,"Enter the keep",55,362,210,func(): arena.level_state="select"; menu("select")).grab_focus()
			audio_button(55,419)
			var slot:Dictionary=arena.read_journey()
			if not slot.is_empty():
				button(panel,"Continue at "+Rules.PLACES[slot.stage],275,362,270,arena.resume_journey)
		"select":
			label(panel,"Choose your oath",52,118,42,ivory,true)
			label(panel,Rules.NAMES[arena.selected],55,193,32,gold,true)
			label(panel,{"warden":"Heavy warrior  /  Two-handed blade","seer":"Dark mage  /  Ember staff","swift":"Agile warrior  /  Twin knives"}[arena.selected],55,244,18,ivory)
			label(panel,{"warden":"Three chained cuts  /  Cinder cleave  /  Tide ring","seer":"Fire lance  /  Evasive step  /  Storm field","swift":"Fast cuts  /  Lunging dodge  /  Counter critical"}[arena.selected],55,285,16,ivory)
			for i in Rules.HEROES.size():
				var id:String=Rules.HEROES[i]
				button(panel,Rules.NAMES[id],55+i*147,326,137,func(): arena.selected=id; menu("select"))
			button(panel,"Begin with "+Rules.NAMES[arena.selected],55,385,234,func(): arena.begin()).grab_focus()
			var preview=Actor.new()
			panel.add_child(preview)
			preview.configure(arena.selected,arena)
			preview.position=Vector2(722,407)
			preview.scale=Vector2.ONE*2.35
		"pause","lost","won":
			var title:String={"pause":"At rest","lost":"The oath falls","won":"The final silence"}[which]
			label(panel,title,52,131,45,ivory,true)
			var msg:String={"pause":"Move: WASD / arrows     Strike: J     Jump: K\nMagic: L     Special / timed counter: Shift\nHold Jump for height. Press Strike in midair.","lost":"Return to the last encounter with restored vitality.","won":"The last bell falls silent. Dawn reaches Cinder Keep."}[which]
			label(panel,msg,55,219,18,ivory)
			if which=="won": label(panel,"Timed counters this run: %d" % arena.counters,55,270,17,gold)
			if which=="pause":
				button(panel,"Resume",55,302,184,arena.pause_game).grab_focus()
				audio_button(250,302)
			button(panel,"Retry encounter" if which=="lost" else "Restart level",55,362,184,func(): arena.begin(arena.checkpoint if which=="lost" else 0))
			button(panel,"Title screen",250,362,150,func(): arena.level_state="title"; menu("title"))
func audio_button(x,y):
	var b=button(panel,"",x,y,160,func(): arena.sound.toggle(); menu(arena.level_state))
	b.text="Sound off" if arena.sound.muted else "Sound on"
func refresh():
	hero_name.text=Rules.NAMES[arena.selected].to_upper()
	hp.max_value=arena.hero.max_hp
	hp.value=arena.hero.hp
	mp.value=arena.hero.mana
	buff.text="EMBER   +50%% damage   %ds" % ceili(arena.hero.ember_time) if arena.hero.ember_time>0 else ""
	var index:=clampi(arena.wave if arena.locked else arena.wave+1,0,Rules.WAVES.size()-1)
	place.text=Rules.PLACES[index]
	hint.text="Defeat the defenders" if arena.locked else "Advance east   →"
	if arena.counter_notice>0:
		hint.text="Counter!   +15 magic"
	elif arena.hero.position.x<398 and arena.wave<0:
		hint.text="Double-tap a direction, hold, then Strike." if arena.selected=="warden" else "Hold Jump for height. Strike in midair."
	elif arena.locked and arena.wave==0:
		hint.text="Face the flash. Special to counter."
	elif arena.locked and arena.wave==1:
		hint.text="Lure the defenders onto the grate."
	var active:bool=arena.wave in [2,5] and arena.locked and not arena.enemies.is_empty()
	boss.visible=active
	boss_name.visible=active
	if active:
		var e=arena.enemies[0]
		boss.max_value=e.max_hp
		boss.value=e.hp
		if e.kind=="headsman" and arena.counter_notice<=0 and e.state=="attack":
			hint.text="Ground shock   /   Jump!" if e.move=="quake" else "Blade sweep   /   Counter or sidestep"
		if e.kind=="cantor":
			hint.text="Break the two bell seals" if arena.chimes_alive() else "Dodge the chord. Strike between peals."
		boss_name.text=("THE PALE CANTOR" if e.kind=="cantor" else "THE LANTERN HEADSMAN") + ("   /   UNBOUND" if e.phase_two else "")

