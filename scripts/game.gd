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
# 웹 새 게임과 같은 "어려움": 적 체력 135% · 공격력 130% · 수비대 30% 더 · 진화한 적 3구역부터
const DF := {"h": 1.35, "a": 1.3, "n": 1.3, "p": 0.95, "e": 2}
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
var mouse_in := false
var tap_tip_p := Vector2.ZERO
var ui: Array = []
var us := 1.0
var touch_mode := false
var shop_open := false
var shop_tab := "prod"
var shop_desc := ""
var paused := false
var skn := {}
var bsk := {}
var thm := {}
var kro_s := {}
var tkro_s := {}
var tn_cols: Array = []
var parts: Array = []
var wfx: Array = []
var vig_tex: Texture2D = null
var lost_at := 0.0
var won_at := 0.0
var flags: Array = []
var keys_open := false
var muted := false
var zm_t := -9.0
var t_real := 0.0
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
	_snd_init()
	sv_load()
	new_game()
	scene = "lobby"
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
	flags = []
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
	if a.has("base"):
		sfx_at("myturret", a.p if a.has("p") else B)
	elif a.has("op"):
		sfx_at("turret", a.p)
	elif a.team == 0:
		sfx_at("shoot" if float(a.get("rng", 0.0)) > 40.0 else "hit", a.p)
	else:
		sfx_at("ehit", a.p)
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
		boom(b.p, Color("#fff6d6") if a.team == 0 else Color("#ff7a66"), KRO() if a.team == 0 else TKRO())

func hit_base(u: Dictionary) -> void:
	sfx("basehit")
	base.hp -= u.atk
	u.cd = 1.0 / u.aspd
	fx.append({"k": "imp", "p": B + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), "t": 0.18, "c": Color("#ff7a66")})
	fx.append({"k": "txt", "p": B + Vector2(rng.randf_range(-24, 24), -40), "t": 0.9, "d0": 0.9, "s": "-" + str(roundi(u.atk)), "c": Color("#ff6a55"), "fs": 15})
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
				sfx_at("ore", u.p)
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
	sfx("raid")
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
		sfx("err")
		return
	ore -= c
	SS.made += 1
	sfx("spawn")
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
		sfx("up")
	elif s.any(func(u): return u.lv < 11):
		msg("광석이 부족해요")
		sfx("err")
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
		sfx("evo")
	elif need > 0:
		msg("진화석이 부족해요 (필요 " + str(need) + ")")
		sfx("err")
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
	sfx("spawn")
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
	zm_t = t_real
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
			sfx("cmd_atk")
			fx.append({"k": "atk", "p": e.p, "t": 0.75, "tg": e, "big": e.has("op"), "pts": s.filter(func(q): return q.t == "c" or q.t == "r").map(func(q): return q.p)})
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
			sfx("cmd_mv")
			fx.append({"k": "mine", "p": m.p, "t": 0.75, "pts": s.filter(func(q): return q.t == "m").map(func(q): return q.p)})
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
		sfx("cmd_mv")
		fx.append({"k": "mv", "p": w, "t": 0.75, "pts": s.map(func(q): return q.p)})
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
	if keys_open:
		return
	if won or lost:
		if t_real - (won_at if won else lost_at) > 2.6:
			if won:
				_add("wlobby", Rect2(Vector2.ZERO, u))
			else:
				_add("retry", Rect2(u.x / 2.0 - 230.0, u.y / 2.0 + 64.0, 220.0, 54.0))
				_add("llobby", Rect2(u.x / 2.0 + 10.0, u.y / 2.0 + 64.0, 220.0, 54.0))
		return
	if paused:
		var py := u.y / 2.0 - 70.0
		for i in 4:
			_add(["resume", "tolobby", "endg", "keys"][i], Rect2(u.x / 2.0 - 130.0, py + i * 62.0, 260.0, 52.0))
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

	_tut_buttons()
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
	if it.id in ["pause", "resume"]:
		sfx("pause")
	elif not (it.id in ["shopbg", "infobg", "ctllist", "card"]):
		sfx("click")
	match it.id:
		"restart":
			paused = false
			shop_open = false
			info_open = false
			new_game()
		"resume":
			paused = false
		"tolobby":
			to_lobby_saved()
		"endg":
			if quit_arm > t_real:
				quit_arm = 0.0
				end_game()
			else:
				quit_arm = t_real + 3.0
		"wlobby", "llobby":
			end_game()
		"retry":
			end_game(true)
		"tutskip":
			tut = -1
			SV.tut_done = true
			sv_save()
		"tutnext":
			tut_next()
		"keys":
			keys_open = true
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
		sfx("oil")
		msg("기름 뿌리기! 로봇 " + str(us_.size()) + "대가 20초간 이속·공속 +20%" + ("" if sc == 0 else " · 정찰 로봇 " + str(sc) + "대 연료 +50%"))
	elif aim == "vb":
		ore -= 60.0
		SS.spItem += 60
		vb_cd = vb_cdv()
		reveal(w, 180.0)
		fx.append({"k": "ring", "p": w, "t": 0.6, "r": 180.0})
		msg("시야 폭탄! 주변이 영구적으로 밝혀졌어요")
		sfx("vbomb")
	elif aim == "dr":
		ore -= 25.0
		SS.spItem += 25
		dr_cd = d_cd()
		drones.append({"p": w, "t": 4.0})
		msg("정찰 드론 투하! 4초 동안 보여요")
		sfx("drone")
	aim = ""

func vis2(p: Vector2) -> bool:
	if seen(p):
		return true
	for d in drones:
		if p.distance_to(d.p) < 260.0:
			return true
	return false

func num_key(i: int, jump: bool = false) -> void:
	if i < 0 or i >= ORDER.size():
		return
	var k: String = ORDER[i]
	var dbl: bool = not jump and last_num.k == k and t_real - last_num.t < 0.35
	last_num = {"k": "" if (dbl or jump) else k, "t": t_real}
	if dbl or jump:
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
			var G: Array = lst.filter(func(q): return (q.p as Vector2).distance_to(best) < 350.0)
			var gc := Vector2.ZERO
			for q in G:
				gc += q.p
			gc /= G.size()
			cam_to(gc)
			fx.append({"k": "ring", "p": gc, "t": 0.6, "r": 120.0})
			msg(UT[k].n + " " + str(lst.size()) + "대 중 " + str(G.size()) + "대가 모인 곳으로 이동했어요")
		else:
			msg(UT[k].n + " 로봇이 없어요")
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
	var items: Array = [["flag", str(captured()) + "/50", Color("#e6edf3")], ["stone", str(stone), Color("#c08cff")], ["base", str(int(maxf(0.0, base.hp))), Color("#e6edf3")], ["raid", "레이드!" if raid_alive else "%d:%02d" % [int(rl / 60.0), int(rl) % 60], Color("#ff8a6b") if (raid_alive or rl < 30.0) else Color("#e6edf3")], ["time", "%d:%02d" % [int(t / 60.0), int(t) % 60], Color("#e6edf3")]]
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
		var acc: Color = UT[su.t].acc
		var pat := ""
		if not skn.is_empty():
			col = C(skn.c)
			acc = C(skn.a)
			pat = skn.pt
		elif su.ev > 0:
			col = [Color("#a98ae0"), Color("#9462e0"), Color("#7d3fdc")][su.ev - 1]
		_ui_tf(pr.get_center(), -0.5, 2.6)
		art_bot_s(self, su.t, col, acc, t, pat)
	else:
		_ui_tf(pr.get_center() + Vector2(0, 2), 0.0, 0.62)
		art_base(self, Vector2.ZERO, t, inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(0.0, Vector2(0.62, 0.62), 0.0, pr.get_center() + Vector2(0, 2)), bsk)
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
			if skn.is_empty():
				art_bot(self, k, UT[k].col, UT[k].acc, t)
			else:
				art_bot_s(self, k, C(skn.c), C(skn.a), t, skn.pt)
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
	if not won and not lost:
		_raid_ui(f)
	if shop_open:
		_shop(f, hov)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
		draw_string(f, Vector2(0, u.y / 2.0 - 100.0), "일시정지", HORIZONTAL_ALIGNMENT_CENTER, u.x, 34, GOLD)
		for it in ui:
			var lb: String = {"resume": "계속하기", "tolobby": "저장하고 로비로", "endg": "게임 종료", "keys": "조작법"}.get(it.id, "")
			if it.id == "endg" and quit_arm > t_real:
				lb = "정말 끝낼까요? 한 번 더"
			_btn(f, it.r, lb, hov == it, 17, Color("#ff9a8a") if it.id == "endg" else Color.WHITE)
		if quit_arm > t_real:
			draw_string(f, Vector2(0, u.y / 2.0 + 190.0), "게임을 끝내면 저장이 지워지고, 10분 이상 했으면 청석을 받아요", HORIZONTAL_ALIGNMENT_CENTER, u.x, 13, Color("#c9d4dc"))
	if won or lost:
		if won:
			_victory(f)
		else:
			_defeat(f)
		for it in ui:
			if it.id == "wlobby":
				var wt := t_real - won_at
				var c := Vector2(u.x / 2.0, u.y * 0.36)
				draw_string(f, Vector2(0, minf(u.y - 30.0, c.y + minf(115.0, u.x * 0.09) + 180.0)), "화면을 누르면 로비로 돌아가요", HORIZONTAL_ALIGNMENT_CENTER, u.x, 15, Color(0.91, 0.93, 0.97, 0.55 + 0.45 * sin(wt * 3.0)))
			else:
				_btn(f, it.r, "다시하기" if it.id == "retry" else "로비", hov == it, 16)
	_zoom_badge(f)
	_tut_ui(f)
	if keys_open:
		_keys_win(f)
		return
	if tip != "" and not shop_open and not info_open:
		_tooltip(f, tip)
	elif tip == "" and hov == null and not shop_open and not info_open and not paused and not won and not lost and dn == null and not box_active:
		_world_tip(f)

# ═════════ 흐름: 로비 · 설정 · 저장 · 이어하기 · 튜토리얼 ═════════
const SAVE_P := "user://save.dat"
const SV_P := "user://sv.dat"
var scene := "lobby"
var lsec := "main"
var lmsg := ""
var SV := {"cs": 0, "ss": 0, "vol_s": 70, "vol_b": 35, "mute": false, "uis": 100, "tut_done": false, "bpxp": 0}
var save_acc := 0.0
var slider_drag = null
var wipe_arm := ""
var wipe_t := 0.0
var raid_wins := 0
var tut := -1
var tut_c := Vector2.ZERO
var lob_scroll := 0.0

func sv_load() -> void:
	if FileAccess.file_exists(SV_P):
		var f := FileAccess.open(SV_P, FileAccess.READ)
		var d = f.get_var()
		if d is Dictionary:
			SV.merge(d, true)
	_sv_defaults()
	_apply_sv()

func sv_save() -> void:
	var f := FileAccess.open(SV_P, FileAccess.WRITE)
	if f != null:
		f.store_var(SV)

func _apply_sv() -> void:
	muted = SV.mute
	vol_s = int(SV.vol_s)
	vol_b = int(SV.vol_b)
	us = float(SV.uis) / 100.0
	_vol_apply()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_P)

func _strip(d: Dictionary, keys: Array) -> Dictionary:
	var o := d.duplicate()
	for k in keys:
		o.erase(k)
	return o

func save_game() -> void:
	if scene != "game" or won or lost:
		return
	var S := {"v": 1, "t": t, "ore": ore, "stone": stone, "next_raid": next_raid, "raid_warned": raid_warned, "kills": kills, "lost_n": lost_n,
		"oil": oil, "vb_cd": vb_cd, "dr_cd": dr_cd, "SS": SS, "base_hp": base.hp, "flags": flags, "cam": cam.position, "zm": zm,
		"ex": ex, "mines": mines, "dead": dead, "raid_wins": raid_wins, "uid": uid, "tut": tut, "tut_c": tut_c,
		"outs": outs.map(func(o): return _strip(o, ["tt", "ft"]))}
	S.bots = bots.map(func(u):
		var o := _strip(u, ["tgt", "sq", "dgo", "fo", "kx", "rh", "pp"])
		o.mine = mines.find(u.mine) if u.mine != null else -1
		o.sel = false
		return o)
	S.ens = ens.map(func(e):
		var o := _strip(e, ["ag", "et"])
		o.o = outs.find(e.o) if e.o != null else -1
		return o)
	var f := FileAccess.open(SAVE_P, FileAccess.WRITE)
	if f != null:
		f.store_var(S)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_P, FileAccess.READ)
	var S = f.get_var()
	if not (S is Dictionary) or not S.has("ex"):
		return false
	new_game()
	t = S.t
	ore = S.ore
	stone = S.stone
	next_raid = S.next_raid
	raid_warned = S.raid_warned
	kills = S.kills
	lost_n = S.lost_n
	oil = S.oil
	vb_cd = S.vb_cd
	dr_cd = S.dr_cd
	SS = S.SS
	base.hp = S.base_hp
	flags = S.flags
	raid_wins = S.get("raid_wins", 0)
	tut = S.get("tut", -1)
	tut_c = S.get("tut_c", Vector2.ZERO)
	ex = S.ex
	mines = S.mines
	outs = S.outs
	for o in outs:
		o.tt = null
		o.ft = null
	dead = S.dead
	bots = S.bots
	for u in bots:
		var mi: int = u.mine
		u.mine = mines[mi] if mi >= 0 and mi < mines.size() else null
		for k in ["tgt", "sq", "dgo", "fo", "kx", "rh"]:
			u[k] = null
		u.pp = []
		u.pk = -1
	ens = S.ens
	for e in ens:
		var oi: int = e.o
		e.o = outs[oi] if oi >= 0 and oi < outs.size() else null
		e.ag = null
		e.et = null
	uid = S.uid
	mm_img.fill(Color(0, 0, 0, 0))
	for j in GN:
		for i in GN:
			if ex[j * GN + i]:
				mm_img.set_pixel(i, j, Color("#2d4a3a"))
	mm_dirty = true
	raid_alive = ens.any(func(e): return e.raid)
	zm = S.zm
	cam.zoom = Vector2(zm, zm)
	cam.position = S.cam
	_clamp_cam()
	return true

func del_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_P)

func start_game(cont: bool, with_tut: bool = false) -> void:
	scene = "game"
	paused = false
	shop_open = false
	info_open = false
	keys_open = false
	if not (cont and load_game()):
		new_game()
		del_save()
		raid_wins = 0
		tut = -1
		if with_tut or not SV.tut_done:
			tut = 0
			tut_c = cam.position
	save_acc = 0.0
	lmsg = ""

func cs_gain() -> int:
	var g := int(float(SS.earn) * 0.04)
	for o in outs:
		if o.cap:
			g += 10 * (int(o.tr) + 1)
	return g

func end_game(retry: bool = false) -> void:
	var t0 := t
	var ok := t0 >= 600.0 or won
	var g := cs_gain() if ok else 0
	SV.cs = int(SV.cs) + g
	var bx := int(t0 / 60.0) * 10 + int(SS.kills) * 2 + captured() * 30 + raid_wins * 50
	SV.bp.xp = mini(15000, int(SV.bp.xp) + bx)
	sv_save()
	del_save()
	won = false
	lost = false
	paused = false
	if retry:
		start_game(false)
		return
	scene = "lobby"
	lsec = "main"
	lmsg = "[배틀패스 +" + str(bx) + " XP] " + ("게임 종료! 청석 " + str(g) + "개를 받았어요 (번 광석의 4% + 정복 보너스)" if ok else "10분 이상 플레이해야 청석을 받아요. 이번 판은 " + str(int(t0 / 60.0)) + "분이라 청석이 없어요")

func to_lobby_saved() -> void:
	save_game()
	scene = "lobby"
	lsec = "main"
	paused = false
	lmsg = "저장했어요. 이어하기로 계속할 수 있어요"

# ── 튜토리얼 (웹 TUT 그대로 · 모바일은 터치 문구) ──
func tut_steps() -> Array:
	var T := touch_ui()
	return [
		["Sorok에 오신 걸 환영해요!", "목표는 지도 곳곳에 있는 외계 기지 50개를 정복하는 거예요. 광석을 캐서 로봇을 만들고, 키우고, 진격하세요.", false],
		["지도 둘러보기", "한 손가락으로 지도를 끌어 보세요. 아래 [기지] 버튼을 누르면 언제든 기지로 돌아와요." if T else "WASD나 방향키, 화면 가장자리에 마우스 대기, 좌클릭 드래그로 지도를 움직여 보세요. Q를 누르면 언제든 기지로 돌아와요.", true],
		["상점 열기", "아래 [상점] 버튼을 눌러 보세요. 로봇 생산, 아이템, 업그레이드가 모두 여기 있어요." if T else "Y를 눌러 상점을 열어 보세요. 로봇 생산, 아이템, 업그레이드가 모두 여기 있어요.", true],
		["채굴 로봇 만들기", "로봇 생산 탭에서 채굴 로봇(광석 35)을 눌러 구매하세요." if T else "로봇 생산 탭에서 채굴 로봇(광석 35)을 우클릭해서 구매하세요. 상점에서는 우클릭으로 사요.", true],
		["광석 캐기", "상점을 닫고, 채굴 로봇을 누른 뒤 기지 근처의 청록색 광산을 누르세요. 알아서 캐서 기지로 날라요." if T else "Esc로 상점을 닫고, 채굴 로봇을 클릭한 뒤 기지 근처의 청록색 광산을 클릭하세요. 알아서 캐서 기지로 날라요.", true],
		["어둠 밝히기", "정찰 로봇(광석 15)을 만들어 선택한 뒤 어두운 곳을 " + ("누르세요" if T else "클릭하세요") + ". 지나간 곳의 시야가 밝혀져요. 연료가 다 떨어지면 고장나요.", true],
		["전투 로봇 만들기", "광석이 모이면 근접 로봇(40)이나 원거리 로봇(55)을 만드세요. 채굴 로봇이 광석을 모으는 동안 잠깐 기다려도 돼요.", true],
		["부대 지휘", "화면을 꾹 누른 채 끌면 로봇을 묶을 수 있어요. [전체] 버튼은 전체 선택이에요. 묶은 상태로 땅을 누르면 그곳으로 이동해요." if T else "우클릭을 누른 채 드래그하면 로봇을 묶을 수 있어요. E는 전체 선택이에요. 묶은 상태로 좌클릭하면 그곳으로 이동해요.", true],
		["외계 기지 정복", "보라색 외계 기지를 " + ("누르면" if T else "클릭하면") + " 공격해요. 기지에서 멀수록 강하니 가까운 곳부터 정복하세요. 기지를 정복하면 광석 보너스와 수입이 생겨요.", false],
		["레이드에 대비하세요", "15분부터 5~10분마다 레이드가 기지로 몰려와요. 미니맵의 빨간 표시를 보고 기지를 지키세요. 기지가 파괴되면 패배예요.", false],
		["준비 완료!", ("[정보]는 게임 기록, 왼쪽 위 버튼은 일시정지, 아래 1~5 칸은 로봇 종류별 전체 선택, 6 칸은 기름 들기예요." if T else "I는 게임 정보, Esc는 일시정지, T는 깃발 꽂기, 1~5는 로봇 종류별 전체 선택, Ctrl+1~5나 숫자 두 번은 그 로봇들 위치로 화면 이동, 6이나 스페이스는 기름 들기예요.") + " 10분 이상 하고 끝내면 청석을 받아 로비에서 스킨을 살 수 있어요. 행운을 빌어요!", false]]

func _tut_ok(i: int) -> bool:
	match i:
		1: return cam.position.distance_to(tut_c) > 180.0
		2: return shop_open
		3: return bots.any(func(u): return u.t == "m")
		4: return bots.any(func(u): return u.t == "m" and u.mine != null)
		5: return bots.any(func(u): return u.t == "s" and u.f < u.fm)
		6: return bots.any(func(u): return u.t == "c" or u.t == "r")
		7: return bots.any(func(u): return (u.t == "c" or u.t == "r") and (u.goal != null or u.tgt != null))
	return false

func tut_next() -> void:
	tut += 1
	if tut >= tut_steps().size():
		tut = -1
		SV.tut_done = true
		sv_save()
		msg("튜토리얼 완료! 즐거운 정복 되세요")

func _tut_tick() -> void:
	if tut >= 0 and _tut_ok(tut):
		tut_next()

func _tut_mark():
	match tut:
		4:
			var u = _first(func(q): return q.t == "m")
			if u == null or shop_open:
				return null
			return _near_mine() if u.sel else u.p
		5:
			var u = _first(func(q): return q.t == "s")
			if u == null or shop_open:
				return null
			return B + Vector2(520, -520) if u.sel else u.p
		8:
			var best = null
			var bd := 1e9
			for o in outs:
				if not o.cap and B.distance_to(o.p) < bd:
					bd = B.distance_to(o.p)
					best = o.p
			return best
	return null

func _first(fn: Callable):
	for q in bots:
		if fn.call(q):
			return q
	return null

func _near_mine():
	var best = null
	var bd := 1e9
	for m in mines:
		if not m.ev and m.amt > 0 and seen(m.p) and B.distance_to(m.p) < bd:
			bd = B.distance_to(m.p)
			best = m.p
	return best

func _tut_hl() -> Array:
	var ids: Array = []
	match tut:
		2: ids = [["shop", null]]
		3: ids = [["shop", null]] if not shop_open else [["card", "m"]]
		4: ids = [["shopx", null]] if shop_open else []
		5:
			if bots.any(func(u): return u.t == "s"):
				ids = [["shopx", null]] if shop_open else []
			else:
				ids = [["card", "s"]] if shop_open else [["shop", null]]
		6: ids = [["card", "c"], ["card", "r"]] if shop_open else [["shop", null]]
		7: ids = [["all", null]]
	var out: Array = []
	for it in ui:
		for q in ids:
			if it.id == q[0] and (q[1] == null or (it.arg is Dictionary and it.arg.get("k", "") == q[1])):
				out.append(it.r)
	return out

func _tut_world() -> void:
	if tut < 0:
		return
	var P = _tut_mark()
	if P == null:
		return
	var by := sin(t_real * 1000.0 / 180.0) * 6.0
	var p: Vector2 = P
	var pts := PackedVector2Array([p + Vector2(0, -30 + by), p + Vector2(-13, -50 + by), p + Vector2(-5, -50 + by), p + Vector2(-5, -68 + by), p + Vector2(5, -68 + by), p + Vector2(5, -50 + by), p + Vector2(13, -50 + by)])
	draw_colored_polygon(pts, Color("#ffe28a"))
	pts.append(pts[0])
	draw_polyline(pts, Color("#1c1406"), 2.0)
	draw_arc(p, 24.0 + by * 0.6, 0, TAU, 40, Color(1.0, 0.89, 0.54, 0.8), 2.0)

func _tut_rect() -> Rect2:
	var u := ui_size()
	var w := minf(420.0, u.x - 24.0)
	if shop_open:
		return Rect2(u.x - w - 12.0, u.y - 230.0 - 140.0, w, 200.0)
	return Rect2(12.0, 68.0 if touch_ui() else 12.0, w, 200.0)

