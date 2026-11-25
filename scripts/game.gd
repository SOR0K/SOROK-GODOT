extends Node2D
# ═══════════════════════════════════════════════════════════
#  SOROK — 고도판 (SOROMA GAMES)
#  1단계: 큰 맵 · 화면 이동/확대 · 선택 · 이동 명령 · 길찾기 · 시야 · 미니맵
#  파일 하나로 돌아가요: Node2D에 이 스크립트를 붙이고 실행하면 끝
# ═══════════════════════════════════════════════════════════

# ───────── 고정값 (웹 SOROK과 같은 숫자) ─────────
const MAPW := 5000          # 맵 크기 (px)
const CELL := 40            # 칸 크기
const GN := 125             # 한 줄 칸 수
const ZMIN := 0.6
const ZMAX := 1.8
const SCOUT_VIEW := 220.0
const BASE_VIEW := 280.0
const UT := {
	"s": {"n": "정찰", "c": 15, "hp": 20, "sp": 150.0, "col": Color("#f2d14e"), "acc": Color("#ffffff"), "z": 7.0},
	"m": {"n": "채굴", "c": 35, "hp": 30, "sp": 100.0, "col": Color("#f2a64e"), "acc": Color("#ffd9a8"), "z": 11.0},
	"c": {"n": "근접", "c": 40, "hp": 70, "sp": 90.0, "col": Color("#5aa0ff"), "acc": Color("#bcdcff"), "z": 12.0},
	"r": {"n": "원거리", "c": 55, "hp": 40, "sp": 85.0, "col": Color("#5fe0e6"), "acc": Color("#bff7fb"), "z": 9.0},
	"h": {"n": "지원", "c": 60, "hp": 45, "sp": 85.0, "col": Color("#8be28b"), "acc": Color("#10301c"), "z": 9.0},
}
const ORDER := ["s", "m", "c", "r", "h"]
const TN := [Color("#4a4234"), Color("#4e4537"), Color("#463f32"), Color("#524939")]
const FOG := Color("#070b0e")
const GOLD := Color("#ffd76a")

# ───────── 상태 ─────────
var ex := PackedByteArray()      # 밝혀진 칸 (1 = 밝혀짐)
var mines: Array = []            # {p, amt, ev}
var bots: Array = []             # {t, p, path, fa, sel}
var fx: Array = []               # 이동 명령 효과 {p, t}
var B := Vector2(200, MAPW - 200)
var t := 0.0
var zm := 1.0
var cam: Camera2D
var msg_text := ""
var msg_t := 0.0
var rng := RandomNumberGenerator.new()
var mm_img: Image
var mm_tex: ImageTexture
var mm_dirty := false

# 입력 상태
var dn = null
var mm_drag := false
var box_active := false
var box_a := Vector2.ZERO
var box_b := Vector2.ZERO
var touches := {}
var pinch = null
var last_tap := {"t": -9.0, "k": ""}

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	ex.resize(GN * GN)
	ex.fill(0)
	mm_img = Image.create_empty(GN, GN, false, Image.FORMAT_RGBA8)
	mm_img.fill(Color(0, 0, 0, 0))
	mm_tex = ImageTexture.create_from_image(mm_img)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	reveal(B, BASE_VIEW)
	_make_mines()
	_spawn_start()
	cam.position = B + Vector2(380, -180)
	_clamp_cam()
	msg("SOROK 고도판 1단계 · 드래그로 화면 이동 · 휠/두 손가락으로 확대")

# ───────── 맵 만들기 (웹과 같은 규칙) ─────────
func _make_mines() -> void:
	var w := float(MAPW)
	for p in [Vector2(430, w - 300), Vector2(300, w - 520), Vector2(580, w - 170), Vector2(760, w - 420), Vector2(520, w - 760), Vector2(900, w - 260)]:
		mines.append({"p": p, "amt": 700, "ev": false})
	var g := 0
	while mines.size() < 102 and g < 30000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		if p.distance_to(B) > 500 and _far_from_mines(p, 170):
			mines.append({"p": p, "amt": 700, "ev": false})
	var n := 0
	g = 0
	while n < 2 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		var d := p.distance_to(B)
		if d > 1100 and d < 1500 and _far_from_mines(p, 200):
			mines.append({"p": p, "amt": 150, "ev": true})
			n += 1
	n = 0
	g = 0
	while n < 8 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		if p.distance_to(B) > 1100 and _far_from_mines(p, 200):
			mines.append({"p": p, "amt": 150, "ev": true})
			n += 1

