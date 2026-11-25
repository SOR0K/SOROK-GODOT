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
var oil := 0
var quit_arm := 0.0
var info_open := false
var ctl_f := "c"
var ctl_arm := -1
var ctl_scroll := 0.0
var ctl_arm_t := 0.0
var list_drag = null
var SS := {}
var uid := 0
var sell_arm := 0.0
var zm := 1.0
var cam: Camera2D
var msg_text := ""
var msg_t := 0.0
var rwm := -99.0
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
var last_num := {"t": -9.0, "k": ""}
var mouse_ui := Vector2(-999, -999)
var tap_tip_t := 0.0
var tap_tip_p := Vector2.ZERO
var ui: Array = []
var us := 1.0
var touch_mode := false
var shop_open := false
var shop_tab := "prod"
var shop_desc := ""
var paused := false
var aim := ""
var vb_cd := 0.0
var dr_cd := 0.0
var drones: Array = []
var sb_red: StyleBoxFlat
var sb_hud: StyleBoxFlat
var sb_badge: StyleBoxFlat
var sb_btn_hi: StyleBoxFlat
var sb_shop: StyleBoxFlat
var sb_tab_on: StyleBoxFlat
var sb_card: StyleBoxFlat
var sb_card_hi: StyleBoxFlat

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sb_btn = _sb(Color(0.08, 0.11, 0.15, 0.94), Color("#c9a255"))
	sb_dis = _sb(Color(0.06, 0.07, 0.09, 0.85), Color(0.3, 0.34, 0.4))
	sb_panel = _sb(PANEL, Color(0.79, 0.64, 0.33, 0.7))
	sb_red = _sb(Color(0.35, 0.08, 0.08, 0.92), Color("#ff6a55"))
	sb_hud = _sb(Color(0.05, 0.07, 0.1, 0.94), Color(0.79, 0.64, 0.33, 0.55))
	sb_badge = _sb(Color("#1c1406"), Color("#c9a255"))
	sb_btn_hi = _sb(Color(0.16, 0.2, 0.26, 0.98), Color("#ffd76a"))
	sb_shop = _sb(Color(0.06, 0.08, 0.11, 0.98), Color("#c9a255"))
	sb_tab_on = _sb(Color(0.2, 0.15, 0.06, 0.95), Color("#ffd76a"))
	sb_card = _sb(Color(0.09, 0.12, 0.16, 0.95), Color("#2f6a4a"))
	sb_card_hi = _sb(Color(0.13, 0.18, 0.22, 0.98), Color("#5fe0a0"))
	touch_mode = DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touchui")
	us = 1.0
	if touch_mode:
		get_window().content_scale_size = Vector2i(1600, 900)
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
	vb_cd = 0.0
	dr_cd = 0.0
	drones.clear()
	aim = ""
	quit_arm = 0.0
	shop_open = false
	ctl_f = "c"
	won = false
	lost = false
	kills = 0
	lost_n = 0
	oil = 0
	info_open = false
	SS = {"earn": 0.0, "stEarn": 0, "kills": 0, "lost": 0, "made": 0, "spRobot": 0, "spUp": 0, "spItem": 0, "stUsed": 0}
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
			"cap": false, "al": 0.0, "cd": 0.0, "tt": null, "stk": 0, "ft": null, "fts": -9.0, "warn": false, "dt": 0, "n": 0, "cbt": -99.0, "fa": 0.0})
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
		"mo": 0.0, "ms": 0, "acq": 0.0, "pk": -1, "pt": 0.0, "pp": [], "pok": true, "oilT": 0.0,
		"ai": 0.0, "dodge": 0.0, "dgo": null, "fo": null, "kite": 0.0, "kx": null, "rh": null, "rw": false, "sq": null, "spc": 0.0}
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
	var spd: float = minf(u.sp, u.spc) if float(u.get("spc", 0.0)) > 0.0 else float(u.sp)
	var s := minf(d, spd * (1.2 if float(u.get("oilT", 0.0)) > 0.0 else 1.0) * dt)
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
func _atk(u: Dictionary, tg: Dictionary) -> void:
	hit(u, tg, patk(u))
	u.cd = 1.0 / (u.aspd * (1.2 if u.oilT > 0.0 else 1.0))

# 상대 반대쪽으로 살짝 물러나기 (밝혀진 곳으로만)
func _away(u: Dictionary, from: Vector2, step: float, dt: float) -> void:
	var p: Vector2 = u.p
	var d := maxf(p.distance_to(from), 1.0)
	var np := p + (p - from) / d * step
	if u.team == 1 or seen(np):
		step_to(u, np, dt)

func _seen_ens(p: Vector2, r: float) -> Array:
	var a: Array = []
	for e in ens:
		if e.hp > 0 and seen(e.p) and p.distance_to(e.p) < r:
			a.append(e)
	return a

func _near_in(p: Vector2, arr: Array, r: float):
	var b = null
	var bd := r
	for e in arr:
		var d := p.distance_to(e.p)
		if d < bd:
			bd = d
			b = e
	return b

# 웹 smartAI 그대로: 포탑 피하기 · 점수로 대상 고르기 · 카이팅 · 후퇴
func smart_ai(u: Dictionary, dt: float) -> bool:
	u.ai -= dt
	if u.dodge > 0.0:
		u.dodge -= dt
		var o = u.dgo
		if o != null and not o.cap and (u.p as Vector2).distance_to(o.p) < 240.0:
			_away(u, o.p, 40.0, dt)
		return true
	if u.tgt != null and (u.tgt.hp <= 0 or u.tgt.get("cap", false)):
		u.tgt = u.fo if (u.fo != null and not u.fo.get("cap", false) and u.fo.hp > 0) else null
		u.fo = null
	if u.ai <= 0.0:
		u.ai = 0.25
		var E := _seen_ens(u.p, 260.0)
		var to = null
		for o in outs:
			if not o.cap and is_same(o.tt, u):
				to = o
				break
		if to != null and u.hp < u.mh * 0.45 and to.stk >= 2:
			var mate := false
			for a in bots:
				if not is_same(a, u) and (a.t == "c" or a.t == "r") and a.hp > a.mh * 0.5 and (a.p as Vector2).distance_to(to.p) < 260.0:
					mate = true
					break
			if mate:
				u.dodge = 1.6
				u.dgo = to
				to.tt = null
				to.stk = 0
				return true
		if u.tgt == null and u.goal == null:
			var R: float = u.rng + 70.0
			var b = null
			var bs := 1e9
			for e in E:
				var d := (u.p as Vector2).distance_to(e.p)
				if d > 220.0:
					continue
				var sc: float = d * 0.6 + (e.hp / e.mh) * 120.0 - (60.0 if d < R else 0.0)
				if sc < bs:
					bs = sc
					b = e
			if b != null:
				u.tgt = b
			else:
				for o in outs:
					if not o.cap and seen(o.p) and (u.p as Vector2).distance_to(o.p) < u.rng + 40.0:
						u.tgt = o
						break
		elif u.tgt != null and u.tgt.team == 1 and not u.tgt.has("op"):
			var b: Dictionary = u.tgt
			var bs: float = b.hp / b.mh
			for e in E:
				if (u.p as Vector2).distance_to(e.p) <= u.rng + 5.0 and e.hp / e.mh < bs - 0.35:
					b = e
					bs = e.hp / e.mh
			u.tgt = b
		if u.t == "r":
			var mel: Array = E.filter(func(e): return e.t != "r")
			var m = _near_in(u.p, mel, 55.0)
			if m != null and u.cd > 0.25:
				u.kite = 0.35
				u.kx = m
		if u.hp < u.mh * 0.2:
			var hs: Array = bots.filter(func(a): return a.t == "h")
			var h = _near_in(u.p, hs, 320.0)
			if h != null:
				u.rh = h
			else:
				var db := (u.p as Vector2).distance_to(B)
				if not u.rw and db < 1400.0 and db > WELL - 60.0:
					u.rw = true
					if t - rwm > 10.0:
						rwm = t
						msg("체력이 낮은 로봇이 우물로 돌아가요")
		elif u.hp > u.mh * 0.6:
			u.rh = null
		if u.rw and u.hp > u.mh * 0.9:
			u.rw = false
	if u.rw and u.goal == null:
		if (u.p as Vector2).distance_to(B) > WELL - 80.0:
			move_to(u, B, dt)
		if u.cd <= 0.0:
			var e = _near_in(u.p, _seen_ens(u.p, u.rng), u.rng)
			if e != null:
				_atk(u, e)
		return true
	if u.kite > 0.0 and u.kx != null and u.kx.hp > 0:
		u.kite -= dt
		_away(u, u.kx.p, 30.0, dt)
		if u.cd <= 0.0 and u.tgt != null and u.tgt.hp > 0 and (u.p as Vector2).distance_to(u.tgt.p) <= u.rng:
			_atk(u, u.tgt)
		return true
	if u.rh != null and u.rh.hp > 0 and u.goal == null:
		if (u.p as Vector2).distance_to(u.rh.p) > 45.0:
			move_to(u, u.rh.p, dt)
		if u.cd <= 0.0:
			var e = _near_in(u.p, _seen_ens(u.p, u.rng), u.rng)
			if e != null:
				_atk(u, e)
		return true
	return false

# 적 기지 공격 대형: 모였다가 한꺼번에 돌격
func squad(us: Array, tg: Dictionary) -> void:
	var A: Array = us.filter(func(q): return q.t != "h")
	if A.size() < 3 or us.all(func(q): return (q.p as Vector2).distance_to(tg.p) < 420.0):
		return
	var c := Vector2.ZERO
	var msp := 1e9
	for q in us:
		c += q.p
		msp = minf(msp, q.sp)
	c /= us.size()
	var dv: Vector2 = c - (tg.p as Vector2)
	dv = dv.normalized() if dv.length() > 1.0 else Vector2.RIGHT
	var pv := Vector2(-dv.y, dv.x)
	var G := {"tg": tg, "ph": "gather", "t0": t, "m": us, "sp": msp, "go": 0.0}
	var row := 0
	for k in ["c", "r", "h"]:
		var L: Array = us.filter(func(q): return q.t == k)
		var i := 0
		while i < L.size():
			var R: Array = L.slice(i, i + 8)
			for j in R.size():
				var q = R[j]
				var off := (j - (R.size() - 1) / 2.0) * 24.0
				var D := 370.0 + row * 24.0
				q.sq = G
				q.tgt = null
				q.goal = (tg.p as Vector2) + dv * D + pv * off
				q.pk = -1
				q.spc = 0.0
			row += 1
			i += 8
	msg("공격 대형으로 모이는 중… 다 모이면 한꺼번에 돌격해요")

