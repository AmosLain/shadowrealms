extends Node2D
# All joints are authored against a boot pivot. Gameplay volumes live on the parent.
const R = preload("res://scripts/rules.gd")
var actor
var ink := Color("#191b24")
var steel: Color
var cloth: Color
var frames: AnimatedSprite2D
var shift := Vector2.ZERO
var tilt := 0.
var mirror := Vector2.ONE
func install_frames(kind:String):
	var path := "res://art/actors/%s/frames.tres" % kind
	if not ResourceLoader.exists(path): return
	frames=AnimatedSprite2D.new()
	frames.sprite_frames=load(path)
	frames.centered=false
	frames.position=Vector2(-96,-156)
	add_child(frames)
# Articulate the tucked-sword pose at the visor, pauldron, belt and boots.
# Coordinates are in the original atlas cell, with the ground at y=156.
var tackle_skin: Polygon2D
var tackle_rest := PackedVector2Array()

func pose_shoulder():
	if not tackle_skin:
		var pose:AtlasTexture=frames.sprite_frames.get_frame_texture("cut",0)
		tackle_skin=Polygon2D.new()
		tackle_skin.texture=pose.atlas
		var uv:=PackedVector2Array()
		var faces:Array[PackedInt32Array]=[]
		var columns:=[0,67,90,104,116,139,192]
		for y in [0,54,69,80,94,108,125,143,156,176]:
			for x in columns:
				var p:=Vector2(x,y)
				var i:=tackle_rest.size()
				tackle_rest.append(p)
				uv.append(p+pose.region.position)
				if y>0 and x>0:
					var above:=i-columns.size()
					faces.append(PackedInt32Array([above-1,above,i]))
					faces.append(PackedInt32Array([above-1,i,i-1]))
		tackle_skin.polygon=tackle_rest
		tackle_skin.uv=uv
		tackle_skin.polygons=faces
		tackle_skin.position=Vector2(-96,-156)
		add_child(tackle_skin)
	var t:float=maxf(actor.elapsed,.11) if actor.shoulder_contact else actor.elapsed
	var brace:=smoothstep(0.,.06,t)*(1.-smoothstep(.29,.46,t))
	var drive:=smoothstep(.04,.11,t)*(1.-smoothstep(.27,.43,t))
	var points:=tackle_rest.duplicate()
	for i in points.size():
		var p:=tackle_rest[i]
		var upper:=1.-smoothstep(91.,152.,p.y)
		var helm:=1.-smoothstep(48.,83.,p.y)
		var shoulder:=smoothstep(90.,112.,p.x)*(1.-smoothstep(7.,20.,absf(p.y-79.)))
		var boot:=smoothstep(110.,151.,p.y)
		var lead:=smoothstep(90.,122.,p.x)
		points[i].x+=upper*(drive*19.-brace*5.)-helm*brace*4.+shoulder*drive*17.
		points[i].x+=boot*lerpf(-13.,10.,lead)*drive
		points[i].y+=upper*(brace*9.+drive*6.)+helm*brace*10.-shoulder*drive*3.
		points[i].y-=boot*(1.-lead)*sin(PI*drive)*5.
	tackle_skin.polygon=points
	tackle_skin.visible=true