func _far_from_mines(p: Vector2, r: float) -> bool:
	for m in mines:
		if (m.p as Vector2).distance_to(p) <= r:
			return false
	return true

func _spawn_start() -> void:
	for k in ["s", "m", "m", "c", "c", "r", "h"]:
		var p := B + Vector2(rng.randf_range(60, 130), rng.randf_range(-110, 40))
		bots.append({"t": k, "p": p, "path": [], "fa": rng.randf_range(-PI, PI), "sel": false})

# ───────── 시야 ─────────
func cell_of(p: Vector2) -> int:
	return clampi(int(p.y / CELL), 0, GN - 1) * GN + clampi(int(p.x / CELL), 0, GN - 1)

func seen(p: Vector2) -> bool:
	return ex[cell_of(p)] == 1

func exa(i: int, j: int) -> bool:
	if i < 0 or j < 0 or i >= GN or j >= GN:
		return true
	return ex[j * GN + i] == 1

func reveal(p: Vector2, r: float) -> void:
	var j0 := maxi(0, int((p.y - r) / CELL))
	var j1 := mini(GN - 1, int((p.y + r) / CELL))
	var i0 := maxi(0, int((p.x - r) / CELL))
	var i1 := mini(GN - 1, int((p.x + r) / CELL))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var q := j * GN + i
			if ex[q] == 0 and Vector2(i * CELL + CELL / 2.0, j * CELL + CELL / 2.0).distance_to(p) <= r:
				ex[q] = 1
				mm_img.set_pixel(i, j, Color("#2d4a3a"))
				mm_dirty = true

func line_seen(a: Vector2, b: Vector2) -> bool:
	var n := ceili(a.distance_to(b) / 16.0)
	for i in range(1, n):
		if not seen(a.lerp(b, float(i) / n)):
			return false
	return true

# 밝혀진 칸으로만 다니는 길찾기 (8방향, 모서리 끼기 금지)
func find_path(s: Vector2, gl: Vector2):
	if not seen(gl):
		return null
	if line_seen(s, gl):
		return [gl]
	var N := GN * GN
	var prev := PackedInt32Array()
	prev.resize(N)
	prev.fill(-2)
	var q := PackedInt32Array()
	q.resize(N)
	var h := 0
	var tl := 0
	var s0 := cell_of(s)
	var gk := cell_of(gl)
	q[tl] = s0
	tl += 1
	prev[s0] = -1
	var D := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while h < tl:
		var c := q[h]
		h += 1
		if c == gk:
			break
		var ci := c % GN
		var cj := c / GN
		for d in D:
			var ni: int = ci + d.x
			var nj: int = cj + d.y
			if ni < 0 or nj < 0 or ni >= GN or nj >= GN:
				continue
			var nk := nj * GN + ni
			if prev[nk] != -2 or ex[nk] == 0:
				continue
			if d.x != 0 and d.y != 0 and (ex[cj * GN + ni] == 0 or ex[nj * GN + ci] == 0):
				continue
			prev[nk] = c
			q[tl] = nk
			tl += 1
	if prev[gk] == -2:
		return null
	var cells: Array = []
	var k := gk
	while k != -1 and k != s0:
		cells.push_front(k)
		k = prev[k]
	var pts: Array = []
	for c in cells:
		pts.append(Vector2((c % GN) * CELL + CELL / 2.0, (c / GN) * CELL + CELL / 2.0))
	if pts.is_empty():
		return [gl]
	pts[pts.size() - 1] = gl
	var out: Array = []
	var cur := s
	var idx := 0
	while idx < pts.size():
		var best := idx
		var j := mini(idx + 40, pts.size() - 1)
		while j > idx:
			if line_seen(cur, pts[j]):
				best = j
				break
			j -= 1
		out.append(pts[best])
		cur = pts[best]
		idx = best + 1
	return out

# ───────── 카메라 ─────────
func vsize() -> Vector2:
	return get_viewport_rect().size