func sq_tick(u: Dictionary) -> void:
	var G: Dictionary = u.sq
	if G.tg.cap or G.tg.hp <= 0 or t - G.t0 > 60.0:
		u.sq = null
		u.spc = 0.0
		return
	if G.ph == "gather":
		var L: Array = G.m.filter(func(q): return q.hp > 0 and q.sq != null and is_same(q.sq, G))
		var ok := L.filter(func(q): return q.goal == null).size()
		if t - G.t0 > 14.0 or ok >= ceili(L.size() * 0.85):
			G.ph = "go"
			G.go = t
			for q in L:
				q.goal = null
				if q.t != "h":
					q.tgt = G.tg
			if L.size() > 0:
				msg("돌격!")
	else:
		u.spc = G.sp if u.t == "h" else 0.0
		if t - G.go > 20.0:
			u.sq = null
			u.spc = 0.0

func ctrl(u: Dictionary, dt: float) -> void:
	u.cd -= dt
	if u.hp < u.mh and (u.p as Vector2).distance_to(B) <= WELL:
		var wr := 0.03 if t - u.cbt < 3.0 else 0.1
		u.hp = minf(u.mh, u.hp + u.mh * wr * dt)
	if u.sq != null:
		sq_tick(u)
	elif u.spc > 0.0 and u.goal == null:
		u.spc = 0.0
	if u.oilT > 0.0:
		u.oilT -= dt
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
	if u.t == "c" or u.t == "r":
		var tg = u.tgt
		# 방어막이 센 적 기지면 근처 수비 로봇부터
		if tg != null and tg.has("op") and not tg.cap and shm(tg) < 0.5 and (u.p as Vector2).distance_to(tg.p) < u.rng + 260.0:
			var dfs: Array = ens.filter(func(e): return e.hp > 0 and e.get("oid", -1) == tg.id)
			var D = _near_in(u.p, dfs, u.rng + 200.0)
			if D != null:
				if (u.p as Vector2).distance_to(D.p) > u.rng:
					move_to(u, D.p, dt)
				elif u.cd <= 0.0:
					_atk(u, D)
				return
		if smart_ai(u, dt):
			return
	if u.tgt != null and (u.tgt.hp <= 0 or u.tgt.get("cap", false)):
		u.tgt = null
	if u.t != "h" and u.tgt != null:
		var tg: Dictionary = u.tgt
		var d := (u.p as Vector2).distance_to(tg.p)
		var reach: float = u.rng + (20.0 if tg.has("op") else 0.0)
		if d > reach:
			if move_to(u, tg.p, dt) < 0.0:
				u.tgt = null
		elif u.cd <= 0.0:
			_atk(u, tg)
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
		if d < bd and vis2(e.p):
			bd = d
			best = e
	for o in outs:
		if o.cap:
			continue
		var d := p.distance_to(o.p)
		if d < bd and vis2(o.p):
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
				SS.stEarn += u.c
			else:
				var g: float = u.c * eco()
				ore += g
				u.mo += g
				SS.earn += g
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
	var EN: Array = ens.filter(func(e): return e.hp > 0 and seen(e.p))
	var th = _near_in(u.p, EN, 95.0)
	if th != null and (u.hp < u.mh * 0.6 or (u.p as Vector2).distance_to(th.p) < 55.0):
		_away(u, th.p, 30.0, dt)
	else:
		var tA = null
		var tw := 1e9
		for a in bots:
			if is_same(a, u) or a.t == "s" or a.t == "m" or a.hp >= a.mh:
				continue
			var d := (u.p as Vector2).distance_to(a.p)
			if d > 460.0:
				continue
			var w: float = a.hp / a.mh + d / 900.0
			if w < tw:
				tw = w
				tA = a
		var fol = tA
		if fol == null:
			fol = _near_in(u.p, bots.filter(func(a): return a.t == "c" or a.t == "r"), 500.0)
		var want: float = u.rng * 0.85 if tA != null else 100.0
		if fol != null and (u.p as Vector2).distance_to(fol.p) > want:
			var op: Vector2 = u.p
			var n0 := _min_d(op, EN)
			move_to(u, fol.p, dt)
			var n1 := _min_d(u.p, EN)
			if n1 < 80.0 and n1 < n0 and not (tA != null and tA.hp < tA.mh * 0.35 and u.hp > u.mh * 0.5):
				u.p = op
	if b != null:
		b.hp = minf(b.mh, b.hp + heal_v(u) * dt)
		if rng.randf() < dt * 8.0:
			fx.append({"k": "heal", "p": u.p, "q": b.p, "t": 0.15})

func _min_d(p: Vector2, arr: Array) -> float:
	var m := 1e9
	for e in arr:
		m = minf(m, p.distance_to(e.p))
	return m

# ═════════ 적 행동 ═════════
# 웹 ePick: 가깝고 체력 낮은 로봇 · 지원/원거리 우선 · 기지를 치는 로봇 우선
func e_pick(u: Dictionary, L: Array, o) -> Variant:
	var b = null
	var bs := 1e9
	var rg: float = float(u.get("rng", 30.0)) + 60.0
	for r in L:
		if r.hp <= 0:
			continue
		var dd := (u.p as Vector2).distance_to(r.p)
		var sc: float = dd * 0.9 + (r.hp / r.mh) * 110.0
		if dd < rg and r.t == "h":
			sc -= 40.0
		elif dd < rg and r.t == "r":
			sc -= 20.0
		if r.t == "m" or r.t == "s":
			sc += 40.0
		if o != null and r.tgt != null and is_same(r.tgt, o):
			sc -= 35.0
		if sc < bs:
			bs = sc
			b = r
	return b

# 웹 eKite: 적 사격병이 우리 근접 로봇에게서 물러나기
func e_kite(u: Dictionary, dt: float, lim = null, lr: float = 0.0) -> bool:
	if u.rng <= 40.0 or u.cd < 0.3:
		return false
	var m = _near_in(u.p, bots.filter(func(r): return r.t == "c" and r.hp > 0), 58.0)
	if m == null:
		return false
	var p: Vector2 = u.p
	var d := maxf(p.distance_to(m.p), 1.0)
	var np := p + (p - (m.p as Vector2)) / d * 30.0
	if lim != null and np.distance_to(lim) > lr:
		return false
	step_to(u, np, dt)
	return true

func _e_fight(u: Dictionary, tg: Dictionary, dt: float) -> void:
	if (u.p as Vector2).distance_to(tg.p) > u.rng:
		step_to(u, tg.p, dt)
	elif u.cd <= 0.0:
		hit(u, tg, u.atk)
		u.cd = 1.0 / u.aspd

func ectrl(u: Dictionary, dt: float) -> void:
	u.cd -= dt
	if u.raid:
		u.eai -= dt
		if u.eai <= 0.0 or u.et == null or u.et.hp <= 0 or (u.p as Vector2).distance_to(u.et.p) > 260.0:
			u.eai = 0.4
			u.et = e_pick(u, bots.filter(func(r): return (u.p as Vector2).distance_to(r.p) < 220.0), null)
		if u.et != null:
			if e_kite(u, dt):
				return
			_e_fight(u, u.et, dt)
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
			_e_fight(u, u.ag, dt)
			return
		if (u.p as Vector2).distance_to(B) < 320.0:
			if (u.p as Vector2).distance_to(B) > 45.0:
				step_to(u, B, dt)
			elif u.cd <= 0.0:
				hit_base(u)
			return
	var o: Dictionary = u.o
	var p = null
	if o.al > 0.0:
		var op: Vector2 = o.p
		if o.ft == null or o.ft.hp <= 0 or op.distance_to(o.ft.p) > 440.0 or t - o.fts > 0.6:
			o.fts = t
			o.ft = e_pick(o, bots.filter(func(r): return op.distance_to(r.p) < 420.0), o)
		u.eai -= dt
		if u.eai <= 0.0 or u.et == null or u.et.hp <= 0 or op.distance_to(u.et.p) > 440.0:
			u.eai = 0.4
			u.et = e_pick(u, bots.filter(func(r): return op.distance_to(r.p) < 420.0), o)
		p = o.ft if (o.ft != null and (u.p as Vector2).distance_to(o.ft.p) < u.rng + 140.0) else u.et
	if p != null and u.t != "k" and u.hp < u.mh * 0.25 and (u.p as Vector2).distance_to(o.p) > 50.0:
		step_to(u, o.p, dt)
		if u.cd <= 0.0 and (u.p as Vector2).distance_to(p.p) <= u.rng:
			hit(u, p, u.atk)
			u.cd = 1.0 / u.aspd
		return
	if p != null:
		_e_fight(u, p, dt)
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
	SS.made += 1
	SS.spRobot += c
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
		SS.spUp += c
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
		SS.stUsed += c
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
		if d < bd and vis2(e.p):
			bd = d
			best = e
	if best != null:
		return best
	for o in outs:
		if not o.cap and (o.p as Vector2).distance_to(w) < 44.0 and vis2(o.p):
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
	for q in s:
		q.sq = null
		q.spc = 0.0
	var e = foe_at(w)
	if e != null:
		var n := 0
		for q in s:
			if q.t == "c" or q.t == "r":
				q.tgt = e
				q.goal = null
				n += 1
			elif q.t == "h":
				q.tgt = null
				q.goal = null
		if n > 0:
			fx.append({"k": "atk", "p": e.p, "t": 0.75})
			if e.has("op"):
				squad(s.filter(func(q): return q.t == "c" or q.t == "r" or q.t == "h"), e)
			return
		msg("공격할 수 있는 로봇이 선택되지 않았어요")
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
	var msp := 1e9
	for u in s:
		if u.t != "s":
			msp = minf(msp, u.sp)
	for k in n:
		var u = s[k]
		# 웹과 같은 해바라기 대형 · 여러 대면 가장 느린 로봇 속도로 함께
		var off := Vector2.ZERO if k == 0 else Vector2.from_angle(k * 2.4) * (19.0 * sqrt(float(k)))
		u.spc = msp if (n > 1 and u.t != "s" and msp < 1e8) else 0.0
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

# ═════════ 화면 UI (웹 SOROK과 같은 구성) ═════════
func touch_ui() -> bool:
	return touch_mode

func ui_size() -> Vector2:
	return vsize() / us

func ui_hit(sp: Vector2):
	var p := sp / us
	for i in range(ui.size() - 1, -1, -1):
		var it: Dictionary = ui[i]
		if (it.r as Rect2).has_point(p):
			return it
	return null

func _add(id: String, r: Rect2, on: bool = true, tip: String = "", arg = null) -> Dictionary:
	var it := {"id": id, "r": r, "on": on, "tip": tip, "arg": arg}
	ui.append(it)
	return it

func d_cd() -> float:
	return snappedf(maxf(3.0, minf(8.0, 8.0 - 5.0 * (t / 60.0 - 20.0) / 60.0)), 0.1)

func vb_cdv() -> float:
	return roundf(maxf(120.0, minf(300.0, 300.0 - 3.0 * (t / 60.0 - 20.0))))

func hud_rect() -> Rect2:
	var u := ui_size()
	var mmw := mm_rect().size.x / us + 24.0
	var w := 690.0
	var x := maxf(12.0, (u.x - mmw - w) / 2.0)
	if touch_ui():
		x = 12.0
	return Rect2(x, u.y - 128.0, w, 118.0)

