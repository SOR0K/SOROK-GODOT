extends Node2D
# ═══════════════════════════════════════════════════════════
#  SOROK — 고도판 (SOROMA GAMES)
#  2단계: 생산 · 채굴 · 적 기지 · 전투 · 정복 · 레이드 · 부활 · 업그레이드 · 진화
#  파일 하나로 돌아가요: Node2D에 이 스크립트를 붙이고 실행하면 끝
# ═══════════════════════════════════════════════════════════

# ───────── 고정값 (웹 SOROK과 같은 숫자) ─────────
const MAPW := 5000
const CELL := 40
const GN := 125
const ZMIN := 0.6
const ZMAX := 1.8
const BASE_VIEW := 280.0
const WELL := 300.0
const UT := {
	"s": {"n": "정찰", "c": 15, "hp": 20.0, "atk": 0.0, "rng": 0.0, "sp": 150.0, "col": Color("#f2d14e"), "acc": Color("#ffffff"), "z": 7.0},
	"m": {"n": "채굴", "c": 35, "hp": 30.0, "atk": 0.0, "rng": 0.0, "sp": 100.0, "col": Color("#f2a64e"), "acc": Color("#ffd9a8"), "z": 11.0},
	"c": {"n": "근접", "c": 40, "hp": 70.0, "atk": 7.0, "rng": 30.0, "sp": 90.0, "col": Color("#5aa0ff"), "acc": Color("#bcdcff"), "z": 12.0},
	"r": {"n": "원거리", "c": 55, "hp": 40.0, "atk": 8.0, "rng": 150.0, "sp": 85.0, "col": Color("#5fe0e6"), "acc": Color("#bff7fb"), "z": 9.0},
	"h": {"n": "지원", "c": 60, "hp": 45.0, "atk": 0.0, "rng": 150.0, "sp": 85.0, "col": Color("#8be28b"), "acc": Color("#10301c"), "z": 9.0},
}
const ORDER := ["s", "m", "c", "r", "h"]
const CAP := {"s": 3, "m": 15, "c": 40, "r": 40, "h": 40}
const EVC := [11, 22, 33]
const DF := {"h": 1.0, "a": 1.0, "n": 1.0, "p": 1.15, "e": 3}
const TN := [Color("#4a4234"), Color("#4e4537"), Color("#463f32"), Color("#524939")]
const FOG := Color("#070b0e")
const GOLD := Color("#ffd76a")
const PANEL := Color(0.04, 0.055, 0.08, 0.86)

# ───────── 상태 ─────────
var ex := PackedByteArray()
var mines: Array = []
var outs: Array = []
var bots: Array = []
var ens: Array = []
var prs: Array = []
var fx: Array = []
var dead: Array = []
var B := Vector2(200, MAPW - 200)
var base := {}
var ore := 70.0
var stone := 0
var t := 0.0
var won := false
var lost := false
var next_raid := 0.0
var raid_warned := false
var raid_alive := false
var kills := 0
var lost_n := 0
var uid := 0
var sell_arm := 0.0
var zm := 1.0
var cam: Camera2D
var msg_text := ""
var msg_t := 0.0
var rng := RandomNumberGenerator.new()
var mm_img: Image
var mm_tex: ImageTexture
var mm_dirty := false
var inv := Transform2D.IDENTITY
var sb_btn: StyleBoxFlat
var sb_dis: StyleBoxFlat
var sb_panel: StyleBoxFlat

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
	sb_btn = _sb(Color(0.08, 0.11, 0.15, 0.94), Color("#c9a255"))
	sb_dis = _sb(Color(0.06, 0.07, 0.09, 0.85), Color(0.3, 0.34, 0.4))
	sb_panel = _sb(PANEL, Color(0.79, 0.64, 0.33, 0.7))
	rng.randomize()
	RenderingServer.set_default_clear_color(FOG)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	new_game()
	if OS.get_cmdline_user_args().has("--selftest"):
		_selftest()