func view_rect() -> Rect2:
	var vs := vsize() / zm
	return Rect2(cam.position - vs / 2.0, vs)

func s2w(sp: Vector2) -> Vector2:
	return cam.position + (sp - vsize() / 2.0) / zm

func _clamp_cam() -> void:
	var half := vsize() / zm / 2.0
	var w := float(MAPW)
	cam.position = Vector2(clampf(cam.position.x, half.x, w - half.x), clampf(cam.position.y, half.y, w - half.y))

func set_zoom(nz: float, anchor: Vector2) -> void:
	var wp := s2w(anchor)
	zm = clampf(snappedf(nz, 0.01), ZMIN, ZMAX)
	cam.zoom = Vector2(zm, zm)
	cam.position = wp - (anchor - vsize() / 2.0) / zm
	_clamp_cam()

func cam_to(wp: Vector2) -> void:
	cam.position = wp
	_clamp_cam()

# ───────── 미니맵 위치 ─────────
func mm_rect() -> Rect2:
	var vs := vsize()
	var ms := clampf(minf(vs.y * 0.34, vs.x * 0.22), 170.0, 320.0)
	return Rect2(vs - Vector2(ms, ms) - Vector2(12, 12), Vector2(ms, ms))

func mm_go(sp: Vector2) -> void:
	var r := mm_rect()
	cam_to((sp - r.position) / r.size.x * MAPW)

# ───────── 선택·명령 ─────────
func selected() -> Array:
	return bots.filter(func(u): return u.sel)

func clear_sel() -> void:
	for u in bots:
		u.sel = false

func unit_at(w: Vector2):
	var best = null
	var bd := 1e9
	for u in bots:
		var z: float = UT[u.t].z
		var d := (u.p as Vector2).distance_to(w)
		if d < z * 1.35 + 12.0 and d < bd:
			best = u
			bd = d
	return best

func click(w: Vector2, add: bool) -> void:
	var u = unit_at(w)
	if u != null:
		if last_tap.k == u.t and t - last_tap.t < 0.35:
			clear_sel()
			for q in bots:
				if q.t == u.t:
					q.sel = true
			msg(UT[u.t].n + " 로봇 전체 선택")
			last_tap = {"t": -9.0, "k": ""}
			return
		if add:
			u.sel = not u.sel
		else:
			clear_sel()
			u.sel = true
		last_tap = {"t": t, "k": u.t}
		return
	if w.distance_to(B) < 55.0:
		clear_sel()
		for q in bots:
			q.sel = true
		return
	var s := selected()
	if s.is_empty():
		return
	command_move(s, w)

func command_move(s: Array, w: Vector2) -> void:
	var n := s.size()
	var ok := 0
	var fail := 0
	var mw := float(MAPW)
	for k in n:
		var u = s[k]
		var off := Vector2.ZERO if n == 1 else Vector2.from_angle(TAU * k / float(n)) * (16.0 + 7.0 * sqrt(float(n)))
		var goal := (w + off).clamp(Vector2(10, 10), Vector2(mw - 10, mw - 10))
		if u.t == "s":
			u.path = [goal]
			ok += 1
			continue
		var p = find_path(u.p, goal)
		if p == null:
			p = find_path(u.p, w)
		if p == null:
			fail += 1
			continue
		u.path = p
		ok += 1
	if ok > 0:
		fx.append({"p": w, "t": 0.0})
	if fail > 0:
		msg("밝혀진 길이 없어서 갈 수 없어요 · 정찰 로봇으로 길을 먼저 밝혀 주세요")

func box_rect() -> Rect2:
	return Rect2(box_a, Vector2.ZERO).expand(box_b)

func finish_box(add: bool) -> void:
	var r := box_rect()
	if r.size.length() < 8.0:
		return
	var hit := bots.filter(func(u): return r.has_point(u.p))
	if hit.is_empty():
		return
	if not add:
		clear_sel()
	for u in hit:
		u.sel = true

func select_type(k: String) -> void:
	clear_sel()
	var n := 0
	for u in bots:
		if u.t == k:
			u.sel = true
			n += 1
	if n == 0:
		msg(UT[k].n + " 로봇이 없어요")

