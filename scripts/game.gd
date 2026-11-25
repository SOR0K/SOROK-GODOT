extends Node2D
# SOROK 고도판 — 게임 본체 (상태·입력·카메라·이동·시야)
# 1단계: 큰 맵, 화면 이동/확대, 선택(터치·클릭·드래그 상자), 이동 명령, 길찾기, 시야, 미니맵

const WorldScript := preload("res://scripts/world.gd")
const HudScript := preload("res://scripts/hud.gd")

var ex := PackedByteArray()      # 밝혀진 칸 (1 = 밝혀짐)
var mines: Array = []            # {p, amt, ev}
var bots: Array = []             # {t, p, path, fa, sel}
var fx: Array = []               # 이동 명령 효과 {p, t}
var B := Vector2(200, Def.W - 200)
var t := 0.0
var zm := 1.0
var cam: Camera2D
var world
var hud
var msg_text := ""
var msg_t := 0.0
var rng := RandomNumberGenerator.new()

# 입력 상태
var dn = null                    # 누르기 시작 {s, c, m, t0, touch}
var box_active := false
var box_a := Vector2.ZERO
var box_b := Vector2.ZERO
var touches := {}
var pinch = null
var last_tap := {"t": -9.0, "k": ""}

func _ready() -> void:
	rng.randomize()
	ex.resize(Def.GN * Def.GN)
	ex.fill(0)
	world = WorldScript.new()
	world.g = self
	add_child(world)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HudScript.new()
	hud.g = self
	layer.add_child(hud)
	reveal(B, Def.BASE_VIEW)
	_make_mines()
	_spawn_start()
	cam.position = B + Vector2(380, -180)
	_clamp_cam()
	msg("SOROK 고도판 1단계 · 드래그로 화면 이동 · 휠/두 손가락으로 확대")

# ───────── 맵 만들기 (웹과 같은 규칙) ─────────
func _make_mines() -> void:
	var W := float(Def.W)
	for p in [Vector2(430, W - 300), Vector2(300, W - 520), Vector2(580, W - 170), Vector2(760, W - 420), Vector2(520, W - 760), Vector2(900, W - 260)]:
		mines.append({"p": p, "amt": 700, "ev": false})
	var g := 0
	while mines.size() < 102 and g < 30000:
		g += 1
		var p := Vector2(rng.randf_range(100, W - 100), rng.randf_range(100, W - 100))
		if p.distance_to(B) > 500 and _far_from_mines(p, 170):
			mines.append({"p": p, "amt": 700, "ev": false})
	var n := 0
	g = 0
	while n < 2 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, W - 100), rng.randf_range(100, W - 100))
		var d := p.distance_to(B)
		if d > 1100 and d < 1500 and _far_from_mines(p, 200):
			mines.append({"p": p, "amt": 150, "ev": true})
			n += 1
	n = 0
	g = 0
	while n < 8 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, W - 100), rng.randf_range(100, W - 100))
		if p.distance_to(B) > 1100 and _far_from_mines(p, 200):
			mines.append({"p": p, "amt": 150, "ev": true})
			n += 1

func _far_from_mines(p: Vector2, r: float) -> bool:
	for m in mines:
		if (m.p as Vector2).distance_to(p) <= r:
			return false
	return true

func _spawn_start() -> void:
	# 1단계 테스트용: 종류별 로봇 몇 대
	for k in ["s", "m", "m", "c", "c", "r", "h"]:
		var p := B + Vector2(rng.randf_range(60, 130), rng.randf_range(-110, 40))
		bots.append({"t": k, "p": p, "path": [], "fa": rng.randf_range(-PI, PI), "sel": false})

# ───────── 시야 ─────────
func cell_of(p: Vector2) -> int:
	return clampi(int(p.y / Def.G), 0, Def.GN - 1) * Def.GN + clampi(int(p.x / Def.G), 0, Def.GN - 1)

func seen(p: Vector2) -> bool:
	return ex[cell_of(p)] == 1

func exa(i: int, j: int) -> bool:
	if i < 0 or j < 0 or i >= Def.GN or j >= Def.GN:
		return true
	return ex[j * Def.GN + i] == 1