func _sb(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	return s

# ═════════ 새 게임 (웹 reset과 같은 규칙) ═════════
func new_game() -> void:
	ex.resize(GN * GN)
	ex.fill(0)
	mm_img = Image.create_empty(GN, GN, false, Image.FORMAT_RGBA8)
	mm_img.fill(Color(0, 0, 0, 0))
	mm_tex = ImageTexture.create_from_image(mm_img)
	mines.clear()
	outs.clear()
	bots.clear()
	ens.clear()
	prs.clear()
	fx.clear()
	dead.clear()
	ore = 70.0
	stone = 0
	t = 0.0
	won = false
	lost = false
	kills = 0
	lost_n = 0
	base = {"id": 0, "team": 0, "base": true, "p": B, "hp": 1500.0, "mh": 1500.0, "rng": 280.0, "cd": 0.0, "cbt": -99.0, "fa": 0.0}
	reveal(B, BASE_VIEW)
	var w := float(MAPW)
	for p in [Vector2(430, w - 300), Vector2(300, w - 520), Vector2(580, w - 170), Vector2(760, w - 420), Vector2(520, w - 760), Vector2(900, w - 260)]:
		mines.append({"p": p, "amt": 700, "ev": false, "safe": false})
	var g := 0
	while mines.size() < 102 and g < 30000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		if p.distance_to(B) > 500 and _far(mines, p, 170):
			mines.append({"p": p, "amt": 700, "ev": false, "safe": false})
	var n := 0
	g = 0
	while n < 2 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		var d := p.distance_to(B)
		if d > 1100 and d < 1500 and _far(mines, p, 200):
			mines.append({"p": p, "amt": 150, "ev": true, "safe": true})
			n += 1
	n = 0
	g = 0
	while n < 8 and g < 5000:
		g += 1
		var p := Vector2(rng.randf_range(100, w - 100), rng.randf_range(100, w - 100))
		if p.distance_to(B) > 1100 and _far(mines, p, 200):
			mines.append({"p": p, "amt": 150, "ev": true, "safe": false})
			n += 1
	# 적 기지 50곳
	g = 0
	while outs.size() < 50 and g < 30000:
		g += 1
		var p := Vector2(rng.randf_range(150, w - 150), rng.randf_range(150, w - 150))
		var d := p.distance_to(B)
		if d > 800 and _far(outs, p, 380) and _far_mines_out(p):
			uid += 1
			outs.append({"id": uid, "op": true, "team": 1, "p": p, "d": d})
	var ds: Array = outs.map(func(o): return o.d)
	ds.sort()
	ds.reverse()
	var md: float = ds[mini(2, ds.size() - 1)] if ds.size() > 0 else 2000.0
	for o in outs:
		var dn_: float = clampf((o.d - 800.0) / maxf(md - 800.0, 1.0), 0.0, 1.0)
		var tr: int = mini(6, int(dn_ * 7.0))
		var lv: int = 11 if tr >= 6 else clampi(roundi(1.0 + 10.0 * pow(dn_, DF.p)), 1, 11)
		var ev: int = 0
		if tr >= DF.e:
			ev = 3 if tr >= 6 else (2 if tr >= 5 else 1)
		var hpv: float = (130.0 + 1100.0 * dn_ * dn_) * DF.h
		o.merge({"s": 0.5 + 8.0 * dn_, "dn": dn_, "tr": tr, "lv": lv, "ev": ev, "mx": hpv, "hp": hpv, "atk": (4.0 + 10.0 * dn_) * DF.a,
			"cap": false, "al": 0.0, "cd": 0.0, "tt": null, "stk": 0, "warn": false, "dt": 0, "n": 0, "cbt": -99.0, "fa": 0.0})
	for o in outs:
		var cnt: int = maxi(2, roundi([4, 5, 6, 8, 10, 13, 16][o.tr] * DF.n))
		var ne: int = maxi(1, roundi(cnt * 0.25)) if o.ev > 0 else 0
		for i in cnt:
			ens.append(mk_en(o, "c" if rng.randf() < 0.5 else "r", i < ne))
		ens.append(mk_en(o, "k", o.ev > 0 and rng.randf() < 0.25))
		o.dt = cnt + 1
	next_raid = 900.0 + rng.randf_range(0, 300)
	raid_warned = false
	raid_alive = false
	cam.position = B + Vector2(380, -180)
	zm = 1.0
	cam.zoom = Vector2.ONE
	_clamp_cam()
	msg("정찰 로봇을 만들어 주변을 밝혀 보세요 · 정찰 로봇은 연료가 떨어지면 고장나요")

func _far(arr: Array, p: Vector2, r: float) -> bool:
	for m in arr:
		if (m.p as Vector2).distance_to(p) <= r:
			return false
	return true

func _far_mines_out(p: Vector2) -> bool:
	for m in mines:
		var lim: float = 520.0 if m.safe else 110.0
		if (m.p as Vector2).distance_to(p) <= lim:
			return false
	return true

# ═════════ 로봇·적 만들기 / 능력치 ═════════
func lm(u: Dictionary) -> float:
	return 1.0 + 0.12 * (u.lv - 1)

func em(u: Dictionary) -> float:
	return 1.0 + 0.35 * u.ev

func patk(u: Dictionary) -> float:
	return UT[u.t].atk * lm(u) * em(u)

func heal_v(u: Dictionary) -> float:
	return 9.0 * lm(u) * em(u)

func carry(u: Dictionary) -> int:
	return roundi((7.0 + 2.0 * (u.lv - 1)) * (1.0 + 0.2 * u.ev))

func vis(u: Dictionary) -> float:
	return 220.0 + 15.0 * (u.lv - 1) + 10.0 * u.ev

func calc(u: Dictionary) -> void:
	var d: Dictionary = UT[u.t]
	var r: float = u.hp / u.mh if u.mh > 0.0 else 1.0
	var fr: float = u.f / u.fm if u.fm > 0.0 else 1.0
	u.mh = d.hp * lm(u) * em(u)
	u.hp = minf(u.mh, r * u.mh)
	u.sp = d.sp * (1.0 + 0.03 * (u.lv - 1)) * (1.0 + 0.08 * u.ev)
	u.fm = (1600.0 + 260.0 * (u.lv - 1)) / (1.0 - 0.12 * u.ev) if u.t == "s" else 0.0
	u.f = u.fm * fr
	u.aspd = (1.0 + 0.03 * (u.lv - 1)) * (1.0 + 0.06 * u.ev)

func mk_bot(k: String, p: Vector2) -> Dictionary:
	uid += 1
	var u := {"id": uid, "team": 0, "t": k, "p": p, "goal": null, "fa": rng.randf_range(-PI, PI), "sel": false,
		"lv": 1, "ev": 0, "hp": 1.0, "mh": 1.0, "sp": 1.0, "aspd": 1.0, "rng": float(UT[k].rng), "cd": 0.0,
		"tgt": null, "mine": null, "st": "go", "c": 0, "w": 0.0, "f": 0.0, "fm": 0.0, "cbt": -99.0,
		"mo": 0.0, "ms": 0, "acq": 0.0, "pk": -1, "pt": 0.0, "pp": [], "pok": true}
	calc(u)
	u.hp = u.mh
	u.f = u.fm
	return u

func mk_en(o: Dictionary, k: String, ve: bool) -> Dictionary:
	var m := k != "r"
	var hk := k == "k"
	var lv: int = o.lv
	var ev: int = o.ev if ve else 0
	var L := 1.0 + 0.12 * (lv - 1)
	var dnv: float = o.dn
	var E := (1.0 + 0.32 * ev) * (1.05 - 0.1 * dnv)
	var h: float = (82.0 if hk else (60.0 if m else 38.0)) * L * E * DF.h
	var p: Vector2 = (o.p as Vector2) + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70))
	uid += 1
	return {"id": uid, "team": 1, "t": k, "p": p, "home": p, "lv": lv, "ev": ev, "hp": h, "mh": h,
		"sp": (95.0 if hk else (80.0 if m else 75.0)) * (1.0 + 0.03 * (lv - 1)) * (1.0 + 0.08 * ev),
		"rng": 30.0 if m else 150.0, "atk": (7.5 if hk else (5.5 if m else 7.0)) * L * E * DF.a,
		"cd": 0.0, "aspd": (1.0 + 0.03 * (lv - 1)) * (1.0 + 0.06 * ev), "o": o, "oid": o.id,
		"raid": false, "ag": null, "et": null, "eai": 0.0, "fa": rng.randf_range(-PI, PI), "cbt": -99.0}

func mk_raid(k: String, lv: int, ev: int, p: Vector2) -> Dictionary:
	var m := k != "r"
	var L := 1.0 + 0.12 * (lv - 1)
	var E := 1.0 + 0.32 * ev
	var h: float = (60.0 if m else 38.0) * L * E * DF.h
	uid += 1
	return {"id": uid, "team": 1, "t": k, "p": p, "home": p, "lv": lv, "ev": ev, "hp": h, "mh": h,
		"sp": (80.0 if m else 75.0) * (1.0 + 0.03 * (lv - 1)), "rng": 30.0 if m else 150.0,
		"atk": (5.5 if m else 7.0) * L * E * DF.a, "cd": 0.0, "aspd": (1.0 + 0.03 * (lv - 1)) * (1.0 + 0.06 * ev),
		"o": null, "oid": -1, "raid": true, "ag": null, "et": null, "eai": 0.0, "fa": 0.0, "cbt": -99.0}

func captured() -> int:
	var n := 0
	for o in outs:
		if o.cap:
			n += 1
	return n

func eco() -> float:
	return 1.0 + 0.03 * captured()

func income() -> float:
	var s := 0.0
	for o in outs:
		if o.cap:
			s += 0.3 + 0.25 * o.s
	return s * eco()

func is_cmb(k: String) -> bool:
	return k == "c" or k == "r" or k == "h"

func cap_n(k: String) -> int:
	var n := 0
	for u in bots:
		if (is_cmb(k) and is_cmb(u.t)) or (not is_cmb(k) and u.t == k):
			n += 1
	if is_cmb(k):
		n += dead.size()
	return n

# ═════════ 시야 ═════════
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

# ═════════ 이동 ═════════
func step_to(u: Dictionary, tg: Vector2, dt: float) -> float:
	var p: Vector2 = u.p
	var d := p.distance_to(tg)
	if d < 0.5:
		return 0.0
	var s := minf(d, float(u.sp) * dt)
	u.fa = lerp_angle(float(u.fa), (tg - p).angle(), minf(1.0, dt * 14.0))
	u.p = (p + (tg - p) / d * s).clamp(Vector2.ZERO, Vector2(MAPW, MAPW))
	return d - s

# 플레이어 로봇(정찰 제외)은 밝혀진 칸으로만 다녀요. 길이 없으면 -1
func move_to(u: Dictionary, tg: Vector2, dt: float) -> float:
	if u.team == 0 and u.t != "s":
		var p: Vector2 = u.p
		if not line_seen(p, tg):
			var gk := cell_of(tg)
			if u.pk != gk or t > u.pt:
				u.pk = gk
				u.pt = t + 1.5
				var r = find_path(p, tg)
				u.pok = r != null
				u.pp = r if r != null else []
			if not u.pok:
				return -1.0
			var path: Array = u.pp
			while path.size() > 1 and p.distance_to(path[0]) < 8.0:
				path.pop_front()
			if path.is_empty():
				return step_to(u, tg, dt)
			var wp: Vector2 = path[0]
			step_to(u, wp, dt)
			return (u.p as Vector2).distance_to(tg)
	return step_to(u, tg, dt)