func msg(s: String) -> void:
	msg_text = s
	msg_t = 4.0

# ───────── 입력 ─────────
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch(e)
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zm + 0.1, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zm - 0.1, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mm_rect().has_point(mb.position):
					mm_drag = true
					mm_go(mb.position)
					return
				dn = {"s": mb.position, "c": cam.position, "m": false, "t0": t, "touch": false}
			else:
				mm_drag = false
				if dn != null:
					if not dn.m:
						click(s2w(mb.position), mb.shift_pressed)
					dn = null
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				box_active = true
				box_a = s2w(mb.position)
				box_b = box_a
			elif box_active:
				box_b = s2w(mb.position)
				finish_box(mb.shift_pressed)
				box_active = false
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if mm_drag:
			mm_go(mm.position)
			return
		if box_active:
			box_b = s2w(mm.position)
		if dn != null:
			var d: Vector2 = mm.position - dn.s
			if dn.m or d.length() > 8.0:
				dn.m = true
				cam.position = dn.c - d / zm
				_clamp_cam()
	elif e is InputEventKey:
		var ke := e as InputEventKey
		if not ke.pressed or ke.echo:
			return
		var kc: int = ke.keycode
		if kc >= KEY_1 and kc <= KEY_5:
			select_type(ORDER[kc - KEY_1])
		elif kc == KEY_SPACE or kc == KEY_HOME:
			cam_to(B)
		elif kc == KEY_ESCAPE:
			clear_sel()

