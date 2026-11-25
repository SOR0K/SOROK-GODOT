extends Control
# 미니맵: 밝혀진 곳·광산·기지·로봇·지금 보는 화면. 누르거나 끌면 그 위치로 이동

var g
var hud

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_dt: float) -> void:
	var vs := get_viewport_rect().size
	var ms := clampf(minf(vs.y * 0.34, vs.x * 0.22), 170.0, 320.0)
	size = Vector2(ms, ms)
	position = vs - size - Vector2(12, 12)
	queue_redraw()

func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2(-3, -3), sz + Vector2(6, 6)), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.03, 0.05, 0.93))
	draw_texture_rect(hud.tex, Rect2(Vector2.ZERO, sz), false)
	var k := sz.x / Def.W
	for m in g.mines:
		if m.amt > 0 and g.seen(m.p):
			draw_rect(Rect2((m.p as Vector2) * k - Vector2(1.2, 1.2), Vector2(2.5, 2.5)), Color("#c08cff") if m.ev else Color("#5fe0c4"))
	var bp: Vector2 = (g.B as Vector2) * k
	draw_rect(Rect2(bp - Vector2(4, 4), Vector2(8, 8)), Color("#4a86c8"))
	draw_rect(Rect2(bp - Vector2(4, 4), Vector2(8, 8)), Color("#d6ecff"), false, 1.0)
	for u in g.bots:
		var p: Vector2 = (u.p as Vector2) * k
		var r := 2.2 if (u.t == "m" or u.t == "s") else 2.8
		draw_circle(p, r + 1.2, Color("#03121a"))
		var c := Color("#6ff3ff")
		if u.sel:
			c = Color("#ffe066")
		elif u.t == "m":
			c = Color("#ffc27a")
		elif u.t == "s":
			c = Color("#fff3a0")
		draw_circle(p, r, c)
	var vr: Rect2 = g.view_rect()
	draw_rect(Rect2(vr.position * k, vr.size * k), Color(1, 1, 1, 0.65), false, 1.0)

func _gui_input(e: InputEvent) -> void:
	var p := Vector2(-1, -1)
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			p = mb.position
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			p = mm.position
	if p.x >= 0.0:
		g.cam_to(p / size.x * Def.W)
		accept_event()