func nearest(p: Vector2, arr: Array, r: float):
	var best = null
	var bd := r
	for e in arr:
		if e.hp <= 0:
			continue
		var d := p.distance_to(e.p)
		if d < bd:
			bd = d
			best = e
	return best

# ═════════ 전투 ═════════
func shm(o: Dictionary) -> float:
	if o.cap:
		return 1.0
	var f: float = [1.0, 1.0, 1.0, 0.7, 0.5, 0.3, 0.1][o.tr]
	if f >= 1.0 or o.dt <= 0:
		return 1.0
	return f + (1.0 - f) * (1.0 - float(o.n) / float(o.dt))

func hit(a: Dictionary, b: Dictionary, dmg: float) -> void:
	a.cbt = t
	b.cbt = t
	if b.has("op") and a.team == 0:
		dmg *= shm(b)
	if b.get("t", "") == "k" and b.team == 1 and a.team == 0:
		b.ag = a
	a.fa = ((b.p as Vector2) - (a.p as Vector2)).angle()
	var ranged: bool = float(a.get("rng", 0.0)) > 40.0 or a.has("op") or a.has("base")
	if ranged:
		prs.append({"p": a.p, "tg": b, "d": dmg, "big": a.has("op") or a.has("base"), "mine": a.team == 0, "done": false})
	else:
		b.hp -= dmg
		fx.append({"k": "imp", "p": b.p, "t": 0.18, "c": Color("#fff6d6") if a.team == 0 else Color("#ff7a66")})

func hit_base(u: Dictionary) -> void:
	base.hp -= u.atk
	u.cd = 1.0 / u.aspd
	fx.append({"k": "imp", "p": B + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), "t": 0.18, "c": Color("#ff7a66")})
	if msg_t <= 0.0:
		msg("기지가 공격받고 있어요!")

func engage(u: Dictionary, tg: Dictionary, dt: float) -> void:
	var d := (u.p as Vector2).distance_to(tg.p)
	if d > u.rng:
		step_to(u, tg.p, dt)
	elif u.cd <= 0.0:
		hit(u, tg, u.atk)
		u.cd = 1.0 / u.aspd

# ═════════ 우리 로봇 행동 ═════════
func ctrl(u: Dictionary, dt: float) -> void:
	u.cd -= dt
	if u.hp < u.mh and (u.p as Vector2).distance_to(B) <= WELL:
		var wr := 0.03 if t - u.cbt < 3.0 else 0.1
		u.hp = minf(u.mh, u.hp + u.mh * wr * dt)
	if u.t == "s":
		if u.goal != null:
			var o: Vector2 = u.p
			if step_to(u, u.goal, dt) <= 2.0:
				u.goal = null
			u.f -= o.distance_to(u.p)
			if u.f <= 0.0:
				u.hp = 0.0
				msg("정찰 로봇의 연료가 떨어져 고장났어요")
		reveal(u.p, vis(u))
		return
	if u.t == "m":
		_miner(u, dt)
		return
	if u.tgt != null and (u.tgt.hp <= 0 or u.tgt.get("cap", false)):
		u.tgt = null
	if u.t != "h" and u.tgt != null:
		var tg: Dictionary = u.tgt
		# 방어막이 센 적 기지면 근처 수비 로봇부터
		if tg.has("op") and shm(tg) < 0.5 and (u.p as Vector2).distance_to(tg.p) < u.rng + 260.0:
			var dfd = null
			var bd: float = u.rng + 200.0
			for e in ens:
				if e.oid == tg.id and e.hp > 0:
					var dd := (u.p as Vector2).distance_to(e.p)
					if dd < bd:
						bd = dd
						dfd = e
			if dfd != null:
				tg = dfd
		var d := (u.p as Vector2).distance_to(tg.p)
		var reach: float = u.rng + (20.0 if tg.has("op") else 0.0)
		if d > reach:
			if move_to(u, tg.p, dt) < 0.0:
				u.tgt = null
		elif u.cd <= 0.0:
			hit(u, tg, patk(u))
			u.cd = 1.0 / u.aspd
		return
	if u.goal != null:
		if move_to(u, u.goal, dt) <= 2.0:
			u.goal = null
		return
	if u.t == "h":
		_support(u, dt)
		return
	u.acq -= dt
	if u.acq <= 0.0:
		u.acq = 0.3
		var e = _nearest_foe(u.p, 220.0)
		if e != null:
			u.tgt = e

func _nearest_foe(p: Vector2, r: float):
	var best = null
	var bd := r
	for e in ens:
		if e.hp <= 0:
			continue
		var d := p.distance_to(e.p)
		if d < bd and seen(e.p):
			bd = d
			best = e
	for o in outs:
		if o.cap:
			continue
		var d := p.distance_to(o.p)
		if d < bd and seen(o.p):
			bd = d
			best = o
	return best

func _miner(u: Dictionary, dt: float) -> void:
	var m = u.mine
	if m == null:
		if u.goal != null and move_to(u, u.goal, dt) <= 2.0:
			u.goal = null
		return
	if m.amt <= 0 and u.st != "back":
		if u.c > 0:
			u.st = "back"
		else:
			u.mine = null
			u.goal = B + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80))
			msg("광산이 바닥났어요 · 채굴 로봇에게 다른 광산을 지정해 주세요")
			return
	if u.st == "go":
		var r := move_to(u, m.p, dt)
		if r < 0.0:
			u.mine = null
			msg("광산까지 밝혀진 길이 없어요")
		elif r <= 2.0:
			u.st = "dig"
			u.w = 3.0
	elif u.st == "dig":
		u.w -= dt
		if u.w <= 0.0:
			var want: int = maxi(1, roundi(carry(u) / 5.0)) if m.ev else carry(u)
			var c: int = mini(want, m.amt)
			m.amt -= c
			u.c = c
			u.st = "back"
	else:
		var r := move_to(u, B, dt)
		if r >= 0.0 and r <= 34.0:
			if m.ev:
				stone += u.c
				u.ms += u.c
			else:
				var g: float = u.c * eco()
				ore += g
				u.mo += g
			u.c = 0
			u.st = "go"
			if m.amt <= 0:
				u.mine = null
				u.goal = B + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80))
				msg("광산이 바닥났어요 · 채굴 로봇에게 다른 광산을 지정해 주세요")

func _support(u: Dictionary, dt: float) -> void:
	var b = null
	for a in bots:
		if a.hp < a.mh and (u.p as Vector2).distance_to(a.p) < u.rng:
			if b == null or a.hp / a.mh < b.hp / b.mh:
				b = a
	if b != null:
		b.hp = minf(b.mh, b.hp + heal_v(u) * dt)
		if rng.randf() < dt * 8.0:
			fx.append({"k": "heal", "p": u.p, "q": b.p, "t": 0.15})
	var fol = null
	var fd := 500.0
	for a in bots:
		if a.t == "c" or a.t == "r":
			var d := (u.p as Vector2).distance_to(a.p)
			if d < fd:
				fd = d
				fol = a
	if fol != null and fd > 100.0:
		move_to(u, fol.p, dt)