func _touch(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		if st.pressed:
			if touches.is_empty() and mm_rect().grow(4).has_point(st.position):
				mm_drag = true
				mm_go(st.position)
				return
			touches[st.index] = st.position
			if touches.size() == 1:
				dn = {"s": st.position, "c": cam.position, "m": false, "t0": t, "touch": true}
				pinch = null
			elif touches.size() == 2:
				dn = null
				box_active = false
				var ps := touches.values()
				var a: Vector2 = ps[0]
				var b: Vector2 = ps[1]
				pinch = {"d0": maxf(a.distance_to(b), 1.0), "z0": zm, "m0": (a + b) / 2.0, "c0": cam.position}
		else:
			if mm_drag and touches.is_empty():
				mm_drag = false
				return
			if not touches.has(st.index):
				return
			touches.erase(st.index)
			if box_active and touches.is_empty():
				box_b = s2w(st.position)
				finish_box(false)
				box_active = false
			elif dn != null and not dn.m and touches.is_empty() and pinch == null:
				click(s2w(st.position), false)
			if touches.is_empty():
				dn = null
				pinch = null
			elif pinch != null:
				pinch = null
				var rest: Vector2 = touches.values()[0]
				dn = {"s": rest, "c": cam.position, "m": true, "t0": t, "touch": true}
	elif e is InputEventScreenDrag:
		var sd := e as InputEventScreenDrag
		if mm_drag and touches.is_empty():
			mm_go(sd.position)
			return
		if not touches.has(sd.index):
			return
		touches[sd.index] = sd.position
		if pinch != null and touches.size() >= 2:
			var ps := touches.values()
			var a: Vector2 = ps[0]
			var b: Vector2 = ps[1]
			var mid := (a + b) / 2.0
			var z0: float = pinch.z0
			var c0: Vector2 = pinch.c0
			var m0: Vector2 = pinch.m0
			var wp0 := c0 + (m0 - vsize() / 2.0) / z0
			zm = clampf(z0 * a.distance_to(b) / float(pinch.d0), ZMIN, ZMAX)
			cam.zoom = Vector2(zm, zm)
			cam.position = wp0 - (mid - vsize() / 2.0) / zm
			_clamp_cam()
		elif box_active:
			box_b = s2w(sd.position)
		elif dn != null:
			var d: Vector2 = sd.position - dn.s
			if dn.m or d.length() > 14.0:
				dn.m = true
				cam.position = dn.c - d / zm
				_clamp_cam()

# ───────── 매 프레임 ─────────
func _process(dt: float) -> void:
	t += dt
	msg_t = maxf(0.0, msg_t - dt)
	if dn != null and dn.touch and not dn.m and not box_active and t - dn.t0 > 0.45:
		box_active = true
		box_a = s2w(dn.s)
		box_b = box_a
		dn = null
		Input.vibrate_handheld(25)
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if v != Vector2.ZERO:
		cam.position += v.normalized() * 900.0 * dt / zm
		_clamp_cam()
	for u in bots:
		if u.path.is_empty():
			continue
		var tg: Vector2 = u.path[0]
		var d := tg - (u.p as Vector2)
		var step: float = UT[u.t].sp * dt
		if d.length() <= step:
			u.p = tg
			u.path.pop_front()
		else:
			u.p += d.normalized() * step
		if d.length() > 0.5:
			u.fa = lerp_angle(u.fa, d.angle(), minf(1.0, dt * 12.0))
		if u.t == "s":
			reveal(u.p, SCOUT_VIEW)
	for f in fx:
		f.t += dt
	fx = fx.filter(func(f): return f.t < 0.75)
	if mm_dirty:
		mm_tex.update(mm_img)
		mm_dirty = false
	queue_redraw()

# ═════════ 그리기 ═════════
func _draw() -> void:
	var vr: Rect2 = view_rect().grow(CELL)
	var i0 := maxi(0, int(vr.position.x / CELL))
	var j0 := maxi(0, int(vr.position.y / CELL))
	var i1 := mini(GN - 1, int(vr.end.x / CELL))
	var j1 := mini(GN - 1, int(vr.end.y / CELL))
	_ground(i0, j0, i1, j1)
	draw_arc(B, BASE_VIEW, 0.0, TAU, 128, Color(0.37, 0.88, 0.77, 0.2), 2.0)
	base(self, B, t)
	for m in mines:
		if vr.has_point(m.p) and seen(m.p):
			mine(self, m, t)
	for u in bots:
		if vr.has_point(u.p):
			_unit(u)
	for u in bots:
		if u.sel and not u.path.is_empty():
			draw_circle(u.path.back(), 2.5, Color(0.47, 1.0, 0.67, 0.35))
	if box_active:
		var r := box_rect()
		draw_rect(r, Color(0.55, 0.89, 0.55, 0.12))
		draw_rect(r, Color("#8be28b"), false, 1.0 / zm)
	_fx()
	_fog(i0, j0, i1, j1)
	# 여기부터는 화면에 고정 (카메라 영향 안 받음)
	draw_set_transform_matrix(get_canvas_transform().affine_inverse())
	_minimap()
	_hud()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _ground(i0: int, j0: int, i1: int, j1: int) -> void:
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var h: int = ((i * 73856093) ^ (j * 19349663)) & 0xFFFFFFFF
			draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), TN[h % 4])
			var a := i * CELL + (h >> 2) % 30 + 4
			var b := j * CELL + (h >> 6) % 30 + 4
			if h % 11 == 0:
				ell_fill(self, Vector2(a + 2, b + 3), 9, 5, Color(0, 0, 0, 0.18))
				ell_fill(self, Vector2(a, b), 8, 5, Color("#625846"))
				draw_rect(Rect2(a - 4, b - 3, 5, 2), Color("#7a6f5a"))
			elif h % 13 == 1:
				draw_polyline(PackedVector2Array([Vector2(a, b), Vector2(a + 10, b + 4), Vector2(a + 16, b + 1)]), Color(0, 0, 0, 0.22), 1.0)
			elif h % 7 == 2:
				draw_rect(Rect2(a, b, 2, 5), Color(0.47, 0.55, 0.31, 0.35))
				draw_rect(Rect2(a + 4, b + 1, 2, 4), Color(0.47, 0.55, 0.31, 0.35))