const CMDS := [["all", "E", "전체", "[E] 모든 로봇 선택"], ["home", "Q", "기지", "[Q / Home] 기지로 화면 이동"], ["info", "I", "정보", "[I] 이번 게임 기록"], ["shop", "Y", "상점", "[Y] 상점 열기 · 닫기"]]

func _build_ui() -> void:
	ui.clear()
	var u := ui_size()
	if won or lost:
		_add("restart", Rect2(u.x / 2.0 - 110.0, u.y / 2.0 + 40.0, 220.0, 56.0))
		return
	if paused:
		_add("resume", Rect2(u.x / 2.0 - 120.0, u.y / 2.0 - 30.0, 240.0, 54.0))
		_add("restart", Rect2(u.x / 2.0 - 120.0, u.y / 2.0 + 34.0, 240.0, 54.0))
		return
	if touch_ui():
		_add("pause", Rect2(12, 12, 44, 44))
		if not selected().is_empty():
			_add("desel", Rect2(64, 12, 132, 44))
	var h := hud_rect()
	var ox := h.position.x
	var oy := h.position.y
	for i in CMDS.size():
		var b: Array = CMDS[i]
		_add(b[0], Rect2(ox + 244.0 + i * 70.0, oy + 8.0, 64.0, 42.0), true, b[3], b[1])
	for i in 6:
		var r := Rect2(ox + 530.0 + (i % 3) * 52.0, oy + 8.0 + int(i / 3) * 38.0, 48.0, 34.0)
		if i < 5:
			var k: String = ORDER[i]
			_add("slot", r, true, "[" + str(i + 1) + "] " + UT[k].n + " 로봇 전체 선택 · 두 번: 그 로봇들 위치로 화면 이동", k)
		else:
			_add("oil", r, oil > 0, "[6 / Space] 기름 들기 · 보유 " + str(oil) + "개", null)
	if info_open:
		var ir := info_rect()
		_add("infobg", ir)
		_add("infox", Rect2(ir.end.x - 44.0, ir.position.y + 10.0, 34.0, 30.0))
	if shop_open:
		var sr := shop_rect()
		_add("shopbg", sr)
		_add("shopx", Rect2(sr.end.x - 44.0, sr.position.y + 10.0, 34.0, 30.0))
		var tabs := ["prod", "item", "up", "ctl"]
		for i in tabs.size():
			_add("tab", Rect2(sr.position.x + 12.0, sr.position.y + 56.0 + i * 46.0, 150.0, 38.0), true, "", tabs[i])
		if shop_tab == "ctl":
			_build_ctl(sr)
		else:
			var cards := shop_cards()
			var cw := 200.0
			var cols := maxi(1, int((sr.size.x - 190.0) / (cw + 10.0)))
			for i in cards.size():
				var c: Dictionary = cards[i]
				var r := Rect2(sr.position.x + 176.0 + (i % cols) * (cw + 10.0), sr.position.y + 56.0 + int(i / cols) * 72.0, cw, 62.0)
				_add("card", r, c.on, c.desc, c)

func info_rect() -> Rect2:
	var u := ui_size()
	var w := minf(760.0, u.x * 0.94)
	return Rect2((u.x - w) / 2.0, maxf(16.0, (u.y - 140.0 - 300.0) / 2.0), w, 300.0)

func shop_rect() -> Rect2:
	var u := ui_size()
	var w := minf(u.x - 40.0, 860.0)
	var hh := minf(u.y - 160.0, 440.0)
	return Rect2((u.x - w) / 2.0, maxf(16.0, (u.y - 140.0 - hh) / 2.0), w, hh)

func shop_cards() -> Array:
	var out: Array = []
	if shop_tab == "prod":
		for k in ORDER:
			var c: int = UT[k].c
			out.append({"act": "prod", "k": k, "n": UT[k].n + " 로봇 (" + str(cap_n(k)) + "/" + str(CAP[k]) + ")", "cost": str(c), "on": ore >= c and cap_n(k) < CAP[k], "desc": _unit_desc(k)})
		var best = _best_dead()
		if best == null:
			out.append({"act": "rev", "n": "즉시 부활 (대기 없음)", "cost": "", "on": false, "desc": "전투 로봇(근접·원거리·지원)은 죽어도 레벨·진화 그대로 기지에서 부활해요. 대기 시간 10초 + 레벨당 5초 + 진화 단계당 15초, 레이드 중에 죽으면 1.5배. 이 버튼은 가장 강한 대기 로봇을 광석으로 바로 부활시켜요 (레벨×15 + 진화×30)."})
		else:
			var rc := 15 * int(best.lv) + 30 * int(best.ev)
			out.append({"act": "rev", "n": "즉시 부활 · " + UT[best.t].n + " Lv" + str(best.lv), "cost": str(rc), "on": ore >= rc, "desc": "부활 대기 중인 가장 강한 로봇을 광석으로 바로 부활시켜요 (레벨×15 + 진화×30)."})
	elif shop_tab == "item":
		out.append({"act": "dr", "n": "정찰 드론" + ("" if dr_cd <= 0.0 else " (" + str(snappedf(dr_cd, 0.1)) + "초)"), "cost": "25", "on": dr_cd <= 0.0 and ore >= 25.0, "desc": "던진 곳 반경 260을 4초 동안 보여줘요. 재사용 대기 " + str(d_cd()) + "초 (시간이 지날수록 짧아져요)."})
		out.append({"act": "vb", "n": "시야 폭탄" + ("" if vb_cd <= 0.0 else " (%d:%02d)" % [int(vb_cd / 60.0), int(vb_cd) % 60]), "cost": "60", "on": vb_cd <= 0.0 and ore >= 60.0, "desc": "던진 곳 반경 180을 영구적으로 밝혀요. 재사용 대기 " + str(int(vb_cdv())) + "초 (시간이 지날수록 짧아져요)."})
		out.append({"act": "oilb", "n": "기름 구매 (보유 " + str(oil) + ")", "cost": "40", "on": ore >= 40.0, "desc": "기름 1개를 사요. 들고 로봇 근처에 뿌리면 반경 70 안의 로봇이 20초간 이동·공격 속도 +20%, 정찰 로봇은 연료 +50%."})
		out.append({"act": "oilh", "n": "기름 들기 (보유 " + str(oil) + ")", "cost": "", "on": oil > 0, "desc": "기름을 들고 지도에서 로봇 근처를 누르면 뿌려요. 단축키 6 또는 Space."})
	else:
		var s := selected()
		var cost := 0
		for q in s:
			if q.lv < 11:
				cost += lvup_cost(q)
		out.append({"act": "upsel", "n": "선택 업그레이드 (" + str(s.size()) + "대)", "cost": str(cost) if cost > 0 else "", "on": cost > 0 and ore >= 15.0, "desc": "선택한 로봇을 레벨이 낮은 순서대로 1레벨씩 올려요 (15 + 레벨×10)."})
		var evn := 0
		for q in s:
			if q.lv >= 11 and q.ev < 3:
				evn += 1
		out.append({"act": "evo", "n": "선택 진화 (" + str(evn) + "대)", "cost": "", "on": evn > 0, "desc": "11레벨 로봇을 진화석으로 진화시켜요 (1단계 11 · 2단계 22 · 3단계 33개)."})
		out.append({"act": "sell", "n": "한 번 더 누르면 판매" if t < sell_arm else "선택 판매", "cost": "", "on": not s.is_empty(), "desc": "판매하면 광석을 일부 돌려받아요. 진화한 로봇은 진화석을 절반만 돌려받아요."})
		for k in ["c", "r", "h", "m", "s"]:
			var n := 0
			var ucost := 0
			for q in bots:
				if q.t == k:
					n += 1
					if q.lv < 11 and ucost == 0:
						ucost = lvup_cost(q)
			out.append({"act": "uptype", "k": k, "n": UT[k].n + " 업그레이드 (" + str(n) + "대)", "cost": str(ucost) if ucost > 0 else "", "on": ucost > 0 and ore >= ucost, "desc": UT[k].n + " 로봇 중 레벨이 가장 낮은 로봇부터 1레벨씩 올려요."})
	return out

func _unit_desc(k: String) -> String:
	match k:
		"s":
			return "빠르고 시야가 넓어요. 암흑을 밝히는 유일한 로봇. 연료가 다 떨어지면 고장나요. 최대 3대."
		"m":
			return "광산을 눌러 지정하면 캐서 기지로 날라요. 6레벨부터 보라색 진화 광산에서 진화석을 캐요. 최대 15대."
		"c":
			return "체력이 높은 탱커. 앞에서 적을 막아요. 전투 로봇은 부활 대기 포함 최대 40대."
		"r":
			return "사거리 150의 딜러. 근접 로봇 뒤에서 쏴요."
		_:
			return "다친 아군을 따라다니며 치료해요."

func _best_dead():
	var best = null
	for d in dead:
		if best == null or d.lv * 10 + d.ev * 30 > best.lv * 10 + best.ev * 30:
			best = d
	return best

# ───── 로봇 제어 탭 ─────
const CTL_ROLE := {"s": "정찰", "m": "채굴", "c": "근접 (탱커)", "r": "원거리 (딜러)", "h": "지원 (힐러)"}

func ctl_state(u: Dictionary) -> String:
	if u.t == "m":
		return ("진화석 채굴 중" if u.mine.ev else "광석 채굴 중") if u.mine != null else "대기"
	if u.t == "s":
		return "정찰 중" if u.goal != null else "대기"
	if u.tgt != null:
		return "적과 전투 중" if not u.tgt.has("op") else "기지 공격 중"
	if u.goal != null:
		return "이동 중"
	return "전투 중" if t - u.cbt < 3.0 else "대기"

func ctl_stat(u: Dictionary) -> String:
	match u.t:
		"c", "r":
			return "공격력 " + str(snappedf(patk(u), 0.1)) + " · 공속 " + str(snappedf(u.aspd, 0.1)) + " · 사거리 " + str(int(u.rng))
		"h":
			return "치료량 " + str(snappedf(heal_v(u), 0.1))
		"m":
			return "캔 광석 " + str(int(u.mo)) + " · 진화석 " + str(u.ms) + " · 운반량 " + str(carry(u))
		_:
			return "연료 " + str(int(100.0 * u.f / maxf(1.0, u.fm))) + "% · 시야 " + str(int(vis(u)))

func ctl_list() -> Array:
	var lst: Array = bots.filter(func(q): return q.t == ctl_f)
	lst.sort_custom(func(a, b): return a.ev > b.ev or (a.ev == b.ev and (a.lv > b.lv or (a.lv == b.lv and a.id < b.id))))
	return lst