# ═════════ 적 행동 ═════════
func ectrl(u: Dictionary, dt: float) -> void:
	u.cd -= dt
	if u.raid:
		u.eai -= dt
		if u.eai <= 0.0 or u.et == null or u.et.hp <= 0 or (u.p as Vector2).distance_to(u.et.p) > 260.0:
			u.eai = 0.4
			u.et = nearest(u.p, bots, 220.0)
		if u.et != null:
			engage(u, u.et, dt)
			return
		if (u.p as Vector2).distance_to(B) > 45.0:
			step_to(u, B, dt)
		elif u.cd <= 0.0:
			hit_base(u)
		return
	if u.t == "k":
		if u.ag != null and u.ag.hp <= 0:
			u.ag = nearest(u.p, bots, 400.0)
		if u.ag != null:
			engage(u, u.ag, dt)
			return
		if (u.p as Vector2).distance_to(B) < 320.0:
			if (u.p as Vector2).distance_to(B) > 45.0:
				step_to(u, B, dt)
			elif u.cd <= 0.0:
				hit_base(u)
			return
	var o: Dictionary = u.o
	var tg = null
	if o.al > 0.0:
		u.eai -= dt
		if u.eai <= 0.0 or u.et == null or u.et.hp <= 0 or (o.p as Vector2).distance_to(u.et.p) > 440.0:
			u.eai = 0.4
			u.et = null
			var bd := 1e9
			for r in bots:
				if r.hp > 0 and (o.p as Vector2).distance_to(r.p) < 420.0:
					var d := (u.p as Vector2).distance_to(r.p)
					if d < bd:
						bd = d
						u.et = r
		tg = u.et
	if tg != null and u.t != "k" and u.hp < u.mh * 0.25 and (u.p as Vector2).distance_to(o.p) > 50.0:
		step_to(u, o.p, dt)
		if u.cd <= 0.0 and (u.p as Vector2).distance_to(tg.p) <= u.rng:
			hit(u, tg, u.atk)
			u.cd = 1.0 / u.aspd
		return
	if tg != null:
		engage(u, tg, dt)
	else:
		step_to(u, u.home, dt)

# ═════════ 레이드 ═════════
func raid() -> void:
	var mxt := 1 if t < 2700 else (2 if t < 3600 else (3 if t < 4800 else 4))
	var tier := 0
	if t < 1800:
		tier = 0 if rng.randf() < 0.6 else 1
	else:
		tier = mini(mxt, int(pow(rng.randf(), 1.4) * (mxt + 1)))
	var mins := t / 60.0
	var n := 6 + 3 * tier + int(mins / 10.0)
	var lv := clampi(roundi(1.0 + 1.5 * tier + mins / 12.0), 1, 11)
	var a := Vector2(rng.randf_range(1500, MAPW - 100), 100) if rng.randf() < 0.5 else Vector2(MAPW - 100, rng.randf_range(100, MAPW - 1500))
	for i in n:
		var ev := 0
		if tier >= 2 and rng.randf() < 0.15 * tier:
			ev = mini(3, tier - 1)
		ens.append(mk_raid("c" if rng.randf() < 0.55 else "r", lv, ev, a + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80))))
	var nm: String = ["약한", "보통", "강한", "매우 강한", "재앙급"][tier]
	msg("레이드 출현! " + nm + " 적 " + str(n) + "마리가 기지로 몰려와요 (Lv " + str(lv) + ")")

# ═════════ 생산·업그레이드 ═════════
func produce(k: String) -> void:
	if won or lost:
		return
	var c: int = UT[k].c
	if cap_n(k) >= CAP[k]:
		msg(("전투 로봇(근접·원거리·지원)은 부활 대기 포함 최대 40대예요") if is_cmb(k) else (UT[k].n + " 로봇은 최대 " + str(CAP[k]) + "대예요"))
		return
	if ore < c:
		msg("광석이 부족해요 (" + str(c) + " 필요)")
		return
	ore -= c
	var u := mk_bot(k, B + Vector2(rng.randf_range(-40, 50), rng.randf_range(-50, 40)) + Vector2(70, 0))
	bots.append(u)
	fx.append({"k": "ring", "p": u.p, "t": 0.5, "r": 30.0})

func lvup_cost(u: Dictionary) -> int:
	return 15 + 10 * int(u.lv)

func do_upgrade() -> void:
	var s := selected()
	if s.is_empty():
		msg("업그레이드할 로봇을 선택해 주세요")
		return
	s.sort_custom(func(a, b): return a.lv < b.lv)
	var n := 0
	for u in s:
		var c := lvup_cost(u)
		if u.lv >= 11 or ore < c:
			continue
		ore -= c
		u.lv += 1
		calc(u)
		n += 1
	if n > 0:
		msg(str(n) + "대 업그레이드 완료!")
	elif s.any(func(u): return u.lv < 11):
		msg("광석이 부족해요")
	else:
		msg("이미 최고 레벨이에요")

func do_evolve() -> void:
	var n := 0
	var need := 0
	for u in selected():
		if u.lv < 11 or u.ev >= 3:
			continue
		var c: int = EVC[u.ev]
		if stone < c:
			need = c
			continue
		stone -= c
		u.ev += 1
		calc(u)
		n += 1
	if n > 0:
		msg("진화 성공! 로봇이 보랏빛으로 변했어요")
	elif need > 0:
		msg("진화석이 부족해요 (필요 " + str(need) + ")")
	else:
		msg("11레벨 로봇만 진화할 수 있어요")

func sell_value(u: Dictionary) -> int:
	var L := 0
	for k in range(1, int(u.lv)):
		L += 15 + 10 * k
	return int(UT[u.t].c * 0.6 + L * 0.3)

func do_sell() -> void:
	var s := selected()
	if s.is_empty():
		msg("판매할 로봇을 선택해 주세요")
		return
	if t > sell_arm:
		sell_arm = t + 3.0
		msg("한 번 더 누르면 " + str(s.size()) + "대를 판매해요")
		return
	sell_arm = 0.0
	var v := 0
	var sv := 0
	for u in s:
		v += sell_value(u)
		for k in int(u.ev):
			sv += int(EVC[k] * 0.5)
		u.hp = -1.0
	bots = bots.filter(func(u): return u.hp > 0)
	ore += v
	stone += sv
	msg("로봇 " + str(s.size()) + "대 판매 · 광석 +" + str(v) + ("" if sv == 0 else " · 진화석 +" + str(sv)))

func revive(d: Dictionary) -> void:
	var u := mk_bot(d.t, B + Vector2(rng.randf_range(-40, 50), rng.randf_range(-50, 40)) + Vector2(70, 0))
	u.lv = d.lv
	u.ev = d.ev
	calc(u)
	u.hp = u.mh
	bots.append(u)
	fx.append({"k": "txt", "p": u.p + Vector2(0, -30), "t": 1.2, "s": "부활!"})

func rev_time(d: Dictionary) -> float:
	return (10.0 + 5.0 * d.lv + 15.0 * d.ev) * (1.5 if d.rd else 1.0)

# ═════════ 카메라 ═════════
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
	cam.force_update_scroll()

func set_zoom(nz: float, anchor: Vector2) -> void:
	var wp := s2w(anchor)
	zm = clampf(snappedf(nz, 0.01), ZMIN, ZMAX)
	cam.zoom = Vector2(zm, zm)
	cam.position = wp - (anchor - vsize() / 2.0) / zm
	_clamp_cam()

func cam_to(wp: Vector2) -> void:
	cam.position = wp
	_clamp_cam()

func mm_rect() -> Rect2:
	var vs := vsize()
	var ms := clampf(minf(vs.y * 0.34, vs.x * 0.22), 170.0, 320.0)
	return Rect2(vs - Vector2(ms, ms) - Vector2(12, 12), Vector2(ms, ms))

func mm_go(sp: Vector2) -> void:
	var r := mm_rect()
	cam_to((sp - r.position) / r.size.x * MAPW)