func _unit(u: Dictionary) -> void:
	var d: Dictionary = UT[u.t]
	var z: float = d.z
	var p: Vector2 = u.p
	ell_fill(self, p + Vector2(0, z + 2), z + 3, 4, Color(0, 0, 0, 0.3))
	if u.sel:
		ell_line(self, p + Vector2(0, z + 1), z + 6, z / 2.0 + 4.0, Color("#d9ffd0"), 1.5)
	draw_set_transform(p, u.fa, Vector2(1.35, 1.35))
	bot(self, u.t, d.col, d.acc, t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fx() -> void:
	for f in fx:
		var k: float = f.t / 0.75
		var al := maxf(0.0, 1.0 - k)
		var X: Vector2 = f.p
		var ins := minf(1.0, k * 2.6)
		var r1 := 46.0 - 32.0 * ins
		for i in 4:
			var a := PI / 4.0 + i * PI / 2.0
			draw_set_transform(X + Vector2(cos(a), sin(a)) * r1, a + PI, Vector2.ONE)
			poly(self, [Vector2(11, 0), Vector2(-6, -9), Vector2(-2, 0), Vector2(-6, 9)], Color(0.43, 1.0, 0.63, al))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ell_line(self, X, 8 + 34 * k, (8 + 34 * k) * 0.55, Color(0.43, 1.0, 0.63, al * 0.9), 2.2)
		ell_line(self, X, 6 + 14 * k, (6 + 14 * k) * 0.55, Color(0.43, 1.0, 0.63, al * 0.9), 2.2)
		if k < 0.35:
			draw_circle(X, 5, Color(1, 1, 1, (1.0 - k / 0.35) * 0.85))

func _fog(i0: int, j0: int, i1: int, j1: int) -> void:
	var edge := Color(FOG, 0.4)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			if not exa(i, j):
				draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), FOG)
			elif not (exa(i - 1, j) and exa(i + 1, j) and exa(i, j - 1) and exa(i, j + 1)):
				draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), edge)

func _minimap() -> void:
	var r := mm_rect()
	var o := r.position
	var sz := r.size
	draw_rect(Rect2(o - Vector2(3, 3), sz + Vector2(6, 6)), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(o, sz), Color(0.02, 0.03, 0.05, 0.93))
	draw_texture_rect(mm_tex, Rect2(o, sz), false)
	var k := sz.x / MAPW
	for m in mines:
		if m.amt > 0 and seen(m.p):
			draw_rect(Rect2(o + (m.p as Vector2) * k - Vector2(1.2, 1.2), Vector2(2.5, 2.5)), Color("#c08cff") if m.ev else Color("#5fe0c4"))
	var bp := o + B * k
	draw_rect(Rect2(bp - Vector2(4, 4), Vector2(8, 8)), Color("#4a86c8"))
	draw_rect(Rect2(bp - Vector2(4, 4), Vector2(8, 8)), Color("#d6ecff"), false, 1.0)
	for u in bots:
		var p: Vector2 = o + (u.p as Vector2) * k
		var rr := 2.2 if (u.t == "m" or u.t == "s") else 2.8
		draw_circle(p, rr + 1.2, Color("#03121a"))
		var c := Color("#6ff3ff")
		if u.sel:
			c = Color("#ffe066")
		elif u.t == "m":
			c = Color("#ffc27a")
		elif u.t == "s":
			c = Color("#fff3a0")
		draw_circle(p, rr, c)
	var vr := view_rect()
	draw_rect(Rect2(o + vr.position * k, vr.size * k), Color(1, 1, 1, 0.65), false, 1.0)