func _build_ctl(sr: Rect2) -> void:
	var x0 := sr.position.x + 176.0
	var w := sr.size.x - 188.0
	var fs: Array = ["c", "r", "h", "m", "s", "dead"]
	var fw := (w - 5.0 * 6.0) / 6.0
	for i in fs.size():
		_add("cf", Rect2(x0 + i * (fw + 6.0), sr.position.y + 56.0, fw, 32.0), true, "", fs[i])
	var top := sr.position.y + 96.0
	if ctl_f != "dead":
		var up := 0
		for q in bots:
			if q.t == ctl_f and q.lv < 11:
				up += lvup_cost(q)
		_add("ca_sel", Rect2(x0 + w - 250.0, top, 90.0, 28.0))
		_add("ca_up", Rect2(x0 + w - 152.0, top, 152.0, 28.0), up > 0 and ore >= up, "", up)
	var ly := top + 36.0
	var lh := sr.end.y - 50.0 - ly
	_add("ctllist", Rect2(x0, ly, w, lh))
	var rows: Array = dead if ctl_f == "dead" else ctl_list()
	ctl_scroll = clampf(ctl_scroll, 0.0, maxf(0.0, rows.size() * 46.0 - lh))
	for i in rows.size():
		var ry := ly + i * 46.0 - ctl_scroll
		if ry < ly - 1.0 or ry + 42.0 > ly + lh + 1.0:
			continue
		var q: Dictionary = rows[i]
		if ctl_f == "dead":
			var c := 15 * int(q.lv) + 30 * int(q.ev)
			_add("cr_rev", Rect2(x0 + w - 130.0, ry + 7.0, 124.0, 28.0), ore >= c, "", q)
		else:
			if q.lv < 11:
				_add("cu_up", Rect2(x0 + w - 286.0, ry + 7.0, 96.0, 28.0), ore >= lvup_cost(q), "", q)
			elif q.ev < 3 and q.t != "s":
				_add("cu_evo", Rect2(x0 + w - 286.0, ry + 7.0, 96.0, 28.0), stone >= EVC[q.ev], "", q)
			_add("cu_sell", Rect2(x0 + w - 186.0, ry + 7.0, 120.0, 28.0), true, "", q)
			_add("cu_see", Rect2(x0 + w - 62.0, ry + 7.0, 56.0, 28.0), true, "", q)

func ui_press(it: Dictionary, rclick: bool = false) -> void:
	match it.id:
		"restart":
			paused = false
			shop_open = false
			info_open = false
			new_game()
		"resume":
			paused = false
		"pause":
			paused = true
			shop_open = false
		"desel":
			clear_sel()
		"all":
			clear_sel()
			for q in bots:
				q.sel = true
		"home":
			cam_to(B)
		"info":
			info_open = not info_open
			shop_open = false
		"infox":
			info_open = false
		"shop":
			shop_open = not shop_open
			info_open = false
		"shopx":
			shop_open = false
		"save":
			msg("저장·이어하기는 다음 단계(로비)에서 연결돼요")
		"quit":
			if t < quit_arm:
				quit_arm = 0.0
				new_game()
			else:
				quit_arm = t + 3.0
				msg("한 번 더 누르면 게임을 끝내요")
		"tab":
			shop_tab = it.arg
			shop_desc = ""
		"slot":
			num_key(ORDER.find(it.arg))
		"oil":
			hold_oil()
		"cf":
			ctl_f = it.arg
			ctl_arm = -1
			ctl_scroll = 0.0
		"ca_sel":
			clear_sel()
			for q in bots:
				if q.t == ctl_f:
					q.sel = true
		"ca_up":
			var lst: Array = bots.filter(func(q): return q.t == ctl_f and q.lv < 11)
			lst.sort_custom(func(a, b): return a.lv < b.lv)
			var n := 0
			for q in lst:
				if not lvup_one(q):
					break
				n += 1
			msg((UT[ctl_f].n + " 로봇 " + str(n) + "대를 레벨업했어요") if n > 0 else "광석이 부족해요")
		"cr_rev":
			var d: Dictionary = it.arg
			var c := 15 * int(d.lv) + 30 * int(d.ev)
			if ore < c:
				msg("즉시 부활에 광석 " + str(c) + " 필요해요")
			else:
				ore -= c
				SS.spItem += c
				dead.erase(d)
				revive(d)
		"cu_up":
			if not lvup_one(it.arg):
				msg("광석이 부족해요 (" + str(lvup_cost(it.arg)) + " 필요)")
		"cu_evo":
			var keep := selected()
			clear_sel()
			it.arg.sel = true
			do_evolve()
			clear_sel()
			for q in keep:
				q.sel = true
		"cu_sell":
			var q: Dictionary = it.arg
			if ctl_arm != q.id:
				ctl_arm = q.id
				ctl_arm_t = t + 3.0
			else:
				ctl_arm = -1
				var keep := selected()
				clear_sel()
				q.sel = true
				sell_arm = t + 1.0
				do_sell()
				for k in keep:
					if k.hp > 0:
						k.sel = true
		"cu_see":
			clear_sel()
			it.arg.sel = true
			cam_to(it.arg.p)
		"card":
			var c: Dictionary = it.arg
			shop_desc = c.desc
			if not it.on:
				return
			if not touch_ui() and not rclick:
				return
			match c.act:
				"prod":
					produce(c.k)
				"rev":
					var d = _best_dead()
					if d != null:
						var rc := 15 * int(d.lv) + 30 * int(d.ev)
						ore -= rc
						SS.spItem += rc
						dead.erase(d)
						revive(d)
				"vb":
					shop_open = false
					start_aim("vb")
				"dr":
					shop_open = false
					start_aim("dr")
				"oilb":
					ore -= 40.0
					SS.spItem += 40
					oil += 1
				"oilh":
					shop_open = false
					hold_oil()
				"upsel":
					do_upgrade()
				"uptype":
					var lst: Array = bots.filter(func(q): return q.t == c.k and q.lv < 11)
					lst.sort_custom(func(a, b): return a.lv < b.lv)
					if not lst.is_empty() and lvup_one(lst[0]):
						msg(UT[c.k].n + " 로봇 1대 업그레이드!")
					else:
						msg("광석이 부족하거나 이미 최고 레벨이에요")
				"evo":
					do_evolve()
				"sell":
					do_sell()

func lvup_one(u: Dictionary) -> bool:
	var c := lvup_cost(u)
	if u.lv >= 11 or ore < c:
		return false
	ore -= c
	SS.spUp += c
	u.lv += 1
	calc(u)
	return true

func hold_oil() -> void:
	if oil <= 0:
		msg("기름이 없어요. 상점 아이템 탭에서 먼저 구매해 주세요")
		return
	aim = "" if aim == "oil" else "oil"
	if aim == "oil":
		msg("기름을 뿌릴 곳을 누르세요 (원 안의 로봇 모두에게 적용)")

func start_aim(k: String) -> void:
	if k == "vb":
		if vb_cd > 0.0:
			msg("시야 폭탄 재사용 대기 %d:%02d" % [int(vb_cd / 60.0), int(vb_cd) % 60])
			return
		if ore < 60.0:
			msg("광석이 부족해요 (60 필요)")
			return
		msg("시야 폭탄을 던질 곳을 지도에서 누르세요")
	elif k == "dr":
		if dr_cd > 0.0:
			msg("드론 재사용 대기 " + str(ceili(dr_cd)) + "초")
			return
		if ore < 25.0:
			msg("광석이 부족해요 (25 필요)")
			return
		msg("드론을 던질 곳을 지도에서 누르세요")
	aim = k

func throw_at(w: Vector2) -> void:
	if aim == "oil":
		var us_: Array = bots.filter(func(q): return (q.p as Vector2).distance_to(w) <= 70.0)
		if us_.is_empty():
			msg("범위 안에 로봇이 없어요. 로봇 근처를 눌러 주세요")
			return
		var sc := 0
		for q in us_:
			q.oilT = 20.0
			if q.t == "s" and q.fm > 0.0:
				q.f = minf(q.fm, q.f + q.fm * 0.5)
				sc += 1
		oil -= 1
		fx.append({"k": "ring", "p": w, "t": 0.6, "r": 70.0})
		msg("기름 뿌리기! 로봇 " + str(us_.size()) + "대가 20초간 이속·공속 +20%" + ("" if sc == 0 else " · 정찰 로봇 " + str(sc) + "대 연료 +50%"))
	elif aim == "vb":
		ore -= 60.0
		SS.spItem += 60
		vb_cd = vb_cdv()
		reveal(w, 180.0)
		fx.append({"k": "ring", "p": w, "t": 0.6, "r": 180.0})
		msg("시야 폭탄! 주변이 영구적으로 밝혀졌어요")
	elif aim == "dr":
		ore -= 25.0
		SS.spItem += 25
		dr_cd = d_cd()
		drones.append({"p": w, "t": 4.0})
		msg("정찰 드론 투하! 4초 동안 보여요")
	aim = ""

func vis2(p: Vector2) -> bool:
	if seen(p):
		return true
	for d in drones:
		if p.distance_to(d.p) < 260.0:
			return true
	return false

func num_key(i: int) -> void:
	if i < 0 or i >= ORDER.size():
		return
	var k: String = ORDER[i]
	var dbl: bool = last_num.k == k and t - last_num.t < 0.35
	last_num = {"k": "" if dbl else k, "t": t}
	if dbl:
		var lst: Array = bots.filter(func(q): return q.t == k)
		if not lst.is_empty():
			var best: Vector2 = lst[0].p
			var bn := -1
			for a in lst:
				var n := 0
				for b in lst:
					if (a.p as Vector2).distance_to(b.p) < 350.0:
						n += 1
				if n > bn:
					bn = n
					best = a.p
			cam_to(best)
			fx.append({"k": "ring", "p": best, "t": 0.6, "r": 120.0})
		return
	clear_sel()
	for q in bots:
		if q.t == k:
			q.sel = true

# ═════════ 화면 UI 그리기 ═════════
func _ui_tf(pos: Vector2, rot: float, scl: float) -> void:
	draw_set_transform_matrix(inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(rot, Vector2(scl, scl), 0.0, pos))

func _ui_reset() -> void:
	draw_set_transform_matrix(inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO))

func _diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)