# ═════════ 선택·명령 ═════════
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

func foe_at(w: Vector2):
	var best = null
	var bd := 26.0
	for e in ens:
		var d := (e.p as Vector2).distance_to(w)
		if d < bd and seen(e.p):
			bd = d
			best = e
	if best != null:
		return best
	for o in outs:
		if not o.cap and (o.p as Vector2).distance_to(w) < 44.0 and seen(o.p):
			return o
	return null

func mine_at(w: Vector2):
	for m in mines:
		if (m.p as Vector2).distance_to(w) < 32.0 and seen(m.p):
			return m
	return null

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
	var e = foe_at(w)
	if e != null:
		var n := 0
		for q in s:
			if q.t == "c" or q.t == "r":
				q.tgt = e
				q.goal = null
				n += 1
		if n > 0:
			fx.append({"k": "atk", "p": e.p, "t": 0.75})
			return
	var m = mine_at(w)
	if m != null and s.any(func(q): return q.t == "m"):
		var n := 0
		for q in s:
			if q.t != "m":
				continue
			if m.ev and q.lv < 6:
				msg("보라색 진화 광산은 6레벨 이상 채굴 로봇만 캘 수 있어요")
				continue
			q.mine = m
			q.st = "go" if q.c == 0 else "back"
			q.goal = null
			n += 1
		if n > 0:
			fx.append({"k": "mine", "p": m.p, "t": 0.75})
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
		u.tgt = null
		if u.t == "m":
			u.mine = null
		if u.t != "s" and find_path(u.p, goal) == null:
			if find_path(u.p, w) == null:
				fail += 1
				continue
			goal = w
		u.goal = goal
		u.pk = -1
		ok += 1
	if ok > 0:
		fx.append({"k": "mv", "p": w, "t": 0.75})
	if fail > 0:
		msg("밝혀진 길이 없어서 갈 수 없어요 · 정찰 로봇으로 길을 먼저 밝혀 주세요")

func box_rect() -> Rect2:
	return Rect2(box_a, Vector2.ZERO).expand(box_b)

func finish_box(add: bool) -> void:
	var r := box_rect()
	if r.size.length() < 8.0:
		return
	var hit_: Array = bots.filter(func(u): return r.has_point(u.p))
	if hit_.is_empty():
		return
	if not add:
		clear_sel()
	for u in hit_:
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

# ═════════ 화면 버튼 ═════════
func buttons() -> Array:
	var vs := vsize()
	var out: Array = []
	if won or lost:
		out.append({"id": "restart", "r": Rect2(vs.x / 2.0 - 110.0, vs.y / 2.0 + 40.0, 220.0, 56.0), "l": "다시 시작", "sub": "", "on": true})
		return out
	var bw := 104.0
	var bh := 76.0
	var y := vs.y - bh - 12.0
	for i in ORDER.size():
		var k: String = ORDER[i]
		var c: int = UT[k].c
		out.append({"id": "p", "k": k, "r": Rect2(12.0 + i * (bw + 8.0), y, bw, bh), "l": UT[k].n, "sub": str(c), "on": ore >= c and cap_n(k) < CAP[k]})
	var s := selected()
	if not s.is_empty():
		var y2 := y - 54.0
		var cost := 0
		for u in s:
			if u.lv < 11:
				cost += lvup_cost(u)
		var evn := 0
		for u in s:
			if u.lv >= 11 and u.ev < 3:
				evn += 1
		out.append({"id": "up", "r": Rect2(12, y2, 170, 46), "l": "업그레이드", "sub": str(cost) if cost > 0 else "최고", "on": cost > 0 and ore >= 15})
		out.append({"id": "evo", "r": Rect2(190, y2, 110, 46), "l": "진화", "sub": str(evn) + "대", "on": evn > 0})
		out.append({"id": "sell", "r": Rect2(308, y2, 110, 46), "l": "한 번 더" if t < sell_arm else "판매", "sub": "", "on": true})
		out.append({"id": "desel", "r": Rect2(426, y2, 90, 46), "l": "선택 해제", "sub": "", "on": true})
	return out

func btn_at(p: Vector2):
	for b in buttons():
		if (b.r as Rect2).has_point(p):
			return b
	return null

func press_btn(b: Dictionary) -> void:
	match b.id:
		"p":
			produce(b.k)
		"up":
			do_upgrade()
		"evo":
			do_evolve()
		"sell":
			do_sell()
		"desel":
			clear_sel()
		"restart":
			new_game()

# ═════════ 입력 ═════════
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
				var b = btn_at(mb.position)
				if b != null:
					press_btn(b)
					return
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
			if touches.is_empty():
				var b = btn_at(st.position)
				if b != null:
					press_btn(b)
					return
				if mm_rect().grow(4).has_point(st.position):
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
				var b2: Vector2 = ps[1]
				pinch = {"d0": maxf(a.distance_to(b2), 1.0), "z0": zm, "m0": (a + b2) / 2.0, "c0": cam.position}
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
			var b2: Vector2 = ps[1]
			var mid := (a + b2) / 2.0
			var z0: float = pinch.z0
			var c0: Vector2 = pinch.c0
			var m0: Vector2 = pinch.m0
			var wp0 := c0 + (m0 - vsize() / 2.0) / z0
			zm = clampf(z0 * a.distance_to(b2) / float(pinch.d0), ZMIN, ZMAX)
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

# ═════════ 매 프레임 ═════════
func _process(dt: float) -> void:
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
	if not won and not lost:
		update_game(dt)
	else:
		t += dt
	for f in fx:
		f.t -= dt
	fx = fx.filter(func(f): return f.t > 0.0)
	if mm_dirty:
		mm_tex.update(mm_img)
		mm_dirty = false
	queue_redraw()