func _hud() -> void:
	var f := ThemeDB.fallback_font
	var vs := vsize()
	draw_rect(Rect2(12, 12, 300, 66), Color(0.04, 0.055, 0.08, 0.82))
	draw_rect(Rect2(12, 12, 300, 66), Color("#c9a255"), false, 1.0)
	draw_string(f, Vector2(24, 40), "SOROK", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	draw_string(f, Vector2(112, 38), "고도판 · 1단계", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#96aab9"))
	var s := selected()
	var info := "선택 없음 · 로봇을 눌러 고르세요"
	if not s.is_empty():
		var cnt := {}
		for u in s:
			cnt[u.t] = cnt.get(u.t, 0) + 1
		var parts := PackedStringArray()
		for k in ORDER:
			if cnt.has(k):
				parts.append(str(UT[k].n) + " " + str(cnt[k]))
		info = "선택 · " + " · ".join(parts)
	draw_string(f, Vector2(24, 64), info, HORIZONTAL_ALIGNMENT_LEFT, 280, 14, Color("#e6edf3"))
	draw_string(f, Vector2(vs.x - 70, 30), str(roundi(zm * 100.0)) + "%", HORIZONTAL_ALIGNMENT_RIGHT, 56, 14, Color(0.81, 0.89, 1.0, 0.7))
	if msg_t > 0.0:
		var a := minf(1.0, msg_t)
		var fs := 16
		var w := f.get_string_size(msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 36.0
		var y := vs.y - 64.0
		draw_rect(Rect2(vs.x / 2.0 - w / 2.0, y - 26, w, 38), Color(0.04, 0.055, 0.08, 0.85 * a))
		draw_string(f, Vector2(vs.x / 2.0 - w / 2.0 + 18, y), msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))

# ═════════ 웹 SOROK 그림 (기지·로봇·광산) ═════════
const K := Color("#0b1118")
const PL := Color("#232b33")
const RIM := Color("#4b5966")
const BD := Color("#38434d")
const TP := Color("#5a6a78")
const GL := Color("#5fe0c4")
const LT := Color("#d9a441")

func ell(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / float(n)
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p

func ell_fill(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	ci.draw_colored_polygon(ell(c, rx, ry), col)

func ell_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float = 1.5) -> void:
	var p := ell(c, rx, ry)
	p.append(p[0])
	ci.draw_polyline(p, col, w, true)

func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), col)

func oct(r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 8:
		var a := PI / 8.0 + i * PI / 4.0
		p.append(Vector2(cos(a), sin(a)) * r)
	return p

func base(ci: CanvasItem, p: Vector2, t: float) -> void:
	ell_fill(ci, p + Vector2(6, 40), 58, 18, Color(0, 0, 0, 0.32))
	ci.draw_set_transform(p, 0.0, Vector2.ONE)
	var o := oct(54)
	ci.draw_colored_polygon(o, PL)
	o.append(o[0])
	ci.draw_polyline(o, RIM, 3.0, true)
	var o2 := oct(44)
	o2.append(o2[0])
	ci.draw_polyline(o2, Color(1, 1, 1, 0.1), 1.0, true)
	for i in 4:
		ci.draw_set_transform(p, i * PI / 2.0, Vector2.ONE)
		ci.draw_rect(Rect2(-8, -50, 16, 3), Color(LT, 0.55))
	ci.draw_set_transform(p, 0.0, Vector2.ONE)
	ci.draw_rect(Rect2(-25, -19, 56, 46), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(-28, -22, 56, 44), BD)
	ci.draw_rect(Rect2(-18, -32, 36, 64), BD)
	ci.draw_rect(Rect2(-28, -22, 56, 5), TP)
	ci.draw_rect(Rect2(-18, -32, 36, 5), TP)
	ci.draw_rect(Rect2(-24, 8, 48, 6), Color(0, 0, 0, 0.45))
	for i in 6:
		var on := int(t * 2 + i) % 3 != 0
		ci.draw_rect(Rect2(-22 + i * 8, 9, 5, 4), Color(GL, 0.85) if on else Color(1, 1, 1, 0.15))
	var pu := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_circle(Vector2(0, -6), 21, Color(GL, 0.25 * pu))
	ci.draw_circle(Vector2(0, -6), 13, K)
	ci.draw_circle(Vector2(0, -6), 10, GL)
	ci.draw_circle(Vector2(-3, -9), 3.5, Color(1, 1, 1, 0.55))
	ci.draw_line(Vector2(-20, -27), Vector2(-20, -42), RIM, 2.0)
	ci.draw_circle(Vector2(-20, -43), 2.5, LT if int(t * 1.5) % 2 == 1 else Color("#3a2a10"))
	ci.draw_set_transform(p + Vector2(20, -25), t * 1.6, Vector2.ONE)
	ci.draw_arc(Vector2.ZERO, 7, -0.9, 0.9, 12, TP, 2.0)
	ci.draw_line(Vector2.ZERO, Vector2(7, 0), TP, 2.0)
	ci.draw_rect(Rect2(-2, -2, 4, 4), K)
	ci.draw_set_transform(p, 0.0, Vector2.ONE)
	var corners := [Vector2(-46, -19), Vector2(46, -19), Vector2(-46, 19), Vector2(46, 19)]
	for i in 4:
		var c: Vector2 = corners[i]
		ci.draw_rect(Rect2(c.x - 4, c.y - 4, 8, 8), K)
		ci.draw_rect(Rect2(c.x - 2, c.y - 2, 4, 4), LT if int(t * 2 + i * 0.5) % 2 == 1 else Color(0, 0, 0, 0.4))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func mine(ci: CanvasItem, m: Dictionary, t: float) -> void:
	var p: Vector2 = m.p
	var ev: bool = m.ev
	var on: bool = m.amt > 0
	ell_fill(ci, p + Vector2(0, 12), 18, 7, Color(0, 0, 0, 0.28))
	if on:
		var gc := Color(0.67, 0.43, 1.0, 0.16) if ev else Color(0.37, 0.88, 0.77, 0.14)
		ci.draw_circle(p, 28, Color(gc, gc.a + 0.04 * sin(t * 2.0 + p.x)))
	var c1 := Color("#47504d")
	var c2 := Color("#6a746f")
	if on:
		c1 = Color("#8a4fd0") if ev else Color("#2fa88f")
		c2 = Color("#d2a8ff") if ev else Color("#8ff3dd")
	for c in [[-10.0, 6.0, 0.7], [10.0, 5.0, 0.6], [0.0, 0.0, 1.0]]:
		var px: float = p.x + c[0]
		var py: float = p.y + c[1]
		var h: float = 22.0 * c[2]
		var w: float = 9.0 * c[2]
		poly(ci, [Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py + h * 0.35), Vector2(px - w, py)], c1)
		poly(ci, [Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py)], c2)