func _hud(f: Font) -> void:
	_build_ui()
	_ui_reset()
	var u := ui_size()
	var hov = null
	if not touch_ui():
		hov = ui_hit(mouse_ui * us)
	var tip := ""
	# 오른쪽 위 정보 띠
	var rl := maxf(0.0, next_raid - t)
	var items: Array = [["flag", str(captured()) + "/50", Color("#e6edf3")], ["stone", str(stone), Color("#c08cff")], ["base", str(int(base.hp)), Color("#e6edf3")], ["raid", "레이드!" if raid_alive else "%d:%02d" % [int(rl / 60.0), int(rl) % 60], Color("#ff8a6b") if (raid_alive or rl < 30.0) else Color("#e6edf3")], ["time", "%d:%02d" % [int(t / 60.0), int(t) % 60], Color("#e6edf3")]]
	var tw := 0.0
	for it in items:
		tw += f.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 34.0
	var tx := u.x - tw - 12.0
	sb_panel.draw(get_canvas_item(), Rect2(tx - 8.0, 8.0, tw + 16.0, 34.0))
	for it in items:
		var c := Vector2(tx + 9.0, 25.0)
		match it[0]:
			"flag":
				draw_line(c + Vector2(-4, 7), c + Vector2(-4, -7), Color("#e6edf3"), 2.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -7), c + Vector2(6, -4), c + Vector2(-3, -1)]), Color("#ffcf3a"))
			"stone":
				_diamond(c, 6.0, Color("#c08cff"))
			"base":
				draw_colored_polygon(Transform2D(0.0, c) * oct(7.0), Color("#5fe0c4"))
			"raid":
				draw_circle(c, 5.5, Color("#ff3a2a"))
			"time":
				draw_arc(c, 6.0, 0.0, TAU, 16, Color("#aab8c5"), 1.5)
				draw_line(c, c + Vector2(0, -4), Color("#aab8c5"), 1.5)
		draw_string(f, Vector2(tx + 20.0, 31.0), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, it[2])
		tx += f.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 34.0
	# 모바일 왼쪽 위 (웹과 같은 ⏸ · 선택 해제)
	for it in ui:
		if it.id == "pause":
			var r: Rect2 = it.r
			sb_btn.draw(get_canvas_item(), r)
			draw_rect(Rect2(r.position + Vector2(15, 13), Vector2(5, 18)), Color.WHITE)
			draw_rect(Rect2(r.position + Vector2(24, 13), Vector2(5, 18)), Color.WHITE)
		elif it.id == "desel":
			sb_red.draw(get_canvas_item(), it.r)
			draw_string(f, (it.r as Rect2).position + Vector2(0, 29), "X  선택 해제", HORIZONTAL_ALIGNMENT_CENTER, (it.r as Rect2).size.x, 17, Color.WHITE)
	# 아래 HUD
	var h := hud_rect()
	sb_hud.draw(get_canvas_item(), h)
	var ox := h.position.x
	var oy := h.position.y
	var s := selected()
	var su = s[0] if not s.is_empty() else null
	var stats: Array = []
	if su != null:
		var hasatk: bool = UT[su.t].atk > 0
		var sp6 := str(su.lv)
		var sp6n := "레벨"
		if su.t == "m":
			sp6 = str(carry(su))
			sp6n = "한 번에 나르는 광석"
		elif su.t == "s":
			sp6 = str(int(vis(su)))
			sp6n = "시야 범위"
		stats = [[Color("#ff8a5a"), str(snappedf(patk(su), 0.1)) if hasatk else "-", "공격력"], [Color("#ffd25a"), ("%.2f" % su.aspd) if hasatk else "-", "공격 속도 (초당 횟수)"],
			[Color("#7fd8ff"), str(int(su.sp * (1.2 if su.oilT > 0.0 else 1.0))), "이동 속도"], [Color("#c0a0ff"), str(su.ev) + "/3", "진화 단계"],
			[Color("#8be28b"), str(snappedf(heal_v(su), 0.1)) if su.t == "h" else (str(int(su.rng)) if su.rng > 0 else "-"), "초당 치유량" if su.t == "h" else "공격 사거리"],
			[Color("#f2a64e"), sp6, sp6n], [Color("#e6edf3"), str(s.size()), "선택한 로봇 수"], [Color("#ffb03a"), (str(ceili(su.oilT)) + "s") if su.oilT > 0.0 else "-", "기름 효과 남은 시간"]]
	else:
		stats = [[Color("#ff8a5a"), str(snappedf(45.0 * (1.0 + 0.05 * captured()), 0.1)), "기지 포탑 공격력"], [Color("#ffd25a"), "1.00", "기지 포탑 공격 속도 (초당 횟수)"], [Color("#7fd8ff"), "280", "기지 포탑 사거리"], [Color("#8be28b"), "2", "기지 체력 회복 (초당)"],
			[Color("#b8c2cc"), str(captured()), "정복한 상대 기지"], [Color("#f2d14e"), str(snappedf(income(), 0.1)), "초당 광석 수입"], [Color("#c0a0ff"), str(stone), "보유 진화석"], [Color("#5fe0c4"), str(bots.size()), "우리 로봇 수"]]
	for i in 8:
		var st_: Array = stats[i]
		var px := ox + 12.0 + (i / 4) * 66.0
		var py := oy + 24.0 + (i % 4) * 24.0
		_diamond(Vector2(px + 5.0, py - 5.0), 5.0, st_[0])
		draw_string(f, Vector2(px + 14.0, py), st_[1], HORIZONTAL_ALIGNMENT_LEFT, 52, 14, Color.WHITE)
		if not touch_ui() and Rect2(px, py - 14.0, 62.0, 20.0).has_point(mouse_ui):
			tip = st_[2]
	# 초상화
	var pr := Rect2(ox + 146.0, oy + 8.0, 90.0, 90.0)
	draw_rect(pr, Color("#0a1016"))
	draw_circle(pr.get_center(), 40.0, Color("#16222e"))
	if su != null:
		var col: Color = UT[su.t].col
		if su.ev > 0:
			col = [Color("#a98ae0"), Color("#9462e0"), Color("#7d3fdc")][su.ev - 1]
		_ui_tf(pr.get_center(), -0.5, 2.6)
		art_bot(self, su.t, col, UT[su.t].acc, t)
	else:
		_ui_tf(pr.get_center() + Vector2(0, 2), 0.0, 0.62)
		art_base(self, Vector2.ZERO, t, inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(0.0, Vector2(0.62, 0.62), 0.0, pr.get_center() + Vector2(0, 2)))
	_ui_reset()
	var badge := ("x" + str(s.size())) if s.size() > 1 else (("Lv " + str(su.lv)) if su != null else "기지")
	sb_badge.draw(get_canvas_item(), Rect2(pr.get_center().x - 26.0, pr.end.y - 4.0, 52.0, 18.0))
	draw_string(f, Vector2(pr.get_center().x - 26.0, pr.end.y + 9.0), badge, HORIZONTAL_ALIGNMENT_CENTER, 52, 11, GOLD)
	# 명령 버튼 6개 (E 전체 · Q 기지 · I 정보 · Y 상점 · 저장 · 종료)
	for it in ui:
		var cmd := -1
		for i in CMDS.size():
			if CMDS[i][0] == it.id and (it.r as Rect2).position.y > 40.0:
				cmd = i
		if cmd < 0:
			continue
		var r: Rect2 = it.r
		var lit: bool = (it.id == "quit" and t < quit_arm) or (it.id == "info" and info_open) or (it.id == "shop" and shop_open)
		(sb_btn_hi if (hov == it or lit) else sb_btn).draw(get_canvas_item(), r)
		var top: String = it.arg
		if it.id == "save":
			top = "S"
			draw_rect(Rect2(r.position + Vector2(15, 6), Vector2(14, 14)), Color("#7fb8ff"))
			draw_rect(Rect2(r.position + Vector2(18, 6), Vector2(8, 5)), Color("#0b1118"))
		elif it.id == "quit":
			draw_line(r.position + Vector2(16, 7), r.position + Vector2(28, 19), Color("#ff8a6b"), 2.5)
			draw_line(r.position + Vector2(28, 7), r.position + Vector2(16, 19), Color("#ff8a6b"), 2.5)
		else:
			draw_string(f, r.position + Vector2(0, 19), top, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, GOLD)
		draw_string(f, r.position + Vector2(0, 36), CMDS[cmd][2], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#c9d4dc"))
		if hov == it:
			tip = it.tip
	# 체력바 · 두 번째 바
	var hpv := 0.0
	var hpm := 0.0
	if su != null:
		for q in s:
			hpv += maxf(0.0, q.hp)
			hpm += q.mh
	else:
		hpv = maxf(0.0, base.hp)
		hpm = base.mh
	var rr := hpv / maxf(hpm, 1.0)
	var hb := Rect2(ox + 244.0, oy + 58.0, 274.0, 22.0)
	draw_rect(hb, Color("#081018"))
	draw_rect(Rect2(hb.position, Vector2(hb.size.x * rr, hb.size.y)), Color("#46c060") if rr > 0.5 else (Color("#d8b040") if rr > 0.25 else Color("#d04a3a")))
	draw_string(f, hb.position + Vector2(0, 16), ("" if su != null else "기지 ") + str(int(ceilf(hpv))) + " / " + str(int(hpm)), HORIZONTAL_ALIGNMENT_CENTER, hb.size.x, 13, Color.WHITE)
	var b2 := 0.0
	var b2t := ""
	var b2c := Color("#3a7ae0")
	if su != null:
		if su.t == "s":
			b2 = su.f / maxf(1.0, su.fm)
			b2t = "연료 " + str(int(su.f)) + " / " + str(int(su.fm))
			b2c = Color("#e8c04a")
		elif su.oilT > 0.0:
			b2 = su.oilT / 20.0
			b2t = "기름 효과 " + str(ceili(su.oilT)) + "초"
			b2c = Color("#e8a040")
		else:
			b2 = su.lv / 11.0
			b2t = "레벨 " + str(su.lv) + " / 11"
	else:
		b2 = 1.0 if raid_alive else clampf(1.0 - rl / 600.0, 0.0, 1.0)
		b2t = "레이드 진행 중!" if raid_alive else ("다음 레이드 %d:%02d" % [int(rl / 60.0), int(rl) % 60])
		if raid_alive:
			b2c = Color("#d04a3a")
	var b2r := Rect2(ox + 244.0, oy + 86.0, 274.0, 18.0)
	draw_rect(b2r, Color("#081018"))
	draw_rect(Rect2(b2r.position, Vector2(b2r.size.x * clampf(b2, 0.0, 1.0), b2r.size.y)), b2c)
	draw_string(f, b2r.position + Vector2(0, 14), b2t, HORIZONTAL_ALIGNMENT_CENTER, b2r.size.x, 12, Color.WHITE)
	# 슬롯 (1~5 로봇 · 6 기름)
	for it in ui:
		if it.id != "slot" and it.id != "oil":
			continue
		var r: Rect2 = it.r
		var on: bool = it.on
		var lit: bool = it.id == "oil" and aim == "oil"
		(sb_btn_hi if (hov == it or lit) else (sb_btn if on else sb_dis)).draw(get_canvas_item(), r)
		if it.id == "slot":
			var k: String = it.arg
			var n := 0
			for q in bots:
				if q.t == k:
					n += 1
			_ui_tf(r.get_center() + Vector2(-2, 0), 0.0, 1.15)
			art_bot(self, k, UT[k].col, UT[k].acc, t)
			_ui_reset()
			draw_string(f, r.position + Vector2(3, 11), str(ORDER.find(k) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.6))
			draw_string(f, r.position + Vector2(0, 31), str(n), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 4.0, 11, Color.WHITE)
		else:
			var cc := r.get_center() + Vector2(-2, 1)
			draw_rect(Rect2(cc + Vector2(-6, -8), Vector2(12, 16)), Color("#0b1118"))
			draw_rect(Rect2(cc + Vector2(-5, -7), Vector2(10, 14)), Color("#d9a441") if on else Color(0.4, 0.4, 0.4))
			draw_rect(Rect2(cc + Vector2(-3, -11), Vector2(6, 4)), Color("#2a1a08"))
			draw_string(f, r.position + Vector2(3, 11), "6", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.6))
			draw_string(f, r.position + Vector2(0, 31), str(oil), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 4.0, 11, Color.WHITE)
		if hov == it:
			tip = it.tip
	# 광석
	var orr := Rect2(ox + 530.0, oy + 86.0, 152.0, 26.0)
	draw_rect(orr, Color("#081018"))
	draw_string(f, orr.position + Vector2(8, 19), str(int(ore)), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#5fe0c4"))
	draw_string(f, orr.position + Vector2(0, 18), "+" + str(snappedf(income(), 0.1)) + "/s", HORIZONTAL_ALIGNMENT_RIGHT, orr.size.x - 8.0, 11, Color("#aab8c5"))
	# 조준 안내
	if aim != "":
		var nm: String = {"oil": "기름", "vb": "시야 폭탄", "dr": "드론"}[aim]
		var at := nm + " · 지도에서 누르세요 · " + ("우클릭·Esc로 취소" if not touch_ui() else "슬롯을 다시 누르면 취소")
		var aw := f.get_string_size(at, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 30.0
		draw_rect(Rect2(u.x / 2.0 - aw / 2.0, h.position.y - 40.0, aw, 28.0), Color(0.3, 0.24, 0.05, 0.9))
		draw_string(f, Vector2(u.x / 2.0 - aw / 2.0 + 15.0, h.position.y - 21.0), at, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)
	# 메시지 (웹처럼 위 가운데)
	if msg_t > 0.0:
		var a := minf(1.0, msg_t)
		var w := f.get_string_size(msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 28.0
		var mx := u.x / 2.0 - w / 2.0
		draw_rect(Rect2(mx, 10.0, w, 30.0), Color(0.04, 0.055, 0.07, 0.88 * a))
		draw_rect(Rect2(mx, 10.0, w, 30.0), Color(0.2, 0.25, 0.3, a), false, 1.0)
		draw_string(f, Vector2(mx + 14.0, 30.0), msg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.72, 0.42, a))
	if info_open:
		_info(f)
	if shop_open:
		_shop(f, hov)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
		draw_string(f, Vector2(0, u.y / 2.0 - 60.0), "일시정지", HORIZONTAL_ALIGNMENT_CENTER, u.x, 34, GOLD)
		for it in ui:
			sb_btn.draw(get_canvas_item(), it.r)
			draw_string(f, (it.r as Rect2).position + Vector2(0, 34), "계속하기" if it.id == "resume" else "다시 시작", HORIZONTAL_ALIGNMENT_CENTER, (it.r as Rect2).size.x, 18, Color.WHITE)
	if won or lost:
		draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
		var big := "승리! 모든 기지를 정복했어요" if won else "패배 · 기지가 파괴됐어요"
		draw_string(f, Vector2(0, u.y / 2.0 - 20.0), big, HORIZONTAL_ALIGNMENT_CENTER, u.x, 40, GOLD if won else Color("#ff8a6b"))
		draw_string(f, Vector2(0, u.y / 2.0 + 16.0), "시간 " + "%d:%02d" % [int(t / 60.0), int(t) % 60] + "  ·  처치 " + str(kills) + "  ·  정복 " + str(captured()), HORIZONTAL_ALIGNMENT_CENTER, u.x, 16, Color.WHITE)
		for it in ui:
			sb_btn.draw(get_canvas_item(), it.r)
			draw_string(f, (it.r as Rect2).position + Vector2(0, 36), "다시 시작", HORIZONTAL_ALIGNMENT_CENTER, (it.r as Rect2).size.x, 18, Color.WHITE)
	if tip != "" and not shop_open and not info_open:
		_tooltip(f, tip)
	elif tip == "" and hov == null and not shop_open and not info_open and not paused and not won and not lost and dn == null and not box_active:
		_world_tip(f)

# ═════════ 올렸을 때 말풍선 (웹 hovObj·info·einfo) ═════════
func info_txt(u: Dictionary) -> String:
	var d: Dictionary = UT[u.t]
	var s: String = d.n + " Lv " + str(u.lv) + "/11 · 진화 " + str(u.ev) + "/3\n공격력 " + ("%.1f" % patk(u) if float(d.atk) > 0.0 else "-") + " · 체력 " + str(mini(ceili(u.hp), roundi(u.mh))) + "/" + str(roundi(u.mh)) + " · 이속 " + str(roundi(u.sp))
	if not (u.t == "m" or u.t == "s" or u.t == "h"):
		s += "\n공속 " + "%.2f" % float(u.aspd) + "회/초"
	if u.t == "m":
		s += "\n캔 광석 " + str(int(u.mo)) + " · 진화석 " + str(u.ms) + (" · 운반 중 " + str(u.c) if u.c > 0 else "") + "\n운반량 " + str(carry(u)) + " (진화 광산은 6레벨부터)"
	if u.t == "s":
		s += "\n시야 " + str(roundi(vis(u))) + " · 연료 " + str(roundi(u.f)) + "/" + str(roundi(u.fm))
	if u.t == "h":
		s += "\n치유 " + "%.1f" % heal_v(u) + "/초"
	if u.oilT > 0.0:
		s += "\n기름 효과 " + str(ceili(u.oilT)) + "초 (이속·공속 +20%)"
	return s

func einfo_txt(u: Dictionary) -> String:
	var n := "외계 사격병"
	if u.t == "k":
		n = "외계 추격자" + (" (추격 중!)" if u.ag != null else " · 건드리면 끝까지 쫓아와요")
	elif u.t == "c":
		n = "외계 근접병"
	var s: String = n + " Lv " + str(u.lv) + "/11" + (" · 진화 " + str(u.ev) if u.ev > 0 else "")
	s += "\n공격력 " + "%.1f" % float(u.atk) + " · 체력 " + str(mini(ceili(u.hp), roundi(u.mh))) + "/" + str(roundi(u.mh)) + " · 이속 " + str(roundi(u.sp))
	s += "\n공속 " + "%.2f" % float(u.aspd) + "회/초"
	return s

func hov_obj(w: Vector2):
	var best = null
	var bd := 20.0
	for q in bots:
		var d := w.distance_to(q.p)
		if d < bd:
			bd = d
			best = q
	for q in ens:
		if q.hp <= 0 or not vis2(q.p):
			continue
		var d := w.distance_to(q.p)
		if d < bd:
			bd = d
			best = q
	if best != null:
		return {"p": best.p, "ev": best.ev > 0, "tip": info_txt(best) if best.team == 0 else einfo_txt(best)}
	if w.distance_to(B) < 58.0:
		var cap := captured()
		return {"p": B + Vector2(0, -30), "ev": false, "tip": "우리 기지\n체력 " + str(mini(ceili(base.hp), roundi(base.mh))) + " / " + str(roundi(base.mh)) + " · 초당 2 회복\n포탑 공격력 " + "%.1f" % (45.0 * (1.0 + 0.05 * cap)) + " · 1초마다 · 사거리 280\n정복한 기지 1개마다 포탑 +5%\n우물(반경 300): 초당 체력 10% · 전투 중 3%"}
	for o in outs:
		if w.distance_to(o.p) < 42.0 and seen(o.p):
			var z: int = o.tr + 1
			if o.cap:
				return {"p": (o.p as Vector2) + Vector2(0, -30), "ev": false, "tip": "정복한 기지 · " + str(z) + "구역\n기지 수입 초당 +" + "%.2f" % ((0.3 + 0.25 * o.s) * eco()) + "\n우리 기지 포탑 +5%"}
			var df: Array = ens.filter(func(e): return e.hp > 0 and e.get("oid", -1) == o.id and e.ag == null)
			var de := df.filter(func(e): return e.ev > 0).size()
			var g := roundi(20.0 + 20.0 * o.s * o.s)
			var s := "외계 기지 · " + str(z) + "구역 · Lv " + str(o.lv) + (" · 진화 " + str(o.ev) + "단계" if o.ev > 0 else "")
			s += "\n체력 " + str(mini(ceili(o.hp), roundi(o.mx))) + " / " + str(roundi(o.mx))
			s += "\n포탑 공격력 " + "%.1f" % (o.atk * 3.0) + " · 1.3초마다 · 사거리 200\n같은 로봇 연속 공격 시 최대 +120%"
			s += "\n수비대 " + str(df.size()) + "마리" + (" (진화 " + str(de) + ")" if de > 0 else "") + " · 기지를 부수면 사라져요"
			s += "\n보호막: 받는 피해 " + str(roundi(shm(o) * 100.0)) + "% (수비대를 잡을수록 약해져요)"
			s += "\n정복 보상: 광석 " + str(g) + " · 진화석 " + str(4 * z) + " · 게임 끝 청석 +" + str(10 * z)
			return {"p": (o.p as Vector2) + Vector2(0, -30), "ev": o.ev > 0, "tip": s}
	for m in mines:
		if w.distance_to(m.p) < 24.0 and seen(m.p):
			var n := bots.filter(func(q): return q.mine != null and is_same(q.mine, m)).size()
			if m.ev:
				return {"p": (m.p as Vector2) + Vector2(0, -14), "ev": true, "tip": "진화 광산" + (" · 안전 지역" if m.get("safe", false) else "") + "\n남은 진화석 " + str(m.amt) + " / 150\n6레벨 이상 채굴 로봇만 캘 수 있어요\n채굴 중인 로봇 " + str(n) + "대"}
			return {"p": (m.p as Vector2) + Vector2(0, -14), "ev": false, "tip": "광산\n남은 광석 " + str(ceili(m.amt)) + " / 700\n채굴 중인 로봇 " + str(n) + "대\n채굴 로봇을 선택하고 광산을 누르면 캐요"}
	return null

func _wrap(f: Font, line: String, fs: int, mw: float) -> Array:
	if f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= mw:
		return [line]
	var out: Array = []
	var cur := ""
	for wd in line.split(" "):
		var tr := wd if cur == "" else cur + " " + wd
		if f.get_string_size(tr, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > mw and cur != "":
			out.append(cur)
			cur = wd
		else:
			cur = tr
	if cur != "":
		out.append(cur)
	return out

func _world_tip(f: Font) -> void:
	var sp := mouse_ui * us
	if touch_ui():
		if tap_tip_t <= 0.0:
			return
		sp = tap_tip_p
	elif mm_rect().has_point(sp):
		return
	var hv = hov_obj(s2w(sp))
	if hv == null:
		return
	var u := ui_size()
	var mw := minf(380.0, u.x - 24.0) - 20.0
	var rows: Array = []
	var L: PackedStringArray = (hv.tip as String).split("\n")
	for i in L.size():
		for r in _wrap(f, L[i], 13, mw):
			rows.append([r, i])
	var w2 := 0.0
	for r in rows:
		w2 = maxf(w2, f.get_string_size(r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	w2 = ceilf(w2) + 20.0
	var LH := 18.0
	var h2 := rows.size() * LH + 12.0
	var a: Vector2 = (get_canvas_transform() * (hv.p as Vector2)) / us
	var tx := a.x + 18.0
	var ty := a.y - h2 - 10.0
	if tx + w2 > u.x - 6.0:
		tx = a.x - w2 - 18.0
	tx = maxf(tx, 6.0)
	if ty < 6.0:
		ty = a.y + 18.0
	ty = minf(ty, u.y - 6.0 - h2)
	var rr := Rect2(tx, ty, w2, h2)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(10 / 255.0, 14 / 255.0, 20 / 255.0, 0.95)
	sb.border_color = Color("#b080ff") if hv.ev else Color("#3a4a58")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.draw(get_canvas_item(), rr)
	for k in rows.size():
		var r: Array = rows[k]
		draw_string(f, Vector2(tx + 10.0, ty + LH + k * LH), r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE if r[1] == 0 else Color("#c9d4dc"))

# 로봇끼리 겹치지 않게 살짝 밀어내기 (격자로 가까운 것만 비교)
func separate(arr: Array, r: float, dt: float) -> void:
	var G := {}
	for i in arr.size():
		var q = arr[i]
		var key := int(q.p.x / r) * 10000 + int(q.p.y / r)
		if not G.has(key):
			G[key] = []
		G[key].append(i)
	var k := minf(1.0, dt * 8.0)
	for i in arr.size():
		var a = arr[i]
		var ax := int(a.p.x / r)
		var ay := int(a.p.y / r)
		for gx in range(ax - 1, ax + 2):
			for gy in range(ay - 1, ay + 2):
				var key := gx * 10000 + gy
				if not G.has(key):
					continue
				for j in G[key]:
					if j <= i:
						continue
					var b = arr[j]
					var dv: Vector2 = (a.p as Vector2) - (b.p as Vector2)
					var d := dv.length()
					if d >= r:
						continue
					if d < 0.01:
						dv = Vector2.from_angle(float(i * 7 + j)) 
						d = 0.01
					var push := dv / maxf(d, 0.01) * (r - d) * 0.5 * k
					var na: Vector2 = (a.p as Vector2) + push
					var nb: Vector2 = (b.p as Vector2) - push
					if a.team == 1 or seen(na):
						a.p = na
					if b.team == 1 or seen(nb):
						b.p = nb

func _tooltip(f: Font, s: String) -> void:
	var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20.0
	var w := minf(360.0, tw)
	var lines := ceili(tw / 360.0)
	var hh := 12.0 + lines * 18.0
	var p := mouse_ui + Vector2(16, -hh - 8.0)
	var u := ui_size()
	p.x = clampf(p.x, 6.0, u.x - w - 6.0)
	p.y = clampf(p.y, 6.0, u.y - hh - 6.0)
	draw_rect(Rect2(p, Vector2(w, hh)), Color(0.04, 0.055, 0.08, 0.96))
	draw_rect(Rect2(p, Vector2(w, hh)), Color("#3a4a58"), false, 1.0)
	draw_multiline_string(f, p + Vector2(10, 19), s, HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 13, -1, Color.WHITE)

func _info(f: Font) -> void:
	var ir := info_rect()
	draw_rect(Rect2(Vector2.ZERO, ui_size()), Color(0, 0, 0, 0.35))
	sb_shop.draw(get_canvas_item(), ir)
	draw_string(f, ir.position + Vector2(18, 34), "이번 게임 기록", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
	for it in ui:
		if it.id == "infox":
			sb_btn.draw(get_canvas_item(), it.r)
			draw_string(f, (it.r as Rect2).position + Vector2(0, 21), "X", HORIZONTAL_ALIGNMENT_CENTER, (it.r as Rect2).size.x, 15, Color.WHITE)
	var tot: int = int(SS.spRobot) + int(SS.spUp) + int(SS.spItem)
	var secs: Array = [["획득", [["총 획득 광석", str(int(SS.earn))], ["획득한 진화석", str(SS.stEarn)], ["정복한 기지", str(captured()) + " / 50"]]],
		["전투", [["처치한 적 로봇", str(SS.kills)], ["잃은 우리 로봇", str(SS.lost)], ["생산한 로봇", str(SS.made)], ["현재 로봇", str(bots.size())]]],
		["사용한 광석", [["로봇 생산", str(SS.spRobot)], ["업그레이드", str(SS.spUp)], ["아이템", str(SS.spItem)], ["합계", str(tot)], ["사용한 진화석", str(SS.stUsed)]]]]
	var cw := (ir.size.x - 48.0) / 3.0
	for i in secs.size():
		var x := ir.position.x + 16.0 + i * (cw + 8.0)
		var y := ir.position.y + 58.0
		draw_rect(Rect2(x, y, cw, ir.size.y - 74.0), Color(1, 1, 1, 0.03))
		draw_string(f, Vector2(x + 12.0, y + 24.0), secs[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GOLD)
		var rows: Array = secs[i][1]
		for j in rows.size():
			var ry := y + 52.0 + j * 30.0
			draw_string(f, Vector2(x + 12.0, ry), rows[j][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#aab8c5"))
			draw_string(f, Vector2(x, ry), rows[j][1], HORIZONTAL_ALIGNMENT_RIGHT, cw - 12.0, 14, Color.WHITE)

func _shop(f: Font, hov) -> void:
	var sr := shop_rect()
	draw_rect(Rect2(Vector2.ZERO, ui_size()), Color(0, 0, 0, 0.35))
	sb_shop.draw(get_canvas_item(), sr)
	draw_string(f, sr.position + Vector2(18, 34), "상 점", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, GOLD)
	var hint := "누르면 바로 구매해요 · X로 닫기" if touch_ui() else "Y 키로 열고 닫아요 · 우클릭으로 구매 · 마우스를 올리면 설명이 나와요"
	draw_string(f, sr.position + Vector2(84, 32), hint, HORIZONTAL_ALIGNMENT_LEFT, sr.size.x - 140.0, 12, Color("#96aab9"))
	draw_line(sr.position + Vector2(0, 48), sr.position + Vector2(sr.size.x, 48), Color(0.79, 0.64, 0.33, 0.4), 1.0)
	draw_line(sr.position + Vector2(170, 48), sr.position + Vector2(170, sr.size.y - 44.0), Color(1, 1, 1, 0.06), 1.0)
	var rows: Array = []
	var ly := 0.0
	for it in ui:
		var r: Rect2 = it.r
		match it.id:
			"shopx":
				sb_btn.draw(get_canvas_item(), r)
				draw_string(f, r.position + Vector2(0, 21), "X", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color.WHITE)
			"tab":
				(sb_tab_on if it.arg == shop_tab else sb_btn).draw(get_canvas_item(), r)
				var nm: String = {"prod": "로봇 생산", "item": "아이템", "up": "업그레이드 · 진화", "ctl": "로봇 제어"}[it.arg]
				draw_string(f, r.position + Vector2(12, 25), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, 14, GOLD if it.arg == shop_tab else Color("#c9d4dc"))
			"card":
				var c: Dictionary = it.arg
				var on: bool = it.on
				(sb_card_hi if hov == it else (sb_card if on else sb_dis)).draw(get_canvas_item(), r)
				if on:
					draw_rect(Rect2(r.position, Vector2(4, r.size.y)), Color("#3fcf7a"))
				draw_string(f, r.position + Vector2(14, 25), c.n, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20.0, 14, Color.WHITE if on else Color(1, 1, 1, 0.45))
				if c.cost != "":
					_diamond(r.position + Vector2(20, 45), 5.0, Color("#5fe0c4"))
					draw_string(f, r.position + Vector2(30, 50), c.cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#5fe0c4") if on else Color(0.37, 0.88, 0.77, 0.45))
			"cf":
				var k: String = it.arg
				(sb_tab_on if k == ctl_f else sb_btn).draw(get_canvas_item(), r)
				var lab := ""
				if k == "dead":
					lab = "부활 대기 " + str(dead.size())
				else:
					var n := 0
					for q in bots:
						if q.t == k:
							n += 1
					draw_circle(r.position + Vector2(12, 16), 4.0, UT[k].col)
					lab = UT[k].n + " " + str(n)
				draw_string(f, r.position + Vector2(18, 21), lab, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20.0, 13, GOLD if k == ctl_f else Color("#c9d4dc"))
			"ca_sel":
				sb_btn.draw(get_canvas_item(), r)
				draw_string(f, r.position + Vector2(0, 19), "모두 선택", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color.WHITE)
			"ca_up":
				(sb_btn if it.on else sb_dis).draw(get_canvas_item(), r)
				draw_string(f, r.position + Vector2(0, 19), "모두 1레벨 업  " + str(it.arg), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color.WHITE if it.on else Color(1, 1, 1, 0.45))
			"ctllist":
				ly = r.position.y
				if ctl_f != "dead":
					var nmb := 0
					for q in bots:
						if q.t == ctl_f:
							nmb += 1
					var hd: String = CTL_ROLE[ctl_f] + " · " + str(nmb) + "대" + ((" (전투 로봇 " + str(cap_n(ctl_f)) + "/40)") if is_cmb(ctl_f) else (" (최대 " + str(CAP[ctl_f]) + ")"))
					draw_string(f, r.position + Vector2(4, -16), hd, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 260.0, 13, Color("#c9d4dc"))
				else:
					draw_string(f, r.position + Vector2(4, -16), "죽은 전투 로봇은 레벨·진화 그대로 기지에서 부활해요.", HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 13, Color("#c9d4dc"))
				var lst: Array = dead if ctl_f == "dead" else ctl_list()
				if lst.is_empty():
					draw_string(f, r.position + Vector2(4, 24), "부활 대기 중인 로봇이 없어요" if ctl_f == "dead" else "이 종류의 로봇이 없어요. 로봇 생산 탭에서 만들 수 있어요.", HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 13, Color("#96aab9"))
				for i in lst.size():
					var ry := r.position.y + i * 46.0 - ctl_scroll
					if ry < r.position.y - 1.0 or ry + 42.0 > r.end.y + 1.0:
						continue
					var q: Dictionary = lst[i]
					var rowr := Rect2(r.position.x, ry, r.size.x, 42.0)
					draw_rect(rowr, Color(1, 1, 1, 0.07) if (ctl_f != "dead" and q.sel) else Color(1, 1, 1, 0.03))
					var cc: Color = Color("#a070ff") if q.ev > 0 else UT[q.t].col
					draw_circle(rowr.position + Vector2(12, 21), 5.0, cc)
					var nm: String = UT[q.t].n + ("" if ctl_f == "dead" else " #" + str(i + 1))
					draw_string(f, rowr.position + Vector2(22, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, 90, 13, Color.WHITE)
					draw_string(f, rowr.position + Vector2(22, 35), "Lv " + str(q.lv) + ("" if q.ev == 0 else "  ★" + str(q.ev)), HORIZONTAL_ALIGNMENT_LEFT, 90, 12, GOLD)
					if ctl_f == "dead":
						var left := ceili(rev_time(q) - q.w)
						draw_string(f, rowr.position + Vector2(120, 26), "부활까지 " + str(left) + "초" + (" (레이드 중 사망 x1.5)" if q.rd else ""), HORIZONTAL_ALIGNMENT_LEFT, rowr.size.x - 260.0, 13, Color("#c9d4dc"))
					else:
						draw_rect(Rect2(rowr.position + Vector2(78, 30), Vector2(36, 4)), Color(0, 0, 0, 0.8))
						draw_rect(Rect2(rowr.position + Vector2(78, 30), Vector2(36.0 * q.hp / q.mh, 4)), Color("#8be28b"))
						draw_string(f, rowr.position + Vector2(122, 18), "체력 " + str(ceili(q.hp)) + "/" + str(int(q.mh)) + " · " + ctl_stat(q), HORIZONTAL_ALIGNMENT_LEFT, rowr.size.x - 420.0, 12, Color.WHITE)
						draw_string(f, rowr.position + Vector2(122, 35), ctl_state(q), HORIZONTAL_ALIGNMENT_LEFT, rowr.size.x - 420.0, 12, Color("#96aab9"))
			"cr_rev", "cu_up", "cu_evo", "cu_sell", "cu_see":
				var on: bool = it.on
				var warn: bool = it.id == "cu_sell" and ctl_arm == it.arg.id
				(sb_red if warn else (sb_btn if on else sb_dis)).draw(get_canvas_item(), r)
				var q: Dictionary = it.arg
				var lab := ""
				match it.id:
					"cr_rev":
						lab = "즉시 부활 " + str(15 * int(q.lv) + 30 * int(q.ev))
					"cu_up":
						lab = "업 " + str(lvup_cost(q))
					"cu_evo":
						lab = "진화 " + str(EVC[q.ev])
					"cu_sell":
						lab = "정말 판매?" if warn else ("판매 " + str(sell_value(q)))
					"cu_see":
						lab = "보기"
				draw_string(f, r.position + Vector2(0, 19), lab, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color.WHITE if on else Color(1, 1, 1, 0.45))
	var desc := shop_desc
	if hov != null and hov.id == "card":
		desc = hov.tip
	if desc == "":
		desc = "항목을 누르면 설명이 나와요" if touch_ui() else "항목에 마우스를 올려 보세요"
	if shop_tab != "ctl":
		draw_line(sr.position + Vector2(170, sr.size.y - 44.0), sr.position + Vector2(sr.size.x, sr.size.y - 44.0), Color(1, 1, 1, 0.08), 1.0)
		draw_string(f, sr.position + Vector2(186, sr.size.y - 17.0), desc, HORIZONTAL_ALIGNMENT_LEFT, sr.size.x - 200.0, 13, Color("#c9d4dc"))

# ═════════ 입력 ═════════
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch(e)
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN) and mb.pressed and (shop_open or info_open or paused):
			if shop_open and shop_tab == "ctl":
				ctl_scroll += -46.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 46.0
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zm + 0.1, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zm - 0.1, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var it = ui_hit(mb.position)
				if it != null:
					if not (it.id in ["shopbg", "infobg", "ctllist"]):
						ui_press(it)
					return
				if shop_open or info_open or paused or won or lost:
					return
				if aim != "":
					throw_at(s2w(mb.position))
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
			if mb.pressed and aim != "":
				aim = ""
				msg("취소했어요")
				return
			if mb.pressed and (shop_open or info_open or paused):
				if shop_open:
					var it = ui_hit(mb.position)
					if it != null and it.id == "card":
						ui_press(it, true)
				return
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
		mouse_ui = mm.position / us
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
		if kc == KEY_ESCAPE:
			if info_open:
				info_open = false
			elif shop_open:
				shop_open = false
			elif aim != "":
				aim = ""
			elif paused:
				paused = false
			elif not selected().is_empty():
				clear_sel()
			else:
				paused = true
			return
		if kc == KEY_P:
			paused = not paused
			shop_open = false
			return
		if paused or won or lost:
			return
		if kc == KEY_Y:
			shop_open = not shop_open
			info_open = false
		elif kc == KEY_I:
			info_open = not info_open
			shop_open = false
		elif kc >= KEY_1 and kc <= KEY_5:
			num_key(kc - KEY_1)
		elif kc == KEY_6 or kc == KEY_SPACE:
			hold_oil()
		elif kc == KEY_E:
			clear_sel()
			for q in bots:
				q.sel = true
		elif kc == KEY_HOME or kc == KEY_Q:
			cam_to(B)

func _touch(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		if st.pressed:
			if touches.is_empty():
				var it = ui_hit(st.position)
				if it != null:
					if it.id == "ctllist":
						list_drag = {"y": st.position.y, "s0": ctl_scroll, "i": st.index}
					elif not (it.id in ["shopbg", "infobg"]):
						ui_press(it)
					return
				if shop_open or info_open or paused or won or lost:
					return
				if aim != "":
					throw_at(s2w(st.position))
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
			if list_drag != null and list_drag.i == st.index:
				list_drag = null
				return
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
				tap_tip_t = 2.5
				tap_tip_p = st.position
			if touches.is_empty():
				dn = null
				pinch = null
			elif pinch != null:
				pinch = null
				var rest: Vector2 = touches.values()[0]
				dn = {"s": rest, "c": cam.position, "m": true, "t0": t, "touch": true}
	elif e is InputEventScreenDrag:
		var sd := e as InputEventScreenDrag
		if list_drag != null and list_drag.i == sd.index:
			ctl_scroll = list_drag.s0 - (sd.position.y - list_drag.y) / us
			return
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
	tap_tip_t = maxf(0.0, tap_tip_t - dt)
	if ctl_arm != -1 and t > ctl_arm_t:
		ctl_arm = -1
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
	if not won and not lost and not paused:
		update_game(dt)
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
	SS.earn += income() * dt
	vb_cd = maxf(0.0, vb_cd - dt)
	dr_cd = maxf(0.0, dr_cd - dt)
	for d in drones:
		d.t -= dt
	drones = drones.filter(func(d): return d.t > 0.0)
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
	separate(bots.filter(func(q): return q.t != "m"), 16.0, dt)
	var near_e: Array = ens.filter(func(q): return q.hp > 0 and (q.raid or q.cbt > t - 3.0 or vis2(q.p)))
	separate(near_e, 16.0, dt)
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
			SS.earn += g
			SS.stEarn += sg
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
	SS.lost += r0 - bots.size()
	var e0 := ens.size()
	ens = ens.filter(func(e): return e.hp > 0)
	kills += e0 - ens.size()
	SS.kills += e0 - ens.size()
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
		if vr.grow(60).has_point(o.p) and vis2(o.p):
			_outpost(o, f)
	for u in ens:
		if vr.has_point(u.p) and vis2(u.p):
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
	for d in drones:
		draw_arc(d.p, 260.0, 0.0, TAU, 64, Color(1.0, 0.88, 0.47, 0.5), 2.0)
		draw_circle(d.p, 9.0, Color("#0b1118"))
		draw_circle(d.p, 6.0, Color("#ffe27a"))
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
	shop_open = true
	shop_tab = "prod"
	await _shot("02b_shop")
	shop_tab = "up"
	await _shot("02c_shop_up")
	shop_tab = "item"
	oil = 2
	await _shot("02e_shop_item")
	shop_tab = "ctl"
	ctl_f = "c"
	await _shot("02f_shop_ctl")
	shop_open = false
	info_open = true
	await _shot("02g_info")
	info_open = false
	for u in bots:
		u.sel = u.t == "r" and u.sel
	var one = null
	for u in bots:
		if u.t == "c":
			one = u
	clear_sel()
	one.sel = true
	await _shot("02d_one")
	clear_sel()
	for u in bots:
		if u.t == "c" or u.t == "r" or u.t == "h":
			u.sel = true
	Engine.time_scale = 4.0
	await _wait(16.0)
	cam_to(o0.p)
	await _shot("03_scouted")
	for pair in [[o0.p, "03b_tip_out"], [mines[0].p, "03c_tip_mine"], [B, "03d_tip_base"]]:
		cam_to(pair[0])
		await _wait(0.1)
		var sp: Vector2 = get_canvas_transform() * (pair[0] as Vector2)
		mouse_ui = sp / us
		tap_tip_p = sp
		tap_tip_t = 9.0
		await _shot(pair[1])
	mouse_ui = Vector2(-999, -999)
	tap_tip_t = 0.0
	do_upgrade()
	do_upgrade()
	do_upgrade()
	click(o0.p, false)
	print("SQUAD n=", bots.filter(func(q): return q.sq != null).size(), " msg=", msg_text)
	await _wait(5.0)
	cam_to(o0.p)
	await _shot("04a_gather")
	print("SQUAD2 ph=", bots.filter(func(q): return q.sq != null).map(func(q): return q.sq.ph), " msg=", msg_text)
	await _wait(9.0)
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

func art_base(ci: CanvasItem, p: Vector2, t: float, xf: Transform2D = Transform2D.IDENTITY) -> void:
	ell_fill(ci, p + Vector2(6, 40), 58, 18, Color(0, 0, 0, 0.32))
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
	var o := oct(54)
	ci.draw_colored_polygon(o, PL)
	o.append(o[0])
	ci.draw_polyline(o, RIM, 3.0, true)
	var o2 := oct(44)
	o2.append(o2[0])
	ci.draw_polyline(o2, Color(1, 1, 1, 0.1), 1.0, true)
	for i in 4:
		ci.draw_set_transform_matrix(xf * Transform2D(i * PI / 2.0, Vector2.ONE, 0.0, p))
		ci.draw_rect(Rect2(-8, -50, 16, 3), Color(LT, 0.55))
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
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
	ci.draw_set_transform_matrix(xf * Transform2D(t * 1.6, Vector2.ONE, 0.0, p + Vector2(20, -25)))
	ci.draw_arc(Vector2.ZERO, 7, -0.9, 0.9, 12, TP, 2.0)
	ci.draw_line(Vector2.ZERO, Vector2(7, 0), TP, 2.0)
	ci.draw_rect(Rect2(-2, -2, 4, 4), K)
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
	var corners := [Vector2(-46, -19), Vector2(46, -19), Vector2(-46, 19), Vector2(46, 19)]
	for i in 4:
		var c: Vector2 = corners[i]
		ci.draw_rect(Rect2(c.x - 4, c.y - 4, 8, 8), K)
		ci.draw_rect(Rect2(c.x - 2, c.y - 2, 4, 4), LT if int(t * 2 + i * 0.5) % 2 == 1 else Color(0, 0, 0, 0.4))
	ci.draw_set_transform_matrix(xf)

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