func update_game(dt: float) -> void:
	t += dt
	ore += income() * dt
	for o in outs:
		o.n = 0
	for e in ens:
		if e.o != null:
			e.o.n += 1
	# 적 기지 포탑
	for o in outs:
		if o.cap:
			continue
		var nr = nearest(o.p, bots, 330.0)
		o.warn = nr != null
		if nr != null and (o.p as Vector2).distance_to(nr.p) < 240.0:
			o.al = 6.0
		else:
			o.al -= dt
		o.cd -= dt
		if o.tt != null and (o.tt.hp <= 0 or (o.p as Vector2).distance_to(o.tt.p) > 200.0):
			o.tt = null
			o.stk = 0
		if o.tt == null:
			o.tt = nearest(o.p, bots, 200.0)
			o.stk = 0
		if o.tt != null and o.cd <= 0.0:
			hit(o, o.tt, o.atk * 3.0 * (1.0 + 0.4 * mini(3, o.stk)))
			o.stk += 1
			o.cd = 1.3
	# 우리 기지 포탑
	base.cd -= dt
	base.hp = minf(base.mh, base.hp + 2.0 * dt)
	var bt = nearest(B, ens, 280.0)
	if bt != null and base.cd <= 0.0:
		hit(base, bt, 45.0 * (1.0 + 0.05 * captured()))
		base.cd = 1.0
	# 레이드
	if t >= next_raid - 30.0 and not raid_warned:
		raid_warned = true
		msg("30초 뒤 레이드가 와요! 기지 방어를 준비하세요")
	if t >= next_raid:
		raid_warned = false
		raid()
		next_raid = t + rng.randf_range(300, 600)
	for u in bots:
		ctrl(u, dt)
	for u in ens:
		ectrl(u, dt)
	# 탄환
	for p in prs:
		var tg: Dictionary = p.tg
		if tg.hp <= 0 or tg.get("cap", false):
			p.done = true
			continue
		var dv: Vector2 = (tg.p as Vector2) - (p.p as Vector2)
		var dl := dv.length()
		var sp := 420.0 * dt
		if dl <= sp + 6.0:
			tg.hp -= p.d
			fx.append({"k": "imp", "p": tg.p, "t": 0.18, "c": Color("#7ff0ff") if p.mine else Color("#ff8a66")})
			p.done = true
		else:
			p.p = (p.p as Vector2) + dv / dl * sp
	prs = prs.filter(func(p): return not p.done)
	# 정복
	for o in outs:
		if not o.cap and o.hp <= 0:
			o.cap = true
			var g: float = 20.0 + 20.0 * o.s * o.s
			var sg: int = 4 * (int(o.tr) + 1)
			ore += g
			stone += sg
			var oid: int = o.id
			ens = ens.filter(func(e): return e.oid != oid or e.ag != null)
			fx.append({"k": "ring", "p": o.p, "t": 0.8, "r": 90.0})
			msg("기지 정복! 광석 +" + str(int(g)) + " · 진화석 +" + str(sg) + " · 수입 x" + str(snappedf(eco(), 0.01)))
			if captured() >= outs.size():
				won = true
	# 죽은 로봇 정리
	var ra: bool = ens.any(func(e): return e.raid)
	for u in bots:
		if u.hp <= 0 and is_cmb(u.t):
			dead.append({"t": u.t, "lv": u.lv, "ev": u.ev, "rd": ra, "w": 0.0})
	var r0 := bots.size()
	bots = bots.filter(func(u): return u.hp > 0)
	lost_n += r0 - bots.size()
	var e0 := ens.size()
	ens = ens.filter(func(e): return e.hp > 0)
	kills += e0 - ens.size()
	# 부활
	for d in dead:
		d.w += dt
	var rdy: Array = dead.filter(func(d): return d.w >= rev_time(d))
	if not rdy.is_empty():
		dead = dead.filter(func(d): return d.w < rev_time(d))
		for d in rdy:
			revive(d)
		msg(UT[rdy[0].t].n + " 로봇이 기지에서 부활했어요")
	if raid_alive and not ra:
		msg("레이드 방어 성공!")
	raid_alive = ra
	if base.hp <= 0.0:
		lost = true
		msg("기지가 파괴됐어요")

# ═════════ 그리기 (월드) ═════════
func _draw() -> void:
	var f := ThemeDB.fallback_font
	var vr: Rect2 = view_rect().grow(CELL)
	var i0 := maxi(0, int(vr.position.x / CELL))
	var j0 := maxi(0, int(vr.position.y / CELL))
	var i1 := mini(GN - 1, int(vr.end.x / CELL))
	var j1 := mini(GN - 1, int(vr.end.y / CELL))
	_ground(i0, j0, i1, j1)
	draw_arc(B, BASE_VIEW, 0.0, TAU, 128, Color(0.37, 0.88, 0.77, 0.2), 2.0)
	draw_arc(B, WELL, 0.0, TAU, 128, Color(0.43, 0.94, 0.63, 0.18 + 0.08 * sin(t * 2.0)), 2.0)
	art_base(self, B, t)
	_bar(B.x, B.y - 68.0, 90.0, base.hp / base.mh, Color("#5fe0c4") if base.hp / base.mh > 0.3 else Color("#e5604d"), 6.0)
	for m in mines:
		if vr.has_point(m.p) and seen(m.p):
			art_mine(self, m, t)
			_bar(m.p.x, m.p.y + 20.0, 28.0, float(m.amt) / (150.0 if m.ev else 700.0), Color("#c08cff") if m.ev else Color("#5fe0c4"), 3.0)
	for o in outs:
		if vr.grow(60).has_point(o.p) and seen(o.p):
			_outpost(o, f)
	for u in ens:
		if vr.has_point(u.p) and seen(u.p):
			_enemy(u, f)
	for u in bots:
		if vr.has_point(u.p):
			_unit(u, f)
	for u in bots:
		if u.sel and u.goal != null:
			draw_circle(u.goal, 2.5, Color(0.47, 1.0, 0.67, 0.35))
	for p in prs:
		var pp: Vector2 = p.p
		var c := Color("#7ff0ff") if p.mine else Color("#ff8a66")
		draw_circle(pp, 5.0 if p.big else 3.0, c)
		draw_circle(pp, 1.6, Color(1, 1, 1, 0.9))
	if box_active:
		var r := box_rect()
		draw_rect(r, Color(0.55, 0.89, 0.55, 0.12))
		draw_rect(r, Color("#8be28b"), false, 1.0 / zm)
	_fx(f)
	_fog(i0, j0, i1, j1)
	# 화면 고정 그리기
	inv = get_canvas_transform().affine_inverse()
	draw_set_transform_matrix(inv)
	_minimap()
	_hud(f)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _bar(x: float, y: float, w: float, r: float, c: Color, h: float = 3.0) -> void:
	draw_rect(Rect2(x - w / 2.0, y, w, h), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(x - w / 2.0, y, w * clampf(r, 0.0, 1.0), h), c)

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

func _outpost(o: Dictionary, f: Font) -> void:
	var p: Vector2 = o.p
	var c: bool = o.cap
	ell_fill(self, p + Vector2(4, 26), 40, 13, Color(0, 0, 0, 0.3))
	poly(self, [p + Vector2(-34, 20), p + Vector2(-26, -20), p + Vector2(26, -20), p + Vector2(34, 20)], Color("#2e4a3a") if c else Color("#3a2a46"))
	draw_rect(Rect2(p.x - 16, p.y - 34, 32, 40), Color("#4aa86a") if c else Color("#6b4a86"))
	draw_rect(Rect2(p.x - 16, p.y - 34, 32, 6), Color("#7fd49a") if c else Color("#8f66ab"))
	var lamp := Color("#c9f5d6")
	if not c:
		lamp = Color("#ff6a55") if int(t * 3.0) % 2 == 1 else Color("#a8352a")
	draw_circle(p + Vector2(0, -12), 7, lamp)
	draw_line(p + Vector2(10, -34), p + Vector2(10, -48), Color("#7fd49a") if c else Color("#8f66ab"), 2.0)
	if c:
		draw_rect(Rect2(p.x + 10, p.y - 48, 12, 7), Color("#7fd49a"))
		return
	if o.warn:
		draw_arc(p, 200.0, 0.0, TAU, 72, Color(1.0, 0.27, 0.2, 0.35 + 0.25 * sin(t * 6.0)), 2.0)
		if o.tt != null:
			draw_line(p + Vector2(0, -12), o.tt.p, Color(1.0, 0.23, 0.16, 0.25 + 0.6 * maxf(0.0, 1.0 - o.cd / 1.3)), 1.5 + mini(3, o.stk))
	var sh := shm(o)
	if sh < 0.97:
		draw_arc(p + Vector2(0, -6), 52.0, 0.0, TAU, 48, Color(0.63, 0.86, 1.0, 0.3 + 0.4 * (1.0 - sh)), 2.0)
	_bar(p.x, p.y - 54.0, 44.0, o.hp / o.mx, Color("#e5604d"), 4.0)
	var lt := "Lv " + str(o.lv) + ((" · 진화 " + str(o.ev)) if o.ev > 0 else "")
	draw_string(f, p + Vector2(-50, -60), lt, HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color("#d2a8ff") if o.ev > 0 else Color("#ffc9b8"))