# 로봇 모양 (원점 기준, 오른쪽이 앞)
func bot(ci: CanvasItem, k: String, col: Color, acc: Color, t: float) -> void:
	match k:
		"s":
			poly(ci, [Vector2(8, 0), Vector2(-5, -6), Vector2(-3, 0), Vector2(-5, 6)], K)
			poly(ci, [Vector2(6, 0), Vector2(-4, -4), Vector2(-2, 0), Vector2(-4, 4)], col)
			ci.draw_rect(Rect2(2, -1, 2, 2), acc)
		"m":
			ci.draw_rect(Rect2(-10, -8, 20, 16), K)
			ci.draw_rect(Rect2(-9, -7, 14, 14), col)
			ci.draw_rect(Rect2(-7, -5, 5, 10), acc)
			poly(ci, [Vector2(5, -6), Vector2(14, 0), Vector2(5, 6)], Color("#9aa6b2"))
		"c":
			poly(ci, [Vector2(11, 0), Vector2(5, -10), Vector2(-8, -9), Vector2(-11, 0), Vector2(-8, 9), Vector2(5, 10)], K)
			poly(ci, [Vector2(9, 0), Vector2(4, -8), Vector2(-7, -7), Vector2(-9, 0), Vector2(-7, 7), Vector2(4, 8)], col)
			ci.draw_rect(Rect2(-6, -8, 5, 16), Color(0, 0, 0, 0.3))
			ci.draw_rect(Rect2(3, -5, 4, 10), acc)
		"r":
			ci.draw_rect(Rect2(-8, -8, 16, 16), K)
			ci.draw_rect(Rect2(-7, -7, 14, 14), col)
			ci.draw_rect(Rect2(-5, -5, 7, 10), Color(0, 0, 0, 0.3))
			ci.draw_rect(Rect2(2, -2, 14, 4), K)
			ci.draw_rect(Rect2(13, -2, 3, 4), acc)
		_:
			ci.draw_circle(Vector2.ZERO, 9, K)
			ci.draw_circle(Vector2.ZERO, 7.5, col)
			ci.draw_rect(Rect2(-1, -5, 2, 10), acc)
			ci.draw_rect(Rect2(-5, -1, 10, 2), acc)
	if k != "s" and k != "h":
		ci.draw_rect(Rect2(-6, -7, 9, 2), Color(1, 1, 1, 0.26))
	if k == "c" or k == "r":
		ci.draw_rect(Rect2(6 if k == "c" else 10, -1.5, 3, 3), Color(0.84, 0.98, 1.0, 0.55 + 0.45 * sin(t * 3.0)))
	if k == "h":
		ci.draw_arc(Vector2.ZERO, 5.5, 3.6, 5.2, 8, Color(1, 1, 1, 0.35), 1.0)