func draw_frame() -> bool:
	if not frames: return false
	if actor.state=="attack" and actor.move=="shoulder":
		frames.visible=false
		scale.x=absf(scale.y)*actor.face
		rotation=0.
		pose_shoulder()
		return true
	if tackle_skin: tackle_skin.visible=false
	var clip:String=actor.move if actor.state=="attack" else actor.state
	clip=R.ART_CLIP.get(clip,clip)
	if actor.lift>2 and actor.state!="attack": clip="jump"
	frames.visible=frames.sprite_frames.has_animation(clip)
	if frames.visible:
		scale.x=absf(scale.y)*actor.face
		frames.animation=clip
		var count:=frames.sprite_frames.get_frame_count(clip)
		frames.frame=0
		frames.position=Vector2(-96,-156)
		frames.rotation=0.
		frames.self_modulate=Color.WHITE
		rotation=0.
		if actor.state=="attack" and count>=4:
			var timing:Array=R.MOVES[actor.move]
			if actor.move in ["gale","plunge"]: rotation=actor.face*(.30 if actor.move=="plunge" else .13)
			if actor.move=="starfall": rotation=-actor.face*.14
			if actor.elapsed<timing[0]: frames.frame=0 if actor.elapsed<timing[0]*.28 else 1
			else: frames.frame=2 if actor.elapsed<timing[0]+timing[1]*.69 else 3
			if actor.move=="cut": frames.frame=R.cut_frame(actor.elapsed)
		elif clip=="walk":
			if actor.run_dir!=0: rotation=actor.face*.12
			frames.frame=int(actor.stride*.95)%count
			frames.position.y-=absf(sin(actor.stride))*1.8
		elif clip=="idle":
			frames.position.y+=sin(actor.stride)*.9
		elif clip in ["dead","down"] and actor.kind!="warden":
			var fall:=smoothstep(0.,.26,actor.elapsed)
			rotation=actor.knockback_side*(.18+1.25*fall)
			if clip=="down": rotation*=1.-smoothstep(.46,.68,actor.elapsed)
		elif clip=="hurt":
			if actor.cut_reaction>0.:
				var weight:float=smoothstep(0.,.17,actor.cut_reaction)
				rotation=signf(actor.recoil)*.25*weight
				frames.position.y+=2.*weight
			else: rotation=-actor.face*.13
			frames.self_modulate=Color(1.35,1.15,.95) if actor.elapsed<.10 else Color.WHITE
	else: scale.x=absf(scale.y)
	return frames.visible

func local(point: Vector2, angle := 0.):
	draw_set_transform(shift + (point.rotated(tilt)*mirror), (angle+tilt)*mirror.x, mirror)

func plate(coords: Array, color: Color):
	var p := PackedVector2Array()
	for i in range(0,coords.size(),2): p.append(Vector2(coords[i],coords[i+1]))
	draw_colored_polygon(p,color)
	p.append(p[0])
	draw_polyline(p,ink,1.25,true)

func stroke(x:float,y:float,xx:float,yy:float,c:Color,w:=1.5):
	draw_line(Vector2(x,y),Vector2(xx,yy),c,w,true)

func leg(hip: Vector2, foot: Vector2, near_leg: bool):
	var knee := hip.lerp(foot,.47)+Vector2(4,0)
	var c := steel if near_leg else steel.darkened(.34)
	local(hip)
	var k := knee-hip
	var f := foot-hip
	plate([-8,-2,7,-1,k.x+7,k.y,k.x+3,k.y+6,k.x-7,k.y+3],cloth.darkened(.28))
	plate([k.x-7,k.y,k.x+7,k.y-2,f.x+4,f.y-3,f.x+10,f.y-1,f.x+9,f.y+2,f.x-6,f.y+2],c.darkened(.24))
	stroke(k.x+4,k.y+3,f.x+2,f.y-5,c.lightened(.32))
	plate([k.x-8,k.y-3,k.x+2,k.y-6,k.x+8,k.y-2,k.x+4,k.y+5,k.x-6,k.y+5],c)

