extends Node2D

const COVER_START_X = 1020.0
const COVER_STOP_X = 270.0
const COVER_TRAVEL = COVER_START_X - COVER_STOP_X

var font = preload("res://font.ttf")
var mode = "title"
var score = 0
var pose = -1
var target = 0
var distance = 0.0
var timer = 0.0
var phase = "move"
var paused = false
var ticks = 0.0
var keys = [KEY_A, KEY_S, KEY_W, KEY_D]
var names = ["A", "S", "W", "D"]
var art = {}

func _init():
	for file in DirAccess.get_files_at("res://assets"):
		if file.ends_with(".png"):
			var image = Image.load_from_file("res://assets/" + file)
			art[file.trim_suffix(".png")] = ImageTexture.create_from_image(image)

func picture(key, rect):
	draw_texture_rect(art[key], rect, false)

func start():
	score = 0
	pose = -1
	distance = 0
	timer = 0
	phase = "move"
	paused = false
	target = randi_range(0,3)
	mode = "play"

func caught():
	mode = "caught"
	phase = "look"
	timer = 0.65
	queue_redraw()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if mode == "play" and not paused and event.physical_keycode in keys:
			pose = keys.find(event.physical_keycode)
			if phase == "move" or pose != target:
				caught()
		if event.keycode == KEY_ESCAPE and mode == "play":
			paused = not paused
		if event.keycode in [KEY_ENTER, KEY_SPACE] and mode in ["title", "lost"]:
			start()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p = get_global_mouse_position()
		if mode in ["title", "lost"]:
			if Rect2(350,460,300,58).has_point(p): start()
			elif mode == "lost" and Rect2(350,530,300,45).has_point(p): mode = "title"
		elif mode == "play" and Rect2(920,20,60,50).has_point(p): paused = not paused

func _process(delta):
	ticks += delta
	if mode == "caught":
		timer -= delta
		if timer <= 0: mode = "lost"
	if mode == "play" and not paused:
		pose = -1
		for i in range(4):
			if Input.is_physical_key_pressed(keys[i]):
				pose = i
				if phase != "move" and i != target:
					caught()
					return
		if phase == "move":
			if pose == -1: distance += delta * 180
			if distance >= COVER_TRAVEL:
				distance = COVER_TRAVEL
				phase = "warning"
				timer = 1.15
		elif phase == "warning":
			timer -= delta
			if timer <= 0:
				phase = "look"
				timer = 1.1
		elif phase == "look":
			if pose != target:
				caught()
			else:
				timer -= delta
				if timer <= 0:
					score += 1
					phase = "move"
					distance = 0
					target = (target + randi_range(1,3)) % 4
	queue_redraw()

func label_at(s, p, size=24, color=Color("293a37")):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func center(s, y, size=24, color=Color("293a37")):
	label_at(s,Vector2((1000-font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)/2,y),size,color)

func cover(kind, origin, scale_factor=1.0):
	picture("숨는 물건 " + names[kind], Rect2(origin,Vector2(110,120)*scale_factor))

func snake(origin, kind=-1, scale_factor=1.0):
	if kind == -1:
		picture("이동하는 뱀",Rect2(origin+Vector2(0,40+sin(ticks*7)*2)*scale_factor,Vector2(160,50)*scale_factor))
	else:
		picture("변신하는 뱀 " + names[kind],Rect2(origin-Vector2(15,10)*scale_factor,Vector2(140,140)*scale_factor))

func button(text, rect):
	draw_style_box(panel(Color("355e4e")),rect)
	center(text,rect.position.y+38,23,Color.WHITE)

func panel(color):
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(14)
	return s

func _draw():
	picture("게임 배경",Rect2(0,0,1000,650))
	var watching = mode in ["play", "caught"] and phase == "look"
	if watching:
		draw_colored_polygon(PackedVector2Array([Vector2(770,230),Vector2(80,470),Vector2(920,470)]),Color(1,0.63,0.3,0.15))
	picture("주인 눈 뜸" if watching else "주인 눈 감음",Rect2(725,130,120,260))
	label_at("SCORE  %02d" % score,Vector2(30,48),25)
	picture("일시정지 버튼",Rect2(920,20,60,50))
	if mode in ["play", "caught"]:
		var x = COVER_START_X-distance
		cover(target,Vector2(x,320),1.15)
		if pose == -1: snake(Vector2(155,355))
		else: snake(Vector2(270,320),pose,1.15)
		for i in range(4):
			var bx = 245+i*135
			picture("하단 포즈카드 " + names[i] + (" 선택 상태" if pose == i else " 기본"),Rect2(bx,508,112,120))
		if paused:
			draw_rect(Rect2(0,0,1000,650),Color(0.1,0.15,0.13,0.75))
			center("일시정지",300,44,Color.WHITE)
			center("Esc 또는 Ⅱ 버튼으로 계속",350,22,Color.WHITE)
	else:
		draw_rect(Rect2(0,0,1000,650),Color("f3edde") if mode == "title" else Color(0.95,0.93,0.87,0.91))
		if mode == "title":
			center("탈출! 자유를 찾아서",210,48)
			snake(Vector2(380,270),-1,1.5)
			center("물건이 도착하면 같은 모양으로 숨으세요. 틀리면 잡혀요!",560,20)
			center("A  네모    S  ┌    W  └    D  일자 · 누르는 동안 멈춤",597,20)
			button("시작",Rect2(350,460,300,58))
		else:
			center("잡혀버렸어…",230,48)
			center("SCORE  %d" % score,320,40)
			center("몸 전체를 물건 모양에 맞춰 숨겨주세요",380,23)
			button("다시하기",Rect2(350,460,300,58))
			button("처음으로",Rect2(350,530,300,45))