func _tut_ui(f: Font) -> void:
	if tut < 0 or paused or won or lost or keys_open:
		return
	for r in _tut_hl():
		var a := 0.55 + 0.45 * sin(t_real * 6.0)
		draw_rect((r as Rect2).grow(3.0), Color(1.0, 0.85, 0.35, a), false, 3.0)
	var S: Array = tut_steps()
	var q: Array = S[tut]
	var r := _tut_rect()
	var lines := _wrap(f, q[1], 14, r.size.x - 28.0)
	r.size.y = 96.0 + lines.size() * 20.0 + 44.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.96)
	sb.border_color = Color("#ffd76a")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.draw(get_canvas_item(), r)
	var x := r.position.x + 14.0
	var y := r.position.y
	draw_string(f, Vector2(x, y + 24.0), "튜토리얼 " + str(tut + 1) + " / " + str(S.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9fb3c2"))
	draw_rect(Rect2(x, y + 32.0, r.size.x - 28.0, 4.0), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(x, y + 32.0, (r.size.x - 28.0) * (tut + 1) / float(S.size()), 4.0), Color("#ffd76a"))
	draw_string(f, Vector2(x, y + 62.0), q[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	for i in lines.size():
		draw_string(f, Vector2(x, y + 88.0 + i * 20.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c9d4dc"))
	if q[2]:
		draw_string(f, Vector2(r.position.x, r.end.y - 18.0), "해 보면 자동으로 넘어가요", HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14.0, 12, Color("#ffd76a"))
	for it in ui:
		if it.id == "tutskip":
			_btn(f, it.r, "튜토리얼 건너뛰기", false, 12, Color("#c9d4dc"))
		elif it.id == "tutnext":
			var gold := StyleBoxFlat.new()
			gold.bg_color = Color("#d9b04e")
			gold.set_corner_radius_all(5)
			gold.draw(get_canvas_item(), it.r)
			draw_string(f, (it.r as Rect2).position + Vector2(0, 21), "시작하기" if tut == tut_steps().size() - 1 else "다음", HORIZONTAL_ALIGNMENT_CENTER, (it.r as Rect2).size.x, 14, Color("#2a1a02"))

func _tut_buttons() -> void:
	if tut < 0 or paused or won or lost or keys_open:
		return
	var r := _tut_rect()
	var lines := _wrap(ThemeDB.fallback_font, tut_steps()[tut][1], 14, r.size.x - 28.0)
	var bot := r.position.y + 96.0 + lines.size() * 20.0 + 44.0
	_add("tutskip", Rect2(r.position.x + 14.0, bot - 38.0, 150.0, 30.0))
	if not tut_steps()[tut][2]:
		_add("tutnext", Rect2(r.end.x - 114.0, bot - 38.0, 100.0, 30.0))

# ── 로비 그리기 ──
func _lobby_w() -> float:
	return minf(1000.0, ui_size().x - 40.0)

func _build_lobby() -> void:
	if not box_res.is_empty() or lsec in ["shop", "store", "pass"]:
		_build_cos()
		return
	var u := ui_size()
	var W := _lobby_w()
	var x0 := (u.x - W) / 2.0
	if lsec == "main":
		var cw := W * 0.55
		var cr := Rect2(x0, 205.0, cw, 312.0)
		if has_save():
			_add("lcont", Rect2(cr.position.x + 20.0, cr.end.y - 72.0, (cw - 50.0) / 2.0, 54.0))
			_add("lnew", Rect2(cr.position.x + 30.0 + (cw - 50.0) / 2.0, cr.end.y - 72.0, (cw - 50.0) / 2.0, 54.0))
		else:
			_add("lnew", Rect2(cr.position.x + 20.0, cr.end.y - 72.0, cw - 40.0, 54.0))
		var tx := x0 + cw + 12.0
		var tw := (W - cw - 24.0) / 2.0
		var names := ["lshop", "lstore", "lpass", "lset"]
		for i in 4:
			_add(names[i], Rect2(tx + (i % 2) * (tw + 12.0), 205.0 + int(i / 2) * 162.0, tw, 150.0))
		_add("lnotes", Rect2(x0, 529.0, cw, 42.0))
	else:
		var pr := _lsec_rect()
		_add("lback", Rect2(pr.end.x - 130.0, pr.end.y - 54.0, 116.0, 40.0))
		if lsec == "set":
			var y := pr.position.y + 70.0 - lob_scroll
			_add("ltut", Rect2(pr.position.x + 20.0, y, 300.0, 40.0))
			y += 96.0
			for k in ["uis", "vol_s", "vol_b"]:
				_add("sl", Rect2(pr.position.x + 120.0, y, pr.size.x - 220.0, 30.0), true, "", k)
				y += 40.0
			_add("lmute", Rect2(pr.position.x + 20.0, y, 140.0, 38.0))
			_add("lbgm", Rect2(pr.position.x + 20.0, y + 46.0, 320.0, 38.0))
			y += 130.0
			_add("lkeys", Rect2(pr.position.x + 20.0, y, 220.0, 40.0))
			y += 84.0
			_add("lwipe", Rect2(pr.position.x + 20.0, y, 200.0, 40.0))
			_add("lwipeall", Rect2(pr.position.x + 232.0, y, 200.0, 40.0))

func _lsec_rect() -> Rect2:
	var u := ui_size()
	var W := minf(760.0, u.x - 40.0)
	return Rect2((u.x - W) / 2.0, 190.0, W, u.y - 210.0)

func _btn(f: Font, r: Rect2, s: String, hi: bool = false, fs: int = 16, col: Color = Color.WHITE) -> void:
	(sb_btn_hi if hi else sb_btn).draw(get_canvas_item(), r)
	draw_string(f, Vector2(r.position.x, r.position.y + r.size.y / 2.0 + fs * 0.36), s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, col)

func _lobby(f: Font) -> void:
	_ui_reset()
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color("#0b1015"))
	for i in int(u.x / 64.0) + 1:
		draw_line(Vector2(i * 64.0, 0), Vector2(i * 64.0, u.y), Color(1, 1, 1, 0.02), 1.0)
	for j in int(u.y / 64.0) + 1:
		draw_line(Vector2(0, j * 64.0), Vector2(u.x, j * 64.0), Color(1, 1, 1, 0.02), 1.0)
	ui.clear()
	_build_lobby()
	var hov = null if touch_ui() else ui_hit(mouse_ui * us)
	# 로고
	draw_string(f, Vector2(0, 92), "S O R O K", HORIZONTAL_ALIGNMENT_CENTER, u.x, 64, Color("#5a3a08"))
	draw_string(f, Vector2(0, 88), "S O R O K", HORIZONTAL_ALIGNMENT_CENTER, u.x, 64, Color("#f2c86a"))
	draw_string(f, Vector2(0, 118), "외 계  기 지  정 복  전 략", HORIZONTAL_ALIGNMENT_CENTER, u.x, 12, Color("#8a9bad"))
	var chips := [["청석", str(SV.cs), Color("#7fd8ff"), Color("#33414d")], ["별석", str(SV.ss), Color("#c79bff"), Color("#5a4a8a")]]
	var cwid: Array = []
	var ctot := 0.0
	for ch_ in chips:
		var w0: float = 46.0 + f.get_string_size(ch_[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 16.0
		cwid.append(w0)
		ctot += w0
	var cx0 := u.x / 2.0 - (ctot + 6.0) / 2.0
	for i in 2:
		var r := Rect2(cx0, 134.0, cwid[i], 36.0)
		cx0 += cwid[i] + 6.0
		draw_rect(r, Color("#10161c"))
		draw_rect(r, chips[i][3], false, 1.0)
		draw_string(f, r.position + Vector2(10, 23), chips[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8a9bad"))
		draw_string(f, r.position + Vector2(0, 25), chips[i][1], HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 12.0, 18, chips[i][2])
	if lmsg != "":
		draw_string(f, Vector2(0, 192), lmsg, HORIZONTAL_ALIGNMENT_CENTER, u.x, 13, Color("#ffd76a"))
	if lsec in ["shop", "store", "pass"]:
		_lobby_cos(f, hov)
	elif lsec == "main":
		_lobby_main(f, hov)
	elif lsec == "set":
		_lobby_set(f, hov)
	elif lsec == "notes":
		_lobby_notes(f, hov)
	if not box_res.is_empty():
		_box_overlay(f, hov)
	if keys_open:
		_keys_win(f)

func _lobby_main(f: Font, hov) -> void:
	var u := ui_size()
	var W := _lobby_w()
	var x0 := (u.x - W) / 2.0
	var cw := W * 0.55
	var cr := Rect2(x0, 205.0, cw, 312.0)
	# 미리보기 땅
	for j in 8:
		for i in int(cw / 40.0) + 1:
			var c: Color = tn_cols[(i * 3 + j * 5) % 4]
			var rr := Rect2(cr.position.x + i * 40.0, cr.position.y + j * 40.0, 40.0, 40.0).intersection(cr)
			draw_rect(rr, c)
	var bxf := inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(0.0, Vector2(1.6, 1.6), 0.0, cr.position + Vector2(cw * 0.3, 150))
	draw_set_transform_matrix(bxf)
	art_base(self, Vector2.ZERO, t_real, bxf, bsk)
	var bl := [["r", Vector2(0.62, 0.42), 0.0], ["h", Vector2(0.8, 0.43), 0.0], ["s", Vector2(0.88, 0.25), -0.5], ["c", Vector2(0.73, 0.68), 0.3]]
	for b in bl:
		_ui_tf(cr.position + Vector2(cw * b[1].x, cr.size.y * b[1].y), b[2], 3.0)
		if skn.is_empty():
			art_bot(self, b[0], UT[b[0]].col, UT[b[0]].acc, t_real)
		else:
			art_bot_s(self, b[0], C(skn.c), C(skn.a), t_real, skn.pt)
	_ui_reset()
	draw_polygon(PackedVector2Array([Vector2(cr.position.x, cr.position.y + 150), Vector2(cr.end.x, cr.position.y + 150), cr.end, Vector2(cr.position.x, cr.end.y)]),
		PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9)]))
	draw_rect(cr, Color("#e0b85a"), false, 2.0)
	draw_string(f, cr.position + Vector2(20, 200), "출격 준비 완료", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe6a6"))
	draw_string(f, cr.position + Vector2(20, 226), "난이도 어려움 · 로봇 " + skn.get("n", "기본") + " · 기지 " + bsk.get("n", "기본") + " · 테마 " + thm.get("n", "기본"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c9d4dc"))
	var tot := SK.size() + BS.size() + TS.size()
	var own: int = SV.own.size() + SV.bown.size() + SV.town.size()
	var tiles := {"lshop": ["상점", "소로 상자 · ★ 걸작 · 세트", Color("#c9a255")], "lstore": ["창고", "보유 스킨 " + str(own) + " / " + str(tot) + (" · 무료 상자 " + str(SV.fbox) if SV.fbox > 0 else ""), Color("#2f8a78")],
		"lpass": ["배틀패스", SEASON.n + " · " + str(bp_lv()) + " / 30단계" + (" · 프리미엄" if bp().prem else ""), Color("#7a5aa8")], "lset": ["설정", "조작 · 소리 · 데이터", Color("#3a5a8a")]}
	for it in ui:
		var r: Rect2 = it.r
		match it.id:
			"lnew":
				var gold := StyleBoxFlat.new()
				gold.bg_color = Color("#e8c060") if hov == it else Color("#d9b04e")
				gold.set_corner_radius_all(6)
				gold.draw(get_canvas_item(), r)
				draw_string(f, Vector2(r.position.x, r.position.y + 35.0), "새 게임", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color("#2a1a02"))
			"lcont":
				_btn(f, r, "이어하기", hov == it, 18, Color("#ffe6a6"))
			"lnotes":
				_btn(f, r, "패치 노트", hov == it, 14)
			_:
				if tiles.has(it.id):
					var tl: Array = tiles[it.id]
					var sb := StyleBoxFlat.new()
					sb.bg_color = Color("#1a242e") if hov == it else Color("#141c24")
					sb.border_color = Color(1, 1, 1, 0.12)
					sb.set_border_width_all(1)
					sb.set_corner_radius_all(10)
					sb.draw(get_canvas_item(), r)
					draw_circle(Vector2(r.end.x - 26.0, r.position.y + 26.0), 34.0, Color(tl[2], 0.45))
					draw_string(f, Vector2(r.position.x + 14.0, r.end.y - 42.0), tl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
					draw_string(f, Vector2(r.position.x + 14.0, r.end.y - 20.0), tl[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9fb3c2"))

func _lobby_panel(f: Font, title: String) -> Rect2:
	var pr := _lsec_rect()
	sb_panel.draw(get_canvas_item(), pr)
	draw_string(f, pr.position + Vector2(20, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
	return pr

func _lobby_set(f: Font, hov) -> void:
	var pr := _lobby_panel(f, "설정")
	var y := pr.position.y + 70.0 - lob_scroll
	var x := pr.position.x + 20.0
	var names := {"uis": ["UI 크기", 50, 130], "vol_s": ["효과음", 0, 100], "vol_b": ["배경음", 0, 100]}
	draw_string(f, Vector2(x, y - 8.0), "튜토리얼", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c2"))
	for it in ui:
		var r: Rect2 = it.r
		match it.id:
			"ltut": _btn(f, r, "튜토리얼 다시하기 (새 게임으로 시작)", hov == it, 14)
			"lmute": _btn(f, r, "음소거 켜짐" if SV.mute else "음소거", hov == it or SV.mute, 14)
			"lbgm":
				var b: String = str(SV.get("bgm", "auto"))
				var nm: String = "자동 (장착한 테마 곡)" if b == "auto" else ("기본 배경음" if b == "base" else item(b).get("n", b) + " 테마곡")
				_btn(f, r, "배경음: " + nm + "  ▸", hov == it, 14)
			"lkeys": _btn(f, r, "조작법 전체 보기", hov == it, 14)
			"lwipe": _btn(f, r, "정말? 한 번 더" if wipe_arm == "lwipe" else "청석·스킨 초기화", hov == it, 14, Color("#ffb0a0"))
			"lwipeall": _btn(f, r, "정말? 한 번 더" if wipe_arm == "lwipeall" else "게임 전체 초기화", hov == it, 14, Color("#ff9a8a"))
			"lback": _btn(f, r, "뒤로", hov == it, 15)
			"sl":
				var nm: Array = names[it.arg]
				var v := float(SV[it.arg])
				var k: float = (v - float(nm[1])) / float(nm[2] - nm[1])
				draw_string(f, Vector2(x, r.position.y + 21.0), nm[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
				draw_rect(Rect2(r.position.x, r.position.y + 13.0, r.size.x, 4.0), Color(1, 1, 1, 0.15))
				draw_rect(Rect2(r.position.x, r.position.y + 13.0, r.size.x * k, 4.0), Color("#ffd76a"))
				draw_circle(Vector2(r.position.x + r.size.x * k, r.position.y + 15.0), 9.0, Color("#ffd76a"))
				draw_string(f, Vector2(r.end.x + 14.0, r.position.y + 21.0), str(int(v)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffd76a"))
	draw_string(f, Vector2(x, y + 88.0), "화면 · 소리", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c2"))
	draw_string(f, Vector2(x + 150.0, y + 240.0), "게임 중에도 M 키로 음소거를 켜고 끌 수 있어요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7d8b96"))
	draw_string(f, Vector2(x, y + 336.0), "조작", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c2"))
	draw_string(f, Vector2(x, y + 420.0), "데이터", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c2"))

const NOTES := [["고도판 첫 버전", ["웹 SOROK을 고도 엔진으로 옮겼어요 (PC · 모바일 같은 코드)", "웹과 같은 전투 AI · 공격 대형 돌격 · 지원 로봇 · 적 카이팅", "올렸을 때 말풍선 · 휠 이동 · 가장자리 이동 · 깃발 · 조작법 창", "로봇끼리 안 겹치게 밀어내기 (고도판에서 새로 추가)", "효과 · 효과음 · 배경음 · 승리/패배 연출", "로비 · 설정 · 저장 · 이어하기 · 튜토리얼"]]]

func _lobby_notes(f: Font, hov) -> void:
	var pr := _lobby_panel(f, "패치 노트")
	var y := pr.position.y + 70.0
	for v in NOTES:
		draw_string(f, Vector2(pr.position.x + 20.0, y), v[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffe6a6"))
		y += 28.0
		for l in v[1]:
			draw_string(f, Vector2(pr.position.x + 30.0, y), "· " + l, HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 50.0, 13, Color("#c9d4dc"))
			y += 22.0
		y += 10.0
	for it in ui:
		if it.id == "lback":
			_btn(f, it.r, "뒤로", hov == it, 15)

func _slider_set(key: String, sp: Vector2) -> void:
	for it in ui:
		if it.id == "sl" and it.arg == key:
			var r: Rect2 = it.r
			var nm: Array = {"uis": [50, 130, 5], "vol_s": [0, 100, 1], "vol_b": [0, 100, 1]}[key]
			var k := clampf((sp.x / us - r.position.x) / r.size.x, 0.0, 1.0)
			SV[key] = int(snappedf(nm[0] + k * (nm[1] - nm[0]), nm[2]))
			if key != "uis":
				_apply_sv()
			return

func lobby_press(it: Dictionary, sp: Vector2) -> void:
	sfx("click")
	match it.id:
		"lnew": start_game(false)
		"lcont": start_game(true)
		"lset":
			lsec = "set"
			lob_scroll = 0.0
		"lnotes": lsec = "notes"
		"lshop", "lstore", "lpass":
			lsec = {"lshop": "shop", "lstore": "store", "lpass": "pass"}[it.id]
			lob_scroll = 0.0
			lmsg = ""
		"cb":
			cos_press(it.arg)
		"boxok":
			if box_busy():
				box_t0 = t_real - 100.0
				box_shown = box_res.size()
			else:
				box_res = []
		"lback":
			lsec = "main"
			_apply_sv()
			sv_save()
		"ltut": start_game(false, true)
		"lmute":
			SV.mute = not SV.mute
			_apply_sv()
			sv_save()
		"lkeys": keys_open = true
		"lbgm":
			var opts: Array = ["auto", "base"]
			for id in MUS_IDS:
				if SV.town.has(id):
					opts.append(id)
			var cur: String = str(SV.get("bgm", "auto"))
			SV.bgm = opts[(opts.find(cur) + 1) % opts.size()]
			sv_save()
		"sl":
			slider_drag = it.arg
			_slider_set(it.arg, sp)
		"lwipe", "lwipeall":
			if wipe_arm != it.id:
				wipe_arm = it.id
				wipe_t = t_real
				return
			wipe_arm = ""
			SV.cs = 0
			for k in ["own", "bown", "town"]:
				SV[k] = []
			for k in ["eq", "beq", "teq"]:
				SV[k] = ""
			SV.frag = {}
			if it.id == "lwipeall":
				SV.ss = 0
				SV.sfrag = 0
				SV.spity = 0
				SV.fbox = 0
				SV.hist = []
				SV.erase("bp")
				_sv_defaults()
				SV.tut_done = false
				del_save()
			sv_save()
			lmsg = "초기화했어요"

func _lobby_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if keys_open and (e.keycode == KEY_ESCAPE or e.keycode == KEY_TAB):
			keys_open = false
		elif e.keycode == KEY_TAB:
			keys_open = true
		elif e.keycode == KEY_ESCAPE and lsec != "main":
			lsec = "main"
			_apply_sv()
			sv_save()
		return
	var pos = null
	var pressed := false
	var released := false
	if e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dd := -60.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 60.0
			if e.pressed and lsec == "set":
				lob_scroll = clampf(lob_scroll + dd * 0.7, 0.0, 200.0)
			elif e.pressed and lsec == "pass" and not (e.shift_pressed):
				pass_scroll = clampf(pass_scroll + dd * 1.5, 0.0, _pass_max())
			elif e.pressed and lsec in ["shop", "store"] and box_res.is_empty():
				lob_scroll = clampf(lob_scroll + dd, 0.0, lob_max)
			return
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = e.position
		pressed = e.pressed
		released = not e.pressed
	elif e is InputEventScreenTouch:
		pos = e.position
		pressed = e.pressed
		released = not e.pressed
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		mouse_ui = e.position / us
		if slider_drag != null:
			_slider_set(slider_drag, e.position)
		return
	elif e is InputEventScreenDrag:
		if slider_drag != null:
			_slider_set(slider_drag, e.position)
		elif lob_drag != null:
			if (e.position - lob_drag.p).length() > 12.0:
				lob_drag.m = true
			if lob_drag.m:
				if lsec == "pass":
					pass_scroll = clampf(pass_scroll - e.relative.x / us, 0.0, _pass_max())
				elif lsec in ["shop", "store", "set"]:
					lob_scroll = clampf(lob_scroll - e.relative.y / us, 0.0, lob_max if lsec != "set" else 200.0)
		return
	if pos == null:
		return
	var touch := e is InputEventScreenTouch
	if released:
		if slider_drag != null:
			if slider_drag == "uis":
				_apply_sv()
			slider_drag = null
			sv_save()
		elif touch and lob_drag != null:
			var moved: bool = lob_drag.m
			lob_drag = null
			if not moved:
				var it2 = ui_hit(pos)
				if it2 != null and it2.id != "sl":
					lobby_press(it2, pos)
		return
	if pressed:
		if keys_open:
			keys_open = false
			return
		var it = ui_hit(pos)
		if touch:
			lob_drag = {"p": pos, "m": false}
			if it != null and it.id == "sl":
				lobby_press(it, pos)
			return
		if it != null:
			lobby_press(it, pos)

const SK := [
{"id":"j1","g":"ju","n":"봄 벚꽃","c":"#f4a6c0","a":"#fff0f5","pt":"dot","d":"분홍 장갑에 꽃잎 점무늬"},
{"id":"j2","g":"ju","n":"한여름 바다","c":"#3fa7e0","a":"#e8fbff","pt":"band","d":"파도빛 몸체에 흰 물결 띠"},
{"id":"j3","g":"ju","n":"가을 단풍","c":"#d9772b","a":"#ffe0a0","pt":"dot","d":"붉은 단풍색에 금빛 점"},
{"id":"j4","g":"ju","n":"첫눈","c":"#dbeef8","a":"#5f9fd0","pt":"dot","d":"눈처럼 흰 장갑에 푸른 점"},
{"id":"j5","g":"ju","n":"사막 모래","c":"#d8b878","a":"#6e5024","pt":"band","d":"모래색 위장 도색"},
{"id":"j6","g":"ju","n":"정글 이끼","c":"#5f9a48","a":"#d8f0a0","pt":"band","d":"이끼 낀 녹색 장갑"},
{"id":"j7","g":"ju","n":"강철 공장","c":"#7d8894","a":"#f2c14e","pt":"band","d":"회색 철판에 노란 경고 띠"},
{"id":"j8","g":"ju","n":"산호초","c":"#ff8070","a":"#fff4d0","pt":"dot","d":"산호빛 몸체에 모래 점"},
{"id":"j9","g":"ju","n":"박하 사탕","c":"#9ce8cc","a":"#ff5a7a","pt":"band","d":"민트색에 빨간 사탕 줄"},
{"id":"j10","g":"ju","n":"자정","c":"#2c3e70","a":"#ffe27a","pt":"dot","d":"밤하늘 남색에 별빛 점"},
{"id":"k6","g":"kro","p":1100,"n":"심해","c":"#13324a","a":"#3ff0ff","pj":"bubble","pc":["#bffcff","#3ff0ff"],"pt":"glow","d":"물방울 탄환 · 거품 폭발"},
{"id":"k5","g":"kro","p":1200,"n":"벚꽃 폭풍","c":"#ffd6e4","a":"#ff5f97","pj":"petal","pc":["#ffe0ec","#ff6fa0"],"pt":"glow","d":"회전하는 꽃잎 탄환 · 꽃잎 흩날림"},
{"id":"k1","g":"kro","p":1300,"n":"오로라","c":"#1d4a52","a":"#7affd4","pj":"aurora","pc":["#7affd4","#c08cff"],"pt":"glow","d":"초록·보라 빛줄기 탄환"},
{"id":"k3","g":"kro","p":1400,"n":"서리 왕관","c":"#e6f6ff","a":"#4ab0ff","pj":"ice","pc":["#ffffff","#6ac8ff"],"pt":"glow","d":"얼음 창 탄환 · 서리 파편"},
{"id":"k2","g":"kro","p":1500,"n":"용암 핵","c":"#3a1a14","a":"#ff6a1f","pj":"fire","pc":["#ffd25a","#ff4a1a"],"pt":"glow","d":"불덩이 탄환 · 불씨 폭발"},
{"id":"k4","g":"kro","p":1600,"n":"번개 군단","c":"#262b44","a":"#ffe14a","pj":"bolt","pc":["#ffffff","#ffe14a"],"pt":"glow","d":"지직거리는 번개 탄환 · 전기 스파크"},
{"id":"k7","g":"kro","p":1700,"n":"황금 제국","c":"#c9a23a","a":"#fff1a8","pj":"star","pc":["#fffbe0","#ffcc33"],"pt":"glow","d":"회전하는 황금 별 탄환 · 금가루 폭발"},
{"id":"j11","g":"ju","n":"네온 거리","c":"#ff3ad0","a":"#3affe8","pt":"band","d":"형광 분홍 몸체에 민트 네온 띠"},
{"id":"j12","g":"ju","n":"군용 위장","c":"#5a6a3a","a":"#c8b878","pt":"dot","d":"국방색 위장 점무늬"},
{"id":"j13","g":"ju","n":"라벤더","c":"#b89ae0","a":"#fff6ff","pt":"dot","d":"연보라 몸체에 흰 꽃 점"},
{"id":"k8","g":"kro","p":1250,"n":"네온 사이버","c":"#1a1030","a":"#ff3ad0","pj":"bolt","pc":["#3affe8","#ff3ad0"],"pt":"glow","d":"네온 번개 탄환 · 형광 스파크"},
{"id":"k10","g":"kro","p":1350,"n":"장미 기사","c":"#5a1020","a":"#ff4a6a","pj":"petal","pc":["#ffd0d8","#d81a3a"],"pt":"glow","d":"붉은 장미 꽃잎 탄환 · 꽃잎 폭발"},
{"id":"k9","g":"kro","p":1450,"n":"혜성","c":"#1a2240","a":"#9ad8ff","pj":"aurora","pc":["#ffffff","#5a9aff"],"pt":"glow","d":"꼬리 긴 혜성 빛줄기 탄환"},
{"id":"k11","g":"kro","ex":1,"p":0,"n":"은하 사령관","c":"#1a1440","a":"#c08cff","pj":"star","pc":["#ffffff","#c08cff"],"pt":"glow","d":"패스 전용 · 보랏빛 별 탄환 · 별가루 폭발"},
{"id":"m1","g":"star","n":"천상의 기사","c":"#fff4d6","a":"#ffd25a","pj":"holy","pc":["#ffffff","#ffd25a"],"pt":"m1","d":"금빛 후광과 펄럭이는 날개 · 빛의 창 탄환"},
{"id":"m2","g":"star","n":"용의 군주","c":"#8a1a12","a":"#ff6a1f","pj":"dragon","pc":["#ffd25a","#ff3a1a"],"pt":"m2","d":"불꽃 오라와 박쥐 날개 · 용의 화염구"},
{"id":"m3","g":"star","n":"프리즘 코어","c":"#e8f6ff","a":"#ffffff","pj":"rainbow","pc":["#ffffff","#7affd4"],"pt":"m3","d":"무지갯빛 결정체와 공전하는 조각 · 프리즘 광선"}]
const BS := [
{"id":"b1","n":"벚꽃 정원","d":"분홍 꽃잎빛 돔과 정원 판","pl":"#3a2a30","rim":"#f4a6c0","bd":"#5a3a46","tp":"#ffd0de","gl":"#ff8fb8","lt":"#fff0f5"},
{"id":"b2","n":"빙하 요새","d":"얼음 판 위의 푸른 돔","pl":"#1e2c38","rim":"#bfe6ff","bd":"#4a6a82","tp":"#e6f6ff","gl":"#6ac8ff","lt":"#ffffff"},
{"id":"b3","n":"화산 요새","d":"검붉은 장갑과 용암 돔","pl":"#241412","rim":"#7a2a1a","bd":"#3a1a14","tp":"#5a2a1e","gl":"#ff6a1f","lt":"#ffd25a"},
{"id":"b4","n":"황금 궁전","d":"금빛 장식의 사령부","pl":"#2a2416","rim":"#c9a23a","bd":"#6b5420","tp":"#e8c36a","gl":"#fff1a8","lt":"#ffcc33"},
{"id":"b5","n":"심해 기지","d":"깊은 바다색 돔과 청록 조명","pl":"#0c1e2c","rim":"#2a6a8a","bd":"#13324a","tp":"#1d5070","gl":"#3ff0ff","lt":"#bffcff"},
{"id":"b6","n":"정글 전초기지","d":"이끼 낀 녹색 기지","pl":"#1c2a18","rim":"#5f9a48","bd":"#3a5a2c","tp":"#8ab86a","gl":"#d8f0a0","lt":"#f2c14e"},
{"id":"b7","n":"오로라 관측소","d":"오로라빛 돔과 보라 조명","pl":"#101c22","rim":"#7affd4","bd":"#1d4a52","tp":"#2a6a6a","gl":"#7affd4","lt":"#c08cff"},
{"id":"b8","n":"번개 요새","d":"먹구름빛 장갑과 번쩍이는 조명","pl":"#14141c","rim":"#ffe14a","bd":"#262b44","tp":"#3a3a5a","gl":"#ffe14a","lt":"#ffffff"},
{"id":"b9","n":"네온 타워","d":"형광 네온이 번쩍이는 사령부","pl":"#14102a","rim":"#ff3ad0","bd":"#2a1a4a","tp":"#4a2a7a","gl":"#3affe8","lt":"#ff3ad0"},
{"id":"b10","n":"혜성 관측소","d":"밤하늘빛 돔과 별빛 조명","pl":"#0e1426","rim":"#9ad8ff","bd":"#1a2240","tp":"#2a3a6a","gl":"#9ad8ff","lt":"#ffffff"},
{"id":"b11","n":"장미 온실","d":"붉은 장미빛 유리 온실","pl":"#2a1218","rim":"#ff4a6a","bd":"#5a1020","tp":"#8a2a3a","gl":"#ffd0d8","lt":"#ff4a6a"},
{"id":"b12","ex":1,"n":"은하 요새","d":"패스 전용 · 별빛 돔과 보랏빛 조명","pl":"#0c0a1e","rim":"#c08cff","bd":"#1a1440","tp":"#3a2a7a","gl":"#c08cff","lt":"#ffffff"},
{"id":"mb1","g":"star","ex":1,"ms":"mb1","n":"천상의 성소","d":"금빛 기둥과 회전하는 후광 · 하늘로 솟는 빛기둥","pl":"#e8eef8","rim":"#ffd25a","bd":"#c8d0e0","tp":"#ffffff","gl":"#ffd25a","lt":"#ffffff"},
{"id":"mb2","g":"star","ex":1,"ms":"mb2","n":"용의 둥지","d":"거대한 뿔과 용암 웅덩이 · 빛나는 용의 눈","pl":"#1a0806","rim":"#5a1a10","bd":"#3a1410","tp":"#5a2a1e","gl":"#ff6a1f","lt":"#ffd25a"},
{"id":"mb3","g":"star","ex":1,"ms":"mb3","n":"프리즘 첨탑","d":"색이 변하는 결정 첨탑과 공전하는 조각","pl":"#0e1426","rim":"#e8f6ff","bd":"#2a3a6a","tp":"#c8e0ff","gl":"#7affd4","lt":"#ffffff"}]
const TS := [
{"id":"t1","g":"ju","n":"설원","d":"눈 덮인 들판과 푸른 적","tn":["#c9d6de","#d3dfe6","#bfccd5","#dbe5eb"],"en":["#4a6a9a","#6a8ab0"],"ob":["#2a3a50","#5a7a9a","#8aaac8"]},
{"id":"t2","g":"ju","n":"사막","d":"모래 언덕과 흙빛 요새","tn":["#c9a66b","#d1ae72","#bf9c62","#d8b67a"],"en":["#8a4a2a","#a8683a"],"ob":["#5a3a20","#8a5a30","#b07a44"]},
{"id":"t3","g":"ju","n":"초원","d":"푸른 풀밭과 붉은 적","tn":["#4f7a3a","#56823f","#487236","#5c8a44"],"en":["#a83a3a","#c06a3a"],"ob":["#3a2420","#7a3a30","#a85a48"]},
{"id":"t4","g":"ju","n":"화성","d":"붉은 땅과 노란 적","tn":["#7a3a24","#843f27","#713521","#8a462c"],"en":["#e0c060","#e09040"],"ob":["#2a1a14","#5a3a24","#8a5a34"]},
{"id":"t5","g":"ju","n":"달 표면","d":"회색 크레이터와 푸른 적","tn":["#6a6a70","#727278","#636369","#7a7a80"],"en":["#3a8ac8","#5aa0d8"],"ob":["#22262e","#3a4250","#5a6474"]},
{"id":"t6","g":"ju","n":"늪지","d":"어두운 늪과 독초색 적","tn":["#3a4430","#404a34","#363f2c","#465038"],"en":["#8ac040","#a0b050"],"ob":["#1e2418","#3a4a28","#5a6e3a"]},
{"id":"t7","g":"ju","n":"해변","d":"밝은 모래사장과 산호빛 적","tn":["#e0cf9a","#e6d6a3","#d8c690","#ecdcaa"],"en":["#e06a4a","#f09a5a"],"ob":["#2a4a5a","#3a7a8a","#6ab0c0"]},
{"id":"t8","g":"ju","n":"가을 숲","d":"갈색 낙엽 땅과 단풍빛 적","tn":["#6a4a2a","#72502e","#634527","#7a5632"],"en":["#d0502a","#e08a2a"],"ob":["#2a1a10","#5a3018","#8a4a20"]},
{"id":"t9","g":"ju","n":"청록 행성","d":"청록 대지와 주황 적","tn":["#1f4a4a","#235050","#1c4444","#285656"],"en":["#ff8a4a","#ffb04a"],"ob":["#102828","#2a5a5a","#4a8a8a"]},
{"id":"t10","g":"ju","n":"잿빛 폐허","d":"무너진 회색 도시와 붉은 적","tn":["#4a4a4a","#505050","#444444","#565656"],"en":["#c83a3a","#d86a3a"],"ob":["#1a1a1a","#3a3a3a","#5a5a5a"]},
{"id":"tk1","g":"kro","p":1100,"n":"심해 협곡","d":"떠오르는 거품 · 적이 물방울 탄환을 쏴요","tn":["#0c2a3a","#0f3040","#0a2634","#123646"],"en":["#2ad0a0","#3ff0ff"],"ob":["#061820","#14485a","#3ff0ff"],"amb":"bubble","pj":"bubble","pc":["#bffcff","#3ff0ff"],"a":"#3ff0ff"},
{"id":"tk2","g":"kro","p":1200,"n":"벚꽃 계곡","d":"흩날리는 꽃잎 · 적이 꽃잎 탄환을 쏴요","tn":["#5a7a4a","#628250","#557245","#6a8a56"],"en":["#d84a7a","#f07aa0"],"ob":["#3a2030","#8a4a68","#ffb0cc"],"amb":"petal","pj":"petal","pc":["#ffe0ec","#ff6fa0"],"a":"#ff6fa0"},
{"id":"tk3","g":"kro","p":1300,"n":"눈보라 왕국","d":"내리는 눈 · 적이 얼음 창을 던져요","tn":["#c9d6de","#d3dfe6","#bfccd5","#dbe5eb"],"en":["#3a5a9a","#5a7ab8"],"ob":["#1a2a44","#4a6a9a","#cfe6ff"],"amb":"snow","pj":"ice","pc":["#ffffff","#6ac8ff"],"a":"#bfe6ff"},
{"id":"tk4","g":"kro","p":1400,"n":"폭풍 황무지","d":"쏟아지는 비 · 적이 번개를 쏴요","tn":["#3a3a40","#404046","#35353b","#46464c"],"en":["#6a6aff","#8a8aff"],"ob":["#14141c","#3a3a5a","#ffe14a"],"amb":"rain","pj":"bolt","pc":["#ffffff","#ffe14a"],"a":"#ffe14a"},
{"id":"tk5","g":"kro","p":1500,"n":"용암 대지","d":"날리는 불씨 · 적이 불덩이를 쏴요","tn":["#2a1612","#301a14","#26130f","#361e16"],"en":["#ff5a2a","#ff8a2a"],"ob":["#140806","#4a1a10","#ff6a1f"],"amb":"ember","pj":"fire","pc":["#ffd25a","#ff4a1a"],"a":"#ff6a1f"},
{"id":"tk6","g":"kro","p":1600,"n":"오로라 툰드라","d":"하늘의 오로라 · 적이 빛줄기를 쏴요","tn":["#2a3a44","#2f404a","#26353f","#344650"],"en":["#4ac0a0","#7ab0d0"],"ob":["#101c22","#2a5a5a","#7affd4"],"amb":"aurora","pj":"aurora","pc":["#7affd4","#c08cff"],"a":"#7affd4"},
{"id":"tk7","g":"kro","p":1700,"n":"별의 바다","d":"반짝이는 별하늘 · 적이 황금 별을 쏴요","tn":["#0e1428","#111830","#0c1224","#141c36"],"en":["#5a8aff","#8ab0ff"],"ob":["#080c1a","#2a3a7a","#ffe27a"],"amb":"star","pj":"star","pc":["#fffbe0","#ffcc33"],"a":"#ffe27a"},
{"id":"t11","g":"ju","n":"네온 도시","d":"어두운 도시와 형광 적","tn":["#1e1a2e","#231e34","#1a1628","#28223a"],"en":["#3affe8","#ff3ad0"],"ob":["#120e22","#3a2a6a","#ff3ad0"]},
{"id":"t12","g":"ju","n":"라벤더 언덕","d":"보랏빛 들판과 짙은 보라 적","tn":["#8a7aa8","#9282b0","#82729f","#9a8ab8"],"en":["#4a2a6a","#6a3a8a"],"ob":["#3a2a4a","#6a4a8a","#c8a0ff"]},
{"id":"t13","g":"ju","n":"붉은 협곡","d":"붉은 바위 협곡과 푸른 적","tn":["#8a4a2a","#924f2e","#824527","#9a5432"],"en":["#3a6aa8","#5a8ac8"],"ob":["#3a1a10","#6a3020","#a85030"]},
{"id":"tk8","g":"kro","p":1250,"n":"사이버 그리드","d":"네온 비 · 적이 형광 번개를 쏴요","tn":["#120e22","#161128","#100c1e","#1a142e"],"en":["#3affe8","#ff3ad0"],"ob":["#0a0818","#2a1a4a","#3affe8"],"amb":"rain","pj":"bolt","pc":["#3affe8","#ff3ad0"],"a":"#ff3ad0"},
{"id":"tk10","g":"kro","p":1350,"n":"장미 정원","d":"흩날리는 장미잎 · 적이 장미 꽃잎을 쏴요","tn":["#3a5a34","#40623a","#36542f","#46683f"],"en":["#a81a3a","#d84a6a"],"ob":["#2a0a12","#6a1a2a","#ff4a6a"],"amb":"petal","pj":"petal","pc":["#ffd0d8","#d81a3a"],"a":"#ff4a6a"},
{"id":"tk9","g":"kro","p":1450,"n":"유성우 사막","d":"쏟아지는 별빛 · 적이 혜성 빛줄기를 쏴요","tn":["#2a2238","#30283f","#262033","#352c45"],"en":["#5a9aff","#9ad8ff"],"ob":["#0e0a1a","#2a2a5a","#9ad8ff"],"amb":"star","pj":"aurora","pc":["#ffffff","#5a9aff"],"a":"#9ad8ff"},
{"id":"tk11","g":"kro","ex":1,"p":0,"n":"은하수","d":"패스 전용 · 쏟아지는 별 · 적이 보랏빛 별을 쏴요","tn":["#0a0818","#0d0a1e","#080614","#100c24"],"en":["#c08cff","#7a5aff"],"ob":["#06041a","#2a1a5a","#c08cff"],"amb":"star","pj":"star","pc":["#ffffff","#c08cff"],"a":"#c08cff"},
{"id":"tm1","g":"star","ex":1,"p":0,"n":"천상의 구름 정원","d":"구름 위 정원 · 금빛 깃털이 내려와요 · 적이 빛의 창을 던져요","tn":["#c8d8ec","#d2e0f2","#bed0e6","#dae6f6"],"en":["#c8a040","#e0b850"],"ob":["#6a7a9a","#e8eef8","#ffd25a"],"amb":"feather","pj":"holy","pc":["#ffffff","#ffd25a"],"a":"#ffd25a"},
{"id":"tm2","g":"star","ex":1,"p":0,"n":"용암 화산 둥지","d":"끓어오르는 화산 · 불씨가 솟아요 · 적이 용의 화염구를 쏴요","tn":["#2a1210","#321612","#24100e","#3a1a14"],"en":["#ff5a1a","#ffb03a"],"ob":["#1a0806","#5a1a10","#ff6a1f"],"amb":"ember","pj":"dragon","pc":["#ffd25a","#ff3a1a"],"a":"#ff6a1f"},
{"id":"tm3","g":"star","ex":1,"p":0,"n":"프리즘 결정 동굴","d":"무지갯빛 결정 동굴 · 색이 바뀌는 빛가루 · 적이 프리즘 광선을 쏴요","tn":["#141a2e","#182036","#121628","#1c243c"],"en":["#7affd4","#c08cff"],"ob":["#0a0e1e","#2a3a6a","#ffffff"],"amb":"prism","pj":"rainbow","pc":["#ffffff","#7affd4"],"a":"#c8e0ff"}]
const TMN := {"t1":["#7ab8e0","#e6f6ff","rgba(200,230,255,.18)","snow"],"t2":["#d8a040","#fff0b0","rgba(255,210,120,.16)","sand"],"t3":["#3ac0a0","#b0ffe8","rgba(95,224,196,.14)","grass"],"t4":["#e07a3a","#ffd0a0","rgba(255,140,80,.16)","rock"],"t5":["#9ab0ff","#e8eeff","rgba(170,190,255,.16)","crater"],"t6":["#8ac040","#e0ffb0","rgba(160,220,90,.15)","moss"],"t7":["#ff8a7a","#fff0e0","rgba(255,150,130,.16)","shell"],"t8":["#e08a2a","#ffe0a0","rgba(255,170,80,.16)","leaf"],"t9":["#ffb04a","#fff0c0","rgba(255,180,80,.16)","rock"],"t10":["#7ad0e0","#e0faff","rgba(120,210,230,.15)","rubble"],
 "tk1":["#3ff0ff","#d8ffff","rgba(63,240,255,.22)","bubble"],"tk2":["#ff6fa0","#ffe0ec","rgba(255,111,160,.2)","petal"],"tk3":["#6ac8ff","#ffffff","rgba(160,220,255,.22)","ice"],"tk4":["#ffe14a","#fffbe0","rgba(255,225,74,.2)","spark"],"tk5":["#ff6a1f","#ffd25a","rgba(255,106,31,.24)","ember"],"tk6":["#7affd4","#e8fff8","rgba(122,255,212,.22)","aurora"],"tk7":["#ffe27a","#fffbe0","rgba(255,226,122,.22)","star"],
 "t11":["#ff3ad0","#ffd0f6","rgba(255,58,208,.18)","rock"],"t12":["#c8a0ff","#f6eeff","rgba(200,160,255,.16)","grass"],"t13":["#e0904a","#ffe0b0","rgba(255,160,80,.15)","rock"],"tk8":["#3affe8","#e0fffb","rgba(58,255,232,.2)","spark"],"tk9":["#9ad8ff","#ffffff","rgba(154,216,255,.2)","star"],"tk10":["#ff4a6a","#ffd0d8","rgba(255,74,106,.2)","petal"],"tk11":["#c08cff","#f0e0ff","rgba(192,140,255,.22)","star"],"tm1":["#ffd25a","#fffbe0","rgba(255,226,140,.28)","star"],"tm2":["#ff6a1f","#ffd25a","rgba(255,106,31,.3)","ember"],"tm3":["#c8e0ff","#ffffff","rgba(200,230,255,.28)","aurora"]}
const SETS := [{"n":"벚꽃 세트","r":"k5","b":"b1","t":"tk2"},{"n":"서리 세트","r":"k3","b":"b2","t":"tk3"},{"n":"용암 세트","r":"k2","b":"b3","t":"tk5"},{"n":"황금 세트","r":"k7","b":"b4","t":"tk7"},{"n":"심해 세트","r":"k6","b":"b5","t":"tk1"},{"n":"오로라 세트","r":"k1","b":"b7","t":"tk6"},{"n":"번개 세트","r":"k4","b":"b8","t":"tk4"},{"n":"정글 세트","r":"j6","b":"b6","t":"t3"},{"n":"네온 세트","r":"k8","b":"b9","t":"tk8"},{"n":"장미 세트","r":"k10","b":"b11","t":"tk10"},{"n":"혜성 세트","r":"k9","b":"b10","t":"tk9"}]
const MSET := [{"n":"천상 세트","r":"m1","b":"mb1","t":"tm1"},{"n":"용왕 세트","r":"m2","b":"mb2","t":"tm2"},{"n":"프리즘 세트","r":"m3","b":"mb3","t":"tm3"}]

# ═════════ 꾸미기: 스킨 · 기지 · 테마 그림 (웹 bot · base · masterBot · masterBase · amb · mdeco · drawPr) ═════════
var _ccache := {}
func C(s) -> Color:
	if s is Color:
		return s
	var k := str(s)
	if _ccache.has(k):
		return _ccache[k]
	var c := Color.WHITE
	if k.begins_with("rgba("):
		var a := k.substr(5, k.length() - 6).split(",")
		c = Color(float(a[0]) / 255.0, float(a[1]) / 255.0, float(a[2]) / 255.0, float(a[3]))
	else:
		c = Color(k)
	_ccache[k] = c
	return c

func hsl(h: float, s: float, l: float, a: float = 1.0) -> Color:
	var c := (1.0 - absf(2.0 * l - 1.0)) * s
	var hp := fmod(h, 360.0) / 60.0
	var x := c * (1.0 - absf(fmod(hp, 2.0) - 1.0))
	var r := 0.0
	var g := 0.0
	var b := 0.0
	if hp < 1:
		r = c
		g = x
	elif hp < 2:
		r = x
		g = c
	elif hp < 3:
		g = c
		b = x
	elif hp < 4:
		g = x
		b = c
	elif hp < 5:
		r = x
		b = c
	else:
		r = c
		b = x
	var m := l - c / 2.0
	return Color(r + m, g + m, b + m, a)

func _find_in(L: Array, id) -> Dictionary:
	if id == null or str(id) == "":
		return {}
	for q in L:
		if q.id == id:
			return q
	return {}

func SKIN() -> Dictionary:
	return _find_in(SK, SV.eq)
func BSK() -> Dictionary:
	return _find_in(BS, SV.beq)
func TH() -> Dictionary:
	return _find_in(TS, SV.teq)
func KRO() -> Dictionary:
	var s := SKIN()
	return s if (not s.is_empty() and (s.g == "kro" or s.g == "star")) else {}
func TKRO() -> Dictionary:
	var s := TH()
	return s if (not s.is_empty() and (s.g == "kro" or s.g == "star")) else {}
func ground_tn() -> Array:
	var th := TH()
	return th.tn if not th.is_empty() else ["#4a4234", "#4e4537", "#463f32", "#524939"]

# 로봇: 기본 모양 위에 스킨 무늬 (dot · band · glow) · 걸작(m1~m3)은 따로
func art_bot_s(ci: CanvasItem, k: String, col: Color, acc: Color, t: float, pat: String) -> void:
	if pat.length() == 2 and pat[0] == "m":
		art_master_bot(ci, k, pat, t)
		return
	if pat == "glow":
		ci.draw_circle(Vector2.ZERO, 13, Color(acc, 0.22 + 0.12 * sin(t * 4.0)))
	art_bot(ci, k, col, acc, t, pat == "")
	if k != "s":
		if pat == "dot":
			ci.draw_rect(Rect2(-6, -5, 2, 2), acc)
			ci.draw_rect(Rect2(-6, 3, 2, 2), acc)
			ci.draw_rect(Rect2(-3, -1, 2, 2), acc)
		elif pat == "band":
			ci.draw_rect(Rect2(-2, -7, 2, 14), acc)

func _hexp(r: float, rot: float = 0.0, c: Vector2 = Vector2.ZERO, sy: float = 1.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 6:
		var a := i * PI / 3.0 + rot
		p.append(c + Vector2(cos(a) * r, sin(a) * r * sy))
	return p

func _xp(pts: Array, S: float, rot: float = 0.0, off: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var o := PackedVector2Array()
	for v in pts:
		o.append(((v as Vector2).rotated(rot) + off) * S)
	return o

func art_master_bot(ci: CanvasItem, k: String, p: String, tm: float) -> void:
	var S: float = {"c": 1.15, "r": 1.0, "h": 1.0, "m": 0.95, "s": 0.72}.get(k, 1.0)
	if p == "m1":
		for i in 12:
			var a := tm * 1.5 + i * TAU / 12.0
			ci.draw_arc(Vector2.ZERO, 14 * S, a, a + 0.28, 4, Color(1.0, 0.9, 0.55, 0.85), 1.6 * S)
		ci.draw_circle(Vector2.ZERO, 15 * S, Color(1.0, 0.91, 0.63, 0.3 + 0.15 * sin(tm * 3.0)))
		var w := sin(tm * 6.0) * 2.5
		for sg in [-1.0, 1.0]:
			var wing := []
			var a0 := Vector2(-2, sg * 4)
			for j in 9:
				var q := j / 8.0
				wing.append(a0.lerp(Vector2(-10, sg * (14 + w)), q).lerp(Vector2(-10, sg * (14 + w)).lerp(Vector2(-16, sg * (10 + w)), q), q))
			wing.append(Vector2(-10, sg * 8))
			wing.append(Vector2(-6, sg * 5))
			var wp := _xp(wing, S)
			ci.draw_colored_polygon(wp, Color.WHITE)
		ci.draw_colored_polygon(_xp([Vector2(11, 0), Vector2(3, -8), Vector2(-7, -6), Vector2(-7, 6), Vector2(3, 8)], S), K)
		var body := _xp([Vector2(9.5, 0), Vector2(2.5, -6.5), Vector2(-5.5, -5), Vector2(-5.5, 5), Vector2(2.5, 6.5)], S)
		ci.draw_polygon(body, PackedColorArray([Color("#f2d68a"), Color.WHITE, Color.WHITE, Color("#f8e4b0"), Color("#f2d68a")]))
		var bl := body.duplicate()
		bl.append(body[0])
		ci.draw_polyline(bl, Color("#c9a23a"), 1.0)
		ci.draw_circle(Vector2(1, 0) * S, 5.0 * S, Color(1.0, 0.82, 0.35, 0.3))
		ci.draw_circle(Vector2(1, 0) * S, 2.6 * S, Color("#ffd25a"))
	elif p == "m2":
		for i in 8:
			var a := i / 8.0 * TAU + tm * 2.0
			var r := 11.0 + sin(tm * 9.0 + i * 1.7) * 2.5
			ci.draw_circle(Vector2(cos(a), sin(a)) * r * S, 2.6 * S, Color("#ff5a1a" if i % 2 else "#ffb03a", 0.55))
		ci.draw_colored_polygon(_xp([Vector2(-6, -2), Vector2(-17, sin(tm * 5.0) * 4), Vector2(-6, 2)], S), Color("#3a0a0a"))
		for sg in [-1.0, 1.0]:
			ci.draw_colored_polygon(_xp([Vector2(-1, sg * 3), Vector2(-6, sg * (15 + sin(tm * 7.0) * 2)), Vector2(-9, sg * 9), Vector2(-12, sg * 12), Vector2(-8, sg * 4)], S), Color("#5a0e12"))
		ci.draw_colored_polygon(_xp([Vector2(12, 0), Vector2(2, -8), Vector2(-8, -5), Vector2(-8, 5), Vector2(2, 8)], S), K)
		var body := _xp([Vector2(10.5, 0), Vector2(1.5, -6.5), Vector2(-6.5, -4), Vector2(-6.5, 4), Vector2(1.5, 6.5)], S)
		ci.draw_polygon(body, PackedColorArray([Color("#d8321e"), Color("#a02016"), Color("#5a0a0a"), Color("#5a0a0a"), Color("#a02016")]))
		for i in 3:
			ci.draw_rect(Rect2(Vector2(-5 + i * 3.5, -1) * S, Vector2(2, 2) * S), Color(1.0, 0.59, 0.27, 0.4))
		for sg in [-1.0, 1.0]:
			ci.draw_colored_polygon(_xp([Vector2(4, sg * 4), Vector2(-2, sg * 11), Vector2(1, sg * 4)], S), Color("#f0e0c0"))
		ci.draw_rect(Rect2(Vector2(6, -3.2) * S, Vector2(2.4, 1.8) * S), Color("#ffe14a"))
		ci.draw_rect(Rect2(Vector2(6, 1.4) * S, Vector2(2.4, 1.8) * S), Color("#ffe14a"))
	else:
		var h := fmod(tm * 60.0, 360.0)
		for i in 3:
			var a := tm * 2.2 + i * 2.094
			ci.draw_colored_polygon(_xp([Vector2(0, -3.5), Vector2(2.2, 0), Vector2(0, 3.5), Vector2(-2.2, 0)], S, a * 2.0, Vector2(cos(a), sin(a)) * 14.0 / 1.0), hsl(h + i * 120, 0.9, 0.7))
		ci.draw_circle(Vector2.ZERO, 13 * S, hsl(h, 0.9, 0.65, 0.3))
		var rot := tm * 0.6
		ci.draw_colored_polygon(_xp(Array(_hexp(10.5, rot)), S), K)
		var hx := _xp(Array(_hexp(9.0, rot)), S)
		ci.draw_polygon(hx, PackedColorArray([hsl(h, 0.9, 0.75), Color.WHITE, hsl(h + 180, 0.9, 0.65), hsl(h + 180, 0.9, 0.65), Color.WHITE, hsl(h, 0.9, 0.75)]))
		for i in 3:
			var a := i * PI / 3.0 + rot
			ci.draw_line(Vector2(cos(a), sin(a)) * 9 * S, -Vector2(cos(a), sin(a)) * 9 * S, Color(1, 1, 1, 0.6), 0.8)
		ci.draw_circle(Vector2.ZERO, 4.0 * S, Color(1, 1, 1, 0.35))
		ci.draw_circle(Vector2.ZERO, 2.4 * S, Color.WHITE)
	var ac := Color("#ffd25a") if p == "m1" else (Color("#ff8a3a") if p == "m2" else hsl(fmod(tm * 60.0, 360.0), 0.9, 0.7))
	if k == "r":
		ci.draw_rect(Rect2(Vector2(7, -1.8) * S, Vector2(10, 3.6) * S), K)
		ci.draw_rect(Rect2(Vector2(14, -1.8) * S, Vector2(3, 3.6) * S), ac)
	elif k == "c":
		ci.draw_colored_polygon(_xp([Vector2(10, -6), Vector2(17, -2), Vector2(10, -3)], S), ac)
		ci.draw_colored_polygon(_xp([Vector2(10, 6), Vector2(17, 2), Vector2(10, 3)], S), ac)
	elif k == "h":
		ci.draw_rect(Rect2(Vector2(-6, -1) * S, Vector2(6, 2) * S), Color("#8be28b"))
		ci.draw_rect(Rect2(Vector2(-4, -3) * S, Vector2(2, 6) * S), Color("#8be28b"))
	elif k == "m":
		ci.draw_colored_polygon(_xp([Vector2(9, -4), Vector2(16, 0), Vector2(9, 4)], S), Color("#c8d0d8"))

# 걸작 기지 (mb1 천상 · mb2 용 · mb3 프리즘)
func art_master_base(ci: CanvasItem, p: Vector2, m: String, tm: float, xf: Transform2D) -> void:
	var X := xf * Transform2D(0.0, Vector2.ONE, 0.0, p)
	ci.draw_set_transform_matrix(X)
	ci.draw_colored_polygon(ell(Vector2(6, 42), 60, 18), Color(0, 0, 0, 0.32))
	if m == "mb1":
		var ga := 0.35 + 0.15 * sin(tm * 2.0)
		ci.draw_polygon(PackedVector2Array([Vector2(-14, -140), Vector2(14, -140), Vector2(14, 0), Vector2(-14, 0)]), PackedColorArray([Color(1, 0.94, 0.7, 0), Color(1, 0.94, 0.7, 0), Color(1, 0.94, 0.7, ga), Color(1, 0.94, 0.7, ga)]))
		ci.draw_colored_polygon(ell(Vector2(0, 10), 56, 24), Color("#8a96b0"))
		ci.draw_colored_polygon(ell(Vector2(0, 4), 56, 24), Color("#eef2fa"))
		ell_line(ci, Vector2(0, 4), 56, 24, Color("#ffd25a"), 2.0)
		ell_line(ci, Vector2(0, 4), 42, 17, Color(0.78, 0.67, 0.35, 0.5), 1.0)
		var P: Array = []
		for i in 6:
			var a := i / 6.0 * TAU + tm * 0.2
			P.append(Vector2(cos(a) * 44, 4 + sin(a) * 18))
		P.sort_custom(func(a, b): return a.y < b.y)
		var pil := func(q: Vector2):
			ci.draw_rect(Rect2(q.x - 3, q.y - 26, 6, 26), Color("#c8d0e0"))
			ci.draw_rect(Rect2(q.x - 3, q.y - 26, 3, 26), Color.WHITE)
			ci.draw_rect(Rect2(q.x - 4.5, q.y - 29, 9, 3), Color("#ffd25a"))
			ci.draw_rect(Rect2(q.x - 4.5, q.y - 1, 9, 2), Color("#ffd25a"))
		for q in P:
			if q.y < 4:
				pil.call(q)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -58), Vector2(15, 0), Vector2(-15, 0)]), K)
		ci.draw_polygon(PackedVector2Array([Vector2(0, -54), Vector2(12, -2), Vector2(-12, -2)]), PackedColorArray([Color.WHITE, Color("#c0c8d8"), Color("#d8dde8")]))
		ci.draw_circle(Vector2(0, -22), 11, Color(1, 0.82, 0.35, 0.3))
		ci.draw_circle(Vector2(0, -22), 6, Color("#ffd25a"))
		for ring in [[-46.0, 18.0, 1.0], [-30.0, 24.0, -1.4]]:
			var n := 10
			for i in n:
				var a: float = tm * ring[2] + i * TAU / n
				var pts := PackedVector2Array()
				for s in 4:
					var aa := a + s * 0.12
					pts.append(Vector2(cos(aa) * ring[1], ring[0] + sin(aa) * ring[1] * 0.35))
				ci.draw_polyline(pts, Color(1, 0.84, 0.35, 0.9), 2.4)
		for q in P:
			if q.y >= 4:
				pil.call(q)
		for i in 6:
			var a := tm * 0.8 + i
			ci.draw_rect(Rect2(cos(a) * 30, -30 - fmod(tm * 20 + i * 15, 50.0), 2, 2), Color(1, 0.96, 0.84, absf(sin(tm * 2 + i))))
	elif m == "mb2":
		var o1 := PackedVector2Array()
		var o2 := PackedVector2Array()
		for i in 14:
			var a := i / 14.0 * TAU
			var r1 := 50.0 if i % 2 else 58.0
			var r2 := 44.0 if i % 2 else 52.0
			o1.append(Vector2(cos(a) * r1, 6 + sin(a) * r1 * 0.55))
			o2.append(Vector2(cos(a) * r2, 2 + sin(a) * r2 * 0.5))
		ci.draw_colored_polygon(o1, Color("#120604"))
		ci.draw_colored_polygon(o2, Color("#2a1210"))
		var la := 0.7 + 0.3 * sin(tm * 3.0)
		ci.draw_colored_polygon(ell(Vector2(0, 4), 34, 17), Color(0.35, 0.04, 0.04, la))
		ci.draw_colored_polygon(ell(Vector2(0, 4), 24, 12), Color(1.0, 0.42, 0.12, la))
		ci.draw_colored_polygon(ell(Vector2(0, 4), 10, 5), Color(1.0, 0.88, 0.29, la))
		var hood := PackedVector2Array()
		var hood2 := PackedVector2Array()
		for j in 13:
			var q := j / 12.0
			hood.append(Vector2(-18, -6).lerp(Vector2(0, -40), q).lerp(Vector2(0, -40).lerp(Vector2(18, -6), q), q))
			hood2.append(Vector2(-15, -6).lerp(Vector2(0, -35), q).lerp(Vector2(0, -35).lerp(Vector2(15, -6), q), q))
		ci.draw_colored_polygon(hood, Color("#0b0604"))
		ci.draw_colored_polygon(hood2, Color("#3a1a14"))
		for sg in [-1.0, 1.0]:
			var horn := PackedVector2Array()
			for j in 9:
				var q := j / 8.0
				horn.append(Vector2(sg * 10, -20).lerp(Vector2(sg * 38, -36), q).lerp(Vector2(sg * 38, -36).lerp(Vector2(sg * 30, -64), q), q))
			for j in 9:
				var q := j / 8.0
				horn.append(Vector2(sg * 30, -64).lerp(Vector2(sg * 26, -40), q).lerp(Vector2(sg * 26, -40).lerp(Vector2(sg * 4, -26), q), q))
			ci.draw_colored_polygon(horn, Color("#e8dcc0"))
		ci.draw_circle(Vector2(-6, -16), 6, Color(1, 0.42, 0.12, 0.35))
		ci.draw_circle(Vector2(6, -16), 6, Color(1, 0.42, 0.12, 0.35))
		ci.draw_colored_polygon(ell(Vector2(-6, -16), 3, 2, 10), Color("#ffe14a"))
		ci.draw_colored_polygon(ell(Vector2(6, -16), 3, 2, 10), Color("#ffe14a"))
		for i in 10:
			var q := fmod(tm * 0.6 + i / 10.0, 1.0)
			ci.draw_rect(Rect2(sin(i * 2.3) * 30 + sin(tm * 2 + i) * 4, 4 - q * 80, 2.5, 2.5), Color("#ffb03a" if i % 2 else "#ff5a1a", 1.0 - q))
	else:
		var h := fmod(tm * 50.0, 360.0)
		ci.draw_colored_polygon(ell(Vector2(0, 4), 62, 28), hsl(h, 0.9, 0.65, 0.25))
		var hx := _hexp(56, 0.0, Vector2(0, 6), 0.5)
		ci.draw_colored_polygon(hx, Color("#0a0e1e"))
		var hl := hx.duplicate()
		hl.append(hx[0])
		ci.draw_polyline(hl, hsl(h, 0.9, 0.7), 3.0)
		var sh := [[-26, -6, 30, 9], [26, -6, 30, 9], [0, -10, 58, 13], [-12, 6, 22, 7], [14, 8, 20, 6]]
		for i in sh.size():
			var s: Array = sh[i]
			var sx: float = s[0]
			var sy: float = s[1]
			var hh: float = s[2]
			var w: float = s[3]
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, sy - hh - 2), Vector2(sx + w + 1.5, sy), Vector2(sx, sy + w * 0.6 + 1), Vector2(sx - w - 1.5, sy)]), K)
			ci.draw_polygon(PackedVector2Array([Vector2(sx, sy - hh), Vector2(sx + w, sy), Vector2(sx, sy + w * 0.6), Vector2(sx - w, sy)]),
				PackedColorArray([hsl(h + i * 50, 0.9, 0.8), Color.WHITE, hsl(h + i * 50 + 160, 0.85, 0.6), Color.WHITE]))
			ci.draw_line(Vector2(sx, sy - hh), Vector2(sx, sy + w * 0.6), Color(1, 1, 1, 0.55), 0.8)
		for i in 5:
			var a := tm * 1.2 + i * 1.2566
			var c := Vector2(cos(a) * 50, -20 + sin(a) * 16)
			var pts := PackedVector2Array()
			for v in [Vector2(0, -5), Vector2(3, 0), Vector2(0, 5), Vector2(-3, 0)]:
				pts.append(c + (v as Vector2).rotated(a * 2.0))
			ci.draw_colored_polygon(pts, hsl(h + i * 72, 0.95, 0.72))
		ci.draw_circle(Vector2(0, -34), 10, hsl(h, 0.9, 0.7, 0.35))
		ci.draw_circle(Vector2(0, -34), 4, Color.WHITE)
	ci.draw_set_transform_matrix(xf)

# 테마: 광산 주변 꾸미기 (mdeco)
func mdeco(X: Vector2, mn, tm: float, top: bool) -> void:
	if mn == null:
		return
	var d: String = mn[3]
	if not top:
		match d:
			"snow":
				draw_colored_polygon(ell(X + Vector2(0, 10), 24, 8), Color("#f4fbff"))
			"sand":
				draw_colored_polygon(ell(X + Vector2(0, 10), 24, 8), Color("#e6c88a"))
				draw_rect(Rect2(X.x - 16, X.y + 9, 3, 2), Color("#b8925a"))
				draw_rect(Rect2(X.x + 12, X.y + 12, 3, 2), Color("#b8925a"))
			"grass", "moss":
				var gc := Color("#6ab04a") if d == "grass" else Color("#5a7a30")
				for q in [[-18, 8], [-14, 12], [15, 9], [19, 12], [-4, 14]]:
					draw_rect(Rect2(X.x + q[0], X.y + q[1] - 5, 2, 6), gc)
					draw_rect(Rect2(X.x + q[0] + 3, X.y + q[1] - 3, 2, 4), gc)
			"rock", "rubble":
				for q in [[-18, 10, 6], [17, 9, 5], [-8, 14, 4]]:
					draw_colored_polygon(ell(X + Vector2(q[0], q[1]), q[2], q[2] * 0.7, 12), Color("#5a3a2a") if d == "rock" else Color("#3a3a3a"))
			"crater":
				ell_line(self, X + Vector2(0, 8), 26, 9, Color(0, 0, 0, 0.35), 2.0)
			"shell":
				for q in [[-18, 12], [16, 13]]:
					draw_arc(X + Vector2(q[0], q[1]), 1.75, PI, TAU, 6, Color("#fff4e0"), 3.5)
				draw_rect(Rect2(X.x - 2, X.y + 14, 3, 2), Color("#ffb0a0"))
			"leaf":
				for q in [[-17, 9, "#e05a2a"], [16, 11, "#f0a030"], [-6, 15, "#c84a20"]]:
					draw_colored_polygon(ell(X + Vector2(q[0], q[1]), 4, 2, 10), Color(q[2]))
			"bubble":
				for i in 3:
					var q := fmod(tm * 18.0 + i * 14.0, 40.0)
					draw_arc(X + Vector2(-8 + i * 8, -q), 2 + i * 0.6, 0, TAU, 10, Color(0.75, 0.99, 1.0, 0.8 * (1.0 - q / 40.0)), 1.0)
			"petal":
				for i in 4:
					draw_colored_polygon(ell(X + Vector2(-18 + i * 12, 11 + (i % 2) * 3), 3, 1.6, 8), Color("#ffc0d6") if i % 2 else Color("#ff8fb8"))
			"ember":
				draw_colored_polygon(ell(X + Vector2(0, 10), 24, 8), Color(1.0, 0.35, 0.08, 0.35))
				for i in 3:
					var q := fmod(tm * 0.8 + i / 3.0, 1.0)
					draw_rect(Rect2(X.x - 8 + i * 8, X.y - q * 30, 2, 2), Color(1.0, 0.69, 0.23, 1.0 - q))
			"spark":
				if sin(tm * 7.0) > 0.6:
					draw_polyline(PackedVector2Array([X + Vector2(-14, -16), X + Vector2(-8, -10), X + Vector2(-12, -7), X + Vector2(-6, -1)]), Color("#fff6a0"), 1.5)
			"aurora":
				draw_colored_polygon(ell(X + Vector2(0, -4), 16, 30), Color(C(mn[0]), 0.22 + 0.12 * sin(tm * 2.0)))
			"star":
				for i in 4:
					var a := i * 1.57 + tm * 0.5
					draw_rect(Rect2(X.x + cos(a) * 22, X.y + sin(a) * 14, 2, 2), Color(1.0, 0.98, 0.88, absf(sin(tm * 2.0 + i * 1.6))))
	elif d == "snow" or d == "ice":
		var wc := Color(1, 1, 1, 0.92)
		draw_colored_polygon(ell(X + Vector2(0, -20), 4, 2.2, 10), wc)
		draw_colored_polygon(ell(X + Vector2(-10, -9), 3, 1.8, 10), wc)
		draw_colored_polygon(ell(X + Vector2(10, -8), 3, 1.6, 10), wc)
		if d == "ice":
			draw_line(X + Vector2(-22, 11), X + Vector2(22, 11), Color(1, 1, 1, 0.55), 1.0)

const AMB := {"snow": [8, 35], "ember": [0, -30], "petal": [25, 30], "star": [0, 0], "rain": [-60, 450], "bubble": [0, -25], "feather": [14, 26], "prism": [0, -14]}
# 테마 분위기 효과 (화면 좌표 · w×h 영역)
func amb(k: Dictionary, tm: float, o: Vector2, w: float, h: float, ox: float, oy: float, sc: float = 1.0) -> void:
	if k.is_empty() or not k.has("amb"):
		return
	var a: String = k.amb
	if a == "aurora":
		for b in 3:
			var pts := PackedVector2Array()
			for i in 25:
				pts.append(o + Vector2(w * i / 24.0, h * 0.12 + b * h * 0.06 + sin(i / 24.0 * 6.0 + tm * 0.6 + b) * h * 0.04))
			draw_polyline(pts, Color(C(k.pc[b % 2]), 0.12), (18.0 - b * 4) * h / 540.0 + 3.0)
		return
	var v: Array = AMB.get(a, [0, 0])
	for i in 55:
		var r := float((i * 9301 + 49297) % 233280) / 233280.0
		var r2 := float((i * 4447 + 1931) % 1000) / 1000.0
		var px := fposmod(r * w - ox * 0.3 + tm * v[0] + sin(tm * 0.8 + i) * 10.0, w)
		var py := fposmod(r2 * h - oy * 0.3 + tm * v[1] * (0.7 + r * 0.6), h)
		var P := o + Vector2(px, py)
		match a:
			"snow": draw_circle(P, (1.0 + r * 1.6) * sc, Color(1, 1, 1, 0.8))
			"ember": draw_rect(Rect2(P, Vector2(2, 2) * sc), Color("#ffb03a" if i % 2 else "#ff5a1a", 0.4 + 0.5 * absf(sin(tm * 5.0 + i))))
			"petal": draw_colored_polygon(_rot_ell(P, 3 * sc, 1.6 * sc, tm * 2 + i), Color("#ffc0d6" if i % 2 else "#ff8fb8", 0.8))
			"star":
				var z := (1.5 if i % 5 else 2.5) * sc
				draw_rect(Rect2(P, Vector2(z, z)), Color("#ffffff" if i % 3 else "#ffe27a", 0.25 + 0.75 * absf(sin(tm * 1.5 + i * 1.7))))
			"feather": draw_colored_polygon(_rot_ell(P, 3.4 * sc, 1.3 * sc, tm + i), Color("#fff6d6" if i % 3 else "#ffd25a", 0.75))
			"prism": draw_rect(Rect2(P, Vector2(2.6, 2.6) * sc), hsl(tm * 80 + i * 40, 0.95, 0.72, 0.35 + 0.65 * absf(sin(tm * 2 + i))))
			"rain": draw_line(P, P + Vector2(-2, 10) * sc, Color(0.72, 0.78, 1.0, 0.35), 1.0)
			_: draw_arc(P, (1.5 + r * 2.5) * sc, 0, TAU, 10, Color(0.75, 0.99, 1.0, 0.5), 1.0)

func _rot_ell(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p

# 탄환 (스킨별 모양)
func draw_pr(X: Vector2, v: Vector2, s: Dictionary, col: Color, big: bool, mine: bool, tm: float) -> void:
	if big:
		draw_circle(X, 10, Color(Color("#3ab0ff") if mine else Color("#ff3a2a"), 0.35))
		draw_line(X - v * 18.0, X, Color("#7fd8ff") if mine else Color("#ff6a4a"), 4.0)
		draw_circle(X, 4.5, Color("#e0f6ff") if mine else Color("#ffe0d0"))
		return
	if s.is_empty():
		draw_line(X - v * 12.0, X, col, 3.0)
		draw_circle(X, 3.0, Color.WHITE)
		return
	var a := C(s.pc[0])
	var b := C(s.pc[1])
	var an := v.angle()
	var R := func(pts: Array) -> PackedVector2Array:
		var o := PackedVector2Array()
		for q in pts:
			o.append(X + (q as Vector2).rotated(an))
		return o
	match s.get("pj", ""):
		"holy":
			draw_colored_polygon(_rot_ell(X + Vector2(-8, 0).rotated(an), 16, 5, an), Color(b, 0.35))
			draw_colored_polygon(R.call([Vector2(11, 0), Vector2(-2, -3.2), Vector2(-15, 0), Vector2(-2, 3.2)]), a)
			draw_circle(X, 5, Color(b, 0.35))
			draw_circle(X, 2.6, b)
			for i in 3:
				draw_rect(Rect2(X + Vector2(-19 - i * 6, sin(tm * 20 + i) * 3).rotated(an), Vector2(1.6, 1.6)), Color.WHITE)
		"dragon":
			for i in range(4, 0, -1):
				draw_circle(X - v * i * 6.0 + Vector2(sin(tm * 25 + i), cos(tm * 25 + i)) * 1.5, 7 - i, Color(b if i % 2 else a, 0.18 + 0.1 * (5 - i)))
			draw_circle(X, 11, Color(b, 0.35))
			draw_circle(X, 8, Color(b, 0.3))
			draw_circle(X, 5.5, a)
		"rainbow":
			var h := fmod(tm * 240.0, 360.0)
			for k in 3:
				draw_line(X - v * (30 - k * 6), X, hsl(h + k * 70, 0.95, 0.65, 0.85 - k * 0.2), 6 - k * 1.6)
			draw_circle(X, 5, Color(1, 1, 1, 0.35))
			draw_circle(X, 3, Color.WHITE)
		"aurora":
			draw_line(X - v * 26.0, X, Color(b, 0.35), 7.0)
			draw_line(X - v * 16.0, X, Color(a, 0.9), 3.0)
			draw_circle(X, 2.5, Color.WHITE)
		"fire":
			for i in range(3, 0, -1):
				draw_circle(X - v * i * 6.0, 5 - i, Color(b, 0.15 + 0.12 * (4 - i)))
			draw_circle(X, 8, Color(b, 0.4))
			draw_circle(X, 4, a)
		"ice":
			draw_line(X + Vector2(-18, 0).rotated(an), X + Vector2(-4, 0).rotated(an), Color(b, 0.4), 2.0)
			var pts: PackedVector2Array = R.call([Vector2(9, 0), Vector2(0, -3.5), Vector2(-7, 0), Vector2(0, 3.5)])
			draw_colored_polygon(pts, a)
			pts.append(pts[0])
			draw_polyline(pts, b, 1.0)
		"bolt":
			var z := [Vector2(-26, 0), Vector2(-20, 4), Vector2(-14, -4), Vector2(-8, 3), Vector2(-3, -2), Vector2(3, 0)]
			var zz := PackedVector2Array()
			for i in z.size():
				var j := sin(tm * 40 + i) * 2.0 if (i > 0 and i < 5) else 0.0
				zz.append(X + (z[i] + Vector2(0, j)).rotated(an))
			draw_polyline(zz, Color(b, 0.35), 4.0)
			draw_polyline(zz, a, 1.5)
		"petal":
			draw_circle(X - v * 10.0 + Vector2(sin(tm * 9), cos(tm * 9)) * 3.0, 1.8, Color(a, 0.6))
			draw_circle(X - v * 18.0, 1.3, Color(a, 0.6))
			draw_colored_polygon(_rot_ell(X, 6, 3, tm * 12), b)
			draw_colored_polygon(_rot_ell(X + Vector2(1, 0).rotated(tm * 12), 3, 1.5, tm * 12), a)
		"bubble":
			var q := [[0.0, 5.0], [10.0, 2.5], [18.0, 1.6]]
			for i in 3:
				draw_arc(X - v * q[i][0] + Vector2(0, sin(tm * 8 + i) * 2.0 if i else 0.0), q[i][1], 0, TAU, 12, Color(b, 1.0 - i * 0.3), 1.5)
			draw_rect(Rect2(X - Vector2(2, 3), Vector2(2, 2)), a)
		_:
			draw_circle(X, 10, Color(b, 0.3))
			draw_line(X - v * 20.0, X, Color(b, 0.5), 2.0)
			var st := PackedVector2Array()
			for i in 10:
				var r := 2.6 if i % 2 else 6.5
				var qa := i * PI / 5.0 + tm * 6.0
				st.append(X + Vector2(cos(qa), sin(qa)) * r)
			draw_colored_polygon(st, a)


# ═════════ 꾸미기: 상자 · 파편 · 구매 · 장착 · 별 뽑기 · 배틀패스 (웹 로직 그대로) ═════════
const FN := {"r": 6, "b": 5, "t": 4}
const FREF := {"ju": 15, "b": 20, "kro": 60}
const SEASON := {"id": 1, "n": "시즌 1 · 은하 원정", "d": "별의 바다를 건너는 첫 원정 · 보상: 은하 세트"}
var box_res: Array = []
var box_t0 := 0.0
var box_star := false
var box_shown := 0

func _sv_defaults() -> void:
	for k in ["own", "bown", "town", "hist"]:
		if not (SV.get(k) is Array):
			SV[k] = []
	for k in ["eq", "beq", "teq"]:
		if not SV.has(k) or SV[k] == null:
			SV[k] = ""
	if not (SV.get("frag") is Dictionary):
		SV.frag = {}
	for k in ["fbox", "sfrag", "spity", "ss", "cs"]:
		SV[k] = int(SV.get(k, 0))
	if not (SV.get("bp") is Dictionary) or int(SV.bp.get("season", 0)) != SEASON.id:
		SV.bp = {"season": SEASON.id, "xp": int(SV.get("bpxp", 0)), "prem": false, "cf": [], "cp": []}
	SV.erase("bpxp")

func bp() -> Dictionary:
	return SV.bp
func bp_lv() -> int:
	return mini(30, int(int(SV.bp.xp) / 500))
func bpr(L: int) -> Dictionary:
	var f = null
	if L % 5 == 0:
		f = {"box": 2 if L >= 20 else 1}
	elif L % 2 == 1:
		f = {"cs": 50 + L * 5}
	var p = null
	if L == 10:
		p = {"skin": "b12"}
	elif L == 20:
		p = {"skin": "tk11"}
	elif L == 30:
		p = {"skin": "k11"}
	elif L % 3 == 0:
		p = {"frag": 3 if L >= 18 else 2}
	elif L % 2 == 0:
		p = {"box": 2 if L >= 16 else 1}
	else:
		p = {"cs": 150 + L * 10}
	return {"f": f, "p": p}

func cat_of(id: String) -> String:
	if id.begins_with("k") or id.begins_with("j") or (id.begins_with("m") and not id.begins_with("mb")):
		return "s"
	if id.begins_with("b") or id.begins_with("mb"):
		return "b"
	return "t"
func arr_of(cat: String) -> Array:
	return SV.own if cat == "s" or cat == "r" else (SV.bown if cat == "b" else SV.town)
func list_of(cat: String) -> Array:
	return SK if cat == "s" or cat == "r" else (BS if cat == "b" else TS)
func item(id: String) -> Dictionary:
	return _find_in(list_of(cat_of(id)), id)
func owns(id: String) -> bool:
	return arr_of(cat_of(id)).has(id)
func equipped(id: String) -> bool:
	var c := cat_of(id)
	return SV[{"s": "eq", "b": "beq", "t": "teq"}[c]] == id
func equip(id: String) -> void:
	var c := cat_of(id) if id != "" else ""
	SV[{"s": "eq", "b": "beq", "t": "teq"}[c]] = id
func unequip(c: String) -> void:
	SV[{"s": "eq", "b": "beq", "t": "teq"}[c]] = ""

func rt_txt(r: Dictionary) -> String:
	if r.has("cs"):
		return "청석 " + str(r.cs)
	if r.has("box"):
		return "소로 상자 ×" + str(r.box)
	if r.has("frag"):
		return "크로 파편 ×" + str(r.frag)
	return item(r.skin).get("n", "")

func bp_give(r: Dictionary) -> String:
	if r.has("cs"):
		SV.cs += int(r.cs)
		return "청석 +" + str(r.cs)
	if r.has("box"):
		SV.fbox += int(r.box)
		return "소로 상자 +" + str(r.box)
	if r.has("frag"):
		var Cn: Array = []
		for q in SK:
			if q.g == "kro" and not q.has("ex") and not SV.own.has(q.id):
				Cn.append(["r", q])
		for q in TS:
			if q.g == "kro" and not q.has("ex") and not SV.town.has(q.id):
				Cn.append(["t", q])
		if Cn.is_empty():
			SV.cs += int(r.frag) * 60
			return "청석 +" + str(int(r.frag) * 60)
		var pick: Array = Cn[rng.randi() % Cn.size()]
		var R := apply_drop({"cat": pick[0], "g": "kro", "it": pick[1], "amt": int(r.frag)})
		return pick[1].n + " 파편 ×" + str(r.frag) + (" (완성!)" if R.res == "done" else "")
	var a := arr_of(cat_of(r.skin))
	if not a.has(r.skin):
		a.append(r.skin)
	return item(r.skin).n + " 획득!"

func bp_claim(tp: String, L: int):
	var P := bp()
	var arr: Array = P.cf if tp == "f" else P.cp
	var r = bpr(L)[tp]
	if r == null or arr.has(L) or bp_lv() < L or (tp == "p" and not P.prem):
		return null
	arr.append(L)
	return bp_give(r)

func roll_drop() -> Dictionary:
	var r := rng.randf()
	var cat := ""
	var g := ""
	var L: Array = []
	if r < 0.4:
		cat = "r"
		g = "ju" if rng.randf() < 0.82 else "kro"
		L = SK.filter(func(q): return q.g == g and not q.has("ex"))
	elif r < 0.65:
		cat = "b"
		g = "b"
		L = BS.filter(func(q): return not q.has("ex"))
	else:
		cat = "t"
		g = "ju" if rng.randf() < 0.82 else "kro"
		L = TS.filter(func(q): return q.g == g and not q.has("ex"))
	var it: Dictionary = L[rng.randi() % L.size()]
	var q := rng.randf()
	return {"cat": cat, "g": g, "it": it, "amt": 1 if q < 0.65 else (2 if q < 0.9 else 3)}

func apply_drop(D: Dictionary) -> Dictionary:
	var arr := arr_of(D.cat)
	var need: int = FN[D.cat]
	var rate: int = FREF[D.g]
	var o := D.duplicate()
	if arr.has(D.it.id):
		o.res = "dup"
		o.v = int(D.amt) * rate
		SV.cs += o.v
		return o
	var c: int = int(SV.frag.get(D.it.id, 0)) + int(D.amt)
	if c >= need:
		arr.append(D.it.id)
		SV.frag.erase(D.it.id)
		o.res = "done"
		o.v = (c - need) * rate
		SV.cs += o.v
		return o
	SV.frag[D.it.id] = c
	o.res = "prog"
	o.c = c
	o.need = need
	return o

func set_parts(S: Dictionary) -> Array:
	return [item(S.r), item(S.b), item(S.t)]

func jackpot() -> Dictionary:
	var L: Array = SETS.filter(func(S): return item(S.r).g == "kro")
	var S: Dictionary = L[rng.randi() % L.size()]
	var had := 0
	for id in [S.r, S.b, S.t]:
		var a := arr_of(cat_of(id))
		if a.has(id):
			had += 1
		else:
			a.append(id)
		SV.frag.erase(id)
	var v := 3000 if had == 3 else 0
	SV.cs += v
	return {"cat": "set", "g": "kro", "it": {"n": S.n, "id": S.r}, "amt": 0, "res": "jack", "v": v}

func open_box(n: int, free: bool) -> void:
	if n <= 0:
		return
	if free:
		if SV.fbox < n:
			return
		SV.fbox -= n
	else:
		var cost := 600 * n
		if SV.cs < cost:
			lmsg = "청석이 부족해요 (" + str(cost) + " 필요)"
			sfx("err")
			return
		SV.cs -= cost
	var R: Array = []
	for i in n:
		R.append(jackpot() if rng.randf() < 1e-4 else apply_drop(roll_drop()))
	_hist("box", R)
	sv_save()
	box_res = R
	box_star = false
	box_t0 = t_real
	box_shown = 0
	sfx("box")

func star_all() -> Array:
	var o: Array = []
	for q in SK:
		if q.g == "star":
			o.append(q)
	for q in BS:
		if q.get("g", "") == "star":
			o.append(q)
	for q in TS:
		if q.g == "star":
			o.append(q)
	return o

func star_pull(n: int) -> void:
	var cost := 15 * n
	if SV.ss < cost:
		lmsg = "별석이 부족해요 (" + str(cost) + " 필요)"
		sfx("err")
		return
	SV.ss -= cost
	var R: Array = []
	for i in n:
		SV.spity += 1
		if rng.randf() < 1e-5 or SV.spity >= 500:
			SV.spity = 0
			var L: Array = star_all().filter(func(q): return not owns(q.id))
			if not L.is_empty():
				var it: Dictionary = L[rng.randi() % L.size()]
				arr_of(cat_of(it.id)).append(it.id)
				R.append({"res": "star", "it": it, "cat": cat_of(it.id)})
			else:
				SV.sfrag += 30
				R.append({"res": "starx"})
		else:
			var q := rng.randf()
			var a := 1 if q < 0.54 else (2 if q < 0.86 else (3 if q < 0.97 else 4))
			SV.sfrag += a
			R.append({"res": "sf", "a": a})
	_hist("star", R)
	sv_save()
	box_res = R
	box_star = true
	box_t0 = t_real
	box_shown = 0
	sfx("sbox")

func _hist(k: String, R: Array) -> void:
	var now := int(Time.get_unix_time_from_system())
	for i in range(R.size() - 1, -1, -1):
		var q: Dictionary = R[i]
		var x := ""
		if k == "box":
			if q.res == "jack":
				x = q.it.n + " (크로 세트 통째로)"
			else:
				x = q.it.n + " 파편 ×" + str(q.amt) + (" → 완성" if q.res == "done" else (" → 보유 중, 청석 +" + str(q.v) if q.res == "dup" else " (" + str(q.get("c", 0)) + "/" + str(q.get("need", 0)) + ")"))
		else:
			x = ("★ 걸작 완품 · " + q.it.n) if q.res == "star" else ("★ 걸작 완품 (모두 보유) → 별 파편 +30" if q.res == "starx" else "★ 별 파편 ×" + str(q.a))
		SV.hist.push_front({"t": now, "k": k, "x": x})
	if SV.hist.size() > 500:
		SV.hist.resize(500)

func box_step() -> float:
	return minf(0.12, 5.0 / maxf(1.0, box_res.size()))

func box_busy() -> bool:
	return not box_res.is_empty() and t_real - box_t0 < 1.45 + box_res.size() * box_step()

func _box_tick() -> void:
	if box_res.is_empty():
		return
	var n := int((t_real - box_t0 - 1.0) / box_step()) + 1
	n = clampi(n, 0, box_res.size())
	while box_shown < n:
		var q: Dictionary = box_res[box_shown]
		var k := ""
		if box_star:
			k = "sjack" if (q.res == "star" or q.res == "starx") else ("srare" if int(q.get("a", 0)) >= 3 else "sreveal")
		else:
			k = "jack" if q.res == "jack" else ("rare" if (q.res == "done" or q.g == "kro") else "reveal")
		sfx(k)
		box_shown += 1

func buy_skin(id: String) -> void:
	var it := item(id)
	var c := cat_of(id)
	if not owns(id):
		var pr: int = int(it.get("p", 0)) if int(it.get("p", 0)) > 0 else (500 if c == "b" else 300)
		if it.get("g", "") == "star" or it.has("ex"):
			return
		if SV.cs < pr:
			lmsg = "청석이 부족해요 (" + str(pr) + " 필요)"
			sfx("err")
			return
		SV.cs -= pr
		arr_of(c).append(id)
		SV.frag.erase(id)
		lmsg = it.n + " 스킨을 샀어요!"
		sfx("up")
	equip(id)
	sv_save()

func set_miss(S: Dictionary) -> int:
	var P := set_parts(S)
	var m := 0
	if not owns(P[0].id):
		m += int(P[0].get("p", 300)) if int(P[0].get("p", 0)) > 0 else 300
	if not owns(P[1].id):
		m += 500
	if not owns(P[2].id):
		m += int(P[2].get("p", 300)) if int(P[2].get("p", 0)) > 0 else 300
	return m

func buy_set(i: int) -> void:
	var S: Dictionary = SETS[i]
	var cost := roundi(set_miss(S) * 0.85)
	if cost > 0:
		if SV.cs < cost:
			lmsg = "청석이 부족해요 (" + str(cost) + " 필요)"
			sfx("err")
			return
		SV.cs -= cost
		for id in [S.r, S.b, S.t]:
			if not owns(id):
				arr_of(cat_of(id)).append(id)
				SV.frag.erase(id)
		lmsg = S.n + "를 샀어요!"
		sfx("up")
	SV.eq = S.r
	SV.beq = S.b
	SV.teq = S.t
	sv_save()


# ═════════ 꾸미기 화면: 상점 · 창고 · 배틀패스 · 상자 열기 ═════════
var shop_tab2 := "box"
var stF := {"own": "all", "cat": "all", "gr": "all"}
var lob_draw: Array = []
var lob_max := 0.0
var pass_scroll := 0.0
var lob_drag = null

func _wide_rect() -> Rect2:
	var u := ui_size()
	var W := minf(1180.0, u.x - 24.0)
	return Rect2((u.x - W) / 2.0, 180.0, W, u.y - 192.0)

func _content_rect() -> Rect2:
	var pr := _wide_rect()
	return Rect2(pr.position.x + 14.0, pr.position.y + (100.0 if lsec == "shop" else 54.0), pr.size.x - 28.0, pr.size.y - (160.0 if lsec == "shop" else 114.0))

# ── 미리보기 (140×84 기준 좌표) ──
func _pv_xf(r: Rect2) -> Transform2D:
	return inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(0.0, Vector2(r.size.x / 140.0, r.size.x / 140.0), 0.0, r.position)

func _pv_set(M: Transform2D, local: Transform2D = Transform2D.IDENTITY) -> void:
	draw_set_transform_matrix(M * local)

func _pv_tiles(tn: Array, nx: int, ny: int, cw: float, ch: float) -> void:
	for j in ny:
		for i in nx:
			draw_rect(Rect2(i * cw, j * ch, cw, ch), C(tn[(i * 3 + j * 5) % 4]))

func _pv_bot(M: Transform2D, k: String, p: Vector2, sc: float, s: Dictionary, tm: float) -> void:
	_pv_set(M, Transform2D(0.0, Vector2(sc, sc), 0.0, p))
	var col: Color = UT[k].col
	var acc: Color = UT[k].acc
	var pat := ""
	if not s.is_empty():
		col = C(s.c)
		acc = C(s.a)
		pat = s.pt
	art_bot_s(self, k, col, acc, tm, pat)

func _pv_do(M: Transform2D, s: Dictionary, tm: float, d: Vector2, o: Vector2) -> void:
	_pv_set(M)
	var hy := sin(tm * 5.0) * 2.0
	var dc := C(s.c) if not s.is_empty() else Color("#f2d14e")
	var da := C(s.a) if not s.is_empty() else Color.WHITE
	var oc := C(s.c) if not s.is_empty() else Color("#d9a441")
	var oa := C(s.a) if not s.is_empty() else Color("#ffd27a")
	if not s.is_empty() and s.g == "kro":
		draw_circle(d + Vector2(0, hy), 11, Color(da, 0.3))
	draw_rect(Rect2(d.x - 7, d.y - 3 + hy, 14, 7), K)
	draw_rect(Rect2(d.x - 6, d.y - 2 + hy, 12, 5), dc)
	draw_rect(Rect2(d.x - 12, d.y - 5 + hy, 5, 2), Color("#9aa6b2"))
	draw_rect(Rect2(d.x + 7, d.y - 5 + hy, 5, 2), Color("#9aa6b2"))
	draw_rect(Rect2(d.x - 1, d.y - 1 + hy, 2, 2), da)
	for i in 8:
		var a := i * TAU / 8.0
		draw_arc(o, 12, a, a + 0.25, 4, Color(oa, 0.75), 1.0)
	draw_rect(Rect2(o.x - 5, o.y - 6, 10, 12), K)
	draw_rect(Rect2(o.x - 4, o.y - 5, 8, 10), oc)
	draw_rect(Rect2(o.x - 2, o.y - 8, 4, 3), Color("#2a1a08"))
	draw_rect(Rect2(o.x - 3, o.y - 2, 2, 4), oa)

func _pv_base(M: Transform2D, b: Dictionary, p: Vector2, sc: float, tm: float) -> void:
	var xf := M * Transform2D(0.0, Vector2(sc, sc), 0.0, p)
	draw_set_transform_matrix(xf)
	art_base(self, Vector2.ZERO, tm, xf, b)

func _pv_theme(M: Transform2D, k: Dictionary, tm: float) -> void:
	_pv_set(M)
	var tn: Array = k.tn if not k.is_empty() else ["#4a4234", "#4e4537", "#463f32", "#524939"]
	var ob: Array = k.ob if not k.is_empty() else ["#3a2a46", "#6b4a86", "#8f66ab"]
	var en: Array = k.en if not k.is_empty() else ["#c24b68", "#c98a46"]
	_pv_tiles(tn, 7, 4, 20, 21)
	draw_colored_polygon(ell(Vector2(44, 58), 26, 8), Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(20, 56), Vector2(26, 32), Vector2(62, 32), Vector2(68, 56)]), C(ob[0]))
	draw_rect(Rect2(33, 20, 22, 28), C(ob[1]))
	draw_rect(Rect2(33, 20, 22, 4), C(ob[2]))
	draw_circle(Vector2(44, 34), 5, Color("#ff6a55") if int(tm * 3.0) % 2 else Color("#a8352a"))
	for q in [[100, 32, 0], [118, 58, 1]]:
		draw_circle(Vector2(q[0], q[1]), 8, Color("#1c0e14"))
		draw_circle(Vector2(q[0], q[1]), 6.5, C(en[q[2]]))
		draw_rect(Rect2(q[0] - 6, q[1] - 1.5, 4, 3), Color("#ffd0a8"))
	var mn = TMN.get(k.get("id", ""), null) if not k.is_empty() else null
	_pv_set(M, Transform2D(0.0, Vector2(0.6, 0.6), 0.0, Vector2(78, 62)))
	mdeco(Vector2.ZERO, mn, tm, false)
	var M0 := C(mn[0]) if mn != null else Color("#2fa88f")
	var M1 := C(mn[1]) if mn != null else Color("#8ff3dd")
	for c in [[-10.0, 6.0, 0.7], [10.0, 5.0, 0.6], [0.0, 0.0, 1.0]]:
		var h: float = 22.0 * c[2]
		var w: float = 9.0 * c[2]
		var px: float = c[0]
		var py: float = c[1]
		draw_colored_polygon(PackedVector2Array([Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py + h * 0.35), Vector2(px - w, py)]), M0)
		draw_colored_polygon(PackedVector2Array([Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py)]), M1)
	mdeco(Vector2.ZERO, mn, tm, true)
	_pv_set(M)
	if not k.is_empty() and (k.g == "kro" or k.g == "star"):
		amb(k, tm, Vector2.ZERO, 140, 84, 0, 0, 0.8)
		var q := fmod(tm * 0.9, 1.0)
		draw_pr(Vector2(90 - q * 40, 32), Vector2(-1, 0), k, Color.WHITE, false, false, tm)

func draw_preview(r: Rect2, kind: String, id, tm: float) -> void:
	var M := _pv_xf(r)
	_pv_set(M)
	match kind:
		"s":
			var s: Dictionary = item(id) if str(id) != "" else {}
			draw_rect(Rect2(0, 0, 140, 84), Color("#2b2620"))
			draw_rect(Rect2(0, 60, 140, 24), Color(0, 0, 0, 0.18))
			for q in [["c", 20], ["h", 46], ["r", 72]]:
				_pv_bot(M, q[0], Vector2(q[1], 44), 1.4, s, tm)
			_pv_do(M, s, tm, Vector2(122, 16), Vector2(12, 70))
			_pv_set(M)
			var k := fmod(tm * 0.9, 1.0)
			if not s.is_empty() and (s.g == "kro" or s.g == "star"):
				draw_pr(Vector2(94 + k * 40, 44), Vector2(1, 0), s, Color.WHITE, false, true, tm)
			else:
				draw_pr(Vector2(94 + k * 40, 44), Vector2(1, 0), {}, Color("#7ff0ff"), false, true, tm)
		"b":
			draw_rect(Rect2(0, 0, 140, 84), Color("#2b2620"))
			_pv_base(M, item(id) if str(id) != "" else {}, Vector2(70, 44), 0.62, tm)
		"t":
			_pv_theme(M, item(id) if str(id) != "" else {}, tm)
		"set", "mset":
			var S: Dictionary = (SETS if kind == "set" else MSET)[int(id)]
			var P := set_parts(S)
			_pv_tiles(P[2].tn, 7, 4, 20, 21)
			_pv_base(M, P[1], Vector2(36, 46), 0.42, tm)
			for q in [["c", 84, 54], ["r", 106, 38], ["h", 126, 56]]:
				_pv_bot(M, q[0], Vector2(q[1], q[2]), 1.1, P[0], tm)
			_pv_do(M, P[0], tm, Vector2(122, 14), Vector2(68, 72))
			_pv_set(M)
			if P[2].has("amb"):
				amb(P[2], tm, Vector2.ZERO, 140, 84, 0, 0, 0.8)
		"box":
			draw_rect(Rect2(0, 0, 140, 84), Color("#1a1420"))
			var gold: bool = str(id) == "gold"
			draw_rect(Rect2(46, 30, 48, 36), Color("#8a5a20") if gold else Color("#5a3a7a"))
			draw_rect(Rect2(42, 22, 56, 12), Color("#c9a23a") if gold else Color("#8a5ab0"))
			draw_rect(Rect2(66, 22, 8, 44), Color("#ffd76a"))
			draw_circle(Vector2(70, 40), 18 + 3 * sin(tm * 3), Color(1, 0.85, 0.4, 0.15))
		"star":
			draw_rect(Rect2(0, 0, 140, 84), Color("#120e24"))
			var st := PackedVector2Array()
			for i in 10:
				var rr := 9.0 if i % 2 else 24.0
				var a := i * PI / 5.0 - PI / 2.0 + sin(tm) * 0.1
				st.append(Vector2(70, 42) + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(st, Color("#ffd76a"))
	_ui_reset()

# ── 줄 단위 배치 ──
func _rows_shop() -> Array:
	var R: Array = []
	match shop_tab2:
		"star":
			R.append({"h": "★ 걸작 · 로봇 · 기지 · 테마가 완전히 새 모습으로 바뀌는 최상위 등급 · 오직 별 뽑기로만 얻어요"})
			R.append({"p": "별석 " + str(SV.ss) + " · ★ 별 파편 " + str(SV.sfrag) + " / 30 · 천장 " + str(SV.spity) + " / 500  —  500번째 뽑기는 걸작 완품 확정 · 별 파편 30개로 원하는 걸작 제작"})
			R.append({"btns": [["별 뽑기 1회 · 별석 15", {"a": "spull", "n": 1}, SV.ss >= 15], ["별 뽑기 10회 · 별석 150", {"a": "spull", "n": 10}, SV.ss >= 150], ["별석 1개 교환 · 청석 300", {"a": "sx", "n": 1}, SV.cs >= 300], ["별석 10개 교환 · 청석 3,000", {"a": "sx", "n": 10}, SV.cs >= 3000]]})
			var cards: Array = []
			for it in star_all():
				var c := cat_of(it.id)
				var o := owns(it.id)
				var e := equipped(it.id)
				cards.append({"pv": [c, it.id], "tag": "★ 걸작 · " + {"s": "로봇", "b": "기지", "t": "테마"}[c], "n": it.n, "d": it.d, "star": true,
					"btns": [[("장착 중" if e else "장착") if o else "★ 별 파편 30개로 제작", {"a": "eq", "id": it.id} if o else {"a": "craft", "id": it.id}, (not e) if o else SV.sfrag >= 30]]})
			R.append({"cards": cards})
			R.append({"h": "★ 걸작 세트"})
			cards = []
			for i in MSET.size():
				var S: Dictionary = MSET[i]
				var n := [S.r, S.b, S.t].filter(func(id): return owns(id)).size()
				var e: bool = SV.eq == S.r and SV.beq == S.b and SV.teq == S.t
				cards.append({"pv": ["mset", i], "tag": "★ 세트", "n": S.n, "d": "보유 " + str(n) + " / 3", "star": true,
					"btns": [["세트 장착 중" if e else ("세트 장착" if n == 3 else "3종을 모두 모으면 장착"), {"a": "mset", "i": i}, n == 3 and not e]]})
			R.append({"cards": cards})
		"box":
			R.append({"h": "소로 상자 · 스킨 파편 (로봇 6개 · 기지 5개 · 테마 4개 모으면 완성)"})
			R.append({"p": "상자 1개에서 스킨 1종의 파편이 1~3개 나와요 (1개 65% · 2개 25% · 3개 10%) · 로봇 40% · 기지 25% · 테마 35% · 주 등급 82% · 크로 등급 18% · 이미 가진 스킨의 파편은 청석으로 돌려받아요 · 0.01% 확률로 크로 세트가 통째로!"})
			var b: Array = []
			if SV.fbox > 0:
				b.append(["무료 상자 열기 · 보유 " + str(SV.fbox) + "개", {"a": "fbox"}, true])
			b.append(["1개 열기 · 청석 600", {"a": "box", "n": 1}, SV.cs >= 600])
			b.append(["5개 열기 · 청석 3,000", {"a": "box", "n": 5}, SV.cs >= 3000])
			b.append(["10개 열기 · 청석 6,000", {"a": "box", "n": 10}, SV.cs >= 6000])
			var na := mini(100, int(SV.cs / 600))
			if na > 10:
				b.append(["모두 열기 · " + str(na) + "개", {"a": "box", "n": na}, true])
			R.append({"btns": b})
			R.append({"h": "최근 뽑기 기록"})
			var H: Array = SV.hist.slice(0, 12)
			for h in H:
				R.append({"p": ("소로 상자 · " if h.k == "box" else "별 뽑기 · ") + h.x})
			if H.is_empty():
				R.append({"p": "아직 뽑기 기록이 없어요"})
		"set":
			R.append({"h": "로봇 + 기지 + 테마 · 없는 것만 15% 할인"})
			var cards: Array = []
			for i in SETS.size():
				var S: Dictionary = SETS[i]
				var P := set_parts(S)
				var miss := set_miss(S)
				var cost := roundi(miss * 0.85)
				var e: bool = SV.eq == S.r and SV.beq == S.b and SV.teq == S.t
				cards.append({"pv": ["set", i], "tag": "세트", "n": S.n, "d": P[0].n + " · " + P[1].n + " · " + P[2].n, "kro": true,
					"btns": [["장착 중" if e else ("청석 " + str(cost) if miss > 0 else "세트 장착"), {"a": "set", "i": i}, not e]]})
			R.append({"cards": cards})
		"r", "b", "t":
			var c: String = shop_tab2
			var cat := "s" if c == "r" else c
			var hdr: String = {"r": "주 등급 · 외형 변경 · 청석 300  /  크로 등급 · 외형 + 투사체 + 타격 효과", "b": "기지 모습 + 패배 시 폭발 연출 · 청석 500", "t": "필드 배경 · 상대 기지 · 상대 로봇 · 광산"}[c]
			R.append({"h": hdr})
			var cards: Array = [{"pv": [cat, ""], "tag": "기본", "n": {"r": "기본 도색", "b": "기본 기지", "t": "기본 테마"}[c], "d": "처음 모습",
				"btns": [["장착 중" if SV[{"s": "eq", "b": "beq", "t": "teq"}[cat]] == "" else "장착", {"a": "uneq", "c": cat}, SV[{"s": "eq", "b": "beq", "t": "teq"}[cat]] != ""]]}]
			for it in list_of(cat):
				if it.get("g", "") == "star" or (it.has("ex") and not owns(it.id)):
					continue
				var o := owns(it.id)
				var e := equipped(it.id)
				var pr: int = int(it.get("p", 0)) if int(it.get("p", 0)) > 0 else (500 if cat == "b" else 300)
				var fr: int = int(SV.frag.get(it.id, 0))
				var g: String = it.get("g", "b")
				cards.append({"pv": [cat, it.id], "tag": {"ju": "주", "kro": "크로", "b": "기지"}.get(g, ""), "n": it.n, "d": it.d, "kro": g == "kro",
					"st": ("파편 " + str(fr) + " / " + str(FN[cat if cat != "s" else "r"])) if (fr > 0 and not o) else "",
					"btns": [["장착 중" if e else ("장착" if o else "청석 " + str(pr)), {"a": "buy", "id": it.id}, not e]]})
			R.append({"cards": cards})
	return R

func _store_gr(it: Dictionary) -> String:
	if it.get("g", "") == "star":
		return "star"
	if it.has("ex"):
		return "pass"
	if cat_of(it.id) == "b":
		return "base"
	return it.g

func _rows_store() -> Array:
	var R: Array = []
	var all: Array = []
	for c in ["s", "b", "t"]:
		for it in list_of(c):
			all.append(it)
	var cnt := func(c: String) -> String:
		var L: Array = list_of(c)
		return str(L.filter(func(q): return owns(q.id)).size()) + " / " + str(L.size())
	var fsum := 0
	for v in SV.frag.values():
		fsum += int(v)
	R.append({"p": "로봇 " + cnt.call("s") + " · 기지 " + cnt.call("b") + " · 테마 " + cnt.call("t") + " · 스킨 파편 " + str(fsum) + " · ★ 별 파편 " + str(SV.sfrag) + " · 무료 상자 " + str(SV.fbox)})
	var nm := func(c: String) -> String:
		var id: String = SV[{"s": "eq", "b": "beq", "t": "teq"}[c]]
		return item(id).get("n", "기본") if id != "" else "기본"
	R.append({"btns": [["로봇: " + nm.call("s") + (" · 기본으로" if SV.eq != "" else ""), {"a": "uneq", "c": "s"}, SV.eq != ""], ["기지: " + nm.call("b") + (" · 기본으로" if SV.beq != "" else ""), {"a": "uneq", "c": "b"}, SV.beq != ""], ["테마: " + nm.call("t") + (" · 기본으로" if SV.teq != "" else ""), {"a": "uneq", "c": "t"}, SV.teq != ""]]})
	var chips := func(k: String, opts: Array) -> Array:
		var o: Array = []
		for q in opts:
			o.append([q[1], {"a": "sf", "k": k, "v": q[0]}, true, stF[k] == q[0]])
		return o
	R.append({"chips": chips.call("own", [["all", "전체"], ["yes", "보유"], ["no", "미보유"]]) + chips.call("cat", [["all", "모든 종류"], ["s", "로봇"], ["b", "기지"], ["t", "테마"]])})
	R.append({"chips": chips.call("gr", [["all", "모든 등급"], ["ju", "주"], ["kro", "크로"], ["star", "★ 걸작"], ["pass", "패스 전용"], ["base", "일반 기지"]])})
	var cards: Array = []
	for it in all:
		var c := cat_of(it.id)
		var o := owns(it.id)
		var g := _store_gr(it)
		if stF.own != "all" and (stF.own == "yes") != o:
			continue
		if stF.cat != "all" and stF.cat != c:
			continue
		if stF.gr != "all" and stF.gr != g:
			continue
		var e := equipped(it.id)
		var st := ""
		var bar := -1.0
		if not o:
			if g == "star":
				st = "★ 별 파편 " + str(SV.sfrag) + " / 30"
				bar = minf(1.0, SV.sfrag / 30.0)
			elif g == "pass":
				st = "배틀패스 보상"
			else:
				var n: int = int(SV.frag.get(it.id, 0))
				var need: int = FN[c if c != "s" else "r"]
				st = "파편 " + str(n) + " / " + str(need)
				bar = float(n) / need
		cards.append({"pv": [c, it.id], "tag": {"s": "로봇", "b": "기지", "t": "테마"}[c] + " · " + {"ju": "주", "kro": "크로", "star": "★ 걸작", "pass": "패스 전용", "base": "일반"}[g], "n": it.n, "d": "", "st": st, "bar": bar,
			"star": g == "star", "kro": g == "kro", "dim": not o, "btns": [[("장착 중" if e else "장착"), {"a": "eq", "id": it.id}, not e]] if o else []})
	R.append({"p": str(cards.size()) + "개"})
	R.append({"cards": cards})
	return R

func _rows_pass() -> Array:
	var P := bp()
	var lv := bp_lv()
	var cur := int(P.xp) - lv * 500
	var R: Array = []
	R.append({"h": SEASON.n + "  ·  " + str(lv) + " / 30단계" + ("  ·  프리미엄" if P.prem else "")})
	R.append({"bar": 1.0 if lv >= 30 else cur / 500.0, "bt": "MAX" if lv >= 30 else str(cur) + " / 500 XP"})
	R.append({"p": "플레이 1분 +10 · 적 처치 +2 · 기지 정복 +30 · 레이드 방어 +50 · 게임을 끝내면 들어와요"})
	R.append({"btns": [["프리미엄 해금 · 청석 2,000" if not P.prem else "프리미엄 해금됨", {"a": "bpbuy"}, not P.prem], ["1단계 구매 · 청석 100", {"a": "bpskip", "n": 1}, lv < 30], ["5단계 구매 · 청석 500", {"a": "bpskip", "n": 5}, lv < 30], ["받을 보상 모두 받기", {"a": "bpall"}, true]]})
	R.append({"pass": true})
	return R

func _layout_rows(R: Array, cr: Rect2, f: Font) -> void:
	lob_draw.clear()
	var y := cr.position.y - lob_scroll
	var x0 := cr.position.x
	var W := cr.size.x
	for row in R:
		if row.has("h"):
			lob_draw.append({"k": "h", "p": Vector2(x0, y + 22.0), "s": row.h})
			y += 34.0
		elif row.has("p"):
			var L := _wrap(f, row.p, 13, W)
			for l in L:
				lob_draw.append({"k": "p", "p": Vector2(x0, y + 16.0), "s": l})
				y += 20.0
			y += 6.0
		elif row.has("bar"):
			lob_draw.append({"k": "bar", "r": Rect2(x0, y, W, 22.0), "v": row.bar, "s": row.bt})
			y += 32.0
		elif row.has("btns") or row.has("chips"):
			var B: Array = row.btns if row.has("btns") else row.chips
			var bx := x0
			var bh := 38.0 if row.has("btns") else 30.0
			for b in B:
				var bw: float = f.get_string_size(b[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 30.0
				if bx + bw > x0 + W:
					bx = x0
					y += bh + 8.0
				var r := Rect2(bx, y, bw, bh)
				var on: bool = b[3] if b.size() > 3 else false
				lob_draw.append({"k": "btn", "r": r, "s": b[0], "en": b[2], "on": on, "chip": row.has("chips")})
				if r.end.y > cr.position.y and r.position.y < cr.end.y:
					_add("cb", r, b[2], "", b[1])
				bx += bw + 8.0
			y += bh + 12.0
		elif row.has("cards"):
			var cw := 172.0
			var ch := 262.0
			var cols := maxi(1, int((W + 12.0) / (cw + 12.0)))
			cw = (W - 12.0 * (cols - 1)) / cols
			var n: int = row.cards.size()
			for i in n:
				var c: Dictionary = row.cards[i]
				var r := Rect2(x0 + (i % cols) * (cw + 12.0), y + int(i / cols) * (ch + 12.0), cw, ch)
				if r.end.y < cr.position.y - 10.0 or r.position.y > cr.end.y + 10.0:
					continue
				lob_draw.append({"k": "card", "r": r, "c": c})
				var bts: Array = c.get("btns", [])
				for j in bts.size():
					var b: Array = bts[j]
					var br := Rect2(r.position.x + 8.0, r.end.y - 38.0 - j * 34.0, r.size.x - 16.0, 30.0)
					lob_draw.append({"k": "btn", "r": br, "s": b[0], "en": b[2], "on": false, "chip": false})
					if br.end.y > cr.position.y and br.position.y < cr.end.y:
						_add("cb", br, b[2], "", b[1])
			y += ceili(n / float(cols)) * (ch + 12.0) + 6.0
		elif row.has("pass"):
			var cw := 120.0
			var th := 290.0
			var tr := Rect2(x0, y, W, th)
			lob_draw.append({"k": "track", "r": tr})
			var P := bp()
			var lv := bp_lv()
			for L in range(1, 31):
				var cx := x0 + 96.0 + (L - 1) * (cw + 8.0) - pass_scroll
				if cx < x0 + 90.0 or cx + cw > x0 + W:
					continue
				for ti in 2:
					var tp := "f" if ti == 0 else "p"
					var r = bpr(L)[tp]
					var cr2 := Rect2(cx, y + 34.0 + ti * 128.0, cw, 120.0)
					var got: bool = (P.cf if tp == "f" else P.cp).has(L)
					var lk: bool = lv < L or (tp == "p" and not P.prem)
					lob_draw.append({"k": "bpr", "r": cr2, "rw": r, "got": got, "lk": lk, "L": L, "tp": tp})
					if r != null and not got and not lk:
						var br := Rect2(cr2.position.x + 8.0, cr2.end.y - 32.0, cw - 16.0, 26.0)
						lob_draw.append({"k": "btn", "r": br, "s": "받기", "en": true, "on": true, "chip": false})
						_add("cb", br, true, "", {"a": "bpc", "t": tp, "L": L})
				lob_draw.append({"k": "lvn", "p": Vector2(cx, y + 24.0), "w": cw, "L": L, "on": lv >= L})
			y += th + 10.0
	lob_max = maxf(0.0, y + lob_scroll - cr.end.y + 20.0)

func _draw_rows(f: Font, hov) -> void:
	var cr := _content_rect()
	for e in lob_draw:
		match e.k:
			"h":
				if e.p.y > cr.position.y and e.p.y < cr.end.y + 10.0:
					draw_string(f, e.p, e.s, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x, 15, Color("#ffe6a6"))
			"p":
				if e.p.y > cr.position.y and e.p.y < cr.end.y + 10.0:
					draw_string(f, e.p, e.s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9fb3c2"))
			"bar":
				var r: Rect2 = e.r
				draw_rect(r, Color(1, 1, 1, 0.08))
				draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(e.v, 0, 1), r.size.y)), Color("#c79bff"))
				draw_string(f, r.position + Vector2(0, 16), e.s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color.WHITE)
			"btn":
				var r: Rect2 = e.r
				if r.end.y < cr.position.y or r.position.y > cr.end.y:
					continue
				var sb := StyleBoxFlat.new()
				sb.set_corner_radius_all(6)
				sb.set_border_width_all(1)
				if e.chip:
					sb.bg_color = Color("#3a2c10") if e.on else Color("#141c24")
					sb.border_color = Color("#ffd76a") if e.on else Color(1, 1, 1, 0.15)
				elif e.en:
					sb.bg_color = Color("#d9b04e") if e.on else Color("#1c2834")
					sb.border_color = Color("#ffd76a") if e.on else Color("#c9a255")
				else:
					sb.bg_color = Color("#10151a")
					sb.border_color = Color(1, 1, 1, 0.1)
				sb.draw(get_canvas_item(), r)
				var tc := Color("#2a1a02") if (e.on and not e.chip and e.en) else (Color.WHITE if e.en else Color("#6a7682"))
				draw_string(f, Vector2(r.position.x, r.position.y + r.size.y / 2.0 + 5.0), e.s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, tc)
			"card":
				_draw_card(f, e.r, e.c)
			"track":
				draw_rect(e.r, Color(0, 0, 0, 0.25))
				draw_string(f, e.r.position + Vector2(8, 24), "단계", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9fb3c2"))
				draw_string(f, e.r.position + Vector2(8, 34 + 64), "무료", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
				draw_string(f, e.r.position + Vector2(8, 34 + 128 + 64), "프리미엄", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffd76a"))
			"lvn":
				draw_string(f, e.p, str(e.L), HORIZONTAL_ALIGNMENT_CENTER, e.w, 15, Color("#ffd76a") if e.on else Color("#6a7682"))
			"bpr":
				var r: Rect2 = e.r
				var sb := StyleBoxFlat.new()
				sb.set_corner_radius_all(8)
				sb.set_border_width_all(1)
				sb.bg_color = Color("#141c24") if not e.got else Color("#10261e")
				sb.border_color = Color("#ffd76a") if (e.tp == "p" and e.rw != null and e.rw.has("skin")) else Color(1, 1, 1, 0.12)
				sb.draw(get_canvas_item(), r)
				if e.rw == null:
					continue
				var rw: Dictionary = e.rw
				if rw.has("skin"):
					draw_preview(Rect2(r.position + Vector2(10, 8), Vector2(r.size.x - 20, (r.size.x - 20) * 0.6)), cat_of(rw.skin), rw.skin, t_real)
				else:
					var ic := Color("#7fd8ff") if rw.has("cs") else (Color("#c79bff") if rw.has("box") else Color("#ff8fb8"))
					draw_circle(r.position + Vector2(r.size.x / 2.0, 34), 16, Color(ic, 0.3))
					draw_circle(r.position + Vector2(r.size.x / 2.0, 34), 9, ic)
				draw_string(f, r.position + Vector2(4, 78), rt_txt(rw), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 8.0, 11, Color.WHITE if not e.lk else Color("#6a7682"))
				if e.got:
					draw_string(f, r.position + Vector2(0, r.size.y - 12.0), "받음", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#8be28b"))
				elif e.lk:
					draw_string(f, r.position + Vector2(0, r.size.y - 12.0), "잠김", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#6a7682"))

func _draw_card(f: Font, r: Rect2, c: Dictionary) -> void:
	var cr := _content_rect()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.bg_color = Color("#161320") if c.get("star", false) else Color("#121a22")
	sb.border_color = Color("#ffd76a") if c.get("star", false) else (Color("#b07aff") if c.get("kro", false) else Color(1, 1, 1, 0.12))
	sb.draw(get_canvas_item(), r)
	var pv := Rect2(r.position + Vector2(8, 8), Vector2(r.size.x - 16, (r.size.x - 16) * 0.6))
	if pv.position.y > cr.position.y - 20.0 and pv.end.y < cr.end.y + 40.0:
		draw_preview(pv, c.pv[0], c.pv[1], t_real)
		if c.get("dim", false):
			draw_rect(pv, Color(0, 0, 0, 0.45))
	var y := pv.end.y + 18.0
	draw_string(f, Vector2(r.position.x + 10, y), c.tag, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20.0, 11, Color("#ffd76a") if c.get("star", false) else (Color("#c79bff") if c.get("kro", false) else Color("#8a9bad")))
	draw_string(f, Vector2(r.position.x + 10, y + 20), c.n, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20.0, 15, Color.WHITE)
	var L := _wrap(f, c.get("d", ""), 11, r.size.x - 20.0)
	for i in mini(2, L.size()):
		draw_string(f, Vector2(r.position.x + 10, y + 38 + i * 15), L[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9fb3c2"))
	if c.get("st", "") != "":
		var by: float = r.end.y - 38.0 - float(c.get("btns", []).size()) * 34.0 - 4.0
		if c.get("bar", -1.0) >= 0.0:
			draw_rect(Rect2(r.position.x + 8, by - 18, r.size.x - 16, 16), Color(1, 1, 1, 0.08))
			draw_rect(Rect2(r.position.x + 8, by - 18, (r.size.x - 16) * clampf(c.bar, 0, 1), 16), Color("#5a7a9a"))
		draw_string(f, Vector2(r.position.x, by - 6), c.st, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color("#c9d4dc"))

func _box_overlay(f: Font, hov) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.75))
	var W := minf(980.0, u.x - 40.0)
	var pr := Rect2((u.x - W) / 2.0, 60.0, W, u.y - 100.0)
	sb_panel.draw(get_canvas_item(), pr)
	var et := t_real - box_t0
	# 상자 흔들림 → 열림
	var bc := Vector2(u.x / 2.0, pr.position.y + 70.0)
	var gold := box_res.any(func(q): return q.get("g", "") == "kro" or q.res in ["jack", "star", "starx"] or int(q.get("a", 0)) >= 3)
	var sh := sin(et * 40.0) * 4.0 * clampf(1.0 - et, 0.0, 1.0)
	draw_preview(Rect2(bc + Vector2(sh - 63.0, -38.0), Vector2(126, 76)), "star" if box_star else "box", "gold" if gold else "", t_real)
	if et > 0.9 and et < 1.3:
		draw_circle(bc, 60 + (et - 0.9) * 400, Color(1, 0.95, 0.8, 0.5 * (1.3 - et) / 0.4))
	var tot := 0
	for q in box_res:
		tot += int(q.get("amt", q.get("a", 0)))
	var sm := ("별 뽑기 " + str(box_res.size()) + "회 · 별 파편 +" + str(tot) + " (보유 " + str(SV.sfrag) + "/30) · 천장 " + str(SV.spity) + "/500") if box_star else ("상자 " + str(box_res.size()) + "개 · 파편 " + str(tot) + "개")
	draw_string(f, Vector2(pr.position.x, pr.position.y + 136.0), sm, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 14, Color("#ffe6a6"))
	var cw := 150.0
	var ch := 160.0
	var cols := maxi(1, int((pr.size.x - 20.0) / (cw + 8.0)))
	var x0 := pr.position.x + (pr.size.x - cols * (cw + 8.0) + 8.0) / 2.0
	var show := mini(box_res.size(), box_shown)
	var rows_fit := maxi(1, int((pr.size.y - 230.0) / (ch + 8.0)))
	var first := maxi(0, (int((show - 1) / cols) - rows_fit + 1) * cols)
	for i in range(first, show):
		var q: Dictionary = box_res[i]
		var k := i - first
		var r := Rect2(x0 + (k % cols) * (cw + 8.0), pr.position.y + 152.0 + int(k / cols) * (ch + 8.0), cw, ch)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(8)
		sb.set_border_width_all(2)
		var big: bool = q.res in ["jack", "star", "starx", "done"]
		sb.bg_color = Color("#161320")
		sb.border_color = Color("#ffd76a") if big else (Color("#b07aff") if q.get("g", "") == "kro" else Color(1, 1, 1, 0.15))
		sb.draw(get_canvas_item(), r)
		var pv := Rect2(r.position + Vector2(8, 8), Vector2(cw - 16, (cw - 16) * 0.6))
		var title := ""
		var line2 := ""
		var line3 := ""
		if box_star:
			if q.res == "star":
				draw_preview(pv, q.cat, q.it.id, t_real)
				title = q.it.n
				line2 = "★ 걸작 완품!"
			elif q.res == "starx":
				draw_preview(pv, "star", "", t_real)
				title = "모든 걸작 보유 중"
				line2 = "별 파편 +30"
			else:
				draw_preview(pv, "star", "", t_real)
				title = "★ 별 파편"
				line2 = "×" + str(q.a)
		else:
			if q.res == "jack":
				var si := 0
				for j in SETS.size():
					if SETS[j].r == q.it.id:
						si = j
				draw_preview(pv, "set", si, t_real)
				title = q.it.n
				line2 = "크로 세트 획득!"
				line3 = ("이미 보유 → 청석 +" + str(q.v)) if int(q.v) > 0 else "로봇 + 기지 + 테마 전부!"
			else:
				draw_preview(pv, "s" if q.cat == "r" else q.cat, q.it.id, t_real)
				title = q.it.n
				line2 = {"r": "로봇", "b": "기지", "t": "테마"}[q.cat] + " · " + {"ju": "주", "kro": "크로", "b": "기지"}[q.g] + " · 파편 ×" + str(q.amt)
				line3 = "완성!" if q.res == "done" else (("보유 중 → 청석 +" + str(q.v)) if q.res == "dup" else str(q.c) + " / " + str(q.need))
		draw_string(f, Vector2(r.position.x, pv.end.y + 20.0), title, HORIZONTAL_ALIGNMENT_CENTER, cw, 13, Color.WHITE)
		draw_string(f, Vector2(r.position.x, pv.end.y + 38.0), line2, HORIZONTAL_ALIGNMENT_CENTER, cw, 11, Color("#c79bff") if big else Color("#9fb3c2"))
		draw_string(f, Vector2(r.position.x, pv.end.y + 54.0), line3, HORIZONTAL_ALIGNMENT_CENTER, cw, 11, Color("#ffd76a") if big else Color("#c9d4dc"))
	for it in ui:
		if it.id == "boxok":
			_btn(f, it.r, "건너뛰기" if box_busy() else "확인", hov == it, 16)

func _build_cos() -> void:
	if not box_res.is_empty():
		var u := ui_size()
		_add("boxok", Rect2(u.x / 2.0 - 90.0, u.y - 96.0, 180.0, 44.0))
		return
	var pr := _wide_rect()
	_add("lback", Rect2(pr.end.x - 130.0, pr.end.y - 52.0, 116.0, 40.0))
	if lsec == "shop":
		var tabs := [["star", "★ 걸작"], ["box", "소로 상자"], ["set", "세트"], ["r", "로봇 스킨"], ["b", "기지 스킨"], ["t", "테마"]]
		var x := pr.position.x + 14.0
		for tb in tabs:
			var w := 112.0
			_add("cb", Rect2(x, pr.position.y + 50.0, w, 36.0), true, "", {"a": "tab", "k": tb[0], "lb": tb[1]})
			x += w + 6.0
	var cr := _content_rect()
	var R: Array = _rows_shop() if lsec == "shop" else (_rows_store() if lsec == "store" else _rows_pass())
	_layout_rows(R, cr, ThemeDB.fallback_font)

func _pass_max() -> float:
	return maxf(0.0, 96.0 + 30.0 * 128.0 - _content_rect().size.x)

func _lobby_cos(f: Font, hov) -> void:
	var pr := _wide_rect()
	sb_panel.draw(get_canvas_item(), pr)
	_draw_rows(f, hov)
	var cr := _content_rect()
	var mk := Color("#0a0e14")
	draw_rect(Rect2(pr.position.x + 2, pr.position.y + 2, pr.size.x - 4, cr.position.y - pr.position.y - 2), mk)
	draw_rect(Rect2(pr.position.x + 2, cr.end.y, pr.size.x - 4, pr.end.y - cr.end.y - 2), mk)
	draw_string(f, pr.position + Vector2(18, 34), {"shop": "상점", "store": "창고", "pass": "배틀패스"}[lsec], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
	var info := "청석 " + str(SV.cs) + " · 별석 " + str(SV.ss)
	if lsec == "shop":
		info += " · 게임이 끝나면 번 광석의 4% + 정복 보너스가 청석으로 들어와요"
	draw_string(f, pr.position + Vector2(130, 32), info, HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 150.0, 12, Color("#9fb3c2"))
	for it in ui:
		if it.id == "lback":
			_btn(f, it.r, "뒤로", hov == it, 15)
		elif it.id == "cb" and it.arg.get("a", "") == "tab":
			var on: bool = shop_tab2 == it.arg.k
			(sb_tab_on if on else sb_btn).draw(get_canvas_item(), it.r)
			draw_string(f, Vector2(it.r.position.x, it.r.position.y + 23.0), it.arg.lb, HORIZONTAL_ALIGNMENT_CENTER, it.r.size.x, 13, Color.WHITE)
	if lob_max > 0.0:
		var k := lob_scroll / lob_max
		var hh := maxf(30.0, cr.size.y * cr.size.y / (cr.size.y + lob_max))
		draw_rect(Rect2(cr.end.x + 4.0, cr.position.y + (cr.size.y - hh) * k, 4.0, hh), Color(1, 1, 1, 0.25))

func cos_press(a: Dictionary) -> void:
	match a.a:
		"tab":
			shop_tab2 = a.k
			lob_scroll = 0.0
		"buy": buy_skin(a.id)
		"eq":
			equip(a.id)
			sv_save()
		"uneq":
			unequip(a.c)
			sv_save()
		"box": open_box(int(a.n), false)
		"fbox": open_box(mini(30, SV.fbox), true)
		"spull": star_pull(int(a.n))
		"sx":
			var c := 300 * int(a.n)
			if SV.cs < c:
				lmsg = "청석이 부족해요 (" + str(c) + " 필요)"
				return
			SV.cs -= c
			SV.ss += int(a.n)
			lmsg = "별석 " + str(a.n) + "개로 교환했어요"
			sv_save()
		"craft":
			if SV.sfrag < 30 or owns(a.id):
				return
			SV.sfrag -= 30
			arr_of(cat_of(a.id)).append(a.id)
			lmsg = item(a.id).n + " 제작 완료!"
			sfx("evo")
			sv_save()
		"mset":
			var S: Dictionary = MSET[int(a.i)]
			SV.eq = S.r
			SV.beq = S.b
			SV.teq = S.t
			lmsg = S.n + " 장착!"
			sv_save()
		"set": buy_set(int(a.i))
		"sf":
			stF[a.k] = a.v
			lob_scroll = 0.0
		"bpbuy":
			if bp().prem:
				return
			if SV.cs < 2000:
				lmsg = "청석이 부족해요 (2,000 필요)"
				return
			SV.cs -= 2000
			bp().prem = true
			lmsg = "프리미엄 배틀패스가 해금됐어요!"
			sfx("capture")
			sv_save()
		"bpskip":
			var n := mini(int(a.n), 30 - bp_lv())
			if n <= 0:
				return
			if SV.cs < 100 * n:
				lmsg = "청석이 부족해요 (" + str(100 * n) + " 필요)"
				return
			SV.cs -= 100 * n
			bp().xp = mini(15000, int(bp().xp) + 500 * n)
			lmsg = "배틀패스 " + str(n) + "단계 구매! 지금 " + str(bp_lv()) + "단계"
			sv_save()
		"bpc":
			var r = bp_claim(a.t, int(a.L))
			if r != null:
				lmsg = r
				sfx("up")
				sv_save()
		"bpall":
			var G := 0
			for L in range(1, 31):
				for tp in ["f", "p"]:
					if bp_claim(tp, L) != null:
						G += 1
			lmsg = ("보상 " + str(G) + "개 받기 완료!") if G > 0 else "받을 보상이 없어요"
			sv_save()

# ═════════ 소리 (웹 효과음·배경음을 WAV로 만든 것) ═════════
const SFX_GAP := {"shoot": 0.06, "hit": 0.06, "ehit": 0.08, "die": 0.05, "ore": 0.12, "turret": 0.06, "myturret": 0.1, "basehit": 0.15, "up": 0.05, "click": 0.03, "cmd_atk": 0.05, "cmd_mv": 0.05}
var snd_cache := {}
var snd_last := {}
var sfx_pool: Array = []
var sfx_i := 0
var bgm_p: AudioStreamPlayer = null
var bgm_k := ""
var vol_s := 70
var vol_b := 35

func _snd(k: String) -> AudioStream:
	if not snd_cache.has(k):
		var s = null
		if ResourceLoader.exists("res://sounds/" + k + ".ogg"):
			s = load("res://sounds/" + k + ".ogg")
			if s is AudioStreamOggVorbis:
				(s as AudioStreamOggVorbis).loop = true
		else:
			s = load("res://sounds/" + k + ".wav")
		if s is AudioStreamWAV and k.begins_with("bgm_"):
			var w := s as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)
		snd_cache[k] = s
	return snd_cache[k]

func _snd_init() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_pool.append(p)
	bgm_p = AudioStreamPlayer.new()
	add_child(bgm_p)
	_vol_apply()

func _vol_apply() -> void:
	var sv := linear_to_db(maxf(0.0001, vol_s / 70.0))
	for p in sfx_pool:
		p.volume_db = sv
	if bgm_p != null:
		bgm_p.volume_db = linear_to_db(maxf(0.0001, vol_b / 35.0))

func sfx(k: String) -> void:
	if muted or vol_s <= 0 or sfx_pool.is_empty():
		return
	var gap: float = SFX_GAP.get(k, 0.0)
	if gap > 0.0 and t_real - float(snd_last.get(k, -9.0)) < gap:
		return
	snd_last[k] = t_real
	var s := _snd(k)
	if s == null:
		return
	var p: AudioStreamPlayer = sfx_pool[sfx_i]
	sfx_i = (sfx_i + 1) % sfx_pool.size()
	p.stream = s
	p.play()

func sfx_at(k: String, p: Vector2) -> void:
	if view_rect().grow(60.0).has_point(p):
		sfx(k)

const MUS_IDS := ["t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8", "t9", "t10", "t11", "t12", "t13", "tk1", "tk2", "tk3", "tk4", "tk5", "tk6", "tk7", "tk8", "tk9", "tk10", "tk11", "tm1", "tm2", "tm3"]
func bgm_theme() -> String:
	var b: String = str(SV.get("bgm", "auto"))
	if b == "base":
		return ""
	if b != "auto" and SV.get("town", []).has(b) and MUS_IDS.has(b):
		return b
	var te: String = str(SV.get("teq", ""))
	return te if MUS_IDS.has(te) else ""

func mset_done(id: String) -> bool:
	for S in MSET:
		if S.t == id:
			return owns(S.r) and owns(S.b) and owns(S.t)
	return false

func _bgm_tick() -> void:
	if bgm_p == null:
		return
	var want := ""
	var tid := bgm_theme()
	if not muted and vol_b > 0 and scene == "lobby" and box_res.is_empty():
		want = ("bgm_" + tid) if tid != "" else "bgm_lobby"
	elif not muted and vol_b > 0 and scene == "game" and not paused and not lost:
		if tid != "":
			want = "bgm_" + tid + (("_raidx" if mset_done(tid) else "_raid") if raid_alive else "")
		else:
			want = "bgm_raid" if raid_alive else "bgm_game"
	if want == bgm_k:
		return
	bgm_k = want
	if want == "":
		bgm_p.stop()
	else:
		bgm_p.stream = _snd(want)
		bgm_p.play()

# ═════════ 효과: 파티클 · 레이드 띠 · 화살표 · 비네트 · 승리/패배 ═════════
func boom(p: Vector2, c: Color, sk: Dictionary = {}) -> void:
	var n := 7 if not sk.is_empty() else 6
	for i in n:
		var a := rng.randf() * TAU
		var v := rng.randf_range(40.0, 130.0)
		var cc: Color = C(sk.pc[i % 2]) if not sk.is_empty() else c
		parts.append({"p": p, "v": Vector2.from_angle(a) * v, "t": rng.randf_range(0.3, 0.6), "c": cc})

func _tick_fx(dt: float) -> void:
	for q in parts:
		q.p = (q.p as Vector2) + (q.v as Vector2) * dt
		q.v = (q.v as Vector2) * 0.93
		q.t -= dt
	parts = parts.filter(func(q): return q.t > 0.0)
	if won:
		_tick_win(dt)

func _parts() -> void:
	for q in parts:
		draw_rect(Rect2((q.p as Vector2) - Vector2(1.5, 1.5), Vector2(3, 3)), Color(q.c, minf(1.0, q.t * 2.0)))

# 이동·공격·채굴 명령: 로봇에서 목표로 점선
func _cmd_lines(e: Dictionary, X: Vector2, k: float, cc: Color) -> void:
	if not e.has("pts") or k >= 0.55:
		return
	var al := 0.28 * (1.0 - k / 0.55)
	for q in e.pts:
		var a: Vector2 = q
		var L := a.distance_to(X)
		if L < 4.0:
			continue
		var dv := (X - a) / L
		var off := fmod(k * 40.0, 9.0)
		var s := -off
		while s < L:
			var s0 := maxf(0.0, s)
			var s1 := minf(L, s + 4.0)
			if s1 > s0:
				draw_line(a + dv * s0, a + dv * s1, Color(cc, al), 1.2)
			s += 9.0

func _atk_mark(e: Dictionary, X: Vector2, k: float, cc: Color) -> void:
	var al := maxf(0.0, 1.0 - k)
	var big: bool = e.get("big", false)
	var R0 := (50.0 if big else 24.0) + 16.0 * (1.0 - minf(1.0, k * 2.2))
	var rt := k * 2.2
	for i in 4:
		var a := rt + i * PI / 2.0
		draw_arc(X, R0, a - 0.42, a + 0.42, 10, Color(cc, al), 3.0)
	var c2 := 8.0 + 6.0 * (1.0 - minf(1.0, k * 3.0))
	draw_line(X - Vector2(c2, 0), X + Vector2(c2, 0), Color(cc, al), 2.5)
	draw_line(X - Vector2(0, c2), X + Vector2(0, c2), Color(cc, al), 2.5)

func _vignette() -> void:
	if vig_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.set_color(1, Color(0, 0, 0, 0.35))
		g.set_offset(0, 0.62)
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.05, 0.5)
		gt.width = 256
		gt.height = 256
		vig_tex = gt
	draw_texture_rect(vig_tex, Rect2(Vector2.ZERO, vsize()), false)

func raid_center():
	var n := 0
	var c := Vector2.ZERO
	for e in ens:
		if e.raid and e.hp > 0:
			c += e.p
			n += 1
	return c / n if n > 0 else null

# 화면 좌표(UI 단위)에서 그리기
func _raid_ui(f: Font) -> void:
	var u := ui_size()
	var rl := 0
	for e in ens:
		if e.raid and e.hp > 0:
			rl += 1
	var tl := next_raid - t
	if rl > 0 or (tl <= 30.0 and tl > 0.0):
		var tx := ("레이드 진행 중 · 남은 적 " + str(rl)) if rl > 0 else ("레이드까지 " + str(ceili(tl)) + "초")
		var w := f.get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 40.0
		var by := 52.0 if touch_ui() else hud_rect().position.y - 56.0
		var r := Rect2(u.x / 2.0 - w / 2.0, by, w, 38.0)
		draw_rect(r, Color(70 / 255.0, 8 / 255.0, 8 / 255.0, 0.92))
		draw_rect(r, Color("#ff5a4a"), false, 2.0)
		draw_string(f, Vector2(r.position.x, by + 26.0), tx, HORIZONTAL_ALIGNMENT_CENTER, w, 19, Color("#ffe0dc"))
	# 화면 밖 레이드 방향 화살표
	var rc = raid_center()
	if rc != null:
		var sp: Vector2 = (get_canvas_transform() * (rc as Vector2)) / us
		if sp.x < 0.0 or sp.y < 0.0 or sp.x > u.x or sp.y > u.y:
			var c := u / 2.0
			var d: Vector2 = sp - c
			var sc := minf((u.x / 2.0 - 40.0) / maxf(absf(d.x), 1.0), (u.y / 2.0 - 40.0) / maxf(absf(d.y), 1.0))
			var ap := c + d * sc
			var an := d.angle()
			var al := 0.6 + 0.4 * absf(sin(t_real * 4.0))
			var tri := PackedVector2Array([Vector2(16, 0), Vector2(-8, -11), Vector2(-8, 11)])
			draw_colored_polygon(Transform2D(an, ap) * tri, Color(1.0, 0.23, 0.16, al))
			draw_string(f, ap + Vector2(-40, 24), "레이드", HORIZONTAL_ALIGNMENT_CENTER, 80, 12, Color("#ffdcd6"))

# 기지 파괴 (웹 baseBoom 기본 모양)
func _base_boom(lt: float) -> void:
	var X := B
	var h := func(i: int) -> float: return fmod(i * 9301.0 + 49297.0, 233280.0) / 233280.0
	if lt < 0.45:
		var sh := (1.0 - lt / 0.45) * 7.0
		art_base(self, X + Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * sh, t, Transform2D.IDENTITY, bsk)
		draw_circle(X, 58.0, Color(1, 1, 1, lt / 0.45 * 0.85))
		return
	var tt := lt - 0.45
	draw_colored_polygon(ell(X + Vector2(0, 10), 62, 22), Color(0, 0, 0, 0.35))
	for i in 10:
		draw_rect(Rect2(X.x - 42.0 + h.call(i) * 84.0, X.y - 16.0 + h.call(i + 20) * 36.0, 6.0 + h.call(i + 40) * 11.0, 4.0 + h.call(i + 60) * 7.0), C(bsk.get("bd", "#38434d")) if i % 2 else C(bsk.get("tp", "#5a6a78")))
	if tt < 0.8:
		draw_arc(X, 20.0 + tt * 280.0, 0, TAU, 64, Color(C(bsk.lt) if bsk.has("lt") else Color(1.0, 0.95, 0.75), 1.0 - tt / 0.8), 7.0 * (1.0 - tt / 0.8) + 1.0)
	if tt < 1.2:
		draw_circle(X, 32.0 + tt * 55.0, Color(C(bsk.gl) if bsk.has("gl") else Color(1.0, 0.42, 0.12), (1.0 - tt / 1.2) * 0.85))
		draw_circle(X, 18.0 + tt * 26.0, Color(C(bsk.lt) if bsk.has("lt") else Color(1.0, 0.82, 0.35), 1.0 - tt / 1.2))
	var fade := maxf(0.0, 1.0 - tt / 2.3)
	for i in 48:
		var a: float = h.call(i) * TAU
		var v: float = 60.0 + h.call(i + 7) * 230.0
		var d := v * tt * (1.0 - minf(tt, 2.0) / 4.0)
		var z: float = 2.0 + h.call(i + 11) * 4.0
		var pp := X + Vector2(cos(a) * d, sin(a) * d + tt * tt * 30.0)
		var col := Color(0.35, 0.35, 0.35, 0.85)
		if i % 3:
			col = Color("#ffb03a") if i % 2 else Color("#ff5a1a")
		draw_circle(pp, z + (0.0 if i % 3 else tt * 6.0), Color(col, col.a * fade))
	var sa := maxf(0.0, 0.55 - tt * 0.15)
	for i in 6:
		draw_circle(X + Vector2((h.call(i + 90) - 0.5) * 64.0, -20.0 - tt * 40.0 - h.call(i + 70) * 30.0), 14.0 + tt * 10.0, Color(0.24, 0.24, 0.24, 0.65 * sa))

func _defeat(f: Font) -> void:
	var lt := t_real - lost_at
	if lt <= 2.6:
		return
	var u := ui_size()
	var a := minf(1.0, (lt - 2.6) * 2.0)
	draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.55 * a))
	var rise := (1.0 - minf(1.0, (lt - 2.6) / 0.8)) * 30.0
	var fs := int(clampf(u.x * 0.14, 80.0, 160.0))
	var y := u.y / 2.0 - 30.0 + rise
	draw_string(f, Vector2(0, y + 6), "패 배", HORIZONTAL_ALIGNMENT_CENTER, u.x, fs, Color(0.29, 0.04, 0.02, a))
	draw_string(f, Vector2(0, y), "패 배", HORIZONTAL_ALIGNMENT_CENTER, u.x, fs, Color(1.0, 0.29, 0.23, a))
	var sub := "10분 이상 플레이해야 청석을 받아요" if t < 600.0 else "시간 %d:%02d · 처치 %d · 정복 %d" % [int(t / 60.0), int(t) % 60, kills, captured()]
	draw_string(f, Vector2(0, y + 40.0), sub, HORIZONTAL_ALIGNMENT_CENTER, u.x, 15, Color(1.0, 0.86, 0.84, a))

# 승리 연출 (웹 drawWin 기본 꽃가루 모양)
func _tick_win(dt: float) -> void:
	var u := ui_size()
	var wt := t_real - won_at
	var WC := [Color("#ffd76a"), Color("#7fe0ff"), Color("#ff7aa8"), Color("#9bff8a"), Color("#c79bff")]
	if rng.randf() < (0.08 if wt < 4.0 else 0.035):
		var bp0 := Vector2(u.x * rng.randf_range(0.15, 0.85), u.y * rng.randf_range(0.12, 0.57))
		for i in 46:
			var a := rng.randf() * TAU
			var v := rng.randf_range(60.0, 250.0)
			wfx.append({"p": bp0, "v": Vector2.from_angle(a) * v, "l": rng.randf_range(1.0, 1.6), "c": WC[rng.randi() % 5], "r": rng.randf_range(2.0, 3.6), "g": 90.0, "fr": true})
	if wfx.size() < 650 and wt > 0.3:
		for i in 2:
			wfx.append({"p": Vector2(rng.randf() * u.x, -10), "v": Vector2(rng.randf_range(-20, 20), rng.randf_range(60, 140)), "l": 9.0, "c": WC[rng.randi() % 5], "cf": true, "a": rng.randf() * 7.0})
	for q in wfx:
		q.l -= dt
		if q.has("g"):
			q.v = (q.v as Vector2) + Vector2(0, q.g * dt)
		if q.get("fr", false):
			q.v = (q.v as Vector2) * 0.97
		q.p = (q.p as Vector2) + (q.v as Vector2) * dt
		if q.has("a"):
			q.a += dt * 6.0
	wfx = wfx.filter(func(q): return q.l > 0.0 and q.p.y < u.y + 20.0)

func _victory(f: Font) -> void:
	var u := ui_size()
	var wt := t_real - won_at
	var c := Vector2(u.x / 2.0, u.y * 0.36)
	draw_rect(Rect2(Vector2.ZERO, u), Color(6 / 255.0, 8 / 255.0, 16 / 255.0, minf(0.72, wt * 0.9)))
	if wt < 0.5:
		draw_rect(Rect2(Vector2.ZERO, u), Color(1.0, 0.96, 0.82, (1.0 - wt / 0.5) * 0.75))
	# 빛줄기
	var ra := minf(1.0, wt * 1.3)
	for i in 14:
		var a := wt * 0.25 + i * TAU / 14.0
		var L := u.x * 0.7
		var dv := Vector2.from_angle(a - PI / 2.0)
		var pv := Vector2(-dv.y, dv.x)
		var pts := PackedVector2Array([c, c + dv * L - pv * 40.0, c + dv * L + pv * 40.0])
		var cols := PackedColorArray([Color(1, 0.84, 0.42, 0.3 * ra), Color(1, 0.84, 0.42, 0.0), Color(1, 0.84, 0.42, 0.0)])
		draw_polygon(pts, cols)
	for q in wfx:
		var al := minf(1.0, q.l * 1.4)
		if q.get("cf", false):
			_ui_tf(q.p, q.a, 1.0)
			draw_rect(Rect2(-4, -2, 8, 4), Color(q.c, al))
			_ui_reset()
		else:
			draw_circle(q.p, q.r, Color(q.c, al))
	_ui_reset()
	var sc := 0.4 + 1.0 * (wt / 0.6) + 0.15 * sin(wt / 0.6 * PI) if wt < 0.6 else 1.0 + 0.03 * sin(wt * 3.0)
	var fs := int(minf(110.0, u.x * 0.09))
	_ui_tf(c, 0.0, sc)
	var tw := f.get_string_size("승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base_p := Vector2(-tw / 2.0, fs * 0.36)
	draw_string_outline(f, base_p, "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, Color("#5a3300"))
	draw_string(f, base_p, "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffd24a"))
	_ui_reset()
	if wt > 0.7:
		var a := minf(1.0, (wt - 0.7) * 2.0)
		draw_string(f, Vector2(0, c.y + minf(80.0, u.x * 0.065)), "외계 기지 50개를 모두 정복했어요!", HORIZONTAL_ALIGNMENT_CENTER, u.x, int(minf(24.0, u.x * 0.02)), Color(0.91, 0.93, 0.97, a))
	if wt > 1.4:
		var a := minf(1.0, (wt - 1.4) * 1.6)
		var w := minf(520.0, u.x - 40.0)
		var py := c.y + minf(115.0, u.x * 0.09)
		var r := Rect2(c.x - w / 2.0, py, w, 150.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(14 / 255.0, 20 / 255.0, 30 / 255.0, 0.92 * a)
		sb.border_color = Color(1, 0.82, 0.29, a)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.draw(get_canvas_item(), r)
		var items := [["플레이 시간", "%d분 %02d초" % [int(t / 60.0), int(t) % 60]], ["정복", "50 / 50"], ["잡은 적", str(int(SS.kills))], ["만든 로봇", str(int(SS.made))], ["번 광석", str(int(SS.earn))], ["받을 청석", "+0"]]
		for i in 6:
			var ix := r.position.x + w / 6.0 + (i % 3) * w / 3.0 - 80.0
			var iy := py + 42.0 + (i / 3) * 62.0
			draw_string(f, Vector2(ix, iy), items[i][0], HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(0.54, 0.61, 0.68, a))
			draw_string(f, Vector2(ix, iy + 26.0), items[i][1], HORIZONTAL_ALIGNMENT_CENTER, 160, 21, Color(0.5, 0.85, 1.0, a) if i == 5 else Color(1.0, 0.84, 0.42, a))

# ═════════ 조작: 깃발 · 조작법 창 · 확대 표시 ═════════
const KEYS := [["마우스", [["좌클릭", "명령 (이동 · 공격 · 채굴) / 로봇 선택"], ["좌클릭 드래그", "지도 이동"], ["우클릭 누른 채 드래그", "로봇 여러 대 묶어서 선택"], ["Ctrl + 휠", "화면 확대 · 축소 (60~180%)"], ["휠", "지도 위아래 이동 (Shift+휠: 좌우)"], ["미니맵 클릭·드래그", "그 위치로 화면 이동"], ["마우스 올리기", "로봇 · 적 · 기지 · 광산 정보 보기"]]],
	["화면 · 선택", [["W A S D / 화면 가장자리", "지도 이동"], ["E", "모든 로봇 선택"], ["Q", "우리 기지로 화면 이동"], ["1 ~ 5", "정찰 · 채굴 · 근접 · 원거리 · 지원 로봇 전체 선택"], ["Ctrl+1~5 · 숫자 두 번", "그 로봇들이 모인 곳으로 화면 이동"], ["T", "마우스 위치에 깃발 꽂기 / 뽑기"]]],
	["기능", [["Y", "상점 열기 · 닫기"], ["I", "게임 정보"], ["6 · Space", "기름 들기 (Esc · 우클릭으로 취소)"], ["Esc", "일시정지 · 창 닫기 (일시정지 메뉴에도 조작법)"], ["M", "소리 켜기 · 끄기"], ["Tab", "이 조작법 창 열기 · 닫기"]]]]
const KEYS_T := [["터치", [["탭", "로봇 선택 · 이동 · 공격 · 채굴 명령"], ["한 손가락 드래그", "지도 이동"], ["두 손가락 벌리기 · 오므리기", "확대 · 축소"], ["길게 누른 채 드래그", "로봇 여러 대 묶기"], ["미니맵 탭 · 드래그", "그 위치로 화면 이동"], ["기지 · 광산 · 적 탭", "정보가 잠깐 떠요"]]],
	["버튼", [["아래 1~5 칸", "정찰 · 채굴 · 근접 · 원거리 · 지원 전체 선택"], ["아래 6 칸", "기름 들기"], ["전체 · 기지 · 정보 · 상점", "전체 선택 · 기지로 · 게임 기록 · 상점"], ["왼쪽 위 일시정지 버튼", "일시정지 · 조작법 · 창 닫기"], ["선택 해제", "선택한 로봇 해제"]]],
	["상점", [["항목 탭", "바로 구매"], ["아래 수치 누르고 있기", "설명 보기"]]]]

func toggle_flag(w: Vector2) -> void:
	for i in flags.size():
		if (flags[i] as Vector2).distance_to(w) < 36.0:
			flags.remove_at(i)
			msg("깃발을 뽑았어요")
			return
	if flags.size() >= 20:
		msg("깃발은 최대 20개까지 꽂을 수 있어요. 깃발 위에서 T를 누르면 뽑혀요")
		return
	flags.append(w)
	fx.append({"k": "ring", "p": w, "t": 0.6, "r": 40.0})
	sfx("flag")
	msg("깃발 " + str(flags.size()) + "번을 꽂았어요 (같은 곳에서 T를 다시 누르면 뽑혀요)")

func _flags(f: Font) -> void:
	var vr := view_rect().grow(60.0)
	for i in flags.size():
		var p: Vector2 = flags[i]
		if not vr.has_point(p):
			continue
		var w := sin(t * 4.0 + i) * 2.5
		draw_colored_polygon(ell(p + Vector2(2, 2), 9, 4, 16), Color(0, 0, 0, 0.3))
		draw_line(p, p + Vector2(0, -38), Color("#e9e2cf"), 2.5)
		var pts := PackedVector2Array()
		var a := p + Vector2(1, -38)
		var tip := p + Vector2(24, -31 + w)
		var b := p + Vector2(1, -24)
		for k in 9:
			var q := k / 8.0
			pts.append(a.lerp(p + Vector2(13, -35 + w), q).lerp((p + Vector2(13, -35 + w)).lerp(tip, q), q))
		for k in 9:
			var q := k / 8.0
			pts.append(tip.lerp(p + Vector2(13, -27 - w), q).lerp((p + Vector2(13, -27 - w)).lerp(b, q), q))
		draw_colored_polygon(pts, Color("#ffcf3a"))
		pts.append(pts[0])
		draw_polyline(pts, Color("#8a6a10"), 1.0)
		draw_string(f, p + Vector2(4, -27.5 + 4), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 12, 10, Color("#3a2a05"))

func _keys_win(f: Font) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.55))
	var G: Array = KEYS_T if touch_ui() else KEYS
	var cw := minf(330.0, (u.x - 60.0) / G.size())
	var rows := 0
	for g in G:
		rows = maxi(rows, (g[1] as Array).size())
	var W := cw * G.size() + 20.0 * (G.size() - 1) + 40.0
	var H := 70.0 + rows * 40.0 + 20.0
	var r := Rect2((u.x - W) / 2.0, (u.y - H) / 2.0, W, H)
	sb_panel.draw(get_canvas_item(), r)
	draw_string(f, r.position + Vector2(20, 34), "조작법" if touch_ui() else "조작법   Tab으로 열고 닫아요", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	for gi in G.size():
		var g: Array = G[gi]
		var x := r.position.x + 20.0 + gi * (cw + 20.0)
		var y := r.position.y + 64.0
		draw_string(f, Vector2(x, y), g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb3c2"))
		for li in (g[1] as Array).size():
			var L: Array = g[1][li]
			var yy := y + 14.0 + li * 40.0
			var kw := minf(cw * 0.48, f.get_string_size(L[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0)
			var kr := Rect2(x, yy, kw, 22)
			draw_rect(kr, Color("#1a232c"))
			draw_rect(kr, Color("#3a4a58"), false, 1.0)
			draw_string(f, kr.position + Vector2(0, 16), L[0], HORIZONTAL_ALIGNMENT_CENTER, kw, 12, Color.WHITE)
			draw_multiline_string(f, Vector2(x + kw + 8.0, yy + 15.0), L[1], HORIZONTAL_ALIGNMENT_LEFT, cw - kw - 8.0, 12, 2, Color("#c9d4dc"))
	draw_string(f, Vector2(r.position.x, r.end.y - 10.0), "아무 곳이나 누르면 닫혀요", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#7d8b96"))

func _zoom_badge(f: Font) -> void:
	var a := 1.0 - (t_real - zm_t)
	if a <= 0.0:
		return
	var u := ui_size()
	var s := str(roundi(zm * 100.0)) + "%"
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 24.0
	var r := Rect2((u.x - w) / 2.0, 54.0, w, 28.0)
	var al := minf(1.0, a * 2.5)
	draw_rect(r, Color(0.04, 0.055, 0.08, 0.85 * al))
	draw_string(f, r.position + Vector2(0, 20), s, HORIZONTAL_ALIGNMENT_CENTER, w, 15, Color(1, 1, 1, al))

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
	if scene == "lobby":
		_lobby_input(e)
		return
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
		if mb.pressed and keys_open:
			keys_open = false
			return
		var wheel := mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
		if wheel and mb.pressed:
			var amt := 100.0 * (mb.factor if mb.factor > 0.0 else 1.0)
			var up := mb.button_index == MOUSE_BUTTON_WHEEL_UP
			var vert := up or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN
			if vert and (mb.ctrl_pressed or mb.meta_pressed):
				set_zoom(snappedf(zm + (0.1 if up else -0.1), 0.1), mb.position)
			elif vert and not mb.shift_pressed:
				cam.position.y += -amt if up else amt
			else:
				var left := up or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT
				cam.position.x += -amt if left else amt
			_clamp_cam()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
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
	elif e is InputEventPanGesture:
		cam.position += (e as InputEventPanGesture).delta * 30.0
		_clamp_cam()
	elif e is InputEventMagnifyGesture:
		var mg := e as InputEventMagnifyGesture
		set_zoom(zm * mg.factor, mg.position)
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		mouse_ui = mm.position / us
		mouse_in = true
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
		if kc == KEY_TAB:
			keys_open = not keys_open
			return
		if kc == KEY_M:
			muted = not muted
			msg("음소거" if muted else "소리 켜짐")
			return
		if kc == KEY_ESCAPE:
			if keys_open:
				keys_open = false
			elif info_open:
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
			sfx("pause")
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
			num_key(kc - KEY_1, ke.ctrl_pressed or ke.shift_pressed)
		elif kc >= KEY_KP_1 and kc <= KEY_KP_5:
			num_key(kc - KEY_KP_1, ke.ctrl_pressed or ke.shift_pressed)
		elif kc == KEY_T:
			var sp := mouse_ui * us
			if sp.x >= 0.0:
				toggle_flag(s2w(sp))
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
		if st.pressed and keys_open:
			keys_open = false
			return
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
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if scene == "game":
			save_game()
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_in = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		mouse_in = true

func _process(dt: float) -> void:
	t_real += dt
	_tick_fx(dt)
	_bgm_tick()
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
	# 화면 가장자리에 마우스를 대면 지도 이동 (PC)
	var mp := mouse_ui * us
	var vs := vsize()
	if scene == "game" and not touch_mode and mouse_in and mp.x >= 0.0 and dn == null and not box_active and not mm_drag and not mm_rect().has_point(mp) \
			and not shop_open and not info_open and not paused and not keys_open and ui_hit(mp) == null:
		var es := 1500.0 * dt / zm
		var ev := Vector2.ZERO
		if mp.x < 26.0:
			ev.x = -es
		elif mp.x > vs.x - 26.0:
			ev.x = es
		if mp.y < 26.0:
			ev.y = -es
		elif mp.y > vs.y - 26.0:
			ev.y = es
		if ev != Vector2.ZERO:
			cam.position += ev
			_clamp_cam()
	if wipe_arm != "" and t_real - wipe_t > 3.0:
		wipe_arm = ""
	if scene == "lobby":
		_box_tick()
		queue_redraw()
		return
	if not won and not lost and not paused:
		update_game(dt)
		_tut_tick()
		save_acc += dt
		if save_acc > 15.0:
			save_acc = 0.0
			save_game()
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
		sfx("alarm")
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
			boom(tg.p, Color("#7ff0ff") if p.mine else Color("#ff8a66"), kro_s if p.mine else tkro_s)
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
			sfx("capture")
			msg("기지 정복! 광석 +" + str(int(g)) + " · 진화석 +" + str(sg) + " · 수입 x" + str(snappedf(eco(), 0.01)))
			if captured() >= outs.size():
				won = true
				won_at = t_real
				sfx("victory")
				wfx = []
	# 죽은 로봇 정리
	var ra: bool = ens.any(func(e): return e.raid)
	for u in bots:
		if u.hp <= 0 and is_cmb(u.t):
			dead.append({"t": u.t, "lv": u.lv, "ev": u.ev, "rd": ra, "w": 0.0})
	var r0 := bots.size()
	bots = bots.filter(func(u): return u.hp > 0)
	lost_n += r0 - bots.size()
	SS.lost += r0 - bots.size()
	if bots.size() < r0:
		sfx("lost")
	var e0 := ens.size()
	ens = ens.filter(func(e): return e.hp > 0)
	if ens.size() < e0:
		sfx("die")
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
		sfx("capture")
	raid_alive = ra
	if base.hp <= 0.0 and not lost:
		lost = true
		lost_at = t_real
		sfx("boom")
		cam_to(B)
		msg("기지가 파괴됐어요")

# ═════════ 그리기 (월드) ═════════
func _cos_cache() -> void:
	skn = SKIN()
	bsk = BSK()
	thm = TH()
	kro_s = KRO()
	tkro_s = TKRO()
	tn_cols = ground_tn().map(func(c): return C(c))

func _draw() -> void:
	var f := ThemeDB.fallback_font
	_cos_cache()
	if scene == "lobby":
		inv = get_canvas_transform().affine_inverse()
		draw_set_transform_matrix(inv)
		_lobby(f)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var vr: Rect2 = view_rect().grow(CELL)
	var i0 := maxi(0, int(vr.position.x / CELL))
	var j0 := maxi(0, int(vr.position.y / CELL))
	var i1 := mini(GN - 1, int(vr.end.x / CELL))
	var j1 := mini(GN - 1, int(vr.end.y / CELL))
	_ground(i0, j0, i1, j1)
	draw_arc(B, BASE_VIEW, 0.0, TAU, 128, Color(0.37, 0.88, 0.77, 0.2), 2.0)
	draw_arc(B, WELL, 0.0, TAU, 128, Color(0.43, 0.94, 0.63, 0.18 + 0.08 * sin(t * 2.0)), 2.0)
	if lost:
		_base_boom(t_real - lost_at)
	else:
		art_base(self, B, t, Transform2D.IDENTITY, bsk)
		_bar(B.x, B.y - 68.0, 90.0, base.hp / base.mh, Color("#5fe0c4") if base.hp / base.mh > 0.3 else Color("#e5604d"), 6.0)
		draw_string(f, Vector2(B.x - 40.0, B.y - 73.0), str(ceili(maxf(0.0, base.hp))), HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("#e6edf3"))
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
		var dv: Vector2 = (p.tg.p as Vector2) - pp
		var dirv := dv.normalized() if dv.length() > 0.1 else Vector2.RIGHT
		draw_pr(pp, dirv, kro_s if p.mine else tkro_s, Color("#7ff0ff") if p.mine else Color("#ff8a66"), p.big, p.mine, t)
	if box_active:
		var r := box_rect()
		draw_rect(r, Color(0.55, 0.89, 0.55, 0.12))
		draw_rect(r, Color("#8be28b"), false, 1.0 / zm)
	_parts()
	_fx(f)
	_fog(i0, j0, i1, j1)
	_flags(f)
	_tut_world()
	for d in drones:
		draw_arc(d.p, 260.0, 0.0, TAU, 64, Color(1.0, 0.88, 0.47, 0.5), 2.0)
		draw_circle(d.p, 9.0, Color("#0b1118"))
		draw_circle(d.p, 6.0, Color("#ffe27a"))
	# 화면 고정 그리기
	inv = get_canvas_transform().affine_inverse()
	draw_set_transform_matrix(inv)
	if not thm.is_empty():
		var tl := cam.position - vsize() / zm / 2.0
		amb(thm, t_real, Vector2.ZERO, vsize().x, vsize().y, tl.x * zm, tl.y * zm)
	_vignette()
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
			draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), tn_cols[h % 4])
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
	var ob: Array = thm.ob if not thm.is_empty() else ["#3a2a46", "#6b4a86", "#8f66ab"]
	poly(self, [p + Vector2(-34, 20), p + Vector2(-26, -20), p + Vector2(26, -20), p + Vector2(34, 20)], Color("#2e4a3a") if c else C(ob[0]))
	draw_rect(Rect2(p.x - 16, p.y - 34, 32, 40), Color("#4aa86a") if c else C(ob[1]))
	draw_rect(Rect2(p.x - 16, p.y - 34, 32, 6), Color("#7fd49a") if c else C(ob[2]))
	var lamp := Color("#c9f5d6")
	if not c:
		lamp = Color("#ff6a55") if int(t * 3.0) % 2 == 1 else Color("#a8352a")
	draw_circle(p + Vector2(0, -12), 7, lamp)
	draw_line(p + Vector2(10, -34), p + Vector2(10, -48), Color("#7fd49a") if c else C(ob[2]), 2.0)
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
	elif not thm.is_empty():
		col = C(thm.en[0 if m else 1])
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
	var acc: Color = d.acc
	var pat := ""
	if not skn.is_empty():
		col = C(skn.c)
		acc = C(skn.a)
		pat = skn.pt
	elif ev > 0:
		col = [Color("#a98ae0"), Color("#9462e0"), Color("#7d3fdc")][ev - 1]
	if u.oilT > 0.0:
		draw_arc(p, z + 9, t * 4.0, t * 4.0 + 4.5, 20, C(skn.a) if not skn.is_empty() else Color(1, 0.67, 0.16, 0.85), 2.0)
	draw_set_transform(p, u.fa, Vector2(1.35, 1.35))
	art_bot_s(self, u.t, col, acc, t, pat)
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
				draw_string(f, p + Vector2(-40, -(float(e.get("d0", 1.2)) - e.t) * 30.0), e.s, HORIZONTAL_ALIGNMENT_CENTER, 80, int(e.get("fs", 14)), Color(e.get("c", Color(0.5, 1.0, 0.7)), minf(1.0, e.t * 2.0)))
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
				var tgd = e.get("tg", null)
				if tgd != null and tgd.hp > 0:
					p = tgd.p
				_cmd_lines(e, p, k, cc)
				if e.k == "atk":
					_atk_mark(e, p, k, cc)
					continue
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
	var bpm := o + B * k
	draw_rect(Rect2(bpm - Vector2(4, 4), Vector2(8, 8)), Color("#4a86c8"))
	draw_rect(Rect2(bpm - Vector2(4, 4), Vector2(8, 8)), Color("#d6ecff"), false, 1.0)
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
	for fl in flags:
		var fp: Vector2 = o + (fl as Vector2) * k
		draw_line(fp, fp + Vector2(0, -8), Color.WHITE, 1.0)
		draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -8), fp + Vector2(6, -6), fp + Vector2(0, -4)]), Color("#ffcf3a"))
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
	await _shot("00_lobby")
	lsec = "set"
	await _shot("00b_set")
	SV.cs = 30000
	SV.ss = 200
	lsec = "shop"
	shop_tab2 = "box"
	await _shot("00c_shop_box")
	open_box(10, false)
	await _wait(1.6)
	await _shot("00d_box_open")
	await _wait(1.5)
	box_res = []
	shop_tab2 = "r"
	await _shot("00e_shop_r")
	shop_tab2 = "star"
	await _shot("00f_shop_star")
	buy_set(0)
	print("SET eq=", SV.eq, " beq=", SV.beq, " teq=", SV.teq, " cs=", SV.cs)
	lsec = "store"
	await _shot("00g_store")
	SV.bp.xp = 6200
	lsec = "pass"
	await _shot("00h_pass")
	cos_press({"a": "bpall"})
	print("BP ", lmsg, " cs=", SV.cs, " fbox=", SV.fbox)
	lsec = "main"
	await _shot("00i_main_skin")
	start_game(false)
	await _wait(0.3)
	await _shot("01_start")
	tut = 3
	shop_open = true
	await _shot("01b_tut_shop")
	shop_open = false
	tut = -1
	paused = true
	await _shot("01c_pause")
	paused = false
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
	cam_to(B + Vector2(200, -150))
	toggle_flag(B + Vector2(150, -120))
	toggle_flag(B + Vector2(260, -60))
	num_key(2, true)
	set_zoom(1.2, vsize() / 2.0)
	await _shot("03e_flags")
	keys_open = true
	await _shot("03f_keys")
	keys_open = false
	set_zoom(1.0, vsize() / 2.0)
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
	cam_to(B)
	await _shot("06b_raid_ui")
	var nb := bots.size()
	var ne := ens.size()
	var o1: float = outs[0].hp
	save_game()
	load_game()
	print("SAVELOAD bots ", nb, "->", bots.size(), " ens ", ne, "->", ens.size(), " out0 ", int(o1), "->", int(outs[0].hp), " has=", has_save())
	Engine.time_scale = 1.0
	base.hp = -100.0
	await _wait(0.9)
	await _shot("07_boom")
	await _wait(2.4)
	await _shot("08_defeat")
	lost = false
	base.hp = base.mh
	for o in outs:
		o.hp = 0.0
	await _wait(1.2)
	await _shot("09_win_a")
	await _wait(2.4)
	await _shot("10_win_b")
	print("SND bgm=", _snd("bgm_game") != null, " len=", snappedf(_snd("bgm_game").get_length(), 0.01), " victory=", _snd("victory") != null)
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

func art_base(ci: CanvasItem, p: Vector2, t: float, xf: Transform2D = Transform2D.IDENTITY, P: Dictionary = {}) -> void:
	if P.has("ms"):
		art_master_base(ci, p, P.ms, t, xf)
		return
	var pl := C(P.pl) if P.has("pl") else PL
	var rim := C(P.rim) if P.has("rim") else RIM
	var bd := C(P.bd) if P.has("bd") else BD
	var tp := C(P.tp) if P.has("tp") else TP
	var gl := C(P.gl) if P.has("gl") else GL
	var lt := C(P.lt) if P.has("lt") else LT
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
	ell_fill(ci, Vector2(6, 40), 58, 18, Color(0, 0, 0, 0.32))
	var o := oct(54)
	ci.draw_colored_polygon(o, pl)
	o.append(o[0])
	ci.draw_polyline(o, rim, 3.0, true)
	var o2 := oct(44)
	o2.append(o2[0])
	ci.draw_polyline(o2, Color(1, 1, 1, 0.1), 1.0, true)
	for i in 4:
		ci.draw_set_transform_matrix(xf * Transform2D(i * PI / 2.0, Vector2.ONE, 0.0, p))
		ci.draw_rect(Rect2(-8, -50, 16, 3), Color(lt, 0.55))
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
	ci.draw_rect(Rect2(-25, -19, 56, 46), Color(0, 0, 0, 0.35))
	ci.draw_rect(Rect2(-28, -22, 56, 44), bd)
	ci.draw_rect(Rect2(-18, -32, 36, 64), bd)
	ci.draw_rect(Rect2(-28, -22, 56, 5), tp)
	ci.draw_rect(Rect2(-18, -32, 36, 5), tp)
	ci.draw_rect(Rect2(-24, 8, 48, 6), Color(0, 0, 0, 0.45))
	for i in 6:
		var on := int(t * 2 + i) % 3 != 0
		ci.draw_rect(Rect2(-22 + i * 8, 9, 5, 4), Color(gl, 0.85) if on else Color(1, 1, 1, 0.15))
	var pu := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_circle(Vector2(0, -6), 21, Color(gl, 0.25 * pu))
	ci.draw_circle(Vector2(0, -6), 13, K)
	ci.draw_circle(Vector2(0, -6), 10, gl)
	ci.draw_circle(Vector2(-3, -9), 3.5, Color(1, 1, 1, 0.55))
	ci.draw_line(Vector2(-20, -27), Vector2(-20, -42), rim, 2.0)
	ci.draw_circle(Vector2(-20, -43), 2.5, lt if int(t * 1.5) % 2 == 1 else Color("#3a2a10"))
	ci.draw_set_transform_matrix(xf * Transform2D(t * 1.6, Vector2.ONE, 0.0, p + Vector2(20, -25)))
	ci.draw_arc(Vector2.ZERO, 7, -0.9, 0.9, 12, tp, 2.0)
	ci.draw_line(Vector2.ZERO, Vector2(7, 0), tp, 2.0)
	ci.draw_rect(Rect2(-2, -2, 4, 4), K)
	ci.draw_set_transform_matrix(xf * Transform2D(0.0, Vector2.ONE, 0.0, p))
	var corners := [Vector2(-46, -19), Vector2(46, -19), Vector2(-46, 19), Vector2(46, 19)]
	for i in 4:
		var c: Vector2 = corners[i]
		ci.draw_rect(Rect2(c.x - 4, c.y - 4, 8, 8), K)
		ci.draw_rect(Rect2(c.x - 2, c.y - 2, 4, 4), lt if int(t * 2 + i * 0.5) % 2 == 1 else Color(0, 0, 0, 0.4))
	ci.draw_set_transform_matrix(xf)

func art_mine(ci: CanvasItem, m: Dictionary, t: float) -> void:
	var p: Vector2 = m.p
	var ev: bool = m.ev
	var on: bool = m.amt > 0
	ell_fill(ci, p + Vector2(0, 12), 18, 7, Color(0, 0, 0, 0.28))
	var MN = TMN.get(thm.get("id", ""), null)
	if on:
		var gc := Color(0.67, 0.43, 1.0, 0.16) if ev else (C(MN[2]) if MN != null else Color(0.37, 0.88, 0.77, 0.14))
		ci.draw_circle(p, 28, Color(gc, gc.a + 0.04 * sin(t * 2.0 + p.x)))
	mdeco(p, MN, t_real, false)
	var c1 := Color("#47504d")
	var c2 := Color("#6a746f")
	if on:
		c1 = Color("#8a4fd0") if ev else (C(MN[0]) if MN != null else Color("#2fa88f"))
		c2 = Color("#d2a8ff") if ev else (C(MN[1]) if MN != null else Color("#8ff3dd"))
	for c in [[-10.0, 6.0, 0.7], [10.0, 5.0, 0.6], [0.0, 0.0, 1.0]]:
		var px: float = p.x + c[0]
		var py: float = p.y + c[1]
		var h: float = 22.0 * c[2]
		var w: float = 9.0 * c[2]
		poly(ci, [Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py + h * 0.35), Vector2(px - w, py)], c1)
		poly(ci, [Vector2(px, py - h), Vector2(px + w, py), Vector2(px, py)], c2)
	mdeco(p, MN, t_real, true)

# 로봇 모양 (원점 기준, 오른쪽이 앞)
func art_bot(ci: CanvasItem, k: String, col: Color, acc: Color, t: float, plain: bool = true) -> void:
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
	if not plain:
		return
	if k != "s" and k != "h":
		ci.draw_rect(Rect2(-6, -7, 9, 2), Color(1, 1, 1, 0.26))
	if k == "c" or k == "r":
		ci.draw_rect(Rect2(6 if k == "c" else 10, -1.5, 3, 3), Color(0.84, 0.98, 1.0, 0.55 + 0.45 * sin(t * 3.0)))
	if k == "h":
		ci.draw_arc(Vector2.ZERO, 5.5, 3.6, 5.2, 8, Color(1, 1, 1, 0.35), 1.0)