func _enemy(u: Dictionary, f: Font) -> void:
	var m: bool = u.t != "r"
	var hk: bool = u.t == "k"
	var z := 14.0 if hk else (12.0 if m else 9.0)
	var p: Vector2 = u.p
	var ev: int = u.ev
	ell_fill(self, p + Vector2(0, z), z + 2, 4, Color(0, 0, 0, 0.28))
	draw_set_transform(p, u.fa, Vector2(1.3, 1.3))
	var dk := Color("#1c0e14")
	var col: Color
	if hk:
		col = Color("#5a2a8a") if ev > 0 else Color("#4a1620")
	elif ev > 0:
		col = Color("#8a4fc0") if m else Color("#9a6ad0")
	else:
		col = Color("#c24b68") if m else Color("#c98a46")
	if m:
		poly(self, [Vector2(z + 5, 0), Vector2(z - 2, -z), Vector2(-z, -z + 2), Vector2(-z - 3, 0), Vector2(-z, z - 2), Vector2(z - 2, z)], dk)
		poly(self, [Vector2(z + 3, 0), Vector2(z - 3, -z + 3), Vector2(-z + 1, -z + 4), Vector2(-z, 0), Vector2(-z + 1, z - 4), Vector2(z - 3, z - 3)], col)
	else:
		draw_circle(Vector2.ZERO, z + 1, dk)
		draw_circle(Vector2.ZERO, z - 1, col)
		draw_rect(Rect2(0, -2, z + 6, 4), Color("#7a4a1a"))
	draw_rect(Rect2(z - 6, -2, 5, 4), Color("#ffd0a8"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hk:
		draw_arc(p, z + 4, 0.0, TAU, 24, Color("#ff3a2a") if u.ag != null else Color(1.0, 0.35, 0.24, 0.5), 2.0)
	for i in ev:
		draw_arc(p, z + 5 + i * 3, 0.0, TAU, 24, Color(0.69, 0.5, 1.0, 0.7), 1.0)
	draw_string(f, p + Vector2(-20, z + 14), str(u.lv), HORIZONTAL_ALIGNMENT_CENTER, 40, 9, Color("#ffb0a0"))
	if u.hp < u.mh:
		_bar(p.x, p.y - z - 7.0, 18.0, u.hp / u.mh, Color("#e5604d"))

func _unit(u: Dictionary, f: Font) -> void:
	var d: Dictionary = UT[u.t]
	var z: float = d.z
	var p: Vector2 = u.p
	var ev: int = u.ev
	ell_fill(self, p + Vector2(0, z + 2), z + 3, 4, Color(0, 0, 0, 0.3))
	if u.sel:
		ell_line(self, p + Vector2(0, z + 1), z + 6, z / 2.0 + 4.0, Color("#d9ffd0"), 1.5)
	var col: Color = d.col
	if ev > 0:
		col = [Color("#a98ae0"), Color("#9462e0"), Color("#7d3fdc")][ev - 1]
	draw_set_transform(p, u.fa, Vector2(1.35, 1.35))
	art_bot(self, u.t, col, d.acc, t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ev > 0:
		draw_arc(p, z + 7, 0.0, TAU, 24, Color(0.69, 0.5, 1.0, 0.55), 1.0)
	if u.lv > 1:
		draw_string(f, p + Vector2(-20, z + 14), str(u.lv), HORIZONTAL_ALIGNMENT_CENTER, 40, 9, Color(1, 1, 1, 0.85))
	if u.hp < u.mh:
		_bar(p.x, p.y - z - 6.0, 16.0, u.hp / u.mh, Color("#8be28b"))
	if u.t == "s":
		_bar(p.x, p.y - z - 11.0, 16.0, u.f / u.fm, Color("#f2d14e"))
	if u.t == "m" and u.c > 0:
		draw_circle(p + Vector2(-8, -8), 3.0, Color("#c08cff") if (u.mine != null and u.mine.ev) else Color("#8ff3dd"))

func _fx(f: Font) -> void:
	for e in fx:
		var p: Vector2 = e.p
		match e.k:
			"imp":
				draw_circle(p, 4.0 + (0.18 - e.t) * 40.0, Color(e.c, e.t / 0.18 * 0.8))
			"ring":
				var k: float = 1.0 - e.t / 0.6
				draw_arc(p, e.r * clampf(k, 0.05, 1.0), 0.0, TAU, 40, Color(1.0, 0.89, 0.48, clampf(e.t / 0.6, 0.0, 1.0)), 3.0)
			"txt":
				draw_string(f, p + Vector2(-40, -(1.2 - e.t) * 30.0), e.s, HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color(0.5, 1.0, 0.7, minf(1.0, e.t * 2.0)))
			"heal":
				draw_line(p, e.q, Color(0.55, 0.89, 0.55, 0.7), 2.0)
			_:
				var k: float = 1.0 - e.t / 0.75
				var al := maxf(0.0, 1.0 - k)
				var cc := Color(0.43, 1.0, 0.63)
				if e.k == "atk":
					cc = Color(1.0, 0.35, 0.27)
				elif e.k == "mine":
					cc = Color(1.0, 0.78, 0.31)
				var ins := minf(1.0, k * 2.6)
				var r1 := 46.0 - 32.0 * ins
				for i in 4:
					var a := PI / 4.0 + i * PI / 2.0
					draw_set_transform(p + Vector2(cos(a), sin(a)) * r1, a + PI, Vector2.ONE)
					poly(self, [Vector2(11, 0), Vector2(-6, -9), Vector2(-2, 0), Vector2(-6, 9)], Color(cc, al))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				ell_line(self, p, 8 + 34 * k, (8 + 34 * k) * 0.55, Color(cc, al * 0.9), 2.2)
				if k < 0.35:
					draw_circle(p, 5, Color(1, 1, 1, (1.0 - k / 0.35) * 0.85))

func _fog(i0: int, j0: int, i1: int, j1: int) -> void:
	var edge := Color(FOG, 0.4)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			if not exa(i, j):
				draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), FOG)
			elif not (exa(i - 1, j) and exa(i + 1, j) and exa(i, j - 1) and exa(i, j + 1)):
				draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), edge)

# ═════════ 그리기 (화면 고정) ═════════
func _minimap() -> void:
	var r := mm_rect()
	var o := r.position
	var sz := r.size
	draw_rect(Rect2(o - Vector2(3, 3), sz + Vector2(6, 6)), Color(0.79, 0.64, 0.33, 0.6))
	draw_rect(Rect2(o, sz), Color(0.02, 0.03, 0.05, 0.96))
	draw_texture_rect(mm_tex, Rect2(o, sz), false)
	var k := sz.x / MAPW
	for m in mines:
		if m.amt > 0 and seen(m.p):
			draw_rect(Rect2(o + (m.p as Vector2) * k - Vector2(1.2, 1.2), Vector2(2.5, 2.5)), Color("#c08cff") if m.ev else Color("#5fe0c4"))
	for q in outs:
		if seen(q.p):
			draw_rect(Rect2(o + (q.p as Vector2) * k - Vector2(2.5, 2.5), Vector2(5, 5)), Color("#4aa86a") if q.cap else Color("#9b5fd0"))
	for e in ens:
		if seen(e.p) and not e.raid:
			draw_rect(Rect2(o + (e.p as Vector2) * k - Vector2(1.5, 1.5), Vector2(3, 3)), Color("#e5604d"))
		elif e.raid:
			draw_rect(Rect2(o + (e.p as Vector2) * k - Vector2(2, 2), Vector2(4, 4)), Color("#ff3a2a"))
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

func _tf_screen(pos: Vector2, rot: float, scl: float) -> void:
	draw_set_transform_matrix(inv * Transform2D(rot, Vector2(scl, scl), 0.0, pos))