func reveal(p: Vector2, r: float) -> void:
	var G := Def.G
	var j0 := maxi(0, int((p.y - r) / G))
	var j1 := mini(Def.GN - 1, int((p.y + r) / G))
	var i0 := maxi(0, int((p.x - r) / G))
	var i1 := mini(Def.GN - 1, int((p.x + r) / G))
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var q := j * Def.GN + i
			if ex[q] == 0 and Vector2(i * G + G / 2.0, j * G + G / 2.0).distance_to(p) <= r:
				ex[q] = 1
				if hud:
					hud.mark(i, j)

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
	var N := Def.GN * Def.GN
	var GN := Def.GN
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
		pts.append(Vector2((c % GN) * Def.G + Def.G / 2.0, (c / GN) * Def.G + Def.G / 2.0))
	if pts.is_empty():
		return [gl]
	pts[pts.size() - 1] = gl
	# 직선으로 갈 수 있는 곳은 건너뛰기
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
	var W := float(Def.W)
	cam.position = Vector2(clampf(cam.position.x, half.x, W - half.x), clampf(cam.position.y, half.y, W - half.y))

func set_zoom(nz: float, anchor: Vector2) -> void:
	var wp := s2w(anchor)
	zm = clampf(snappedf(nz, 0.01), Def.ZMIN, Def.ZMAX)
	cam.zoom = Vector2(zm, zm)
	cam.position = wp - (anchor - vsize() / 2.0) / zm
	_clamp_cam()

func cam_to(wp: Vector2) -> void:
	cam.position = wp
	_clamp_cam()

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
		var z: float = Def.T[u.t].z
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
			msg(Def.T[u.t].n + " 로봇 전체 선택")
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
	var W := float(Def.W)
	for k in n:
		var u = s[k]
		var off := Vector2.ZERO if n == 1 else Vector2.from_angle(TAU * k / float(n)) * (16.0 + 7.0 * sqrt(float(n)))
		var goal := (w + off).clamp(Vector2(10, 10), Vector2(W - 10, W - 10))
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
		msg(Def.T[k].n + " 로봇이 없어요")

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
				dn = {"s": mb.position, "c": cam.position, "m": false, "t0": t, "touch": false}
			elif dn != null:
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
			select_type(Def.ORDER[kc - KEY_1])
		elif kc == KEY_SPACE or kc == KEY_HOME:
			cam_to(B)
		elif kc == KEY_ESCAPE:
			clear_sel()

func _touch(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		if st.pressed:
			if touches.is_empty() and hud.in_minimap(st.position):
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
				# 두 손가락 중 하나를 떼면 남은 손가락으로 계속 이동
				pinch = null
				var rest: Vector2 = touches.values()[0]
				dn = {"s": rest, "c": cam.position, "m": true, "t0": t, "touch": true}
	elif e is InputEventScreenDrag:
		var sd := e as InputEventScreenDrag
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
			zm = clampf(z0 * a.distance_to(b) / float(pinch.d0), Def.ZMIN, Def.ZMAX)
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
	# 터치로 꾹 누르면 상자 선택 시작
	if dn != null and dn.touch and not dn.m and not box_active and t - dn.t0 > 0.45:
		box_active = true
		box_a = s2w(dn.s)
		box_b = box_a
		dn = null
		Input.vibrate_handheld(25)
	# 키보드로 화면 이동 (WASD / 방향키)
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
	# 로봇 이동
	for u in bots:
		if u.path.is_empty():
			continue
		var tg: Vector2 = u.path[0]
		var d := tg - (u.p as Vector2)
		var step: float = Def.T[u.t].sp * dt
		if d.length() <= step:
			u.p = tg
			u.path.pop_front()
		else:
			u.p += d.normalized() * step
		if d.length() > 0.5:
			u.fa = lerp_angle(u.fa, d.angle(), minf(1.0, dt * 12.0))
		if u.t == "s":
			reveal(u.p, Def.SCOUT_VIEW)
	for f in fx:
		f.t += dt
	fx = fx.filter(func(f): return f.t < 0.75)