func _draw():
	if actor==null or draw_frame(): return
	if actor.kind=="chime":
		draw_chime()
		return
	steel=Color(R.UNITS[actor.kind][3])
	cloth=Color(R.UNITS[actor.kind][4])
	var st: String=actor.state
	var walk := sin(float(actor.stride)) if st=="walk" else 0.
	var breath := sin(float(actor.stride)) * 1.2
	var a := -.48
	var reach := 0.
	var swing := 0.
	var attacking := st=="attack"
	var hit_flash: bool=actor.invincible>0 and st in ["down","hurt"] and actor.elapsed<.10
	if hit_flash: steel=Color("#f6e0b4")
	if attacking:
		var data: Array=R.MOVES[actor.move]
		var wind := minf(actor.elapsed/float(data[0]),1.)
		swing=clampf((actor.elapsed-float(data[0])+.035)/.16,0.,1.)
		var high: bool=actor.move in ["return","magic","cast"]
		var backswing := .84 if high else -2.25
		if actor.move=="cut": backswing=-1.42
		if actor.move in ["cleave","special"]: backswing=-2.94
		a=lerpf(-.48,backswing,wind)
		a=lerpf(a,-1.95 if high else .53,smoothstep(0.,1.,swing))
		reach=sin(swing*PI)*13.+swing*5.
	mirror=Vector2(actor.face,1.)
	tilt = -.12 if st=="hurt" else .045*walk
	shift=Vector2(0,breath-absf(walk)*2)
	if st in ["dead","down"]:
		var fall:=smoothstep(0.,.22,actor.elapsed)
		tilt=-1.35*fall
		shift.y-=6*fall
	var cape:=sin(float(actor.stride)*.8)*3.
	local(Vector2(0,-77))
	plate([-12,-4,4,1,0,32,-10,63,-16,57,-28,64,-21,51,-33+cape,54,-21,20],cloth)
	stroke(-13,8,-25+cape,48,cloth.lightened(.18))
	var airborne: bool=actor.lift>3
	leg(Vector2(-6,-43),Vector2(-14-walk*11,-2-(12 if airborne else maxf(walk,0)*7)),false)
	leg(Vector2(6,-42),Vector2(12+walk*13,-2-(6 if airborne else maxf(-walk,0)*8)),true)
	local(Vector2(0,-67))
	plate([-17,-10,-7,-15,11,-13,18,-5,11,16,12,24,-12,24,-16,6],steel.darkened(.19))
	plate([-13,-8,-2,-11,13,-7,10,3,-2,9,-13,4],steel)
	stroke(-11,-7,0,-9,steel.lightened(.62),2)
	stroke(-11,7,-1,12,ink)
	for i in 3:
		stroke(-8+i*3,-5,-3+i*3,-1,steel.darkened(.28),.9)
		stroke(-4+i*3,-1,2+i*3,-5,steel.lightened(.25),.9)
	for y in [8,12]:
		stroke(-9,y,1,y+3,steel.lightened(.24),1.1)
		stroke(1,y+3,10,y-1,steel.darkened(.31),1.1)
	plate([-13,15,12,12,14,17,-13,21],Color("#594536"))
	plate([-3,15,4,14,4,19,-3,20],Color("#e5c687"))
	plate([-10,21,10,18,14,34,4,30,-3,37,-12,32],cloth)
	if actor.kind=="headsman":
		local(Vector2(0,-78))
		plate([-22,-3,-19,-16,-13,-10,-10,-22,-3,-9,5,-14,9,-4,4,3,-15,5],steel.darkened(.18))
		for j in 3:
			stroke(-12+j*6,-2,-16+j*6,19,steel.lightened(.25),1)
	local(Vector2(1,-93))
	if actor.kind=="cantor":
		draw_arc(Vector2(0,-5),23,-2.9,1.8,36,Color("#e4ce92"),2,true)
		for angle in [-2.9,-2.35,-1.8,-1.25,-.7]:
			var ray:=Vector2.from_angle(angle)
			draw_line(ray*23+Vector2(0,-5),ray*34+Vector2(0,-5),Color("#ded1aa"),2,true)
	if actor.kind in ["cultist","seer","cantor"]:
		plate([-14,15,-13,-3,-4,-16,9,-11,15,5,9,16,3,10,-4,9],cloth.lightened(.18))
		plate([-7,2,4,-7,10,-2,7,9,-4,11],ink)
	else:
		plate([-11,9,-12,-3,-6,-13,2,-16,12,-9,14,1,11,10,6,16,-4,14],steel.darkened(.10))
		plate([-11,-1,1,-4,14,-2,15,2,4,3,-3,7,-9,4],ink)
		plate([3,3,12,1,11,9,5,14,3,11],steel)
		stroke(-9,-5,0,-12,steel.lightened(.55),2)
		if actor.kind in ["warden","headsman"]:
			plate([-6,-11,-14,-20,-17,-30,-8,-24,1,-16,5,-14],steel.darkened(.20))
	stroke(3,1,10,-1,Color("#bffbf1") if actor.playable else Color("#ff9866"),2)
	local(Vector2(8,-77))
	plate([-13,-3,-6,-12,6,-13,15,-6,16,1,8,5,-9,5],steel)
	stroke(-7,-8,4,-11,steel.lightened(.57),2)
	stroke(-9,-2,3,1,steel.darkened(.30),1.4)
	stroke(3,1,13,-3,steel.lightened(.36),1.3)
	for rivet in [Vector2(-7,1),Vector2(8,1)]:
		draw_circle(rivet,1.4,steel.lightened(.49))
	if actor.kind=="warden":
		local(Vector2(-8,-70))
		plate([-7,0,1,-1,9,10,7,14,-2,10],steel.darkened(.24))
		stroke(7,12,17+reach,-54+70+sin(a)*7,cloth.lightened(.19),5)
	var hand:=Vector2(20+reach,-56+sin(a)*9)
	local(Vector2(0,0))
	stroke(10,-73,hand.x-7,hand.y+5,ink,10)
	stroke(10,-73,hand.x-7,hand.y+5,steel.darkened(.21),7)
	stroke(hand.x-7,hand.y+5,hand.x,hand.y,steel,8)
	local(hand,a)
	if actor.kind in ["cultist","seer","cantor"]:
		plate([-16,-2,49,-3,58,-1,48,2,-16,2],Color("#876e55"))
		plate([45,0,53,-12,63,-4,58,5,50,8],Color("#74c5bd"))
	elif actor.kind in ["headsman","brute"]:
		plate([-15,-3,56,-3,56,2,-15,3],Color("#78634c"))
		plate([38,-5,46,-12,49,-23,60,-13,64,0,59,14,46,21,48,8,39,5],steel)
	else:
		plate([-12,-3,9,-3,9,3,-12,3],Color("#72503e"))
		plate([7,-11,12,-8,14,7,8,11],steel)
		var tip:=67 if actor.kind=="warden" else (32 if actor.kind=="swift" else 44)
		plate([13,-4,tip-12,-5,tip,0,tip-14,5,13,4],Color("#c4d6d3"))
		stroke(15,1,tip-8,0,Color("#798e93"))
	if actor.kind=="swift":
		local(Vector2(-8+reach*.3,-60),-1.05-.35*sin(float(actor.stride)))
		plate([-6,-2,5,-2,7,-5,33,-4,42,-1,30,3,7,3,5,6,3,2,-6,2],Color("#c0cfcd"))
	if attacking and actor.move in ["cleave","special","quake"]:
		local(Vector2.ZERO)
		draw_arc(Vector2(12,-62),70.,-2.5+2.6*swing,-2.1+2.6*swing,12,Color(1,.68,.36,.47),3,true)
	if attacking and swing>.05 and swing<.97:
		local(hand)
		draw_arc(Vector2.ZERO,59.,a-.65,a+.28,18,Color(.96,.83,.58,.70),3,true)
	if attacking and not actor.playable and not actor.did_hit:
		local(Vector2(0,-122))
		plate([0,-6,4,0,0,6,-4,0],Color("#ffa66b"))


func draw_chime():
	var bronze:=Color("#bd9761")
	plate([-24,0,-27,-5,-19,-12,18,-12,27,-5,24,0],Color("#675c53"))
	plate([-17,-12,-12,-65,-7,-69,-8,-12],bronze)
	plate([10,-12,8,-69,14,-65,17,-12],bronze.darkened(.26))
	draw_arc(Vector2(1,-64),13,-PI,0,24,bronze,4,true)
	draw_line(Vector2(1,-76),Vector2(1,-57),bronze,2,true)
	plate([-12,-36,-7,-42,-6,-52,0,-57,7,-52,8,-42,14,-36],bronze)
	draw_circle(Vector2(1,-34),3,Color("#fae0ae"))
	draw_arc(Vector2(1,-47),22+sin(actor.stride)*2,-2.9,-.2,20,Color("#94c5c5"),1,true)