func _hud(f: Font) -> void:
	var vs := vsize()
	# 왼쪽 위: 자원
	sb_panel.draw(get_canvas_item(), Rect2(12, 12, 430, 64))
	draw_string(f, Vector2(26, 42), "SOROK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, GOLD)
	draw_circle(Vector2(118, 35), 6, Color("#5fe0c4"))
	draw_string(f, Vector2(130, 42), str(int(ore)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_circle(Vector2(212, 35), 6, Color("#c08cff"))
	draw_string(f, Vector2(224, 42), str(stone), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(f, Vector2(280, 42), "기지 " + str(int(base.hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8be28b") if base.hp / base.mh > 0.3 else Color("#ff8a6b"))
	var inc := income()
	draw_string(f, Vector2(26, 66), "수입 +" + str(snappedf(inc, 0.1)) + "/초  ·  정복 " + str(captured()) + "/50  ·  로봇 " + str(bots.size()) + ("  ·  부활 대기 " + str(dead.size()) if dead.size() > 0 else ""), HORIZONTAL_ALIGNMENT_LEFT, 410, 13, Color("#aab8c5"))
	# 위 가운데: 시간·레이드
	var tm := "%d:%02d" % [int(t / 60.0), int(t) % 60]
	var rl := next_raid - t
	var rt := "레이드 진행 중!" if raid_alive else ("다음 레이드 %d:%02d" % [int(rl / 60.0), int(rl) % 60])
	sb_panel.draw(get_canvas_item(), Rect2(vs.x / 2.0 - 130, 12, 260, 40))
	draw_string(f, Vector2(vs.x / 2.0 - 120, 38), tm + "   " + rt, HORIZONTAL_ALIGNMENT_CENTER, 240, 15, Color("#ff8a6b") if (raid_alive or rl < 30.0) else Color("#e6edf3"))
	draw_string(f, Vector2(vs.x - 70, 30), str(roundi(zm * 100.0)) + "%", HORIZONTAL_ALIGNMENT_RIGHT, 56, 14, Color(0.81, 0.89, 1.0, 0.7))
	# 선택 정보
	var s := selected()
	if s.size() == 1:
		var u: Dictionary = s[0]
		var line: String = UT[u.t].n + "  Lv " + str(u.lv) + "/11  진화 " + str(u.ev) + "/3  ·  체력 " + str(int(u.hp)) + "/" + str(int(u.mh))
		if u.t == "c" or u.t == "r":
			line += "  ·  공격 " + str(snappedf(patk(u), 0.1))
		elif u.t == "h":
			line += "  ·  치유 " + str(snappedf(heal_v(u), 0.1)) + "/초"
		elif u.t == "m":
			line += "  ·  운반 " + str(carry(u)) + "  ·  캔 광석 " + str(int(u.mo))
		elif u.t == "s":
			line += "  ·  연료 " + str(int(100.0 * u.f / u.fm)) + "%"
		draw_string(f, Vector2(14, vs.y - 158), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	elif s.size() > 1:
		draw_string(f, Vector2(14, vs.y - 158), "로봇 " + str(s.size()) + "대 선택", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	# 버튼
	for b in buttons():
		var r: Rect2 = b.r
		(sb_btn if b.on else sb_dis).draw(get_canvas_item(), r)
		var tc := Color.WHITE if b.on else Color(1, 1, 1, 0.4)
		if b.id == "p":
			var k: String = b.k
			_tf_screen(r.position + Vector2(r.size.x / 2.0, 26), -PI / 2.0, 2.0)
			art_bot(self, k, UT[k].col if b.on else Color(0.4, 0.42, 0.45), UT[k].acc, t)
			draw_set_transform_matrix(inv)
			draw_string(f, r.position + Vector2(0, 56), b.l, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, tc)
			draw_circle(r.position + Vector2(r.size.x / 2.0 - 18, 66), 4, Color("#5fe0c4"))
			draw_string(f, r.position + Vector2(r.size.x / 2.0 - 10, 71), b.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(GOLD, 1.0 if b.on else 0.5))
		else:
			var lab: String = b.l if b.sub == "" else (b.l + "  " + b.sub)
			draw_string(f, r.position + Vector2(0, r.size.y / 2.0 + 6), lab, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, tc)
	# 메시지
	if msg_t > 0.0:
		var a := minf(1.0, msg_t)
		var fs := 16
		var w := f.get_string_size(msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 36.0
		var y := 100.0
		draw_rect(Rect2(vs.x / 2.0 - w / 2.0, y - 26, w, 38), Color(0.04, 0.055, 0.08, 0.88 * a))
		draw_string(f, Vector2(vs.x / 2.0 - w / 2.0 + 18, y), msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
	# 승리·패배
	if won or lost:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.6))
		var big := "승리! 모든 기지를 정복했어요" if won else "패배 · 기지가 파괴됐어요"
		draw_string(f, Vector2(0, vs.y / 2.0 - 20), big, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 40, GOLD if won else Color("#ff8a6b"))
		draw_string(f, Vector2(0, vs.y / 2.0 + 16), "시간 " + tm + "  ·  처치 " + str(kills) + "  ·  정복 " + str(captured()), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 16, Color.WHITE)
		for b in buttons():
			sb_btn.draw(get_canvas_item(), b.r)
			draw_string(f, (b.r as Rect2).position + Vector2(0, 36), b.l, HORIZONTAL_ALIGNMENT_CENTER, (b.r as Rect2).size.x, 18, Color.WHITE)

# ═════════ 자동 점검 (GitHub에서만 돌아가요) ═════════
func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir + "/" + name + ".png")
	print("SHOT ", name)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _selftest() -> void:
	await _wait(0.6)
	await _shot("01_start")
	ore = 5000.0
	stone = 100
	for k in ["s", "m", "m", "c", "c", "c", "c", "r", "r", "r", "h"]:
		produce(k)
	await _wait(0.4)
	clear_sel()
	for u in bots:
		if u.t == "m":
			u.sel = true
	click(mines[0].p, false)
	var o0 = null
	var bd := 1e9
	for o in outs:
		var d := (o.p as Vector2).distance_to(B)
		if d < bd:
			bd = d
			o0 = o
	clear_sel()
	for u in bots:
		if u.t == "s":
			u.sel = true
	click((o0.p as Vector2) + ((B - (o0.p as Vector2)).normalized() * 120.0), false)
	clear_sel()
	for u in bots:
		if u.t == "c" or u.t == "r" or u.t == "h":
			u.sel = true
	await _shot("02_units")
	Engine.time_scale = 4.0
	await _wait(16.0)
	cam_to(o0.p)
	await _shot("03_scouted")
	do_upgrade()
	do_upgrade()
	do_upgrade()
	click(o0.p, false)
	await _wait(14.0)
	cam_to(o0.p)
	await _shot("04_battle")
	await _wait(40.0)
	cam_to(o0.p)
	await _shot("05_after")
	print("STAT t=", int(t), " ore=", int(ore), " stone=", stone, " cap=", captured(), " bots=", bots.size(), " dead=", dead.size(), " ens=", ens.size(), " kills=", kills, " mine0=", mines[0].amt)
	raid()
	cam_to(B + Vector2(300, -300))
	await _wait(60.0)
	await _shot("06_raid")
	print("STAT2 t=", int(t), " basehp=", int(base.hp), " bots=", bots.size(), " ens=", ens.size(), " kills=", kills, " lost=", lost_n)
	print("SELFTEST_DONE")
	get_tree().quit()

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

func art_base(ci: CanvasItem, p: Vector2, t: float) -> void:
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

func art_mine(ci: CanvasItem, m: Dictionary, t: float) -> void:
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
func art_bot(ci: CanvasItem, k: String, col: Color, acc: Color, t: float) -> void:
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
