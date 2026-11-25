extends Control
# 화면 위에 고정되는 정보 (왼쪽 위 패널, 메시지) + 미니맵

const MinimapScript := preload("res://scripts/minimap.gd")

var g
var mm
var img: Image
var tex: ImageTexture
var dirty := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	img = Image.create_empty(Def.GN, Def.GN, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	tex = ImageTexture.create_from_image(img)
	mm = MinimapScript.new()
	mm.g = g
	mm.hud = self
	add_child(mm)

func mark(i: int, j: int) -> void:
	img.set_pixel(i, j, Color("#2d4a3a"))
	dirty = true

func in_minimap(p: Vector2) -> bool:
	return mm != null and mm.get_global_rect().grow(4).has_point(p)

func _process(_dt: float) -> void:
	if dirty:
		tex.update(img)
		dirty = false
	queue_redraw()

func _draw() -> void:
	var f := ThemeDB.fallback_font
	var vs := get_viewport_rect().size
	# 왼쪽 위 패널
	draw_rect(Rect2(12, 12, 300, 66), Color(0.04, 0.055, 0.08, 0.82))
	draw_rect(Rect2(12, 12, 300, 66), Color("#c9a255"), false, 1.0)
	draw_string(f, Vector2(24, 40), "SOROK", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Def.GOLD)
	draw_string(f, Vector2(110, 38), "고도판 · 1단계", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#96aab9"))
	var s: Array = g.selected()
	var info := "선택 없음 · 로봇을 눌러 고르세요"
	if not s.is_empty():
		var cnt := {}
		for u in s:
			cnt[u.t] = cnt.get(u.t, 0) + 1
		var parts: Array = []
		for k in Def.ORDER:
			if cnt.has(k):
				parts.append(Def.T[k].n + " " + str(cnt[k]))
		info = "선택 · " + " · ".join(PackedStringArray(parts))
	draw_string(f, Vector2(24, 64), info, HORIZONTAL_ALIGNMENT_LEFT, 280, 14, Color("#e6edf3"))
	# 확대 비율
	var zt := str(roundi(g.zm * 100.0)) + "%"
	draw_string(f, Vector2(vs.x - 70, 30), zt, HORIZONTAL_ALIGNMENT_RIGHT, 56, 14, Color(0.81, 0.89, 1.0, 0.7))
	# 메시지
	if g.msg_t > 0.0:
		var a := minf(1.0, g.msg_t)
		var fs := 16
		var w := f.get_string_size(g.msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 36.0
		var y := vs.y - 64.0
		draw_rect(Rect2(vs.x / 2.0 - w / 2.0, y - 26, w, 38), Color(0.04, 0.055, 0.08, 0.85 * a))
		draw_string(f, Vector2(vs.x / 2.0 - w / 2.0 + 18, y), g.msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
