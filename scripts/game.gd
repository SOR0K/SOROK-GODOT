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
# 테스트 모드: 재화 무한 · 기록은 테스트 전용 파일에만 · 클라우드에 올리지 않아요 (출시할 땐 false)
const TEST := true
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
var rvm := -99.0
var mdm := -99.0
var bwm := -99.0
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
var fog_img: Image
var fog_tex: ImageTexture
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
	_gnd_setup()
	_font_warm()
	sv_load()
	new_game()
	scene = "lobby"
	acct = preload("res://scripts/account.gd").new()
	acct.no_push = TEST
	acct.g = self
	acct.srv = "m" if touch_mode else "pc"
	add_child(acct)
	adm = preload("res://scripts/admin.gd").new()
	adm.a = acct
	adm.g = self
	add_child(adm)
	bat = preload("res://scripts/battle.gd").new()
	bat.a = acct
	bat.g = self
	add_child(bat)
	get_tree().set_auto_accept_quit(false)
	if OS.get_cmdline_user_args().has("--selftest"):
		print("OVERSAMPLE_PROP ", "oversampling_override" in get_viewport())
		_selftest()
	else:
		_check_update()
		intro_start()

# 인트로·런처에 쓰는 큰 글자를 미리 만들어 둬요 (처음 그릴 때 끊기지 않게)
func _font_warm() -> void:
	var f := ThemeDB.fallback_font
	var s := "SOROMAGESK외계기지정복전략플레이0123456789·"
	for fs in [12, 13, 14, 15, 16, 18, 19, 22, 34, 42, 52, 64, 68, 88, 110, 128, 150]:
		f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		fb().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)

func _after_intro() -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		return
	var had: bool = await acct.boot()
	if not had:
		acct.show_login("")

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
	fog_img = Image.create_empty(GN, GN, false, Image.FORMAT_RGBA8)
	fog_img.fill(FOG)
	fog_tex = ImageTexture.create_from_image(fog_img)
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
		"ai": 0.0, "dodge": 0.0, "dgo": null, "fo": null, "kite": 0.0, "kx": null, "rh": null, "rw": false, "sq": null, "spc": 0.0, "wh": 0.0}
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
				_fog_upd(i, j)
				_fog_upd(i - 1, j)
				_fog_upd(i + 1, j)
				_fog_upd(i, j - 1)
				_fog_upd(i, j + 1)

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
	if t - bwm > 8.0:
		bwm = t
		msg("⚠ 기지가 공격받고 있어요! " + ("(기지 버튼으로 보기)" if touch_ui() else "(Q로 기지 보기)"))

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
	u.wh = 0.0
	if u.hp < u.mh and (u.p as Vector2).distance_to(B) <= WELL:
		var wr := 0.03 if t - u.cbt < 3.0 else 0.1
		u.hp = minf(u.mh, u.hp + u.mh * wr * dt)
		u.wh = wr
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
			if t - mdm > 6.0:
				mdm = t
				msg("⛏ 광산이 바닥나서 채굴 로봇이 기지로 돌아와요. 다른 광산을 지정해 주세요")
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
				if t - mdm > 6.0:
					mdm = t
					msg("⛏ 광산이 바닥나서 채굴 로봇이 기지에 대기해요. 다른 광산을 지정해 주세요")

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
	msg("🚨 " + nm + " 레이드 출현! " + str(n) + "마리가 기지로 몰려와요 (Lv " + str(lv) + ")")

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
		msg(("⚠ 진화한 로봇이 있어요. 진화석은 절반만 돌려받아요. " if s.any(func(q): return int(q.ev) > 0) else "") + "한 번 더 누르면 " + str(s.size()) + "대를 판매해요")
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
	sfx("ore")
	msg("로봇 " + str(s.size()) + "대를 판매했어요 · 광석 +" + str(v) + ("" if sv == 0 else " · 진화석 +" + str(sv)))

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
	if not touch_ui():
		# PC는 웹과 똑같이: 로봇 바로 위(20 이내)를 누르면 그 로봇 하나만 선택 · 나머지는 명령
		var pu = nearest(w, bots, 20.0)
		if pu != null:
			clear_sel()
			pu.sel = true
			return
		_command(w)
		return
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
	_command(w)

func _command(w: Vector2) -> void:
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
	if s.any(func(q): return q.t != "s") and not seen(w):
		msg("어두운 곳으로는 정찰 로봇만 갈 수 있어요")
		var sc: Array = s.filter(func(q): return q.t == "s")
		if not sc.is_empty():
			command_move(sc, w)
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
	# PC 우클릭 (웹과 같음): 거의 안 끌었으면 가까운 로봇 하나만 선택 · 빈 곳이면 선택 해제
	if not touch_ui() and r.size.x < 8.0 and r.size.y < 8.0:
		var nu = nearest(box_a, bots, 24.0)
		if nu == null:
			if not add:
				clear_sel()
			return
		if not add:
			clear_sel()
		nu.sel = true
		return
	if r.size.length() < 8.0:
		r = r.grow(22.0)
	var hit_: Array = bots.filter(func(u): return r.has_point(u.p))
	if hit_.is_empty():
		if not add and not touch_ui():
			clear_sel()
		return
	if not add:
		clear_sel()
	for u in hit_:
		u.sel = true
	if touch_ui():
		msg(str(hit_.size()) + "대를 묶었어요 · 땅을 누르면 이동, 적을 누르면 공격해요")

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

const CMDS := [["all", "E", "전체", "[E] 모든 로봇 선택"], ["home", "Q", "기지", "[Q / Home] 기지로 화면 이동"], ["shop", "Y", "상점", "[Y] 상점 열기 · 닫기"], ["info", "I", "정보", "[I] 이번 게임 기록"]]

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
	if paused and pause_set:
		var G := _pset_geo()
		var r: Rect2 = G.r
		var x := r.position.x + 24.0
		var w := r.size.x - 48.0
		for i in 3:
			var k: String = ["vol_s", "vol_b", "uis"][i]
			_add("gsl", Rect2(x + 92.0 - 11.0, r.position.y + 70.0 + i * 50.0, w - 92.0 - 60.0 + 22.0, 34.0), true, "", k)
		var by := r.position.y + 70.0 + 150.0 + 10.0
		_add("gmute", Rect2(x, by, (w - 10.0) / 2.0, 44.0))
		_add("keys", Rect2(x + (w + 10.0) / 2.0, by, (w - 10.0) / 2.0, 44.0))
		_add("gbgm", Rect2(x, by + 54.0, w, 44.0))
		_add("psback", Rect2(x, by + 108.0, w, 46.0))
		return
	if paused:
		var py := u.y / 2.0 - 70.0
		for i in 4:
			_add(["resume", "pset", "tolobby", "endg"][i], Rect2(u.x / 2.0 - 130.0, py + i * 62.0, 260.0, 52.0))
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
	if float(u.get("wh", 0.0)) > 0.0:
		return "우물 회복 중" if u.wh > 0.05 else "전투 중 (기지)"
	if u.get("rw", false):
		return "우물로 귀환 중"
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
			pause_set = false
		"pset":
			pause_set = true
		"psback":
			pause_set = false
			_apply_sv()
			sv_save()
		"gsl":
			slider_drag = it.arg
			_slider_set(it.arg, get_viewport().get_mouse_position())
		"gmute":
			SV.mute = not SV.mute
			_apply_sv()
			sv_save()
		"gbgm":
			var O := _bgm_opts()
			var i := O.find(str(SV.get("bgm", "auto")))
			SV.bgm = O[(i + 1) % O.size()]
			sv_save()
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
	if paused and pause_set:
		_pset_draw(f, hov)
	elif paused:
		draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
		draw_string(f, Vector2(0, u.y / 2.0 - 100.0), "일시정지", HORIZONTAL_ALIGNMENT_CENTER, u.x, 34, GOLD)
		for it in ui:
			var lb: String = {"resume": "계속하기", "pset": "설정", "tolobby": "저장하고 로비로", "endg": "게임 종료"}.get(it.id, "")
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
const SAVE_P := "user://test_save.dat" if TEST else "user://save.dat"
const SV_P := "user://test_sv.dat" if TEST else "user://sv.dat"
var scene := "lobby"
var lsec := "main"
var lmsg := ""
const SV_BASE := {"cs": 0, "ss": 0, "vol_s": 70, "vol_b": 35, "mute": false, "uis": 100, "tut_done": false}
var SV := SV_BASE.duplicate(true)
var acct = null
var adm = null
var bat = null
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

func sv_save(from_cloud: bool = false) -> void:
	var f := FileAccess.open(SV_P, FileAccess.WRITE)
	if f != null:
		f.store_var(SV)
	if not from_cloud and acct != null:
		acct.mark()

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
	if acct != null:
		acct.mark()

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
	for j in GN:
		for i in GN:
			_fog_upd(i, j)
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

# ── 내 기록 (대전 화면) ──
func _rec_stats(t0: float) -> void:
	if not (won or lost):
		return
	if not (SV.get("st") is Dictionary):
		SV.st = {}
	var S: Dictionary = SV.st
	S.pl = int(S.get("pl", 0)) + 1
	S.cap = int(S.get("cap", 0)) + captured()
	if won:
		S.w = int(S.get("w", 0)) + 1
		var sec := int(t0)
		if int(S.get("best", 0)) <= 0 or sec < int(S.best):
			S.best = sec
	else:
		S.l = int(S.get("l", 0)) + 1
	if acct != null:
		acct.pub_push()

func cs_gain() -> int:
	var g := int(float(SS.earn) * 0.04)
	for o in outs:
		if o.cap:
			g += 10 * (int(o.tr) + 1)
	return g

func end_game(retry: bool = false) -> void:
	var t0 := t
	_rec_stats(t0)
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
	_build_lobby0()
	if not _cos_on():
		if not box_res.is_empty():
			_build_box()
		elif cash_sel >= 0:
			_build_cash()
	if box_res.is_empty() and cash_sel < 0 and not acp_open:
		_add("lprof", _prof_rect())
		if not _cos_on() and lsec == "main":
			for t in _tb_list():
				_add(t[0], t[1])
	if acp_open:
		_build_acp()

func _build_lobby0() -> void:
	if _cos_on():
		_build_cos()
		if not box_res.is_empty():
			_build_box()
		elif cash_sel >= 0:
			_build_cash()
		return
	var u := ui_size()
	var W := _lobby_w()
	var x0 := (u.x - W) / 2.0
	if lsec == "main":
		var cw := W * 0.55
		var cr := Rect2(x0, 205.0, cw, 312.0)
		# 게임 모드 고르기 + 플레이
		var mw := (cw - 40.0 - 16.0) / 3.0
		for i in 3:
			_add("lmode", Rect2(cr.position.x + 20.0 + i * (mw + 8.0), cr.end.y - 132.0, mw, 44.0), true, "", i)
		_add("lplay", Rect2(cr.position.x + 20.0, cr.end.y - 76.0, cw - 40.0, 58.0))
		var tx := x0 + cw + 12.0
		var tw := (W - cw - 24.0) / 2.0
		var names := ["lshop", "lstore", "lpass", "lbattle"]
		for i in 4:
			_add(names[i], Rect2(tx + (i % 2) * (tw + 12.0), 205.0 + int(i / 2) * 162.0, tw, 150.0))
		_add("lnotes", Rect2(x0, 529.0, cw, 42.0))
		if upd_url != "":
			_add("lupd", Rect2(x0 + cw + 12.0, 529.0, W - cw - 12.0, 42.0))
		var PR := promos()
		if not PR.is_empty() and u.y >= 700.0:
			var pr := Rect2(x0, 583.0, W, minf(118.0, u.y - 595.0))
			_add("lpromo", pr, true, "", PR[promo_i % PR.size()])
			for i in PR.size():
				_add("pdot", Rect2(pr.end.x - 18.0 - (PR.size() - 1 - i) * 18.0, pr.end.y - 18.0, 12.0, 12.0), true, "", i)
	else:
		var pr := _lsec_rect()
		_add("lback", Rect2(pr.end.x - 130.0, pr.end.y - 54.0, 116.0, 40.0))

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
	_page_bg(Rect2(Vector2.ZERO, u))
	ui.clear()
	var tq := Time.get_ticks_usec()
	_build_lobby()
	_pf("l_build_" + lsec, tq)
	var hov = null if touch_ui() else ui_hit(mouse_ui * us)
	if _cos_on():
		tq = Time.get_ticks_usec()
		_lobby_cos(f, hov)
		_pf("l_draw_" + lsec, tq)
	elif lsec == "main":
		_lobby_main(f, hov)
	elif lsec == "notes":
		_lobby_notes(f, hov)
	if not _cos_on():
		_logo(f)
	if not box_res.is_empty():
		_box_overlay(f, hov)
	elif cash_sel >= 0:
		_cash_overlay(f, hov)
	if acp_open:
		_acp_draw(f, hov)
	if keys_open:
		_keys_win(f)
	if conn_msg != "":
		_conn_draw(f)
	elif booting():
		_boot_toast(f)

func _logo(f: Font, small: bool = false) -> void:
	var u := ui_size()
	var hv0 = null if touch_ui() else ui_hit(mouse_ui * us)
	_prof_card(f, hv0)
	var tby := 22 + _safe_top()
	if not _cos_on() and lsec == "main" and not acp_open:
		_tb_draw(hv0)
		tby += 54.0
	if TEST:
		draw_string(fb(), Vector2(0, tby), "테스트 모드 · 재화 무한 · 클라우드 저장 꺼짐  ", HORIZONTAL_ALIGNMENT_RIGHT, u.x, 12, Color("#ff9a5a"))
	var cy := 134.0
	if small:
		_spaced(fb(), "SOROK", u.x / 2.0, 54.0, 42, 0.32, Color("#5c4316"))
		_spaced(fb(), "SOROK", u.x / 2.0, 51.0, 42, 0.32, Color("#e8c36a"))
		cy = 64.0
	else:
		_spaced(fb(), "SOROK", u.x / 2.0, 86.0, 64, 0.32, Color("#5c4316"))
		_spaced(fb(), "SOROK", u.x / 2.0, 81.0, 64, 0.32, Color("#e8c36a"))
		draw_string(f, Vector2(0, 111), "외 계  기 지  정 복  전 략", HORIZONTAL_ALIGNMENT_CENTER, u.x, 12, Color("#7f8d99"))
		cy = 124.0
	var chips := [["청석", str(SV.cs), Color("#7fd2ff"), Color("#3a4a58")], ["별석", str(SV.ss), Color("#d2a8ff"), Color("#6a4a9a")]]
	var cwid: Array = []
	var ctot := 0.0
	for ch_ in chips:
		var w0: float = 36.0 + _tw(ch_[0], 13) + 8.0 + _tw(ch_[1], 21, true)
		cwid.append(w0)
		ctot += w0
	var cx0 := u.x / 2.0 - (ctot + 5.0) / 2.0
	for i in 2:
		var r := Rect2(cx0, cy, cwid[i], 37.0)
		cx0 += cwid[i] + 5.0
		draw_rect(r, Color("#10151a"))
		draw_rect(r, chips[i][3], false, 1.0)
		draw_string(f, r.position + Vector2(18, 24), chips[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#7f8d99"))
		draw_string(fb(), r.position + Vector2(26.0 + _tw(chips[i][0], 13), 26), chips[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, chips[i][2])
	if lmsg != "":
		draw_string(f, Vector2(0, 122.0 if small else 191.0), lmsg, HORIZONTAL_ALIGNMENT_CENTER, u.x, 14, Color("#e0a44a"))

# ── 오른쪽 위 아이콘 줄: (운영자) · 우편함 · 공지 · 설정 · 계정 ──
func _mail_n() -> int:
	return acct.mails.size() if acct != null else 0

func _tb_list() -> Array:
	var ids: Array = ["tb_mail", "tb_notice", "tb_set", "tb_acct"]
	if acct != null and acct.is_admin():
		ids.push_front("tb_admin")
	var u := ui_size()
	var S := 46.0
	var x := u.x - 14.0 - S
	var y := 10.0 + _safe_top()
	var out: Array = []
	for i in range(ids.size() - 1, -1, -1):
		out.push_front([ids[i], Rect2(x, y, S, S)])
		x -= S + 8.0
	return out

func _badge(c: Vector2, t: String) -> void:
	var w := maxf(18.0, _tw(t, 11, true) + 10.0)
	_gbox(Rect2(c - Vector2(w / 2.0, 9), Vector2(w, 18)), Color("#e0403a"), 180.0, 9.0, Color("#0e1419"), 2.0)
	draw_string(fb(), Vector2(c.x - w / 2.0, c.y + 4.5), t, HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color.WHITE)

func _tb_draw(hov) -> void:
	var tips := {"tb_admin": "운영자", "tb_mail": "우편함", "tb_notice": "공지", "tb_set": "설정", "tb_acct": "계정"}
	for t in _tb_list():
		var r: Rect2 = t[1]
		var h: bool = hov != null and hov.id == t[0]
		var adm_: bool = t[0] == "tb_admin"
		_gbox(r, Color("#2a2410") if adm_ else (Color("#223040") if h else Color("#1a2430")), 180.0, 12.0, Color("#c9a255") if (h or adm_) else Color("#2c3a49"))
		_tb_icon(t[0], r.get_center() + Vector2(0, -3), 22.0)
		draw_string(f_(), Vector2(r.position.x, r.end.y - 4.0), tips[t[0]], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color("#ffd76a") if adm_ else Color("#9fb3c2"))
		if t[0] == "tb_mail" and _mail_n() > 0:
			_badge(Vector2(r.end.x - 4.0, r.position.y + 4.0), str(_mail_n()))
		if t[0] == "tb_notice" and acct != null and acct.notice_new:
			draw_circle(Vector2(r.end.x - 6.0, r.position.y + 6.0), 6.0, Color("#0e1419"))
			draw_circle(Vector2(r.end.x - 6.0, r.position.y + 6.0), 4.5, Color("#e0403a"))

func f_() -> Font:
	return ThemeDB.fallback_font

func _tb_icon(k: String, c: Vector2, s: float) -> void:
	var W := Color("#e6edf3")
	match k:
		"tb_mail":
			var r := Rect2(c.x - s * 0.48, c.y - s * 0.32, s * 0.96, s * 0.64)
			_gbox(r, Color("#e8eef2"), 180.0, s * 0.08)
			draw_polyline(PackedVector2Array([r.position + Vector2(2, 2), Vector2(c.x, c.y + s * 0.06), Vector2(r.end.x - 2, r.position.y + 2)]), Color("#5a6a7a"), maxf(1.5, s * 0.08), true)
			draw_rect(Rect2(c.x - s * 0.48, c.y - s * 0.32, s * 0.96, s * 0.1), Color("#e05a4a"))
		"tb_notice":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, -s * 0.14), c + Vector2(s * 0.28, -s * 0.42), c + Vector2(s * 0.28, s * 0.42), c + Vector2(-s * 0.36, s * 0.14)]), Color("#ffc83a"))
			draw_rect(Rect2(c.x - s * 0.5, c.y - s * 0.16, s * 0.18, s * 0.32), Color("#e8a62a"))
			draw_rect(Rect2(c.x - s * 0.3, c.y + s * 0.12, s * 0.14, s * 0.34), Color("#c98a1a"))
			draw_arc(c + Vector2(s * 0.3, 0), s * 0.2, -0.9, 0.9, 8, W, 1.5, true)
		"tb_set":
			for i in 8:
				var a := TAU * i / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * s * 0.22, c + d * s * 0.46, Color("#b8c6d2"), s * 0.18)
			draw_circle(c, s * 0.32, Color("#b8c6d2"))
			draw_circle(c, s * 0.13, Color("#1a2430"))
		"tb_acct":
			draw_circle(c + Vector2(0, -s * 0.16), s * 0.2, Color("#ffd76a"))
			var P0 := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				P0.append(c + Vector2(0, s * 0.46) + Vector2(cos(a) * s * 0.38, sin(a) * s * 0.34))
			draw_colored_polygon(P0, Color("#ffd76a"))
		"tb_admin":
			var P := PackedVector2Array([c + Vector2(0, -s * 0.48), c + Vector2(s * 0.42, -s * 0.3), c + Vector2(s * 0.36, s * 0.12), c + Vector2(0, s * 0.5), c + Vector2(-s * 0.36, s * 0.12), c + Vector2(-s * 0.42, -s * 0.3)])
			draw_colored_polygon(P, Color("#ffc83a"))
			draw_colored_polygon(PackedVector2Array([P[0], P[1], P[2], P[3]]), Color("#e8a62a"))
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.16, 0), c + Vector2(-s * 0.03, s * 0.14), c + Vector2(s * 0.2, -s * 0.14)]), Color("#3a2a06"), maxf(1.5, s * 0.1), true)

var lmode := 0     # 로비에서 고른 게임 모드 (0 일반전 · 1 경쟁전 · 2 사용자 설정)
func _ask_cont() -> void:
	var v: VBoxContainer = acct._overlay("일반전", 460)
	acct._label(v, "하던 판이 있어요 · 어떻게 할까요?", 14, Color("#3a424c"))
	acct._btn(v, "▶ 이어하기", func():
		acct.close_overlay()
		start_game(true), true)
	acct._btn(v, "새 게임 (하던 판은 사라져요)", func():
		acct.close_overlay()
		start_game(false))
	acct._btn(v, "취소", acct.close_overlay)

var promo_i := 0
var promo_t := 0.0
func promos() -> Array:
	var P: Array = []
	var day := int(Time.get_unix_time_from_system() / 86400.0)
	var lv := bp_lv()
	if SV.fbox > 0:
		var tl: Array = TS.filter(func(q): return not q.has("ex"))
		P.append({"c": "g", "tag": "선물 도착", "t": "무료 소로 상자 " + str(SV.fbox) + "개", "d": "배틀패스에서 받은 상자가 기다리고 있어요 · 지금 바로 열어 보세요", "b": "상자 열러 가기", "go": "box", "pv": ["t", tl[day % tl.size()].id]})
	if SV.sfrag >= 30:
		P.append({"c": "s", "tag": "★ 별 파편 30개 달성", "t": "걸작을 제작할 수 있어요", "d": "원하는 걸작 로봇·기지·테마를 골라 바로 만들어 보세요", "b": "걸작 제작하기", "go": "star", "pv": ["mset", day % 3]})
	var pass_ := {"c": "s", "tag": "배틀패스 · " + SEASON.n, "t": "패스 전용 은하 세트", "d": ("프리미엄 진행 중 · " + str(lv) + " / 30단계 · 30단계에 은하 사령관") if bp().prem else "청석 2,000으로 프리미엄 해금 · 10 · 20 · 30단계에서 은하 세트 획득", "b": "배틀패스 보기", "go": "pass", "pv": ["set", {"r": "k11", "b": "b12", "t": "tk11"}]}
	var S: Dictionary = MSET[(day + 1) % 3]
	var star := {"c": "s", "tag": "★ 걸작 · 별 뽑기 한정", "t": S.n, "d": item(S.r).n + " · " + item(S.b).n + " · " + item(S.t).n + " · 로봇 모양부터 기지까지 완전히 새로운 모습", "b": "별 뽑기 보러 가기", "go": "star", "pv": ["mset", (day + 1) % 3]}
	var K: Array = SK.filter(func(q): return q.g == "kro" and not q.has("ex"))
	var k: Dictionary = K[day % K.size()]
	var dly := {"c": "g", "tag": "오늘의 추천 스킨", "t": k.n, "d": k.d + " · 크로 등급 · 청석 " + str(k.p) + (" · 보유 중" if owns(k.id) else ""), "b": "로봇 스킨 보기", "go": "r", "pv": ["s", k.id]}
	if bp().prem:
		P.append_array([star, dly, pass_])
	else:
		P.append_array([pass_, star, dly])
	return P

func _promo_draw(f: Font, it: Dictionary, hov) -> void:
	var r: Rect2 = it.r
	var q: Dictionary = it.arg
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(1)
	sb.bg_color = Color("#1a1430") if q.c == "s" else Color("#1c1a10")
	sb.border_color = Color("#8a6ad0") if q.c == "s" else Color("#c9a255")
	sb.draw(get_canvas_item(), r)
	var pw := minf(r.size.y * 1.66, 220.0)
	draw_preview(Rect2(r.position + Vector2(8, 8), Vector2(pw - 16.0, (pw - 16.0) * 0.6)), q.pv[0], q.pv[1], t_real)
	var x := r.position.x + pw + 6.0
	draw_string(f, Vector2(x, r.position.y + 24.0), q.tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c79bff") if q.c == "s" else Color("#ffd76a"))
	draw_string(f, Vector2(x, r.position.y + 50.0), q.t, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - pw - 200.0, 19, Color.WHITE)
	draw_string(f, Vector2(x, r.position.y + 74.0), q.d, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - pw - 30.0, 12, Color("#9fb3c2"))
	var br := Rect2(r.end.x - 180.0, r.position.y + 28.0, 164.0, 36.0)
	var gold := StyleBoxFlat.new()
	gold.set_corner_radius_all(6)
	gold.bg_color = Color("#8a5ad8") if q.c == "s" else Color("#d9b04e")
	gold.draw(get_canvas_item(), br)
	draw_string(f, Vector2(br.position.x, br.position.y + 24.0), q.b, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 13, Color.WHITE if q.c == "s" else Color("#2a1a02"))

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
	draw_polygon(PackedVector2Array([Vector2(cr.position.x, cr.position.y + 70), Vector2(cr.end.x, cr.position.y + 70), Vector2(cr.end.x, cr.position.y + 160), Vector2(cr.position.x, cr.position.y + 160)]),
		PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.82), Color(0, 0, 0, 0.82)]))
	draw_rect(Rect2(cr.position.x, cr.position.y + 160, cr.size.x, cr.size.y - 160), Color(0, 0, 0, 0.82))
	draw_rect(cr, Color("#e0b85a"), false, 2.0)
	draw_string(f, cr.position + Vector2(20, 142), "출격 준비 완료", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe6a6"))
	if app_ver != "":
		draw_string(f, Vector2(0, ui_size().y - 10.0), "버전 " + app_ver, HORIZONTAL_ALIGNMENT_RIGHT, ui_size().x - 12.0, 11, Color("#5a6672"))
	draw_string(f, cr.position + Vector2(20, 166), "난이도 어려움 · 로봇 " + skn.get("n", "기본") + " · 기지 " + bsk.get("n", "기본") + " · 테마 " + thm.get("n", "기본"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c9d4dc"))
	var tot := SK.size() + BS.size() + TS.size()
	var own: int = SV.own.size() + SV.bown.size() + SV.town.size()
	var tiles := {"lshop": ["상점", "소로 상자 · ★ 걸작 · 세트", Color("#c9a255")], "lstore": ["창고", "보유 스킨 " + str(own) + " / " + str(tot) + (" · 무료 상자 " + str(SV.fbox) if SV.fbox > 0 else ""), Color("#2f8a78")],
		"lpass": ["배틀패스", SEASON.n + " · " + str(bp_lv()) + " / 30단계" + (" · 프리미엄" if bp().prem else ""), Color("#7a5aa8")], "lset": ["설정", "조작 · 소리 · 데이터", Color("#3a5a8a")],
		"lbattle": ["대전", "게임 모드 · 내 기록 · 랭킹 · 친구" + ((" · 친구 신청 " + str(bat.fr_in.size())) if bat != null and bat.fr_in.size() > 0 else ""), Color("#d0603a")],
		"lmail": ["우편함", ("안 받은 우편 " + str(_mail_n()) + "개 · 눌러서 받기") if _mail_n() > 0 else "운영자 보상 · 알림", Color("#c0503c")]}
	for it in ui:
		var r: Rect2 = it.r
		match it.id:
			"lmode":
				var mi: int = int(it.arg)
				var on := mi == lmode
				var open_ := mi == 0
				var sb0 := StyleBoxFlat.new()
				sb0.set_corner_radius_all(8)
				sb0.set_border_width_all(2 if on else 1)
				sb0.bg_color = Color("#2a2410") if on else (Color("#1a2430") if hov == it else Color(0.06, 0.08, 0.1, 0.85))
				sb0.border_color = Color("#ffd76a") if on else Color(1, 1, 1, 0.16)
				sb0.draw(get_canvas_item(), r)
				var mn: String = ["일반전", "경쟁전", "사용자 설정"][mi]
				draw_string(fb(), Vector2(r.position.x, r.position.y + (21.0 if not open_ else 28.0)), mn, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color("#ffd76a") if on else (Color.WHITE if open_ else Color("#8a98a5")))
				if not open_:
					draw_string(f, Vector2(r.position.x, r.position.y + 37.0), "준비 중", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color("#6a7885"))
			"lplay":
				var gold := StyleBoxFlat.new()
				var ok_ := lmode == 0
				gold.bg_color = (Color("#e8c060") if hov == it else Color("#d9b04e")) if ok_ else Color("#3a3f45")
				gold.set_corner_radius_all(8)
				gold.draw(get_canvas_item(), r)
				draw_string(fb(), Vector2(r.position.x, r.position.y + 38.0), "플레이" if ok_ else "준비 중", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 21, Color("#2a1a02") if ok_ else Color("#8a98a5"))
			"lnew":
				var gold := StyleBoxFlat.new()
				gold.bg_color = Color("#e8c060") if hov == it else Color("#d9b04e")
				gold.set_corner_radius_all(6)
				gold.draw(get_canvas_item(), r)
				draw_string(f, Vector2(r.position.x, r.position.y + 35.0), "새 게임", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color("#2a1a02"))
			"lcont":
				_btn(f, r, "이어하기", hov == it, 18, Color("#ffe6a6"))
			"lpromo":
				_promo_draw(f, it, hov)
			"pdot":
				draw_circle(r.get_center(), 4.0, Color("#ffd76a") if int(it.arg) == promo_i % maxi(1, promos().size()) else Color(1, 1, 1, 0.25))
			"lnotes":
				_btn(f, r, "패치 노트", hov == it, 14)
			"lupd":
				var gold := StyleBoxFlat.new()
				gold.bg_color = Color("#2a6a4a") if hov == it else Color("#1f5a3c")
				gold.border_color = Color("#8be28b")
				gold.set_border_width_all(1)
				gold.set_corner_radius_all(6)
				gold.draw(get_canvas_item(), r)
				draw_string(f, Vector2(r.position.x, r.position.y + 27.0), "새 버전이 나왔어요 · 눌러서 받기", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, Color.WHITE)
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
					if it.id == "lbattle":
						if bat != null and bat.fr_in.size() > 0:
							_badge(Vector2(r.end.x - 14.0, r.position.y + 14.0), str(bat.fr_in.size()))
					if it.id == "lmail":
						_tb_icon("tb_mail", Vector2(r.end.x - 34.0, r.position.y + 34.0), 26.0)
						if _mail_n() > 0:
							_badge(Vector2(r.end.x - 14.0, r.position.y + 14.0), str(_mail_n()))
					draw_string(f, Vector2(r.position.x + 14.0, r.end.y - 42.0), tl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
					draw_string(f, Vector2(r.position.x + 14.0, r.end.y - 20.0), tl[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9fb3c2"))

func _lobby_panel(f: Font, title: String) -> Rect2:
	var pr := _lsec_rect()
	sb_panel.draw(get_canvas_item(), pr)
	draw_string(f, pr.position + Vector2(20, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
	return pr

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
		if it.id in ["sl", "gsl"] and it.arg == key:
			var r: Rect2 = it.r
			var nm: Array = {"uis": [50, 130, 5], "vol_s": [0, 100, 1], "vol_b": [0, 100, 1]}[key]
			var k := clampf((sp.x / us - r.position.x - 11.0) / (r.size.x - 22.0), 0.0, 1.0)
			SV[key] = int(snappedf(nm[0] + k * (nm[1] - nm[0]), nm[2]))
			if key != "uis":
				_apply_sv()
			return

const BOOT_OK := ["lmode", "lshop", "lstore", "lpass", "lset", "lnotes", "lback", "pdot", "lprof", "tb_set", "tb_acct", "tb_notice", "acp_bg", "acp_close", "bgmsel", "bgmx", "lkeys", "sl"]
func lobby_press(it: Dictionary, sp: Vector2) -> void:
	if booting() and not (it.id in BOOT_OK) and not (it.id == "cb" and it.arg is Dictionary and str(it.arg.get("a", "")) in ["tab", "settab", "hf", "sf", "jump", "tprev"]):
		lmsg = "계정 기록을 불러오는 중이에요 · 잠깐만 기다려 주세요"
		sfx("click")
		return
	sfx("click")
	match it.id:
		"lnew": start_game(false)
		"lcont": start_game(true)
		"lmode":
			lmode = int(it.arg)
			if lmode != 0:
				lmsg = ["", "경쟁전은 점수 기준을 정한 뒤에 열려요", "사용자 설정 게임은 멀티플레이 업데이트 때 열려요"][lmode]
		"lplay":
			if lmode != 0:
				lmsg = "이 모드는 아직 준비 중이에요 · 일반전을 골라 주세요"
			elif has_save():
				_ask_cont()
			else:
				start_game(false)
		"lset":
			lsec = "set"
			set_tab = "a"
			lob_scroll = 0.0
		"lnotes":
			lsec = "notes"
			lob_scroll = 0.0
		"lprof", "tb_acct":
			acp_show()
		"tb_mail", "lmail":
			acct.open_mailbox()
		"lbattle":
			bat.open()
		"tb_notice":
			acct.show_notice()
		"tb_set":
			lsec = "set"
			set_tab = "a"
			lob_scroll = 0.0
		"tb_admin":
			adm.open()
		"acp_bg", "acp_close", "acp_login", "acp_out", "acp_save", "acp_vsend", "acp_reset", "acp_admin", "acp_srv":
			acp_press(it.id)
		"pdot":
			promo_i = int(it.arg)
			promo_t = t_real
		"lpromo":
			var go: String = it.arg.go
			if go == "pass":
				lsec = "pass"
				pass_init = true
			else:
				lsec = "shop"
				shop_tab2 = go
			lob_scroll = 0.0
		"lupd":
			OS.shell_open(upd_url)
			lmsg = "새 버전을 받는 중이에요 · 받은 파일을 실행해서 설치해 주세요"
		"lshop", "lstore", "lpass":
			lsec = {"lshop": "shop", "lstore": "store", "lpass": "pass"}[it.id]
			lob_scroll = 0.0
			pass_init = true
			lmsg = ""
		"cb":
			cos_press(it.arg)
		"boxok", "boxskip":
			if box_busy():
				box_t0 = t_real - 100.0
				box_shown = box_res.size()
			elif it.id == "boxok":
				box_res = []
				box_scroll = 0.0
		"cashno":
			cash_sel = -1
		"cashok":
			if cash_sel >= 0:
				var P: Dictionary = CASH[cash_sel]
				SV.cs += int(P.a)
				SV.paid = int(SV.get("paid", 0)) + int(P.w)
				lmsg = "청석 " + _cm(P.a) + "개 충전 완료!"
				sv_save()
			cash_sel = -1
		"bgmsel":
			bgm_open = not bgm_open
		"bgmx":
			bgm_open = false
		"bgmopt":
			SV.bgm = str(it.arg)
			bgm_open = false
			sv_save()
		"lback":
			lsec = "main"
			lob_scroll = 0.0
			_apply_sv()
			sv_save()
		"ltut": start_game(false, true)
		"lmute":
			SV.mute = not SV.mute
			_apply_sv()
			sv_save()
		"lkeys": keys_open = true
		"lacct":
			acp_show()
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
		elif e.keycode == KEY_ESCAPE and acp_open:
			acp_open = false
		elif e.keycode == KEY_ESCAPE and bgm_open:
			bgm_open = false
		elif e.keycode == KEY_ESCAPE and cash_sel >= 0:
			cash_sel = -1
		elif e.keycode == KEY_ESCAPE and not box_res.is_empty():
			if not box_busy():
				box_res = []
		elif e.keycode == KEY_ESCAPE and lsec != "main":
			lsec = "main"
			lob_scroll = 0.0
			_apply_sv()
			sv_save()
		return
	var pos = null
	var pressed := false
	var released := false
	if e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dd := -60.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 60.0
			if not e.pressed:
				return
			if not box_res.is_empty():
				box_scroll = clampf(box_scroll + dd, 0.0, box_max)
			elif lsec == "pass" and (e.shift_pressed or pass_tr.has_point(e.position / us)):
				pass_scroll = clampf(pass_scroll + dd * 1.5, 0.0, _pass_max())
			elif _cos_on() and not bgm_open:
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
		elif lob_drag != null and lob_drag.get("mouse", false):
			_drag_move(e.position, e.relative)
		return
	elif e is InputEventScreenDrag:
		if slider_drag != null:
			_slider_set(slider_drag, e.position)
		elif lob_drag != null:
			_drag_move(e.position, e.relative)
		return
	if pos == null:
		return
	var touch := e is InputEventScreenTouch
	if released:
		if slider_drag != null:
			if slider_drag == "uis":
				_apply_sv()
			slider_drag = null
			lob_drag = null
			sv_save()
		elif lob_drag != null:
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
		if not acp_open and _sb_start(pos):
			lob_drag.mouse = not touch
			return
		lob_drag = {"p": pos, "m": false, "mouse": not touch}
		if it != null and it.id == "sl":
			lobby_press(it, pos)

func _sb_start(pos: Vector2) -> bool:
	var p := pos / us
	for k in [["box", sb_box], ["lob", sb_lob], ["pass", sb_pass]]:
		var d: Dictionary = k[1]
		if d.is_empty():
			continue
		if (k[0] == "box") == box_res.is_empty():
			continue
		if k[0] == "pass" and lsec != "pass":
			continue
		if k[0] == "lob" and not _cos_on():
			continue
		if (d.r as Rect2).grow(10.0).has_point(p):
			lob_drag = {"p": pos, "m": true, "sb": k[0], "s0": {"box": box_scroll, "lob": lob_scroll, "pass": pass_scroll}[k[0]]}
			return true
	return false

func _drag_move(pos: Vector2, rel: Vector2) -> void:
	if lob_drag.has("sb"):
		var d: Dictionary = {"box": sb_box, "lob": sb_lob, "pass": sb_pass}[lob_drag.sb]
		if d.is_empty():
			return
		var r: Rect2 = d.r
		var hz: bool = lob_drag.sb == "pass"
		var span: float = maxf(1.0, (r.size.x if hz else r.size.y) - float(d.th))
		var dl: float = ((pos.x - lob_drag.p.x) if hz else (pos.y - lob_drag.p.y)) / us
		var mx: float = {"box": box_max, "lob": lob_max, "pass": _pass_max()}[lob_drag.sb]
		var v := clampf(float(lob_drag.s0) + dl / span * mx, 0.0, mx)
		match lob_drag.sb:
			"box": box_scroll = v
			"lob": lob_scroll = v
			"pass": pass_scroll = v
		return
	if (pos - lob_drag.p).length() > 12.0:
		lob_drag.m = true
	if lob_drag.m:
		if not box_res.is_empty():
			box_scroll = clampf(box_scroll - rel.y / us, 0.0, box_max)
		elif lsec == "pass" and pass_tr.has_point(lob_drag.p / us):
			pass_scroll = clampf(pass_scroll - rel.x / us, 0.0, _pass_max())
		elif _cos_on() and not acp_open:
			lob_scroll = clampf(lob_scroll - rel.y / us, 0.0, lob_max)

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

func _num(v, d: int = 0) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is String and v.is_valid_float():
		return int(float(v))
	return d

func _sv_defaults() -> void:
	# 웹에서 온 기록은 칸이 비었거나 모양이 다를 수 있어서 하나하나 고쳐요
	for k in ["own", "bown", "town", "hist"]:
		if not (SV.get(k) is Array):
			SV[k] = []
	SV.hist = SV.hist.filter(func(h): return h is Dictionary and h.has("x"))
	for k in ["eq", "beq", "teq"]:
		if not (SV.get(k) is String):
			SV[k] = ""
	if SV.eq != "" and _find_in(SK, SV.eq).is_empty():
		SV.eq = ""
	if SV.beq != "" and _find_in(BS, SV.beq).is_empty():
		SV.beq = ""
	if SV.teq != "" and _find_in(TS, SV.teq).is_empty():
		SV.teq = ""
	if not (SV.get("frag") is Dictionary):
		SV.frag = {}
	for k in SV.frag.keys():
		SV.frag[k] = _num(SV.frag[k])
	for k in ["fbox", "sfrag", "spity", "ss", "cs"]:
		SV[k] = _num(SV.get(k, 0))
	SV.vol_s = clampi(_num(SV.get("vol_s", 70), 70), 0, 100)
	SV.vol_b = clampi(_num(SV.get("vol_b", 35), 35), 0, 100)
	SV.uis = clampi(_num(SV.get("uis", 100), 100), 50, 130)
	SV.mute = SV.get("mute", false) == true
	SV.tut_done = SV.get("tut_done", false) == true
	var B0 = SV.get("bp")
	if B0 is Dictionary and not B0.has("season"):
		B0.season = 1
	if not (B0 is Dictionary) or _num(B0.get("season", 0)) != SEASON.id:
		SV.bp = {"season": SEASON.id, "xp": _num(SV.get("bpxp", 0)), "prem": false, "cf": [], "cp": []}
	var P: Dictionary = SV.bp
	P.season = SEASON.id
	P.xp = _num(P.get("xp", 0))
	P.prem = P.get("prem", false) == true
	for k in ["cf", "cp"]:
		var a = P.get(k)
		P[k] = (a as Array).map(func(x): return _num(x)) if a is Array else []
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
		var g := ""
		if k == "box":
			if q.res == "jack":
				g = "jack"
				x = q.it.n + " (크로 세트 통째로)"
			else:
				g = "base" if q.g == "b" else q.g
				x = q.it.n + " 파편 ×" + str(q.amt) + (" → 완성" if q.res == "done" else (" → 보유 중, 청석 +" + str(q.v) if q.res == "dup" else " (" + str(q.get("c", 0)) + "/" + str(q.get("need", 0)) + ")"))
		else:
			g = "star" if q.res in ["star", "starx"] else "sf"
			x = ("★ 걸작 완품 · " + q.it.n) if q.res == "star" else ("★ 걸작 완품 (모두 보유) → 별 파편 +30" if q.res == "starx" else "★ 별 파편 ×" + str(q.a))
		SV.hist.push_front({"t": now * 1000, "k": k, "g": g, "x": x})
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


# ═════════ 꾸미기 화면: 상점 · 창고 · 배틀패스 · 설정 · 상자 열기 (웹 .lsec 모양 그대로) ═════════
var shop_tab2 := "box"
var stF := {"own": [], "cat": [], "gr": []}
var hF := "all"
var set_tab := "a"
var lob_draw: Array = []
var lob_max := 0.0
var pass_scroll := 0.0
var pass_init := false
var pass_tr := Rect2()
var lob_drag = null
var cash_sel := -1
var bgm_open := false
var bgm_prev_id := ""
var bgm_prev_u := 0.0
var box_scroll := 0.0
var box_max := 0.0
var box_vp := Rect2()
var FB: Font = null
var _cl: Array = []
var cos_pr := Rect2()
var cos_vp := Rect2()
var cos_hdr: Array = []
var _gtex := {}
const CASH := [{"a": 100, "bn": 0, "w": 1200}, {"a": 550, "bn": 50, "w": 5900}, {"a": 1200, "bn": 200, "w": 11000}, {"a": 2600, "bn": 600, "w": 25000}, {"a": 6500, "bn": 1500, "w": 55000}]
const PBG := Color("#12181e")

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
			var S: Dictionary = id if id is Dictionary else (SETS if kind == "set" else MSET)[int(id)]
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

# ── 그리기 도구: 굵은 글씨 · 둥근 상자 · 그라데이션 · 빛 ──
func fb() -> Font:
	if FB == null:
		var v := FontVariation.new()
		v.base_font = ThemeDB.fallback_font
		v.variation_embolden = 0.65
		FB = v
	return FB

var _tw_c := {}
func _tw(s: String, fs: int, bold: bool = false) -> float:
	var key := "%s|%d|%d" % [s, fs, 1 if bold else 0]
	var v = _tw_c.get(key)
	if v != null:
		return v
	if _tw_c.size() > 6000:
		_tw_c.clear()
	var w: float = (fb() if bold else ThemeDB.fallback_font).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_tw_c[key] = w
	return w

func _cm(n) -> String:
	var s := str(absi(int(n)))
	var o := ""
	while s.length() > 3:
		o = "," + s.substr(s.length() - 3) + o
		s = s.substr(0, s.length() - 3)
	return ("-" if int(n) < 0 else "") + s + o

# 둥근 상자 모서리: 같은 크기·둥글기는 한 번만 계산해 두고 옮겨서 써요
var _rr_c := {}
func _rr_pts(r: Rect2, rad) -> PackedVector2Array:
	var key := Vector4(r.size.x, r.size.y, float(rad[0]) if rad is Array else float(rad), (float(rad[1]) * 1000.0 + float(rad[2]) * 1000000.0 + float(rad[3]) * 1000000000.0) if rad is Array else -1.0)
	var P = _rr_c.get(key)
	if P == null:
		if _rr_c.size() > 3000:
			_rr_c.clear()
		P = _rr_pts0(Rect2(Vector2.ZERO, r.size), rad)
		_rr_c[key] = P
	return Transform2D(0.0, r.position) * (P as PackedVector2Array)

func _rr_pts0(r: Rect2, rad) -> PackedVector2Array:
	var R: Array = rad if rad is Array else [rad, rad, rad, rad]
	var m := minf(r.size.x, r.size.y) / 2.0
	var P := PackedVector2Array()
	var cs := [[Vector2(r.end.x, r.position.y), Vector2(-1, 1), -PI / 2.0, R[1]], [r.end, Vector2(-1, -1), 0.0, R[2]], [Vector2(r.position.x, r.end.y), Vector2(1, -1), PI / 2.0, R[3]], [r.position, Vector2(1, 1), PI, R[0]]]
	for c in cs:
		var rr := minf(float(c[3]), m)
		if rr <= 0.5:
			P.append(c[0])
			continue
		var o: Vector2 = c[0] + c[1] * rr
		for i in 6:
			var a: float = c[2] + i * (PI / 2.0) / 5.0
			P.append(o + Vector2(cos(a), sin(a)) * rr)
	var Q := PackedVector2Array()
	for p in P:
		if Q.is_empty() or (p - Q[Q.size() - 1]).length_squared() > 0.01:
			Q.append(p)
	while Q.size() > 3 and (Q[0] - Q[Q.size() - 1]).length_squared() <= 0.01:
		Q.remove_at(Q.size() - 1)
	return Q

func _gt(stops: Array) -> Texture2D:
	var key := stops.hash()
	if _gtex.has(key):
		return _gtex[key]
	var g := Gradient.new()
	var O := PackedFloat32Array()
	var Cs := PackedColorArray()
	for s in stops:
		O.append(float(s[0]))
		Cs.append(s[1])
	g.offsets = O
	g.colors = Cs
	var tx := GradientTexture1D.new()
	tx.gradient = g
	tx.width = 256
	_gtex[key] = tx
	return tx

# CSS linear-gradient(ang, …) 와 같은 방식 · stops = [[0, 색], [1, 색]] 또는 색 하나
func _gbox(r: Rect2, stops, ang: float = 180.0, rad = 0.0, bc: Color = Color(0, 0, 0, 0), bw: float = 1.0, dash: bool = false) -> void:
	if r.size.x < 1.0 or r.size.y < 1.0:
		return
	var P := _rr_pts(r, rad)
	if P.size() < 3:
		return
	if stops is Color:
		draw_colored_polygon(P, stops)
	else:
		var d := Vector2(sin(deg_to_rad(ang)), -cos(deg_to_rad(ang)))
		var L := maxf(0.001, absf(r.size.x * d.x) + absf(r.size.y * d.y))
		var cen := r.get_center()
		var uv := PackedVector2Array()
		var cols := PackedColorArray()
		for p in P:
			uv.append(Vector2(clampf((p - cen).dot(d) / L + 0.5, 0.002, 0.998), 0.5))
			cols.append(Color.WHITE)
		draw_polygon(P, cols, uv, _gt(stops))
	if bc.a > 0.0:
		if dash:
			var g := r.grow(-bw / 2.0)
			var Q := [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y), g.position]
			for i in 4:
				draw_dashed_line(Q[i], Q[i + 1], bc, bw, 4.0)
		else:
			var B := _rr_pts(r.grow(-bw / 2.0), (rad if rad is Array else maxf(0.0, float(rad) - bw / 2.0)))
			B.append(B[0])
			draw_polyline(B, bc, bw, true)

func _g2(a: String, b: String) -> Array:
	return [[0.0, Color(a)], [1.0, Color(b)]]

func _bglow(r: Rect2, col: Color, sz: float, rad: float = 0.0) -> void:
	for i in 5:
		var k := (i + 1) / 5.0
		var P := _rr_pts(r.grow(sz * k), rad + sz * k)
		if P.size() >= 3:
			draw_colored_polygon(P, Color(col, col.a * 0.32 * (1.0 - k * 0.8)))

func _fade(r: Rect2, a: float, col: Color = PBG) -> void:
	if a > 0.0:
		draw_rect(r, Color(col, a))

# 웹 로비 배경 (radial-gradient(ellipse at 50% 25%, …))
func _bg_col(p: Vector2, u: Vector2) -> Color:
	var d := p - Vector2(u.x * 0.5, u.y * 0.25)
	var t := clampf(sqrt(pow(d.x / (u.x * 0.72), 2.0) + pow(d.y / (u.y * 1.06), 2.0)), 0.0, 1.0)
	return Color("#202a35").lerp(Color("#06090c"), t)

func _page_bg(r: Rect2) -> void:
	if r.size.x < 1.0 or r.size.y < 1.0:
		return
	var u := ui_size()
	var nx := 8
	var ny := 6
	for j in ny:
		for i in nx:
			var a := r.position + Vector2(r.size.x * i / nx, r.size.y * j / ny)
			var b := r.position + Vector2(r.size.x * (i + 1) / nx, r.size.y * (j + 1) / ny)
			var P := PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])
			draw_polygon(P, PackedColorArray([_bg_col(P[0], u), _bg_col(P[1], u), _bg_col(P[2], u), _bg_col(P[3], u)]))

# 글자 (자간 · 그림자 · 굵게)
func _dt(e: Dictionary) -> void:
	var f: Font = fb() if e.get("b", false) else ThemeDB.fallback_font
	var fs: int = e.get("fs", 13)
	var p: Vector2 = e.p
	var col: Color = e.get("c", Color("#dfe6ea"))
	var ls: float = e.get("ls", 0.0)
	var ic: String = e.get("ic", "")
	if ic != "":
		_icon(ic, Vector2(p.x + fs * 0.6, p.y - fs * 0.38), fs * 1.05)
		p.x += fs * 1.2 + 4.0
	var al: int = e.get("al", 0)
	if ls > 0.0:
		var w := 0.0
		for ch in e.s:
			w += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs * ls
		if al == 1:
			p.x += (float(e.w) - w) / 2.0
		for ch in e.s:
			if e.has("sh"):
				draw_string(f, p + Vector2(0, float(e.sh[0])), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, e.sh[1])
			draw_string(f, p, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			p.x += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs * ls
		return
	var w2: float = e.get("w", -1.0)
	var ha: HorizontalAlignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][al]
	if e.has("sh"):
		draw_string(f, p + Vector2(0, float(e.sh[0])), e.s, ha, w2, fs, e.sh[1])
	draw_string(f, p, e.s, ha, w2, fs, col)

# 작은 그림 아이콘 (웹의 이모지 자리)
func _icon(k: String, c: Vector2, s: float) -> void:
	match k:
		"gift":
			var r := Rect2(c.x - s * 0.42, c.y - s * 0.22, s * 0.84, s * 0.62)
			draw_rect(r, Color("#e0503c"))
			draw_rect(Rect2(c.x - s * 0.48, c.y - s * 0.4, s * 0.96, s * 0.22), Color("#f06a50"))
			draw_rect(Rect2(c.x - s * 0.08, c.y - s * 0.4, s * 0.16, s * 0.8), Color("#ffd25a"))
			draw_circle(c + Vector2(-s * 0.14, -s * 0.46), s * 0.12, Color("#ffd25a"))
			draw_circle(c + Vector2(s * 0.14, -s * 0.46), s * 0.12, Color("#ffd25a"))
		"scroll":
			draw_rect(Rect2(c.x - s * 0.32, c.y - s * 0.4, s * 0.64, s * 0.8), Color("#e8d4a0"))
			draw_rect(Rect2(c.x - s * 0.42, c.y - s * 0.46, s * 0.84, s * 0.14), Color("#b8945a"))
			draw_rect(Rect2(c.x - s * 0.42, c.y + s * 0.32, s * 0.84, s * 0.14), Color("#b8945a"))
			for i in 3:
				draw_line(Vector2(c.x - s * 0.2, c.y - s * 0.16 + i * s * 0.16), Vector2(c.x + s * 0.2, c.y - s * 0.16 + i * s * 0.16), Color("#8a6a3a"), 1.0)
		"gem":
			var P := PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.42, -s * 0.08), c + Vector2(0, s * 0.46), c + Vector2(-s * 0.42, -s * 0.08)])
			draw_colored_polygon(P, Color("#5ab8f0"))
			draw_colored_polygon(PackedVector2Array([P[0], P[1], c + Vector2(0, -s * 0.08)]), Color("#d8f6ff"))
		"chart":
			draw_rect(Rect2(c.x - s * 0.45, c.y - s * 0.45, s * 0.9, s * 0.9), Color("#e8eef2"))
			var hs := [0.35, 0.6, 0.25]
			var cl := [Color("#e05050"), Color("#3a9ce0"), Color("#3ac07a")]
			for i in 3:
				draw_rect(Rect2(c.x - s * 0.33 + i * s * 0.24, c.y + s * 0.35 - s * float(hs[i]), s * 0.16, s * float(hs[i])), cl[i])
		"crown":
			var P2 := PackedVector2Array([c + Vector2(-s * 0.45, s * 0.3), c + Vector2(-s * 0.45, -s * 0.25), c + Vector2(-s * 0.2, s * 0.02), c + Vector2(0, -s * 0.38), c + Vector2(s * 0.2, s * 0.02), c + Vector2(s * 0.45, -s * 0.25), c + Vector2(s * 0.45, s * 0.3)])
			draw_colored_polygon(P2, Color("#ffc83a"))
			draw_circle(c + Vector2(0, s * 0.12), s * 0.08, Color("#e0503c"))
		"lock":
			draw_arc(c + Vector2(0, -s * 0.12), s * 0.22, PI, TAU, 8, Color("#c9a255"), maxf(1.5, s * 0.1))
			draw_rect(Rect2(c.x - s * 0.32, c.y - s * 0.1, s * 0.64, s * 0.5), Color("#e8c36a"))
			draw_circle(c + Vector2(0, s * 0.12), s * 0.06, Color("#5c4316"))
		"note":
			draw_circle(c + Vector2(-s * 0.18, s * 0.28), s * 0.15, Color("#dfe6ea"))
			draw_circle(c + Vector2(s * 0.28, s * 0.18), s * 0.15, Color("#dfe6ea"))
			draw_line(c + Vector2(-s * 0.05, s * 0.28), c + Vector2(-s * 0.05, -s * 0.38), Color("#dfe6ea"), 1.5)
			draw_line(c + Vector2(s * 0.41, s * 0.18), c + Vector2(s * 0.41, -s * 0.46), Color("#dfe6ea"), 1.5)
			draw_line(c + Vector2(-s * 0.05, -s * 0.38), c + Vector2(s * 0.41, -s * 0.46), Color("#dfe6ea"), 2.0)
		"sparkle":
			var st := PackedVector2Array()
			for i in 10:
				var a := i * PI / 5.0 - PI / 2.0
				st.append(c + Vector2(cos(a), sin(a)) * (s * 0.5 if i % 2 == 0 else s * 0.2))
			draw_colored_polygon(st, Color("#ffd25a"))

# 소로 상자 (.sbx) · 별 상자 (.stbx) · 청석 (.gem)
func _sbx(c: Vector2, sc: float, glow: bool = true) -> void:
	var r := Rect2(c - Vector2(35, 31) * sc, Vector2(70, 62) * sc)
	if glow:
		_bglow(r, Color(0.91, 0.76, 0.42, 0.4), 18.0 * sc, 8.0 * sc)
	_gbox(r, _g2("#e8c36a", "#8a6420"), 180.0, 8.0 * sc, Color("#2a1c08"), 3.0 * sc)
	var ip := r.position + Vector2(3, 3) * sc
	_gbox(Rect2(ip + Vector2(-7, 12) * sc, Vector2(78, 14) * sc), Color("#5c4316"), 180.0, 3.0 * sc, Color("#2a1c08"), 2.0 * sc)
	_gbox(Rect2(ip + Vector2(24, 4) * sc, Vector2(16, 24) * sc), Color("#7fd2ff"), 180.0, 2.0 * sc, Color("#2a1c08"), 2.0 * sc)

func _stbx(c: Vector2, sc: float) -> void:
	var M := inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(PI / 4.0, Vector2(sc, sc), 0.0, c)
	draw_set_transform_matrix(M)
	var r := Rect2(-31, -31, 62, 62)
	_bglow(r, Color(0.75, 0.55, 1.0, 0.6), 22.0, 10.0)
	_gbox(r, [[0.0, Color("#fff1a8")], [0.6, Color("#c08cff")], [1.0, Color("#5a3a8a")]], 135.0, 10.0, Color("#1a0e2a"), 3.0)
	_ui_reset()

func _gem(c: Vector2, s: float) -> void:
	var M := inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(PI / 4.0, Vector2.ONE, 0.0, c)
	draw_set_transform_matrix(M)
	var r := Rect2(-s / 2.0, -s / 2.0, s, s)
	_bglow(r, Color(0.35, 0.7, 1.0, 0.55), 12.0, 3.0)
	_gbox(r, _g2("#d8f6ff", "#3a9ce0"), 135.0, 3.0, Color("#0b1118"), 2.0)
	_ui_reset()

# ── 버튼 모양 (웹 CSS 그대로) ──
const BST := {
	"def": {"g": ["#1b232b"], "h": "#222d37", "b": "#33414d", "r": 2.0, "t": "#dfe6ea", "s": "#8a9bad"},
	"can": {"g": ["#1e4a30", "#123020"], "b": "#3ae07a", "r": 2.0, "t": "#c8ffd8", "s": "#9effa8", "keep": true},
	"go": {"g": ["#e8c36a", "#b8902f"], "b": "#f3d98e", "r": 2.0, "t": "#1c1406", "s": "#1c1406", "bold": true},
	"tab": {"g": ["#141b22"], "b": "#33414d", "r": 8.0, "t": "#dfe6ea", "s": "#8a9bad", "bold": true},
	"tabon": {"g": ["#3a2e14", "#1e180a"], "b": "#e8c36a", "r": 8.0, "t": "#ffe9b8", "s": "#e8c36a", "bold": true, "keep": true},
	"chip": {"g": ["#141b22"], "b": "#33414d", "r": 16.0, "t": "#dfe6ea", "s": "#8a9bad"},
	"chipon": {"g": ["#3a2e14", "#1e180a"], "b": "#e8c36a", "r": 16.0, "t": "#ffe9b8", "s": "#e8c36a", "keep": true},
	"soro": {"g": ["#3a2e14", "#1e180a"], "b": "#8a6d35", "r": 2.0, "t": "#dfe6ea", "s": "#7fd2ff"},
	"spull": {"g": ["#5a3a8a", "#2a1a4a"], "b": "#c08cff", "r": 2.0, "t": "#dfe6ea", "s": "#ffd25a"},
	"prem": {"g": ["#5a3a8a", "#2a1a4a"], "b": "#c08cff", "r": 2.0, "t": "#f0e0ff", "s": "#e8c36a", "bold": true},
	"skip": {"g": ["#24313e", "#141b22"], "b": "#e8c36a", "r": 2.0, "t": "#dfe6ea", "s": "#7fd2ff"},
	"fbx": {"g": ["#2a5a3a", "#123020"], "b": "#7affd4", "r": 2.0, "t": "#dfe6ea", "s": "#7affd4", "keep": true},
	"bpc": {"g": ["#e8c36a", "#b8902f"], "b": "#f3d98e", "r": 2.0, "t": "#1c1406", "s": "#1c1406", "bold": true},
	"red": {"g": ["#1b232b"], "h": "#222d37", "b": "#a8352a", "r": 2.0, "t": "#ff9a8a", "s": "#8a9bad", "keep": true},
	"tpv": {"g": ["#16202a"], "b": "#33414d", "r": 2.0, "t": "#dfe6ea", "s": "#8a9bad"},
	"tpvon": {"g": ["#3a2e14", "#1e180a"], "b": "#ffd76a", "r": 2.0, "t": "#ffe9b8", "s": "#e8c36a", "keep": true, "bold": true},
	"pf": {"g": ["#1c2733"], "h": "#24323f", "b": "#33414d", "r": 8.0, "t": "#e6edf3", "s": "#8a9bad"},
	"pfgo": {"g": ["#e8c36a", "#b8902f"], "b": "#f3d98e", "r": 8.0, "t": "#1c1406", "s": "#1c1406", "bold": true},
	"pfo": {"g": ["#22171a"], "h": "#2c1c20", "b": "#5a2d2d", "r": 8.0, "t": "#ff9a8a", "s": "#8a9bad"},
	"bxsk": {"g": ["#0e1318"], "b": "#3a4a58", "r": 14.0, "t": "#9fb0bf", "s": "#9fb0bf"},
	"mini": {"g": ["#1b232b"], "h": "#222d37", "b": "#33414d", "r": 2.0, "t": "#dfe6ea", "s": "#8a9bad"},
}

func _wbtn(e: Dictionary, hov) -> void:
	var r: Rect2 = e.r
	var S: Dictionary = BST[e.sty]
	var h: bool = hov != null and e.get("it") != null and hov == e.it and e.en
	var G: Array = S.g
	var st = Color(G[0]) if G.size() == 1 else _g2(G[0], G[1])
	if h and S.has("h"):
		st = Color(S.h)
	var bc := Color(S.b)
	if h and not S.get("keep", false):
		bc = Color("#4fd1b5")
	if (e.get("glow", false) and e.en) or e.sty == "tpvon":
		var gk := 0.5 + 0.5 * sin(t_real * 4.0)
		_bglow(r, Color(1.0, 0.84, 0.4, 0.3 + 0.35 * gk), 6.0 + 6.0 * gk, S.r)
		bc = Color("#ffd76a")
	_gbox(r, st, 180.0, S.r, bc, 1.0 if not e.get("glow", false) else 2.0, e.get("dash", false))
	if e.sty == "tpvon":
		var pk := clampf((bgm_prev_u - t_real) / 15.0, 0.0, 1.0)
		draw_rect(Rect2(r.position.x + 2.0, r.end.y - 4.0, (r.size.x - 4.0) * pk, 2.0), Color("#ffd76a"))
	var fs: int = e.get("fs", 13)
	var bold: bool = e.get("bold", S.get("bold", false))
	var l: String = e.get("l", "")
	var sub: String = e.get("sub", "")
	var ic: String = e.get("ic", "")
	var tc := Color(S.t)
	var cy := r.position.y + r.size.y / 2.0
	if e.get("inl", "") != "":
		var w1 := _tw(l, fs, bold) + (fs * 1.1 + 5.0 if ic != "" else 0.0)
		var w2 := _tw(e.inl, 12)
		var x := r.position.x + (r.size.x - w1 - 6.0 - w2) / 2.0
		if ic != "":
			_icon(ic, Vector2(x + fs * 0.55, cy - 1.0), fs * 1.05)
			x += fs * 1.1 + 5.0
		draw_string(fb() if bold else ThemeDB.fallback_font, Vector2(x, cy + fs * 0.36), l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
		draw_string(ThemeDB.fallback_font, Vector2(x + _tw(l, fs, bold) + 6.0, cy + 4.5), e.inl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(S.s))
	else:
		var ly := cy + fs * 0.36 - (8.0 if sub != "" else 0.0)
		var lw := _tw(l, fs, bold)
		var x0 := r.position.x + (r.size.x - lw) / 2.0
		if ic != "":
			x0 = r.position.x + (r.size.x - lw - fs * 1.1 - 5.0) / 2.0
			_icon(ic, Vector2(x0 + fs * 0.55, ly - fs * 0.36), fs * 1.05)
			x0 += fs * 1.1 + 5.0
		draw_string(fb() if bold else ThemeDB.fallback_font, Vector2(x0, ly), l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
		if sub != "":
			draw_string(ThemeDB.fallback_font, Vector2(r.position.x, cy + 14.0), sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color(S.s))
	if not e.en:
		_fade(r.grow(1.0), 0.45, e.get("fc", PBG))

# ── 줄 배치 ──
func _E(e: Dictionary) -> Dictionary:
	lob_draw.append(e)
	return e

func _C(id: String, r: Rect2, arg, e: Dictionary, clip: bool = true) -> void:
	_cl.append([id, r, arg, e, clip])

# 버튼 스펙: {l, s(아래 작은 글씨), a(누르면 할 일), en, cost:["cs"|"ss", n] 또는 "free", sty, fs, ic, dash, w}
func _bnat(b: Dictionary, padx: float) -> float:
	var fs: int = b.get("fs", 13)
	var w := _tw(b.get("l", ""), fs, b.get("bold", BST[b.get("sty", "def")].get("bold", false)))
	if b.get("ic", "") != "":
		w += fs * 1.1 + 5.0
	if b.get("inl", "") != "":
		w += 6.0 + _tw(b.inl, 12)
	return maxf(w, _tw(b.get("s", ""), 12)) + padx * 2.0 + 2.0

func _can(b: Dictionary) -> bool:
	if not b.get("en", true) or not b.has("cost"):
		return false
	if b.cost is String:
		return true
	return (SV.cs if b.cost[0] == "cs" else SV.ss) >= int(b.cost[1])

func _B(r: Rect2, b: Dictionary, clip: bool = true) -> Dictionary:
	var en: bool = b.get("en", true)
	var sty: String = "can" if _can(b) else b.get("sty", "def")
	var e := _E({"k": "btn", "r": r, "l": b.get("l", ""), "sub": b.get("s", ""), "sty": sty, "en": en, "fs": b.get("fs", 13), "ic": b.get("ic", ""), "dash": b.get("dash", false), "inl": b.get("inl", "")})
	if b.has("bold"):
		e.bold = b.bold
	if b.get("on", false):
		e.sty = "tpvon"
	if b.get("glow", false):
		e.glow = true
	if en and b.has("a"):
		if b.a is String:
			_C(b.a, r, b.get("arg"), e, clip)
		else:
			_C("cb", r, b.a, e, clip)
	return e

func _tabs_layout(tabs: Array, x0: float, y: float, W: float, cur: String) -> float:
	# flex: 1 1 auto · 줄바꿈 · 남는 폭은 똑같이 나눠요
	var nat: Array = []
	for tb in tabs:
		nat.append(_bnat({"l": tb[1], "fs": 14, "bold": true, "ic": tb[3], "inl": tb[2]}, 12.0))
	var i := 0
	while i < tabs.size():
		var j := i
		var tot := 0.0
		while j < tabs.size() and (j == i or tot + 6.0 + nat[j] <= W):
			tot += (6.0 if j > i else 0.0) + nat[j]
			j += 1
		var extra := (W - tot) / float(j - i)
		var x := x0
		for k in range(i, j):
			var w: float = nat[k] + extra
			var tb: Array = tabs[k]
			var e := {"k": "btn", "r": Rect2(x, y, w, 42.0), "l": tb[1], "sty": "tabon" if tb[0] == cur else "tab", "en": true, "fs": 14, "ic": tb[3], "inl": tb[2]}
			cos_hdr.append(e)
			e.it = _add("cb", e.r, true, "", {"a": "settab" if lsec == "set" else "tab", "k": tb[0]})
			x += w + 6.0
		y += 48.0
		i = j
	return y - 6.0

func _card_h(c: Dictionary, cw: float) -> float:
	var h := 10.0
	if c.get("cash", false):
		return 10.0 + 54.0 + 26.0 + 16.0 + 5.0 + 36.0 + 8.0
	h += (cw - 18.0) * 0.6 + 5.0 + 18.0
	if c.has("d"):
		var n := _wrap(ThemeDB.fallback_font, c.d, 12, cw - 18.0).size()
		if c.has("d2"):
			n += _wrap(fb(), c.d2, 12, cw - 18.0).size()
		h += 5.0 + maxf(30.0, n * 17.0)
	if c.get("frg", "") != "":
		h += 5.0 + 21.0
	if c.has("sbar"):
		h += 5.0 + 20.0
	for b in c.get("btns", []):
		h += 5.0 + (27.0 if b.get("sty", "") == "tpv" else 35.0)
	return h + 8.0

func _L(R: Array, x0: float, y0: float, W: float) -> float:
	var y := y0
	var first := true
	var rf := ThemeDB.fallback_font
	for row in R:
		if row.has("h"):
			if not first:
				y += 6.0
			_E({"k": "t", "p": Vector2(x0, y + 14.0), "s": row.h, "fs": 13, "c": Color("#c9a255"), "b": true, "ls": 0.14, "ic": row.get("ic", "")})
			y += 28.0
		elif row.has("p"):
			var fs: int = row.get("fs", 12)
			var lh: float = fs * 1.45
			y += 2.0
			for l in _wrap(rf, row.p, fs, W):
				_E({"k": "t", "p": Vector2(x0, y + fs + 1.0), "s": l, "fs": fs, "c": row.get("c", Color("#8a9bad"))})
				y += lh
			y += row.get("mb", 10.0)
		elif row.has("soro"):
			y = _L_soro(row, x0, y, W)
		elif row.has("stsh"):
			var r := Rect2(x0, y, W, 70.0)
			_E({"k": "box", "r": r, "st": [[0.0, Color("#2a1440")], [0.5, Color("#1a1030")], [1.0, Color("#2a2010")]], "ang": 120.0, "rad": 10.0, "bc": Color("#c08cff")})
			_E({"k": "t", "p": Vector2(x0 + 14.0, y + 32.0), "s": "★ 걸작", "fs": 18, "b": true, "c": Color("#ffe9b8"), "ls": 0.06})
			var S: Array = row.stsh
			var x := x0 + W - 14.0
			var spans: Array = []
			for i in range(S.size() - 1, -1, -1):
				var s: Array = S[i]
				var w := 20.0 + _tw(s[0], 13) + _tw(s[1], 15, true) + _tw(s[2], 13)
				x -= w
				spans.append([Rect2(x, y + 20.0, w, 30.0), s])
				x -= 12.0
			_E({"k": "t", "p": Vector2(x0 + 14.0, y + 54.0), "s": "로봇 · 기지 · 테마가 완전히 새 모습으로 바뀌는 최상위 등급 · 오직 별 뽑기로만 얻어요", "fs": 12, "c": Color("#b8a8d8"), "w": x - x0 - 20.0})
			for sp in spans:
				var rr: Rect2 = sp[0]
				var s2: Array = sp[1]
				_E({"k": "box", "r": rr, "st": Color("#0e0a18"), "rad": 6.0, "bc": Color("#4a3a6a")})
				_E({"k": "t", "p": rr.position + Vector2(10.0, 20.0), "s": s2[0], "fs": 13, "c": Color("#b8a8d8")})
				_E({"k": "t", "p": rr.position + Vector2(10.0 + _tw(s2[0], 13), 21.0), "s": s2[1], "fs": 15, "b": true, "c": Color("#f0e0ff")})
				_E({"k": "t", "p": rr.position + Vector2(10.0 + _tw(s2[0], 13) + _tw(s2[1], 15, true), 20.0), "s": s2[2], "fs": 13, "c": Color("#b8a8d8")})
			y += 82.0
		elif row.has("stex"):
			var B: Array = row.stex
			var x := x0 + W - 4.0
			for i in range(B.size() - 1, -1, -1):
				var w := _bnat(B[i], 14.0)
				x -= w
				_B(Rect2(x, y + 8.0, w, 52.0), B[i])
				x -= 8.0
			_E({"k": "t", "p": Vector2(x0 + 4.0, y + 39.0), "s": "별석 교환 · 별석 1개 = 청석 300", "fs": 13, "c": Color("#9fb0bf")})
			y += 68.0
		elif row.has("cards"):
			y = _L_cards(row, x0, y, W)
		elif row.has("tbl"):
			y = _L_tbl(row, x0, y, W)
		elif row.has("sum"):
			var x := x0
			for s in row.sum:
				var w := 24.0 + _tw(s[0], 13) + 6.0 + _tw(s[1], 13, true)
				var bb: Dictionary = s[3] if s.size() > 3 else {}
				if not bb.is_empty():
					w += 6.0 + _bnat(bb, 9.0)
				if x > x0 and x + w > x0 + W:
					x = x0
					y += 40.0
				var r := Rect2(x, y, w, 32.0)
				var sp: bool = s[2]
				_E({"k": "box", "r": r, "st": Color("#0b1015"), "rad": 7.0, "bc": Color("#6a4a9a") if sp else Color("#2b3640")})
				_E({"k": "t", "p": r.position + Vector2(11.0, 21.0), "s": s[0], "fs": 13, "c": Color("#9fb0bf")})
				_E({"k": "t", "p": r.position + Vector2(17.0 + _tw(s[0], 13), 21.0), "s": s[1], "fs": 13, "b": true, "c": Color("#d2a8ff") if sp else Color("#e8eef2")})
				if not bb.is_empty():
					var bw := _bnat(bb, 9.0)
					_B(Rect2(r.end.x - 11.0 - bw, y + 5.0, bw, 22.0), bb)
				x += w + 8.0
			y += 40.0
		elif row.has("sfbar"):
			_E({"k": "ln", "a": Vector2(x0, y), "b": Vector2(x0 + W, y), "c": Color("#2b3640")})
			var x := x0
			var yy := y + 10.0
			for g in row.sfbar:
				var gw := _tw(g[0], 12) + 7.0
				for c in g[1]:
					gw += _bnat({"l": c[0], "fs": 13}, 12.0) + 5.0
				if x > x0 and x + gw > x0 + W:
					x = x0
					yy += 40.0
				_E({"k": "t", "p": Vector2(x, yy + 21.0), "s": g[0], "fs": 12, "c": Color("#8a9bad")})
				x += _tw(g[0], 12) + 7.0
				for c in g[1]:
					var w := _bnat({"l": c[0], "fs": 13}, 12.0)
					_B(Rect2(x, yy, w, 32.0), {"l": c[0], "fs": 13, "a": c[1], "sty": "chipon" if c[2] else "chip"})
					x += w + 5.0
				x += 9.0
			yy += 42.0
			_E({"k": "ln", "a": Vector2(x0, yy), "b": Vector2(x0 + W, yy), "c": Color("#2b3640")})
			y = yy + 10.0
		elif row.has("row2"):
			var B: Array = row.row2
			var w := (W - 8.0 * (B.size() - 1)) / B.size()
			for i in B.size():
				_B(Rect2(x0 + i * (w + 8.0), y + 6.0, w, 42.0), B[i])
			y += 54.0
		elif row.has("vol"):
			var x := x0
			for v in row.vol:
				_E({"k": "t", "p": Vector2(x, y + 21.0), "s": v[0], "fs": 13, "c": Color("#c9d3dc")})
				x += _tw(v[0], 13) + 8.0
				var r := Rect2(x, y + 4.0, 150.0, 24.0)
				var e := _E({"k": "sl", "r": r, "key": v[1]})
				_C("sl", r.grow_individual(4.0, 6.0, 4.0, 6.0), v[1], e)
				x += 158.0
				var vs := str(int(SV[v[1]])) + ("%" if v[1] == "uis" else "")
				_E({"k": "t", "p": Vector2(x, y + 21.0), "s": vs, "fs": 13, "b": true, "c": Color("#ffe9b8")})
				x += maxf(26.0, _tw(vs, 13, true)) + 22.0
			if row.has("btn"):
				var bw := _bnat(row.btn, 14.0)
				_B(Rect2(x, y, bw, 34.0), row.btn)
			y += 44.0
		elif row.has("sel"):
			var r := Rect2(x0, y, maxf(240.0, row.sel_w), 36.0)
			var e := _E({"k": "sel", "r": r, "s": row.sel})
			_C("bgmsel", r, null, e)
			y += 46.0
		elif row.has("season"):
			var r := Rect2(x0, y, W, 46.0)
			_E({"k": "box", "r": r, "st": [[0.0, Color("#1a1440")], [0.6, Color("#0c0a1e")], [1.0, Color("#2a1a4a")]], "ang": 120.0, "rad": 10.0, "bc": Color("#c08cff")})
			_E({"k": "t", "p": Vector2(x0 + 14.0, y + 30.0), "s": SEASON.n, "fs": 19, "b": true, "c": Color("#f0e0ff"), "ls": 0.08})
			var nw := 0.0
			for ch in SEASON.n:
				nw += _tw(ch, 19, true) + 19 * 0.08
			_E({"k": "t", "p": Vector2(x0 + 26.0 + nw, y + 29.0), "s": SEASON.d, "fs": 13, "c": Color("#b8a8d8")})
			y += 56.0
		elif row.has("bph"):
			y = _L_bph(x0, y, W)
		elif row.has("jump"):
			var x := x0
			for j in row.jump:
				var b := {"l": j[0], "ic": j[2], "a": {"a": "jump", "k": j[1]}, "sty": "chip", "fs": 13}
				var w := _bnat(b, 14.0)
				_B(Rect2(x, y, w, 34.0), b)
				x += w + 8.0
			y += 46.0
		elif row.has("anchor"):
			lob_anchor[row.anchor] = y - y0
		elif row.has("pcard"):
			y = _L_pcard(row.pcard, x0, y, W)
		elif row.has("nhero"):
			y = _L_nhero(x0, y, W)
		elif row.has("note"):
			y = _L_note(row, x0, y, W)
		elif row.has("track"):
			y = _L_track(x0, y, W)
		first = false
	return y - y0

func _L_soro(row: Dictionary, x0: float, y: float, W: float) -> float:
	var star: bool = row.soro == "star"
	var B: Array = row.btns
	var bw := 118.0
	for b in B:
		bw = maxf(bw, _bnat(b, 18.0))
	var colh := B.size() * 56.0 + (B.size() - 1) * 6.0
	var iw := W - 28.0 - 90.0 - 14.0 - bw - 14.0
	var lines: Array = []
	for l in _wrap(ThemeDB.fallback_font, row.info[0], 14, iw):
		lines.append([l, 14, Color("#dfe6ea")])
	for i in range(1, row.info.size()):
		for l in _wrap(ThemeDB.fallback_font, row.info[i], 12, iw):
			lines.append([l, 12, Color("#8a9bad")])
	var ih := lines.size() * 22.0
	var h := maxf(colh, ih) + 28.0
	var r := Rect2(x0, y, W, h)
	if star:
		_E({"k": "box", "r": r, "st": _g2("#1e1430", "#10151a"), "rad": 10.0, "bc": Color("#c08cff")})
	else:
		_E({"k": "box", "r": r, "st": _g2("#20180c", "#10151a"), "rad": 10.0, "bc": Color("#8a6d35")})
	_E({"k": "ic", "kind": "stbx" if star else "sbx", "c": Vector2(x0 + 14.0 + 45.0, y + h / 2.0)})
	var ty := y + (h - ih) / 2.0
	for l in lines:
		_E({"k": "t", "p": Vector2(x0 + 118.0, ty + 16.0), "s": l[0], "fs": l[1], "c": l[2]})
		ty += 22.0
	var by := y + (h - colh) / 2.0
	for b in B:
		_B(Rect2(x0 + W - 14.0 - bw, by, bw, 56.0), b)
		by += 62.0
	return y + h + (10.0 if star else 14.0)

func _L_cards(row: Dictionary, x0: float, y: float, W: float) -> float:
	var mn: float = row.get("min", 150.0)
	var gap: float = 10.0 if mn > 200.0 else 8.0
	var cols := maxi(1, int((W + gap) / (mn + gap)))
	var cw := (W - gap * (cols - 1)) / cols
	var C2: Array = row.cards
	if C2.is_empty():
		_E({"k": "t", "p": Vector2(x0, y + 16.0), "s": row.get("empty", ""), "fs": 12, "c": Color("#8a9bad")})
		return y + 30.0
	var i := 0
	while i < C2.size():
		var hh := 0.0
		for k in range(i, mini(i + cols, C2.size())):
			hh = maxf(hh, _card_h(C2[k], cw))
		for k in range(i, mini(i + cols, C2.size())):
			_L_card(C2[k], Rect2(x0 + (k - i) * (cw + gap), y, cw, hh))
		y += hh + gap
		i += cols
	return y - gap + (12.0 if mn > 200.0 else 14.0)

func _L_card(c: Dictionary, r: Rect2) -> void:
	var af := false
	for b in c.get("btns", []):
		if _can(b):
			af = true
	var e := _E({"k": "card", "r": r, "c": c, "af": af})
	var x := r.position.x + 9.0
	var w := r.size.x - 18.0
	var y := r.position.y + 9.0
	if c.get("cash", false):
		e.gy = y
		y += 54.0 + 26.0 + 16.0 + 5.0
		_B(Rect2(x, y, w, 36.0), c.btns[0])
		return
	e.pv = Rect2(x, y, w, w * 0.6)
	y += w * 0.6 + 5.0
	e.ny = y + 14.0
	y += 18.0
	if c.has("d"):
		e.dl = _wrap(ThemeDB.fallback_font, c.d, 12, w)
		e.dy = y + 5.0 + 12.0
		var n: int = e.dl.size()
		if c.has("d2"):
			e.d2l = _wrap(fb(), c.d2, 12, w)
			e.d2y = e.dy + n * 17.0
			n += e.d2l.size()
		y += 5.0 + maxf(30.0, n * 17.0)
	if c.get("frg", "") != "":
		e.fr = Rect2(x, y + 5.0, _tw(c.frg, 12) + 14.0, 21.0)
		y += 26.0
	if c.has("sbar"):
		e.sb = Rect2(x, y + 5.0, w, 20.0)
		y += 25.0
	for b in c.get("btns", []):
		var bh := 27.0 if b.get("sty", "") == "tpv" else 35.0
		var bb: Dictionary = b.duplicate()
		if bb.get("sty", "") == "tpv":
			bb.fs = 12
			bb.ic = "note"
		_B(Rect2(x, y + 5.0, w, bh), bb)
		y += 5.0 + bh

func _L_tbl(row: Dictionary, x0: float, y: float, W: float) -> float:
	var T: Array = row.tbl
	var hist: bool = row.get("hist", false)
	var nat := [0.0, 0.0, 0.0]
	for ri in T.size():
		for ci in 3:
			nat[ci] = maxf(nat[ci], _tw(str(T[ri][ci]), 13, ri == 0 or ci == 1) + 20.0)
	var tot: float = nat[0] + nat[1] + nat[2]
	var cwid: Array = []
	for ci in 3:
		cwid.append(nat[ci] + (W - tot) * (nat[ci] / tot) if tot < W else W * nat[ci] / tot)
	if hist:
		cwid = [nat[0] + 10.0, nat[1] + 10.0, W - nat[0] - nat[1] - 20.0]
	y += 6.0
	for ri in T.size():
		var hd := ri == 0
		var rh := 33.0 if hd else 32.0
		var r := Rect2(x0, y, W, rh)
		if hd:
			_E({"k": "box", "r": r, "st": Color("#141b22")})
		_E({"k": "ln", "a": Vector2(x0, y + rh - 0.5), "b": Vector2(x0 + W, y + rh - 0.5), "c": Color("#4a3c1e") if hd else Color("#1e2830")})
		var xx := x0 + 10.0
		var gcl: String = row.get("g", [])[ri] if (hist and ri > 0 and ri < row.get("g", []).size()) else ""
		for ci in 3:
			var col := Color("#c9d3dc")
			var fs := 13
			var bold := false
			if hd:
				col = Color("#e8c36a")
				bold = true
			elif hist:
				fs = 13 if ci != 1 else 12
				col = [Color("#8a9bad"), Color("#9fb0bf"), Color("#dfe6ea")][ci]
				if ci == 2:
					if gcl == "kro":
						col = Color("#ffe28a")
					elif gcl == "jack":
						col = Color("#7affd4")
						bold = true
					elif gcl == "star":
						col = Color("#d2a8ff")
						bold = true
					elif gcl == "sf":
						col = Color("#c8b8e8")
			elif ci == 1:
				col = Color("#ffe9b8")
				bold = true
			elif ci == 2:
				col = Color("#8a9bad")
				fs = 12
			_E({"k": "t", "p": Vector2(xx, y + rh / 2.0 + 5.0), "s": str(T[ri][ci]), "fs": fs, "b": bold, "c": col, "w": cwid[ci] - 14.0})
			xx += cwid[ci]
		y += rh
	return y + 10.0

func _L_bph(x0: float, y: float, W: float) -> float:
	var P := bp()
	var lv := bp_lv()
	var cur := int(P.xp) - lv * 500
	var lvw := _tw("단계", 15) + 4.0 + _tw(str(lv), 46, true) + 4.0 + _tw("/30", 15)
	var B: Array = []
	if not P.prem:
		B.append({"l": "프리미엄 해금", "ic": "crown", "s": "청석 2,000", "a": {"a": "bpbuy"}, "sty": "prem", "glow": int(SV.cs) >= 2000})
	if lv < 30:
		B.append({"l": "1단계 구매", "s": "청석 100", "a": {"a": "bpskip", "n": 1}, "sty": "skip", "glow": int(SV.cs) >= 100})
		B.append({"l": "5단계 구매", "s": "청석 500", "a": {"a": "bpskip", "n": 5}, "sty": "skip", "glow": int(SV.cs) >= 500})
	var claim := false
	for L in range(1, lv + 1):
		var rr: Dictionary = bpr(L)
		if rr.f != null and not P.cf.has(L):
			claim = true
		if P.prem and rr.p != null and not P.cp.has(L):
			claim = true
	B.append({"l": "모두 받기", "a": {"a": "bpall"}, "sty": "go", "bold": true, "glow": claim})
	var bws := 0.0
	var bw: Array = []
	for b in B:
		var w := _bnat(b, 18.0 if b.sty != "skip" else 14.0)
		bw.append(w)
		bws += w + 14.0
	var premw := 0.0
	if P.prem:
		premw = _tw("프리미엄 활성", 13, true) + 50.0
		bws += premw + 14.0
	var xw := W - lvw - 14.0 - bws
	var wrap := xw < 220.0
	if wrap:
		xw = W - lvw - 14.0
	var cy := y + 30.0
	_E({"k": "t", "p": Vector2(x0, cy + 14.0), "s": "단계", "fs": 15, "c": Color("#8a9bad")})
	_E({"k": "t", "p": Vector2(x0 + _tw("단계", 15) + 4.0, cy + 16.0), "s": str(lv), "fs": 46, "b": true, "c": Color("#e8c36a")})
	_E({"k": "t", "p": Vector2(x0 + _tw("단계", 15) + 8.0 + _tw(str(lv), 46, true), cy + 14.0), "s": "/30", "fs": 15, "c": Color("#8a9bad")})
	var bx := x0 + lvw + 14.0
	_E({"k": "bar", "r": Rect2(bx, cy - 20.0, xw, 22.0), "v": 1.0 if lv >= 30 else cur / 500.0, "s": "MAX" if lv >= 30 else str(cur) + " / 500 XP"})
	var dy := cy + 18.0
	for l in _wrap(ThemeDB.fallback_font, "플레이 1분 +10 · 적 처치 +2 · 기지 정복 +30 · 레이드 방어 +50 · 게임이 끝날 때 들어와요", 12, xw):
		_E({"k": "t", "p": Vector2(bx, dy), "s": l, "fs": 12, "c": Color("#8a9bad")})
		dy += 16.0
	var x := bx + xw + 14.0
	if wrap:
		y += 72.0
		cy = y + 30.0
		x = x0
	if P.prem:
		var pr := Rect2(x, cy - 22.0, premw, 44.0)
		_E({"k": "box", "r": pr.grow(0.0), "st": _g2("#5a3a8a", "#2a1a4a"), "rad": 8.0, "bc": Color("#c08cff"), "glow": Color(0.75, 0.55, 1.0, 0.4)})
		_E({"k": "t", "p": Vector2(pr.position.x + 16.0, cy + 5.0), "s": "프리미엄 활성", "fs": 13, "b": true, "c": Color("#f0e0ff"), "ic": "crown"})
		x += premw + 14.0
	for i in B.size():
		var b: Dictionary = B[i]
		var h := 54.0 if b.has("s") else 40.0
		_B(Rect2(x, cy - h / 2.0, bw[i], h), b)
		x += bw[i] + 14.0
	return y + 72.0

func _L_track(x0: float, y: float, W: float) -> float:
	var P := bp()
	var lv := bp_lv()
	var top := y + 4.0
	pass_tr = Rect2(x0, top, W, 293.0)
	var vr := Rect2(x0 + 74.0, top - 4.0, W - 74.0, 300.0)
	if pass_init:
		pass_init = false
		pass_scroll = clampf(80.0 + mini(29, lv) * 118.0 - 160.0, 0.0, _pass_max())
	for L in range(1, 31):
		var cx := x0 + 80.0 + (L - 1) * 118.0 - pass_scroll
		if cx > x0 + W + 4.0 or cx + 112.0 < x0 + 70.0:
			continue
		_E({"k": "bpn", "r": Rect2(cx, top, 112.0, 25.0), "s": str(L), "got": lv >= L, "next": lv + 1 == L})
		for ti in 2:
			var tp := "f" if ti == 0 else "p"
			var rw = bpr(L)[tp]
			var cr := Rect2(cx, top + 31.0 + ti * 134.0, 112.0, 128.0)
			var got: bool = (P.cf if tp == "f" else P.cp).has(L)
			var lk: bool = lv < L or (tp == "p" and not P.prem)
			var e := _E({"k": "bpr", "r": cr, "rw": rw, "got": got, "lk": lk, "tp": tp, "can": rw != null and not got and not lk})
			if rw != null and not got and not lk:
				var hh := _bpr_stack(e)
				var bw := _tw("받기", 12, true) + 30.0
				var br := Rect2(cr.position.x + (112.0 - bw) / 2.0, cr.position.y + (128.0 - hh) / 2.0 + hh - 24.0, bw, 24.0)
				e.btn = {"k": "btn", "r": br, "l": "받기", "sty": "bpc", "en": true, "fs": 12}
				_C("cb", br.intersection(vr), {"a": "bpc", "t": tp, "L": L}, e.btn)
	_E({"k": "hmask", "y0": top - 4.0, "y1": top + 300.0, "x0": x0, "x1": x0 + W})
	_E({"k": "bpn", "r": Rect2(x0, top, 74.0, 25.0), "s": "단계", "lab": true})
	_E({"k": "bpr", "r": Rect2(x0, top + 31.0, 74.0, 128.0), "lab": "무료", "tp": "f"})
	_E({"k": "bpr", "r": Rect2(x0, top + 165.0, 74.0, 128.0), "lab": "프리미엄", "tp": "p"})
	var mx := _pass_max()
	sb_pass = {}
	if mx > 0.0:
		var tw := W - 74.0
		var hw := maxf(50.0, tw * tw / (tw + mx))
		sb_pass = {"r": Rect2(x0 + 74.0, top + 296.0, tw, 10.0), "th": hw}
		_E({"k": "box", "r": Rect2(x0 + 74.0, top + 296.0, tw, 10.0), "st": Color("#0b1015"), "rad": 5.0})
		_E({"k": "box", "r": Rect2(x0 + 74.0 + (tw - hw) * pass_scroll / mx, top + 297.0, hw, 8.0), "st": Color("#56687a"), "rad": 4.0})
	return top + 309.0

func _pass_max() -> float:
	return maxf(0.0, 80.0 + 30.0 * 118.0 - 6.0 - pass_tr.size.x)

func _bpr_stack(e: Dictionary) -> float:
	var r: Dictionary = e.rw
	var ih := 32.0
	if r.has("cs"):
		ih = 32.0
	elif r.has("box"):
		ih = 32.0
	elif r.has("frag"):
		ih = 28.0
	else:
		ih = 55.0
	var n := _wrap(ThemeDB.fallback_font, rt_txt(r), 12, 100.0).size()
	var h := ih + 5.0 + n * 16.0
	if e.got or e.can or (e.tp == "p" and not bp().prem):
		h += 5.0 + (24.0 if e.can else 16.0)
	return h

# ── 섹션 내용 ──
func _tpv(id: String) -> Dictionary:
	if bgm_prev_id == id and t_real < bgm_prev_u:
		return {"l": "미리듣기 중 · " + str(ceili(bgm_prev_u - t_real)) + "초", "a": {"a": "tprev", "id": id}, "sty": "tpv", "on": true}
	return {"l": "테마곡 미리듣기", "a": {"a": "tprev", "id": id}, "sty": "tpv"}

func _cpr(id: String) -> int:
	var it := item(id)
	var p: int = int(it.get("p", 0))
	return p if p > 0 else (500 if cat_of(id) == "b" else 300)

func _rows_shop() -> Array:
	var R: Array = []
	match shop_tab2:
		"star":
			R.append({"stsh": [["별석 ", str(SV.ss), ""], ["★ 별 파편 ", str(SV.sfrag), " / 30"], ["천장 ", str(SV.spity), " / 500"]]})
			var sb: Array = [{"l": "1회 뽑기", "s": "별석 15", "a": {"a": "spull", "n": 1}, "cost": ["ss", 15], "sty": "spull"}, {"l": "10회 뽑기", "s": "별석 150", "a": {"a": "spull", "n": 10}, "cost": ["ss", 150], "sty": "spull"}]
			var na := mini(100, int(SV.ss / 15))
			if na > 10:
				sb.append({"l": "모두 뽑기", "s": str(na) + "회 · 별석 " + _cm(na * 15), "a": {"a": "spull", "n": na}, "cost": ["ss", na * 15], "sty": "spull", "dash": true})
			R.append({"soro": "star", "btns": sb, "info": ["별 뽑기 1회 = 별석 15 · 별 파편 1~4개 또는 걸작 완품 (로봇·기지·테마 중 하나)", "파편 1개 54% · 2개 32% · 3개 11% · 4개 3% · 완품 0.001%", "500번째 뽑기는 완품 확정(천장) · 완품이 나오면 천장이 초기화돼요"]})
			R.append({"stex": [{"l": "별석 1개", "s": "청석 300", "a": {"a": "sx", "n": 1}, "cost": ["cs", 300]}, {"l": "별석 10개", "s": "청석 3,000", "a": {"a": "sx", "n": 10}, "cost": ["cs", 3000]}]})
			R.append({"h": "걸작 세트"})
			var cards: Array = []
			for i in MSET.size():
				var S: Dictionary = MSET[i]
				var n := [S.r, S.b, S.t].filter(func(id): return owns(id)).size()
				var e: bool = SV.eq == S.r and SV.beq == S.b and SV.teq == S.t
				cards.append({"pv": ["mset", i], "tag": "★ 세트", "tc": "star", "n": S.n, "d": item(S.r).n + " · " + item(S.b).n + " · " + item(S.t).n + " · 보유 " + str(n) + "/3", "cls": "star",
					"btns": [{"l": ("세트 장착 중" if e else "세트 장착") if n == 3 else "3종을 모두 모으면 장착", "a": {"a": "mset", "i": i}, "en": n == 3 and not e}]})
			R.append({"cards": cards, "min": 230.0})
			for g in [["s", "걸작 로봇"], ["b", "걸작 기지 · 기지 모양과 폭발 연출이 바뀌어요"], ["t", "걸작 테마 · 필드 · 날씨 · 적 탄환이 바뀌어요"]]:
				R.append({"h": g[1]})
				cards = []
				for it in star_all():
					var c := cat_of(it.id)
					if c != g[0]:
						continue
					var o := owns(it.id)
					var e := equipped(it.id)
					var cd := {"pv": [c, it.id], "tag": "★ 걸작", "tc": "star", "n": it.n, "d": it.d, "cls": "star", "btns": []}
					if c == "t":
						cd.d2 = "전용 웅장한 테마곡 포함 · 세트 완성 시 레이드 전용 편곡"
						cd.btns.append(_tpv(it.id))
					if o:
						cd.btns.append({"l": "장착 중" if e else "장착", "a": {"a": "eq", "id": it.id}, "en": not e})
					else:
						cd.btns.append({"l": "★ 별 파편 30개로 제작", "a": {"a": "craft", "id": it.id}, "en": SV.sfrag >= 30, "cost": "free"})
					cards.append(cd)
				R.append({"cards": cards, "min": 230.0})
		"box":
			R.append({"h": "소로 상자 · 스킨 파편 (로봇 6개 · 기지 5개 · 테마 4개 모으면 완성)"})
			var b: Array = []
			if SV.fbox > 0:
				b.append({"l": "무료 상자 열기", "s": "보유 " + str(SV.fbox) + "개", "a": {"a": "fbox"}, "sty": "fbx", "cost": "free"})
			b.append({"l": "1개 열기", "s": "청석 600", "a": {"a": "box", "n": 1}, "cost": ["cs", 600], "sty": "soro"})
			b.append({"l": "5개 열기", "s": "청석 3,000", "a": {"a": "box", "n": 5}, "cost": ["cs", 3000], "sty": "soro"})
			b.append({"l": "10개 열기", "s": "청석 6,000", "a": {"a": "box", "n": 10}, "cost": ["cs", 6000], "sty": "soro"})
			var na := mini(100, int(SV.cs / 600))
			if na > 10:
				b.append({"l": "모두 열기", "s": str(na) + "개 · 청석 " + _cm(na * 600), "a": {"a": "box", "n": na}, "cost": ["cs", na * 600], "sty": "soro", "dash": true})
			R.append({"soro": "box", "btns": b, "info": ["상자 1개에서 스킨 1종의 파편이 1~3개 나와요", "1개 65% · 2개 25% · 3개 10%", "로봇 40% · 기지 25% · 테마 35% · 주 등급 82% · 크로 등급 18%", "이미 가진 스킨의 파편은 청석으로 돌려받아요 · 0.01% 확률로 크로 세트가 통째로!"]})
		"set":
			R.append({"h": "로봇 + 기지 + 테마 · 없는 것만 15% 할인"})
			var cards: Array = []
			for i in SETS.size():
				var S: Dictionary = SETS[i]
				var P := set_parts(S)
				var miss := set_miss(S)
				var cost := roundi(miss * 0.85)
				var e: bool = SV.eq == S.r and SV.beq == S.b and SV.teq == S.t
				var bt := {"l": "장착 중" if e else ("청석 " + str(cost) if miss > 0 else "세트 장착"), "a": {"a": "set", "i": i}, "en": not e}
				if miss > 0 and not e:
					bt.cost = ["cs", cost]
				cards.append({"pv": ["set", i], "tag": "세트", "tc": "kro", "n": S.n, "d": P[0].n + " · " + P[1].n + " · " + P[2].n, "cls": "kro", "btns": [bt]})
			R.append({"cards": cards})
		"r", "b", "t":
			var c: String = shop_tab2
			var cat := "s" if c == "r" else c
			var key: String = {"s": "eq", "b": "beq", "t": "teq"}[cat]
			var dflt := {"pv": [cat, ""], "n": {"r": "기본 도색", "b": "기본 기지", "t": "기본 테마"}[c], "d": "처음 모습",
				"btns": [{"l": "장착 중" if SV[key] == "" else "장착", "a": {"a": "uneq", "c": cat}, "en": SV[key] != ""}]}
			var mk := func(it: Dictionary) -> Dictionary:
				var o := owns(it.id)
				var e := equipped(it.id)
				var g: String = it.get("g", "b")
				var fr: int = int(SV.frag.get(it.id, 0))
				var bt := {"l": "장착 중" if e else ("장착" if o else "청석 " + str(_cpr(it.id))), "a": {"a": "buy", "id": it.id}, "en": not e}
				if not o:
					bt.cost = ["cs", _cpr(it.id)]
				var cd := {"pv": [cat, it.id], "tag": {"ju": "주", "kro": "크로", "b": "기지"}.get(g, ""), "tc": "kro" if g == "kro" else "ju", "n": it.n, "d": it.d, "cls": "kro" if g == "kro" else "",
					"frg": ("파편 " + str(fr) + " / " + str(FN[c])) if (fr > 0 and not o) else "", "btns": [bt]}
				if cat == "t":
					cd.btns.append(_tpv(it.id))
				return cd
			var L: Array = list_of(cat).filter(func(q): return q.get("g", "") != "star" and (not q.has("ex") or owns(q.id)))
			if c == "r":
				R.append({"h": "기본"})
				R.append({"cards": [dflt]})
				R.append({"h": "주 등급 · 외형 변경 · 청석 300"})
				R.append({"cards": L.filter(func(q): return q.g == "ju").map(mk)})
				R.append({"h": "크로 등급 · 외형 + 투사체 + 타격 효과"})
				R.append({"cards": L.filter(func(q): return q.g == "kro").map(mk)})
			else:
				R.append({"h": "기지 모습 + 패배 시 폭발 연출 · 청석 500" if c == "b" else "필드 배경 · 상대 기지 · 상대 로봇 · 광산"})
				R.append({"cards": [dflt] + L.map(mk)})
		"hist":
			var H: Array = SV.hist
			var nb := H.filter(func(h): return h.get("k", "") == "box").size()
			var ns := H.filter(func(h): return h.get("k", "") == "star").size()
			var nk := H.filter(func(h): return h.get("g", "") in ["kro", "jack"]).size()
			var nst := H.filter(func(h): return h.get("g", "") == "star").size()
			R.append({"sum": [["소로 상자", str(nb) + "회", false], ["별 뽑기", str(ns) + "회", false], ["크로·잭팟", str(nk) + "회", false], ["★ 걸작 완품", str(nst) + "회", true]]})
			R.append({"sfbar": [["종류", [["전체", {"a": "hf", "v": "all"}, hF == "all"], ["소로 상자", {"a": "hf", "v": "box"}, hF == "box"], ["별 뽑기", {"a": "hf", "v": "star"}, hF == "star"]]], ["최근 500회까지 기록돼요", []]]})
			var L: Array = H.filter(func(h): return hF == "all" or h.get("k", "") == hF)
			if L.is_empty():
				R.append({"p": "아직 뽑기 기록이 없어요"})
			else:
				var GLN := {"ju": "주", "kro": "크로", "base": "기지", "jack": "잭팟", "star": "★ 걸작", "sf": "별 파편"}
				var T: Array = [["시간", "종류", "결과"]]
				var G: Array = [""]
				for h in L.slice(0, 300):
					T.append([_fmt_t(h.get("t", 0)), ("소로 상자" if h.get("k", "") == "box" else "별 뽑기") + " · " + GLN.get(h.get("g", ""), ""), str(h.get("x", ""))])
					G.append(str(h.get("g", "")))
				R.append({"tbl": T, "hist": true, "g": G})
		"cash":
			R.append({"h": "가상 결제 (실제 돈은 나가지 않아요) · 누적 ₩" + _cm(SV.get("paid", 0))})
			var cards: Array = []
			for i in CASH.size():
				var P: Dictionary = CASH[i]
				cards.append({"cash": true, "a": P.a, "bn": P.bn, "btns": [{"l": "₩" + _cm(P.w), "a": {"a": "cash", "i": i}}]})
			R.append({"cards": cards})
	return R

func _fmt_t(t) -> String:
	var s := float(t)
	if s > 1e11:
		s /= 1000.0
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var d := Time.get_datetime_dict_from_unix_time(int(s) + bias * 60)
	return str(d.month) + "/" + str(d.day) + " " + "%02d:%02d" % [d.hour, d.minute]

func _pc(n: float) -> String:
	var v := n * 100.0
	var d := 4 if v < 0.01 else (3 if v < 1.0 else 2)
	var s := String.num(v, d)
	if "." in s:
		s = s.rstrip("0").rstrip(".")
	return s + "%"

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
	var st: Array = star_all()
	R.append({"sum": [["로봇", cnt.call("s"), false], ["기지", cnt.call("b"), false], ["테마", cnt.call("t"), false], ["★ 걸작", str(st.filter(func(q): return owns(q.id)).size()) + " / " + str(st.size()), true], ["스킨 파편", str(fsum), false], ["★ 별 파편", str(SV.sfrag), true], ["무료 상자", str(SV.fbox), false]]})
	var nm := func(c: String) -> String:
		var id: String = SV[{"s": "eq", "b": "beq", "t": "teq"}[c]]
		return item(id).get("n", "기본") if id != "" else "기본"
	var eqr: Array = []
	for q in [["s", "장착 중 · 로봇"], ["b", "기지"], ["t", "테마"]]:
		var on: bool = SV[{"s": "eq", "b": "beq", "t": "teq"}[q[0]]] != ""
		eqr.append([q[1], nm.call(q[0]), false, {"l": "기본으로", "a": {"a": "uneq", "c": q[0]}, "fs": 12, "sty": "mini"} if on else {}])
	R.append({"sum": eqr})
	var ch := func(k: String, opts: Array) -> Array:
		var o: Array = []
		for q in opts:
			o.append([q[1], {"a": "sf", "k": k, "v": q[0]}, (stF[k] as Array).is_empty() if q[0] == "all" else (stF[k] as Array).has(q[0])])
		return o
	R.append({"sfbar": [["보유", ch.call("own", [["all", "전체"], ["yes", "보유"], ["no", "미보유"]])], ["종류", ch.call("cat", [["all", "전체"], ["s", "로봇"], ["b", "기지"], ["t", "테마"]])], ["등급", ch.call("gr", [["all", "전체"], ["ju", "주"], ["kro", "크로"], ["star", "★ 걸작"], ["pass", "패스 전용"], ["base", "일반 기지"]])]]})
	var cards: Array = []
	for it in all:
		var c := cat_of(it.id)
		var o := owns(it.id)
		var g := _store_gr(it)
		if not (stF.own as Array).is_empty() and not (stF.own as Array).has("yes" if o else "no"):
			continue
		if not (stF.cat as Array).is_empty() and not (stF.cat as Array).has(c):
			continue
		if not (stF.gr as Array).is_empty() and not (stF.gr as Array).has(g):
			continue
		var e := equipped(it.id)
		var cd := {"pv": [c, it.id], "tag": {"s": "로봇", "b": "기지", "t": "테마"}[c] + " · " + {"ju": "주", "kro": "크로", "star": "★ 걸작", "pass": "패스 전용", "base": "일반"}[g], "tc": "star" if g == "star" else ("kro" if g == "kro" else "ju"),
			"n": it.n, "cls": "star" if g == "star" else ("kro" if g == "kro" else ""), "notown": not o}
		if o:
			cd.btns = [{"l": "장착 중" if e else "장착", "a": {"a": "eq", "id": it.id}, "en": not e}]
		elif g == "star":
			cd.sbar = {"v": minf(1.0, SV.sfrag / 30.0), "s": "★ 별 파편 " + str(SV.sfrag) + " / 30", "star": true}
		elif g == "pass":
			cd.sbar = {"v": 0.0, "s": "배틀패스 보상"}
		else:
			var n: int = int(SV.frag.get(it.id, 0))
			var need: int = FN[c if c != "s" else "r"]
			cd.sbar = {"v": float(n) / need, "s": "파편 " + str(n) + " / " + str(need)}
		cards.append(cd)
	R.append({"p": str(cards.size()) + "개", "mb": 8.0})
	R.append({"cards": cards, "empty": "조건에 맞는 스킨이 없어요"})
	return R

func _rows_pass() -> Array:
	return [{"season": true}, {"bph": true}, {"track": true}, {"p": "30단계 프리미엄 보상 · 패스 전용 은하 세트 (10단계 기지 · 20단계 테마 · 30단계 로봇) · 패스 전용 스킨은 상점과 상자에서 나오지 않아요", "mb": 4.0}]

func _bgm_name(id: String) -> String:
	if id == "auto":
		return "자동 (장착한 테마 따라가기)"
	if id == "base":
		return "기본 배경음"
	var it := item(id)
	return ("★ " if it.get("g", "") == "star" else "") + str(it.get("n", id))

func _bgm_opts() -> Array:
	var o: Array = ["auto", "base"]
	var L: Array = []
	for id in MUS_IDS:
		if SV.town.has(id):
			L.append(id)
	L.sort_custom(func(a, b): return item(a).get("g", "") == "star" and item(b).get("g", "") != "star")
	return o + L

func _rows_set() -> Array:
	if set_tab == "p":
		return _rows_prob()
	var R: Array = []
	R.append({"h": "튜토리얼"})
	R.append({"row2": [{"l": "튜토리얼 다시하기 (새 게임으로 시작)", "a": "ltut"}]})
	R.append({"h": "화면"})
	R.append({"vol": [["UI 크기", "uis"]]})
	R.append({"p": "버튼 · 상점 · 로비 · 지도 글씨 크기를 한꺼번에 줄이거나 키워요. 폰은 100%여도 PC보다 작게 맞춰져 있어요."})
	R.append({"h": "소리"})
	R.append({"vol": [["효과음", "vol_s"], ["배경음", "vol_b"]], "btn": {"l": "음소거 해제" if SV.mute else "음소거", "a": "lmute", "fs": 13}})
	R.append({"p": "게임 중에도 M 키로 음소거를 켜고 끌 수 있어요"})
	R.append({"h": "배경음"})
	var sw := 0.0
	for id in _bgm_opts():
		sw = maxf(sw, _tw(_bgm_name(id), 14) + 46.0)
	R.append({"sel": _bgm_name(str(SV.get("bgm", "auto"))), "sel_w": sw})
	R.append({"p": "테마마다 배경음이 달라요. 가진 테마의 곡은 따로 골라 들을 수 있어요. ★ 걸작 테마는 웅장한 전용곡이 있고, 걸작 세트를 완성하면 레이드 때 전용 편곡이 나와요."})
	R.append({"h": "조작"})
	R.append({"row2": [{"l": "조작법 전체 보기" + ("" if touch_ui() else " (Tab)"), "a": "lkeys"}, {"l": "계정 관리", "a": "lacct"}]})
	R.append({"p": "한 손가락으로 지도 이동 · 두 손가락으로 확대 · 탭 선택·명령 · 같은 종류 두 번 탭 = 모두 선택 · 꾹 누르고 끌어서 묶기" if touch_ui() else "좌클릭 명령 · 좌클릭 드래그나 WASD로 지도 이동 · 우클릭 누른 채 드래그로 로봇 묶기 · 1~5 로봇 종류별 선택 · Ctrl(또는 Shift)+1~5 또는 숫자 두 번 = 그 로봇들이 모인 곳으로 화면 이동 · 6/스페이스 기름 · T 깃발 · Ctrl+휠 확대/축소"})
	R.append({"h": "데이터"})
	R.append({"row2": [{"l": "정말? 한 번 더" if wipe_arm == "lwipe" else "청석·스킨 초기화", "a": "lwipe"}, {"l": "정말? 한 번 더" if wipe_arm == "lwipeall" else "게임 전체 초기화", "a": "lwipeall", "sty": "red"}]})
	return R

# ── 화면 만들기 ──
func _cos_on() -> bool:
	return lsec in ["shop", "store", "pass", "set", "prob", "notes"]

func _cos_small() -> bool:
	return lsec in ["shop", "store", "pass"]

func _build_cos() -> void:
	if lsec == "prob":
		lsec = "set"
		set_tab = "p"
	var u := ui_size()
	var small := _cos_small()
	var W := minf(1040.0 if small else 1000.0, u.x - 24.0)
	var px := (u.x - W) / 2.0
	var top := 132.0 if small else 205.0
	var x0 := px + 16.0
	var iw := W - 32.0
	var y := top + 16.0
	cos_hdr = []
	var tabs: Array = []
	var cur := ""
	if lsec == "shop":
		for l in _wrap(ThemeDB.fallback_font, "게임이 끝나면 그 판에 번 광석 총량의 4% + 정복한 기지마다 보너스(1구역 10 ~ 7구역 70)가 청석으로 들어와요. 스킨은 모든 로봇에 적용돼요.", 12, iw):
			cos_hdr.append({"k": "t", "p": Vector2(x0, y + 13.0), "s": l, "fs": 12, "c": Color("#8a9bad")})
			y += 18.0
		y += 19.0
		var own := func(a: Array, L: Array) -> String: return str(L.filter(func(q): return a.has(q.id)).size()) + "/" + str(L.size())
		tabs = [["star", "★ 걸작", "", ""], ["box", "소로 상자", "", "gift"], ["set", "세트", "", ""], ["r", "로봇 스킨", own.call(SV.own, SK), ""], ["b", "기지 스킨", own.call(SV.bown, BS), ""], ["t", "테마", own.call(SV.town, TS), ""], ["hist", "뽑기 내역", "", "scroll"]]
		if SV.get("cashOn", true) != false:
			tabs.append(["cash", "충전", "", "gem"])
		cur = shop_tab2
	elif lsec == "set":
		tabs = [["a", "일반", "", ""], ["p", "확률표", "", "chart"]]
		cur = set_tab
	if not tabs.is_empty():
		y = _tabs_layout(tabs, x0, y, iw, cur)
		cos_hdr.append({"k": "ln", "a": Vector2(x0, y + 10.0), "b": Vector2(x0 + iw, y + 10.0), "c": Color("#2b3640")})
		y += 21.0
	var R: Array = []
	match lsec:
		"shop": R = _rows_shop()
		"store": R = _rows_store()
		"pass": R = _rows_pass()
		"set": R = _rows_set()
		"notes": R = _rows_notes()
	lob_draw = []
	_cl = []
	var H := _L(R, x0, y - lob_scroll, iw)
	var reserve := 54.0
	var sbm := 14.0 if touch_ui() else 0.0
	var vh := minf(H, maxf(80.0, u.y - y - reserve - 24.0 - sbm))
	cos_vp = Rect2(px + 1.0, y, W - 2.0, vh)
	lob_max = maxf(0.0, H - vh)
	var bot := y + vh
	var be := {"k": "btn", "r": Rect2(x0, bot + 6.0, iw, 42.0), "l": "뒤로", "sty": "def", "en": true, "fs": 13}
	cos_hdr.append(be)
	be.it = _add("lback", be.r)
	bot += 48.0
	cos_pr = Rect2(px, top, W, bot + 16.0 - top)
	for c in _cl:
		var rr: Rect2 = (c[1] as Rect2).intersection(cos_vp) if c[4] else c[1]
		if rr.size.x > 1.0 and rr.size.y > 1.0:
			c[3].it = _add(c[0], rr, true, "", c[2])
	if bgm_open and lsec == "set":
		_build_bgm_list()

func _build_bgm_list() -> void:
	var sel = null
	for e in lob_draw:
		if e.k == "sel":
			sel = e
	if sel == null:
		bgm_open = false
		return
	var u := ui_size()
	_add("bgmx", Rect2(Vector2.ZERO, u))
	var O := _bgm_opts()
	var r: Rect2 = sel.r
	var h := O.size() * 28.0 + 4.0
	var y := r.end.y + 2.0
	if y + h > u.y - 8.0:
		y = maxf(8.0, r.position.y - 2.0 - h)
	for i in O.size():
		_add("bgmopt", Rect2(r.position.x + 2.0, y + 2.0 + i * 28.0, r.size.x - 4.0, 28.0), true, "", O[i])

func _lobby_cos(f: Font, hov) -> void:
	var u := ui_size()
	var pr := cos_pr
	var vp := cos_vp
	draw_rect(pr, PBG)
	_draw_rows(hov)
	# 내용이 패널 밖으로 안 나가게 가려요
	_page_bg(Rect2(0, 0, u.x, pr.position.y))
	_page_bg(Rect2(0, pr.end.y, u.x, u.y - pr.end.y))
	draw_rect(Rect2(pr.position.x, pr.position.y, pr.size.x, vp.position.y - pr.position.y), PBG)
	draw_rect(Rect2(pr.position.x, vp.end.y, pr.size.x, pr.end.y - vp.end.y), PBG)
	draw_rect(pr, Color("#2b3640"), false, 1.0)
	for e in cos_hdr:
		_draw_e(e, hov)
	sb_lob = {}
	if lob_max > 0.0:
		var k := clampf(lob_scroll / lob_max, 0.0, 1.0)
		var hh := maxf(40.0, vp.size.y * vp.size.y / (vp.size.y + lob_max))
		var tr := Rect2(pr.end.x - 14.0, vp.position.y, 10.0, vp.size.y)
		sb_lob = {"r": tr, "th": hh}
		_gbox(tr, Color("#0b1015"), 180.0, 5.0)
		var on: bool = lob_drag != null and lob_drag.get("sb", "") == "lob"
		_gbox(Rect2(tr.position.x + 1.0, tr.position.y + (tr.size.y - hh) * k, 8.0, hh), Color("#8a9bad") if on else Color("#56687a"), 180.0, 4.0)
	_logo(f, _cos_small())
	if bgm_open and lsec == "set":
		_draw_bgm_list(hov)

func _draw_bgm_list(hov) -> void:
	var first := true
	for it in ui:
		if it.id != "bgmopt":
			continue
		var r: Rect2 = it.r
		if first:
			var n := _bgm_opts().size()
			var box := Rect2(r.position.x - 2.0, r.position.y - 2.0, r.size.x + 4.0, n * 28.0 + 4.0)
			_bglow(box, Color(0, 0, 0, 0.6), 10.0)
			_gbox(box, Color("#10151a"), 180.0, 2.0, Color("#33414d"))
			first = false
		var on: bool = str(SV.get("bgm", "auto")) == str(it.arg)
		if on or hov == it:
			draw_rect(r, Color("#2a3a4e") if hov == it else Color("#1e2a36"))
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 10.0, r.position.y + 19.0), _bgm_name(str(it.arg)), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 20.0, 14, Color("#ffe9b8") if on else Color("#dfe6ea"))

func _draw_rows(hov) -> void:
	var vp := cos_vp
	for e in lob_draw:
		var r = e.get("r")
		if r != null and ((r as Rect2).end.y < vp.position.y - 4.0 or (r as Rect2).position.y > vp.end.y + 4.0):
			continue
		if e.k == "t" and (e.p.y < vp.position.y - 30.0 or e.p.y > vp.end.y + 30.0):
			continue
		_draw_e(e, hov)

func _draw_e(e: Dictionary, hov) -> void:
	var f := ThemeDB.fallback_font
	match e.k:
		"t":
			_dt(e)
		"ln":
			draw_line(e.a, e.b, e.c, 1.0)
		"box":
			if e.has("glow"):
				_bglow(e.r, e.glow, 14.0, e.get("rad", 0.0))
			_gbox(e.r, e.st, e.get("ang", 180.0), e.get("rad", 0.0), e.get("bc", Color(0, 0, 0, 0)), 1.0)
		"btn":
			_wbtn(e, hov)
		"ic":
			if e.kind == "sbx":
				_sbx(e.c, 1.0)
			else:
				_stbx(e.c, 1.0)
		"card":
			_draw_card(e)
		"sl":
			var r: Rect2 = e.r
			var nm: Array = {"uis": [50, 130], "vol_s": [0, 100], "vol_b": [0, 100]}[e.key]
			var k: float = clampf((float(SV[e.key]) - float(nm[0])) / float(nm[1] - nm[0]), 0.0, 1.0)
			var cy := r.position.y + r.size.y / 2.0
			_gbox(Rect2(r.position.x, cy - 3.0, r.size.x, 6.0), Color("#c9ced4"), 180.0, 3.0)
			_gbox(Rect2(r.position.x, cy - 3.0, r.size.x * k, 6.0), Color("#e8c36a"), 180.0, 3.0)
			draw_circle(Vector2(r.position.x + 7.0 + (r.size.x - 14.0) * k, cy), 8.0, Color("#e8c36a"))
		"sel":
			var r: Rect2 = e.r
			var h: bool = hov != null and e.get("it") != null and hov == e.it
			_gbox(r, Color("#10151a"), 180.0, 2.0, Color("#4fd1b5") if h else Color("#33414d"))
			draw_string(f, Vector2(r.position.x + 9.0, r.position.y + 24.0), e.s, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 34.0, 14, Color("#dfe6ea"))
			var c := Vector2(r.end.x - 16.0, r.position.y + 18.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -2), c + Vector2(5, -2), c + Vector2(0, 4)]), Color("#dfe6ea"))
		"bar":
			var r: Rect2 = e.r
			_gbox(r, Color("#05080b"), 180.0, 11.0, Color("#3a4a58"))
			var fw: float = r.size.x * clampf(e.v, 0.0, 1.0)
			if fw > 2.0:
				var fr := Rect2(r.position.x + 1.0, r.position.y + 1.0, fw - 2.0, r.size.y - 2.0)
				_bglow(fr, Color(1.0, 0.89, 0.54, 0.5), 8.0, 10.0)
				_gbox(fr, _g2("#b8902f", "#ffe28a"), 90.0, 10.0)
			_dt({"p": Vector2(r.position.x, r.position.y + 16.0), "s": e.s, "fs": 13, "b": true, "c": Color("#dfe6ea"), "al": 1, "w": r.size.x, "sh": [1.0, Color(0, 0, 0, 0.8)]})
		"bpn":
			var r: Rect2 = e.r
			if e.get("lab", false):
				draw_rect(r.grow_individual(0, 4, 6, 6), PBG)
			if e.get("got", false):
				_gbox(r, _g2("#e8c36a", "#b8902f"), 180.0, 6.0, Color("#f3d98e"))
			else:
				_gbox(r, Color("#0b1015"), 180.0, 6.0, Color("#e8c36a") if e.get("next", false) else Color("#2b3640"))
			var tc := Color("#1c1406") if e.get("got", false) else (Color("#ffe9b8") if e.get("next", false) else Color("#8a9bad"))
			draw_string(fb(), Vector2(r.position.x, r.position.y + 18.0), e.s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, tc)
		"bpr":
			_draw_bpr(e, hov)
		"pvb":
			draw_preview(e.r, "s", str(SV.eq), t_real)
		"icn":
			if e.kind == "user":
				_icon_user(e.c, e.s)
			else:
				_icon(e.kind, e.c, e.s)
		"hmask":
			var u := ui_size()
			var y0: float = e.y0
			var hh: float = e.y1 - e.y0
			_page_bg(Rect2(0, y0, cos_pr.position.x, hh))
			draw_rect(Rect2(cos_pr.position.x, y0, e.x0 - cos_pr.position.x, hh), PBG)
			draw_rect(Rect2(e.x1, y0, cos_pr.end.x - e.x1, hh), PBG)
			_page_bg(Rect2(cos_pr.end.x, y0, u.x - cos_pr.end.x, hh))

func _draw_bpr(e: Dictionary, hov) -> void:
	var r: Rect2 = e.r
	var p: bool = e.tp == "p"
	if e.has("lab"):
		draw_rect(r.grow_individual(0, 3, 6, 3), PBG)
	var isx: bool = e.get("rw") != null and (e.rw as Dictionary).has("skin")
	var bc := Color("#4a3a6a") if p else Color("#2b3640")
	if isx:
		bc = Color("#c08cff")
	if e.get("can", false):
		bc = Color("#c08cff") if isx else Color("#e8c36a")
		_bglow(r, Color(0.75, 0.55, 1.0, 0.7) if isx else Color(0.91, 0.76, 0.42, 0.45), 12.0 if not isx else 16.0, 9.0)
	_gbox(r, _g2("#1e1430", "#0e0a18") if p else Color("#0e141a"), 180.0, 9.0, bc)
	if e.has("lab"):
		var tc := Color("#d2a8ff") if p else Color("#9fb0bf")
		if p:
			_icon("crown", Vector2(r.position.x + r.size.x / 2.0, r.position.y + 50.0), 16.0)
		draw_string(fb(), Vector2(r.position.x, r.position.y + (78.0 if p else 69.0)), e.lab, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, tc)
		return
	if e.rw == null:
		_fade(r.grow(1.0), 0.65)
		return
	var rw: Dictionary = e.rw
	var hh := _bpr_stack(e)
	var y := r.position.y + (128.0 - hh) / 2.0
	var cx := r.position.x + 56.0
	if rw.has("cs"):
		_gem(Vector2(cx, y + 16.0), 20.0)
		y += 32.0
	elif rw.has("box"):
		_sbx(Vector2(cx, y + 16.0), 38.0 / 70.0, false)
		y += 32.0
	elif rw.has("frag"):
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x, y + 24.0), "◆", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color("#e8c36a"))
		y += 28.0
	else:
		var pv := Rect2(cx - 46.0, y, 92.0, 55.0)
		draw_preview(pv, cat_of(rw.skin), rw.skin, t_real)
		if e.lk:
			_fade(pv, 0.35, Color("#3a3a3a"))
		y += 55.0
	y += 5.0
	for l in _wrap(ThemeDB.fallback_font, rt_txt(rw), 12, 100.0):
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x, y + 12.0), l, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#dfe6ea"))
		y += 16.0
	y += 5.0
	if e.got:
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x, y + 12.0), "✓ 받음", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#7affd4"))
	elif e.can and e.has("btn"):
		_wbtn(e.btn, hov)
	elif p and not bp().prem:
		_icon("lock", Vector2(cx, y + 7.0), 13.0)
	if e.got:
		_fade(r.grow(1.0), 0.45)
	elif e.lk:
		_fade(r.grow(1.0), 0.5)

func _draw_card(e: Dictionary) -> void:
	var c: Dictionary = e.c
	var r: Rect2 = e.r
	var f := ThemeDB.fallback_font
	var cls: String = c.get("cls", "")
	if c.get("cash", false):
		_gbox(r, _g2("#122233", "#0c141c"), 180.0, 0.0, Color("#2f5a7a"))
		_gem(Vector2(r.get_center().x, e.gy + 27.0), 30.0)
		draw_string(fb(), Vector2(r.position.x, e.gy + 54.0 + 22.0), _cm(c.a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 19, Color("#7fd2ff"))
		if int(c.bn) > 0:
			draw_string(f, Vector2(r.position.x, e.gy + 54.0 + 26.0 + 13.0), "+" + str(c.bn) + " 보너스 포함", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color("#ffd27a"))
		return
	if cls == "star":
		_bglow(r, Color(0.75, 0.55, 1.0, 0.25), 16.0)
	if e.af:
		_bglow(r, Color(0.23, 0.88, 0.48, 0.28), 12.0)
	var bc := Color("#2b3640")
	var st = Color("#10151a")
	if cls == "kro":
		bc = Color("#6a5a2a")
		st = _g2("#211c10", "#10151a")
	elif cls == "star":
		bc = Color("#c08cff")
		st = _g2("#22183a", "#0e0a18")
	if e.af:
		bc = Color("#3ae07a")
	_gbox(r, st, 180.0, 0.0, bc)
	var pv: Rect2 = e.pv
	if pv.end.y > cos_vp.position.y - 4.0 and pv.position.y < cos_vp.end.y + 4.0:
		draw_preview(pv, c.pv[0], c.pv[1], t_real)
		if c.get("notown", false):
			_fade(pv, 0.45, Color("#3a3e44"))
	var x := pv.position.x
	var tg: String = c.get("tag", "")
	if tg != "":
		var tw := _tw(tg, 11) + 12.0
		var tcol := Color("#5fe0c4")
		if c.get("tc", "") == "kro":
			tcol = Color("#e8c36a")
		elif c.get("tc", "") == "star":
			tcol = Color("#ffd25a")
		draw_rect(Rect2(x, e.ny - 12.0, tw, 17.0), tcol, false, 1.0)
		draw_string(f, Vector2(x + 6.0, e.ny + 1.0), tg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tcol)
		x += tw + 6.0
	draw_string(fb(), Vector2(x, e.ny + 1.0), c.n, HORIZONTAL_ALIGNMENT_LEFT, maxf(10.0, pv.end.x - x), 14, Color("#dfe6ea"))
	if e.has("dl"):
		var y: float = e.dy
		for l in e.dl:
			draw_string(f, Vector2(pv.position.x, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8a9bad"))
			y += 17.0
	if e.has("d2l"):
		var y2: float = e.d2y
		for l in e.d2l:
			draw_string(fb(), Vector2(pv.position.x, y2), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffd76a"))
			y2 += 17.0
	if e.has("fr"):
		_gbox(e.fr, Color("#1e180a"), 180.0, 4.0, Color("#5c4316"))
		draw_string(f, e.fr.position + Vector2(7.0, 15.0), c.frg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffd27a"))
	if e.has("sb"):
		var sr: Rect2 = e.sb
		_gbox(sr, Color("#05080b"), 180.0, 5.0, Color("#2b3640"))
		var v: float = clampf(c.sbar.v, 0.0, 1.0)
		if v > 0.0:
			_gbox(Rect2(sr.position.x + 1.0, sr.position.y + 1.0, maxf(4.0, (sr.size.x - 2.0) * v), sr.size.y - 2.0), _g2("#7a5aff", "#d2a8ff") if c.sbar.get("star", false) else _g2("#b8902f", "#ffe28a"), 90.0, 4.0)
		_dt({"p": Vector2(sr.position.x, sr.position.y + 15.0), "s": c.sbar.s, "fs": 12, "b": true, "c": Color("#dfe6ea"), "al": 1, "w": sr.size.x, "sh": [1.0, Color(0, 0, 0, 0.9)]})
	if c.get("notown", false):
		_fade(r.grow(1.0), 0.38)

# ── 상자 열기 창 (#boxw .bxin) ──
func _box_card_h(q: Dictionary, cw: float) -> float:
	if box_star and q.res == "sf":
		return 12.0 + 48.0 + 5.0 + 22.0 + 5.0 + 20.0 + 12.0 + 4.0
	var pvh := (cw - 28.0) * 0.6
	if q.res == "starx":
		pvh = 0.0
	return 12.0 + pvh + 5.0 + 16.0 + 5.0 + (26.0 if q.res in ["jack", "star", "starx"] else 22.0) + 5.0 + 20.0 + (5.0 + 17.0 if not box_star else 0.0) + 12.0 + 4.0

func _box_geo() -> Dictionary:
	var u := ui_size()
	var W := minf(820.0, u.x * 0.94)
	var iw := W - 36.0
	var cols := maxi(1, int((iw + 12.0) / (190.0 + 12.0)))
	var cw := minf(230.0, (iw - 12.0 * (cols - 1)) / cols)
	var gw := cols * cw + (cols - 1) * 12.0
	# 줄 나누기 (잭팟·걸작 완품은 한 줄 통째로)
	var rows: Array = []
	var cur: Array = []
	for i in box_res.size():
		var q: Dictionary = box_res[i]
		if q.res in ["jack", "star", "starx"]:
			if not cur.is_empty():
				rows.append(cur)
				cur = []
			rows.append([i])
		else:
			cur.append(i)
			if cur.size() == cols:
				rows.append(cur)
				cur = []
	if not cur.is_empty():
		rows.append(cur)
	var pos := {}
	var y := 0.0
	for rw in rows:
		var hh := 0.0
		var big: bool = rw.size() == 1 and box_res[rw[0]].res in ["jack", "star", "starx"]
		var w := minf(420.0, iw) if big else cw
		for i in rw:
			hh = maxf(hh, _box_card_h(box_res[i], w))
		var x: float = (iw - (w if big else rw.size() * cw + (rw.size() - 1) * 12.0)) / 2.0
		for k in rw.size():
			pos[rw[k]] = Rect2(x + k * (cw + 12.0), y, w, hh)
		y += hh + 12.0
	var gh := maxf(0.0, y - 12.0)
	var busy := box_busy()
	var ah := 76.0 * clampf(1.0 - (t_real - box_t0 - 1.0) / 0.3, 0.0, 1.0) + 4.0
	var fixed := 18.0 + ah + 12.0 + 20.0 + 12.0 + 12.0 + 38.0 + (30.0 if busy else 0.0) + 18.0
	var gvis := minf(gh, minf(u.y * 0.6, u.y * 0.9 - fixed))
	var H := fixed + gvis
	var top := (u.y - H) / 2.0
	var x0 := (u.x - W) / 2.0
	return {"pr": Rect2(x0, top, W, H), "iw": iw, "pos": pos, "gh": gh, "gvis": gvis, "gy": top + 18.0 + ah + 12.0 + 20.0 + 12.0, "busy": busy, "ah": ah}

func _build_box() -> void:
	ui.clear()
	var G := _box_geo()
	var pr: Rect2 = G.pr
	box_vp = Rect2(pr.position.x + 18.0, G.gy, G.iw, G.gvis)
	box_max = maxf(0.0, G.gh - G.gvis)
	if G.busy and box_shown > 0:
		var last: Rect2 = G.pos.get(box_shown - 1, Rect2())
		box_scroll = maxf(box_scroll, last.end.y - G.gvis)
	box_scroll = clampf(box_scroll, 0.0, box_max)
	var by: float = G.gy + G.gvis + 12.0
	_add("boxok", Rect2(pr.position.x + 18.0, by, G.iw, 38.0))
	if G.busy:
		var w := _tw("건너뛰기 ▸▸", 12) + 30.0
		_add("boxskip", Rect2(pr.position.x + (pr.size.x - w) / 2.0, by + 46.0, w, 26.0))

func _box_overlay(f: Font, hov) -> void:
	var u := ui_size()
	_dimbg(Rect2(Vector2.ZERO, u))
	var G := _box_geo()
	var pr: Rect2 = G.pr
	var bst := _g2("#18212a", "#0e1318")
	_bglow(pr, Color(0, 0, 0, 0.5), 20.0, 12.0)
	_gbox(pr, bst, 180.0, 12.0)
	var x0 := pr.position.x + 18.0
	var gy: float = G.gy
	var et := t_real - box_t0
	# 결과 카드
	for i in mini(box_shown, box_res.size()):
		var r0: Rect2 = G.pos[i]
		var r := Rect2(x0 + r0.position.x, gy + r0.position.y - box_scroll, r0.size.x, r0.size.y)
		if r.end.y < gy - 20.0 or r.position.y > gy + G.gvis + 20.0:
			continue
		var age := et - (1.0 + i * box_step())
		var k := clampf(age / 0.35, 0.0, 1.0) if G.busy else 1.0
		k = 1.0 - pow(1.0 - k, 3.0)
		r.position.y += 12.0 * (1.0 - k)
		_box_card(f, box_res[i], r)
		if k < 1.0:
			_fade(r.grow(14.0), 1.0 - k, Color("#141a21"))
	# 위아래 가리기
	var tmask := Rect2(pr.position.x + 2.0, pr.position.y + 2.0, pr.size.x - 4.0, gy - pr.position.y - 2.0)
	var bmask := Rect2(pr.position.x + 2.0, gy + G.gvis, pr.size.x - 4.0, pr.end.y - gy - G.gvis - 2.0)
	var col := func(y: float) -> Color: return Color("#18212a").lerp(Color("#0e1318"), clampf((y - pr.position.y) / pr.size.y, 0.0, 1.0))
	_gbox(tmask, [[0.0, col.call(tmask.position.y)], [1.0, col.call(tmask.end.y)]], 180.0, [10.0, 10.0, 0.0, 0.0])
	_gbox(bmask, [[0.0, col.call(bmask.position.y)], [1.0, col.call(bmask.end.y)]], 180.0, [0.0, 0.0, 10.0, 10.0])
	# 창 밖으로 삐져나온 카드 가리기
	_dimbg(Rect2(0, 0, u.x, pr.position.y))
	_dimbg(Rect2(0, pr.end.y, u.x, u.y - pr.end.y))
	_dimbg(Rect2(0, pr.position.y, pr.position.x, pr.size.y))
	_dimbg(Rect2(pr.end.x, pr.position.y, u.x - pr.end.x, pr.size.y))
	_gbox(pr, Color(0, 0, 0, 0), 180.0, 12.0, Color("#c9a255"), 2.0)
	# 흔들리는 상자 → 커지며 사라짐 (웹 bshake)
	if et < 1.0:
		var k := et
		var rot := 0.0
		var sc := 1.0
		var KF := [[0.0, 0.0, 1.0], [0.15, -9.0, 1.0], [0.3, 9.0, 1.0], [0.45, -12.0, 1.0], [0.6, 12.0, 1.05], [0.8, 0.0, 1.15], [1.0, 0.0, 1.7]]
		for j in range(1, KF.size()):
			if k <= KF[j][0]:
				var a: Array = KF[j - 1]
				var b: Array = KF[j]
				var q: float = (k - a[0]) / (b[0] - a[0])
				q = q * q
				rot = lerpf(a[1], b[1], q)
				sc = lerpf(a[2], b[2], q)
				break
		var al := 1.0 if k < 0.8 else 1.0 - (k - 0.8) / 0.2
		var c := Vector2(u.x / 2.0, pr.position.y + 18.0 + 38.0)
		var M := inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(deg_to_rad(rot), Vector2(sc, sc), 0.0, c)
		draw_set_transform_matrix(M)
		var br := Rect2(-40, -35, 80, 70)
		var gold := box_res.any(func(q2): return q2.get("g", "") == "kro")
		if gold and not box_star:
			_bglow(br, Color(1.0, 0.82, 0.35, al), 30.0, 9.0)
		if box_star:
			_bglow(br, Color(0.75, 0.55, 1.0, 0.6 * al), 22.0, 12.0)
			_gbox(br, [[0.0, Color(Color("#fff1a8"), al)], [0.6, Color(Color("#c08cff"), al)], [1.0, Color(Color("#5a3a8a"), al)]], 135.0, 12.0, Color(Color("#2a1c08"), al), 3.0)
		else:
			_gbox(br, [[0.0, Color(Color("#e8c36a"), al)], [1.0, Color(Color("#8a6420"), al)]], 180.0, 9.0, Color(Color("#2a1c08"), al), 3.0)
		if k > 0.6:
			_gbox(br, Color(1, 1, 1, (k - 0.6) * 1.2 * al), 180.0, 9.0)
		_ui_reset()
	# 요약
	var tot := 0
	var done := 0
	var ref := 0
	for q in box_res:
		tot += int(q.get("amt", q.get("a", 0)))
		if q.res == "done":
			done += 1
		ref += int(q.get("v", 0))
	var sm := ""
	if box_star:
		sm = "별 뽑기 " + str(box_res.size()) + "회 · 별 파편 +" + str(tot) + " (보유 " + str(SV.sfrag) + "/30) · 천장 " + str(SV.spity) + "/500"
	else:
		sm = "상자 " + str(box_res.size()) + "개 · 파편 " + str(tot) + "개" + (" · 완성 " + str(done) + "개!" if done > 0 else "") + (" · 청석 환급 +" + str(ref) if ref > 0 else "")
	draw_string(f, Vector2(pr.position.x, pr.position.y + 18.0 + G.ah + 12.0 + 15.0), sm, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 14, Color("#ffd27a"))
	sb_box = {}
	if box_max > 0.0:
		var hh := maxf(40.0, G.gvis * G.gvis / (G.gvis + box_max))
		var tr := Rect2(pr.end.x - 15.0, gy, 10.0, G.gvis)
		sb_box = {"r": tr, "th": hh}
		_gbox(tr, Color("#0b1015"), 180.0, 5.0)
		_gbox(Rect2(tr.position.x + 1.0, gy + (G.gvis - hh) * box_scroll / box_max, 8.0, hh), Color("#56687a"), 180.0, 4.0)
	for it in ui:
		if it.id == "boxok":
			_wbtn({"r": it.r, "l": "여는 중..." if G.busy else "확인", "sty": "go", "en": not G.busy, "it": it, "fc": Color("#10161c")}, hov)
		elif it.id == "boxskip":
			_wbtn({"r": it.r, "l": "건너뛰기 ▸▸", "sty": "bxsk", "en": true, "it": it, "fs": 12}, hov)

func _box_card(f: Font, q: Dictionary, r: Rect2) -> void:
	var big: bool = q.res in ["jack", "star", "starx"]
	var bc := Color("#2f5a7a")
	var st = Color("#0b1015")
	if big:
		bc = Color("#fff1a8")
		st = [[0.0, Color("#3a2a08")], [0.5, Color("#2a1440")], [1.0, Color("#0b2a3a")]]
		var gk := 0.5 + 0.5 * sin(t_real * 2.6)
		_bglow(r, Color(1.0, 0.89, 0.48, 0.5).lerp(Color(0.75, 0.55, 1.0, 0.8), gk), 18.0 + 22.0 * gk, 12.0)
	elif box_star:
		bc = Color("#c08cff") if int(q.get("a", 0)) >= 4 else Color("#6a4a9a")
		st = _g2("#1e1430", "#0b1015")
		if int(q.get("a", 0)) >= 4:
			_bglow(r, Color(0.75, 0.55, 1.0, 0.6), 18.0, 12.0)
	elif q.get("g", "") == "kro":
		bc = Color("#e8c36a")
		st = _g2("#2a2210", "#0b1015")
		_bglow(r, Color(0.91, 0.76, 0.42, 0.35), 12.0, 12.0)
	elif q.get("g", "") == "b":
		bc = Color("#5a86c8")
	if q.res == "done":
		bc = Color("#7affd4")
		_bglow(r, Color(0.48, 1.0, 0.83, 0.45), 16.0, 12.0)
	_gbox(r, st, 135.0 if big else 180.0, 12.0, bc, 2.0)
	var x := r.position.x + 14.0
	var w := r.size.x - 28.0
	var y := r.position.y + 14.0
	if box_star and q.res == "sf":
		var a: int = int(q.a)
		var sc := Color("#f0e0ff") if a >= 4 else Color("#ffd25a")
		_bglow(Rect2(r.get_center().x - 10.0, y + 10.0, 20.0, 20.0), Color(Color("#c08cff") if a >= 4 else Color("#ffd25a"), 0.6), 12.0, 10.0)
		draw_string(f, Vector2(r.position.x, y + 42.0), "★", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, sc)
		y += 48.0 + 5.0
		draw_string(fb(), Vector2(r.position.x, y + 18.0), "별 파편", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color("#dfe6ea"))
		y += 27.0
		draw_string(fb(), Vector2(r.position.x, y + 16.0), "×" + str(a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, [Color("#7fd2ff"), Color("#9effa8"), Color("#ffd27a")][mini(3, a) - 1])
		return
	var al := HORIZONTAL_ALIGNMENT_CENTER if big else HORIZONTAL_ALIGNMENT_LEFT
	var tag := ""
	var nm2 := ""
	var amt := ""
	var amc := Color("#7fd2ff")
	var emt := ""
	var emc := Color("#c9d3dc")
	if q.res != "starx":
		var pvh := (r.size.x - 28.0) * 0.6
		var pv := Rect2(x, y, w, pvh)
		if q.res == "jack":
			var si := 0
			for j in SETS.size():
				if SETS[j].r == q.it.id:
					si = j
			draw_preview(pv, "set", si, t_real)
		else:
			var cat: String = q.get("cat", "s")
			draw_preview(pv, "s" if cat == "r" else cat, q.it.id, t_real)
		y += pvh + 5.0
	if box_star:
		tag = "★ 걸작 완품" + ("" if q.res == "starx" else " · " + {"s": "로봇", "b": "기지", "t": "테마"}.get(q.get("cat", "s"), ""))
		nm2 = "모든 걸작 보유 중" if q.res == "starx" else q.it.n
		amt = "별 파편 +30" if q.res == "starx" else "걸작 획득!"
		amc = Color("#ffd27a")
	else:
		var CN := {"r": "로봇", "b": "기지", "t": "테마", "set": "세트"}
		tag = CN.get(q.cat, "") + " · " + ("크로" if q.g == "kro" else ("주" if q.g == "ju" else "기지"))
		nm2 = q.it.n
		if q.res == "jack":
			amt = "크로 세트 획득!"
			amc = Color("#ffd27a")
			emt = ("이미 보유 → 청석 +" + str(q.v)) if int(q.v) > 0 else "로봇 + 기지 + 테마 전부!"
		else:
			var a: int = int(q.amt)
			amt = "파편 ×" + str(a)
			amc = [Color("#7fd2ff"), Color("#9effa8"), Color("#ffd27a")][clampi(a, 1, 3) - 1]
			if q.res == "done":
				emt = "완성!"
				emc = Color("#7affd4")
			elif q.res == "dup":
				emt = "보유 중 → 청석 +" + str(q.v)
			else:
				emt = str(q.c) + " / " + str(q.need)
	draw_string(f, Vector2(x, y + 13.0), tag, al, w, 13, Color("#8a9bad"))
	y += 21.0
	var nfs := 22 if big else 18
	draw_string(fb(), Vector2(x, y + nfs - 2.0), nm2, al, w, nfs, Color("#fff1a8") if big else (Color("#ffe28a") if q.get("g", "") == "kro" else Color("#dfe6ea")))
	y += nfs + 9.0
	if q.res == "done":
		_icon("sparkle", Vector2(x + 7.0, y + 30.0), 13.0)
	if amc == Color("#ffd27a"):
		draw_string(fb(), Vector2(x, y + 16.0), amt, al, w, 16, Color(1.0, 0.82, 0.48, 0.35))
	draw_string(fb(), Vector2(x, y + 15.0), amt, al, w, 16, amc)
	y += 25.0
	if emt != "":
		draw_string(fb() if q.res == "done" else f, Vector2(x + (17.0 if q.res == "done" else 0.0), y + 14.0), emt, al, w, 14, emc)

# ── 가상 결제 창 (#cashw) ──
func _build_cash() -> void:
	ui.clear()
	var u := ui_size()
	var r := Rect2(u.x / 2.0 - 180.0, u.y / 2.0 - 125.0, 360.0, 250.0)
	_add("cashno", Rect2(r.position.x + 26.0, r.end.y - 62.0, 150.0, 40.0))
	_add("cashok", Rect2(r.end.x - 176.0, r.end.y - 62.0, 150.0, 40.0))

func _cash_overlay(f: Font, hov) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
	var r := Rect2(u.x / 2.0 - 180.0, u.y / 2.0 - 125.0, 360.0, 250.0)
	_bglow(r, Color(0, 0, 0, 0.6), 30.0, 12.0)
	_gbox(r, _g2("#18212a", "#0e1318"), 180.0, 12.0, Color("#c9a255"), 2.0)
	var P: Dictionary = CASH[clampi(cash_sel, 0, CASH.size() - 1)]
	_gem(Vector2(u.x / 2.0, r.position.y + 48.0), 30.0)
	var l1 := "청석 " + _cm(P.a) + "개" + (" (보너스 " + str(P.bn) + " 포함)" if int(P.bn) > 0 else "") + "를"
	draw_string(fb(), Vector2(r.position.x, r.position.y + 100.0), l1, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color("#dfe6ea"))
	draw_string(fb(), Vector2(r.position.x, r.position.y + 124.0), "₩" + _cm(P.w) + "에 구매할까요?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 15, Color("#dfe6ea"))
	draw_string(f, Vector2(r.position.x, r.position.y + 156.0), "가상 결제예요. 실제로 돈이 빠져나가지 않아요.", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#8a9bad"))
	for it in ui:
		if it.id == "cashno":
			_wbtn({"r": it.r, "l": "취소", "sty": "def", "en": true, "it": it}, hov)
		elif it.id == "cashok":
			_wbtn({"r": it.r, "l": "결제하기", "sty": "go", "en": true, "it": it}, hov)


# ═════════ 계정 관리 창 (웹 새 디자인 .acx) · 프로필 카드 · 확률표 · 패치 노트 ═════════
var acp_open := false
var conn_msg := ""
var conn_t := 0.0
var acp_msg := ""
var acp_ver = null
var lob_anchor := {}
var sb_lob := {}
var sb_box := {}
var sb_pass := {}

func _dimbg(r: Rect2) -> void:
	if r.size.x < 1.0 or r.size.y < 1.0:
		return
	_page_bg(r)
	draw_rect(r, Color(0, 0, 0, 0.6))

# ── 프로필 카드 (로비 왼쪽 위 · 나중에 친구 기능도 여기서) ──
func _prof_info() -> Array:
	var nk := ""
	var tg := ""
	var st := "이 기기에만 저장 · 눌러서 로그인"
	var dot := Color("#7f93a6")
	if acct != null and acct.ses != null and str(acct.ses.get("nick", "")) != "":
		nk = str(acct.ses.nick)
		tg = "#" + str(acct.ses.get("tag", "SR1"))
		var sw: String = {"ok": "저장됨", "sync": "저장 중…", "off": "오프라인", "err": "저장 실패", "conf": "확인 중"}.get(acct.state, "연결됨")
		if TEST:
			sw = "테스트 · 클라우드 꺼짐"
		st = acct.srv_name() + " · " + sw
		dot = {"ok": Color("#4fd17a"), "sync": Color("#ffd76a")}.get(acct.state, Color("#ff8a6b"))
		if TEST:
			dot = Color("#ff9a5a")
	return [nk, tg, st, dot]

func _safe_top() -> float:
	if not touch_ui():
		return 0.0
	var sa := DisplayServer.get_display_safe_area()
	return maxf(maxf(0.0, float(sa.position.y)), 26.0) / us

func _prof_rect() -> Rect2:
	var P := _prof_info()
	var w := maxf(_tw(str(P[0]) if P[0] != "" else "로그인 안 함", 15, true) + _tw(P[1], 12), _tw(P[2], 12) + 14.0)
	return Rect2(12, 10 + _safe_top(), 58.0 + w + 16.0, 50.0)

func _prof_card(f: Font, hov) -> void:
	var r := _prof_rect()
	var P := _prof_info()
	var h: bool = hov != null and hov.id == "lprof"
	_gbox(r, Color("#1a2430") if not h else Color("#223040"), 180.0, 12.0, Color("#c9a255") if h else Color("#2c3a49"))
	var c := r.position + Vector2(27, 25)
	_gbox(Rect2(c - Vector2(17, 17), Vector2(34, 34)), _g2("#ffe08a", "#c9962f"), 135.0, 17.0)
	var L: String = str(P[0]).substr(0, 1).to_upper() if P[0] != "" else "?"
	draw_string(fb(), Vector2(c.x - 17, c.y + 6), L, HORIZONTAL_ALIGNMENT_CENTER, 34, 17, Color("#1c1406"))
	var x := r.position.x + 52.0
	if P[0] != "":
		draw_string(fb(), Vector2(x, r.position.y + 22), P[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		draw_string(f, Vector2(x + _tw(P[0], 15, true) + 1.0, r.position.y + 22), P[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fa3b5"))
	else:
		draw_string(fb(), Vector2(x, r.position.y + 22), "로그인 안 함", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dfe6ea"))
	draw_circle(Vector2(x + 4.0, r.position.y + 37.0), 4.0, P[3])
	draw_string(f, Vector2(x + 12.0, r.position.y + 41), P[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#aab8c5"))

# ── 계정 관리 창 ──
func _acp_geo() -> Dictionary:
	var u := ui_size()
	var W := minf(460.0, u.x - 32.0)
	var logged: bool = acct != null and acct.ses != null and str(acct.ses.get("nick", "")) != ""
	var H := 22.0 + 30.0 + 12.0 + 82.0 + 12.0
	if logged:
		H += 66.0 + 12.0
		if acp_msg != "":
			H += 24.0
		H += (48.0 + 8.0) * (2 if acp_ver == false else 1)
		if acct.is_admin():
			H += 48.0 + 8.0
		if acct.is_tester:
			H += 48.0 + 8.0
		H += 4.0 + 44.0
	else:
		if acp_msg != "":
			H += 24.0
		H += 44.0 + 8.0 + 44.0
	H += 22.0
	var x := (u.x - W) / 2.0
	var y := maxf(10.0, (u.y - H) / 2.0)
	return {"r": Rect2(x, y, W, H), "logged": logged}

func _build_acp() -> void:
	ui.clear()
	var G := _acp_geo()
	var r: Rect2 = G.r
	_add("acp_bg", Rect2(Vector2.ZERO, ui_size()))
	var x := r.position.x + 22.0
	var w := r.size.x - 44.0
	var y := r.position.y + 22.0 + 30.0 + 12.0 + 82.0 + 12.0
	if G.logged:
		_add("acp_save", Rect2(r.end.x - 22.0 - 14.0 - 96.0, y + 16.0, 96.0, 34.0))
		y += 66.0 + 12.0
		if acp_msg != "":
			y += 24.0
		if acp_ver == false:
			_add("acp_vsend", Rect2(x, y, w, 48.0))
			y += 56.0
		_add("acp_reset", Rect2(x, y, w, 48.0))
		y += 56.0
		if acct.is_admin():
			_add("acp_admin", Rect2(x, y, w, 48.0))
			y += 56.0
		if acct.is_tester:
			_add("acp_srv", Rect2(x, y, w, 48.0))
			y += 56.0
		y += 4.0
		_add("acp_out", Rect2(x, y, (w - 8.0) / 2.0, 44.0))
		_add("acp_close", Rect2(x + (w + 8.0) / 2.0, y, (w - 8.0) / 2.0, 44.0))
	else:
		if acp_msg != "":
			y += 24.0
		_add("acp_login", Rect2(x, y, w, 44.0))
		_add("acp_close", Rect2(x, y + 52.0, w, 44.0))

func _acp_draw(f: Font, hov) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0.016, 0.031, 0.047, 0.78))
	var G := _acp_geo()
	var r: Rect2 = G.r
	_bglow(r, Color(0, 0, 0, 0.6), 30.0, 14.0)
	_gbox(r, Color("#121a22"), 180.0, 14.0, Color("#c9a255"))
	var x := r.position.x + 22.0
	var w := r.size.x - 44.0
	var y := r.position.y + 22.0
	_icon_user(Vector2(x + 10.0, y + 14.0), 18.0)
	draw_string(fb(), Vector2(x + 26.0, y + 22.0), "계정 관리", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffd76a"))
	y += 30.0 + 12.0
	# 프로필 (axh)
	var hr := Rect2(x, y, w, 82.0)
	_gbox(hr, Color("#1a2430"), 180.0, 12.0, Color("#2c3a49"))
	var c := hr.position + Vector2(14.0 + 26.0, 41.0)
	_gbox(Rect2(c - Vector2(26, 26), Vector2(52, 52)), _g2("#ffe08a", "#c9962f"), 135.0, 26.0)
	var nk := str(acct.ses.get("nick", "?")) if G.logged else ""
	draw_string(fb(), Vector2(c.x - 26.0, c.y + 9.0), nk.substr(0, 1).to_upper() if nk != "" else "?", HORIZONTAL_ALIGNMENT_CENTER, 52.0, 24, Color("#1c1406"))
	var tx := hr.position.x + 14.0 + 52.0 + 14.0
	if G.logged:
		draw_string(fb(), Vector2(tx, y + 36.0), nk, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(fb(), Vector2(tx + _tw(nk, 22, true) + 2.0, y + 36.0), "#" + str(acct.ses.get("tag", "SR1")), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#8fa3b5"))
		var em := str(acct.ses.get("email", ""))
		draw_string(f, Vector2(tx, y + 62.0), em, HORIZONTAL_ALIGNMENT_LEFT, hr.end.x - tx - 100.0, 13, Color("#aab8c5"))
		var pv := "확인 중…"
		var pb := Color("#2a3542")
		var pc := Color("#aab8c5")
		if acp_ver == true:
			pv = "✓ 인증됨"
			pb = Color("#1d4a2e")
			pc = Color("#8ee4a8")
		elif acp_ver == false:
			pv = "⚠ 미인증"
			pb = Color("#5a3a12")
			pc = Color("#ffc46b")
		elif acp_ver is String:
			pv = "확인 실패"
		var pw := _tw(pv, 12, true) + 16.0
		var px := minf(tx + _tw(em, 13) + 8.0, hr.end.x - 12.0 - pw)
		_gbox(Rect2(px, y + 48.0, pw, 20.0), pb, 180.0, 10.0)
		draw_string(fb(), Vector2(px, y + 62.0), pv, HORIZONTAL_ALIGNMENT_CENTER, pw, 12, pc)
	else:
		draw_string(fb(), Vector2(tx, y + 36.0), "로그인 안 함", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		draw_string(f, Vector2(tx, y + 62.0), "기록이 이 기기에만 저장돼요", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#aab8c5"))
	y += 82.0 + 12.0
	if G.logged:
		# 서버 · 저장 (axr)
		var ar := Rect2(x, y, w, 66.0)
		_gbox(ar, Color("#1a2430"), 180.0, 12.0, Color("#2c3a49"))
		var cw := (w - 28.0 - 110.0) / 2.0
		draw_string(f, Vector2(x + 14.0, y + 26.0), "서버", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7f93a6"))
		draw_string(fb(), Vector2(x + 14.0, y + 48.0), acct.srv_name() + "", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e6edf3"))
		draw_string(f, Vector2(x + 14.0 + cw, y + 26.0), "저장", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7f93a6"))
		var P := _prof_info()
		draw_circle(Vector2(x + 14.0 + cw + 5.0, y + 43.0), 4.5, P[3])
		var sw: String = {"ok": "저장됨", "sync": "저장 중…", "off": "오프라인", "err": "저장 실패", "conf": "확인 중"}.get(acct.state, "연결됨")
		if TEST:
			sw = "테스트 모드 (꺼짐)"
		draw_string(fb(), Vector2(x + 14.0 + cw + 15.0, y + 48.0), sw, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e6edf3"))
		y += 66.0 + 12.0
	if acp_msg != "":
		draw_string(f, Vector2(r.position.x, y + 15.0), acp_msg, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color("#9fd8a8"))
		y += 24.0
	for it in ui:
		var lab := ""
		var sty := "pf"
		var ic := ""
		var al := 0
		match it.id:
			"acp_save":
				lab = "지금 저장"
			"acp_vsend":
				lab = "인증 메일 다시 보내기"
				ic = "mail"
				al = 1
			"acp_reset":
				lab = "비밀번호 재설정 메일 받기"
				ic = "key"
				al = 1
			"acp_srv":
				lab = "🧪 서버 바꾸기 → " + ("정식 서버" if acct.srv.ends_with("T") else "테스트 서버")
				ic = "key"
				al = 1
			"acp_admin":
				lab = "운영자 화면 열기"
				ic = "mail"
				al = 1
			"acp_out":
				lab = "로그아웃"
				sty = "pfo"
			"acp_close":
				lab = "닫기"
				sty = "pfgo" if _acp_geo().logged else "pf"
			"acp_login":
				lab = "로그인 / 회원가입"
				sty = "pfgo"
			_:
				continue
		if al == 1:
			var hv: bool = hov == it
			_gbox(it.r, Color("#24323f") if hv else Color("#1c2733"), 180.0, 8.0, Color("#4fd1b5") if hv else Color("#33414d"))
			if ic == "mail":
				_icon_mail(it.r.position + Vector2(24.0, 24.0), 18.0)
			else:
				_icon_key(it.r.position + Vector2(24.0, 24.0), 18.0)
			draw_string(f, it.r.position + Vector2(44.0, 29.0), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e6edf3"))
		else:
			_wbtn({"r": it.r, "l": lab, "sty": sty, "en": true, "it": it, "fs": 14 if it.id != "acp_save" else 13}, hov)

func _boot_toast(f: Font) -> void:
	var u := ui_size()
	var s := "계정 기록 불러오는 중…"
	var w := _tw(s, 13, true) + 50.0
	var r := Rect2((u.x - w) / 2.0, u.y - 54.0 - (14.0 if touch_ui() else 0.0), w, 34.0)
	_bglow(r, Color(0, 0, 0, 0.5), 12.0, 17.0)
	_gbox(r, Color("#121a22"), 180.0, 17.0, Color("#c9a255"))
	var c := r.position + Vector2(20.0, 17.0)
	draw_arc(c, 8.0, 0.0, TAU, 24, Color("#2b3640"), 3.0, true)
	draw_arc(c, 8.0, t_real * 5.0, t_real * 5.0 + 1.9, 12, Color("#ffd76a"), 3.0, true)
	draw_string(fb(), r.position + Vector2(36.0, 22.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e6edf3"))

func _conn_draw(f: Font) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0.016, 0.031, 0.047, 0.55))
	var r := Rect2(u.x / 2.0 - 170.0, u.y / 2.0 - 58.0, 340.0, 116.0)
	_bglow(r, Color(0, 0, 0, 0.6), 24.0, 14.0)
	_gbox(r, Color("#121a22"), 180.0, 14.0, Color("#c9a255"))
	var c := r.position + Vector2(44.0, 50.0)
	draw_arc(c, 16.0, 0.0, TAU, 32, Color("#2b3640"), 4.0, true)
	var a0 := t_real * 5.0
	draw_arc(c, 16.0, a0, a0 + 1.9, 16, Color("#ffd76a"), 4.0, true)
	draw_string(fb(), r.position + Vector2(78.0, 46.0), conn_msg, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 90.0, 16, Color("#e6edf3"))
	draw_string(f, r.position + Vector2(78.0, 70.0), "계정 기록을 불러오고 있어요", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 90.0, 12, Color("#8a9bad"))
	if t_real - conn_t > 6.0:
		draw_string(f, Vector2(r.position.x, r.end.y - 14.0), "오래 걸리면 인터넷 연결을 확인해 주세요", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#ffc46b"))

var pause_set := false
func _pset_geo() -> Dictionary:
	var u := ui_size()
	var W := minf(460.0, u.x - 32.0)
	var H := 70.0 + 150.0 + 10.0 + 108.0 + 46.0 + 22.0
	return {"r": Rect2((u.x - W) / 2.0, (u.y - H) / 2.0, W, H)}

func _pset_draw(f: Font, hov) -> void:
	var u := ui_size()
	draw_rect(Rect2(Vector2.ZERO, u), Color(0, 0, 0, 0.6))
	var r: Rect2 = _pset_geo().r
	_bglow(r, Color(0, 0, 0, 0.6), 24.0, 14.0)
	_gbox(r, Color("#121a22"), 180.0, 14.0, Color("#c9a255"))
	draw_string(fb(), r.position + Vector2(24.0, 42.0), "설정", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffd76a"))
	draw_string(f, r.position + Vector2(80.0, 42.0), "게임 중에 바꿀 수 있는 것들이에요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8a9bad"))
	var names := {"vol_s": "효과음", "vol_b": "배경음", "uis": "UI 크기"}
	for it in ui:
		var R: Rect2 = it.r
		match it.id:
			"gsl":
				var k: String = it.arg
				draw_string(f, Vector2(r.position.x + 24.0, R.position.y + 23.0), names[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c9d3dc"))
				var nm: Array = {"uis": [50, 130], "vol_s": [0, 100], "vol_b": [0, 100]}[k]
				var v: float = clampf((float(SV[k]) - float(nm[0])) / float(nm[1] - nm[0]), 0.0, 1.0)
				var tx := R.position.x + 11.0
				var tw := R.size.x - 22.0
				var cy := R.position.y + 17.0
				_gbox(Rect2(tx, cy - 3.0, tw, 6.0), Color("#3a4a58"), 180.0, 3.0)
				_gbox(Rect2(tx, cy - 3.0, tw * v, 6.0), Color("#e8c36a"), 180.0, 3.0)
				draw_circle(Vector2(tx + tw * v, cy), 9.0, Color("#ffd76a") if slider_drag == k else Color("#e8c36a"))
				draw_string(fb(), Vector2(R.end.x + 4.0, R.position.y + 23.0), str(int(SV[k])) + ("%" if k == "uis" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffe9b8"))
			"gmute":
				_wbtn({"r": R, "l": "음소거 끄기" if SV.mute else "음소거", "sty": "pf", "en": true, "it": it, "fs": 14}, hov)
			"keys":
				_wbtn({"r": R, "l": "조작법 보기", "sty": "pf", "en": true, "it": it, "fs": 14}, hov)
			"gbgm":
				_wbtn({"r": R, "l": "배경음: " + _bgm_name(str(SV.get("bgm", "auto"))) + "  ▸", "sty": "pf", "en": true, "it": it, "fs": 14}, hov)
			"psback":
				_wbtn({"r": R, "l": "돌아가기", "sty": "pfgo", "en": true, "it": it, "fs": 15}, hov)
	if int(SV.uis) != roundi(us * 100.0):
		draw_string(f, Vector2(r.position.x, r.end.y + 22.0), "UI 크기는 돌아가기를 누르면 바뀌어요", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, Color("#8a9bad"))

func _icon_user(c: Vector2, s: float) -> void:
	draw_circle(c + Vector2(0, -s * 0.18), s * 0.22, Color("#ffd76a"))
	draw_colored_polygon(_rr_pts(Rect2(c.x - s * 0.38, c.y + s * 0.08, s * 0.76, s * 0.4), [s * 0.3, s * 0.3, s * 0.06, s * 0.06]), Color("#ffd76a"))

func _icon_mail(c: Vector2, s: float) -> void:
	var r := Rect2(c.x - s * 0.5, c.y - s * 0.34, s, s * 0.68)
	draw_rect(r, Color("#e8eef2"))
	draw_polyline(PackedVector2Array([r.position, c + Vector2(0, s * 0.06), Vector2(r.end.x, r.position.y)]), Color("#3a9ce0"), 2.0)

func _icon_key(c: Vector2, s: float) -> void:
	draw_circle(c + Vector2(-s * 0.22, 0), s * 0.22, Color("#ffd76a"))
	draw_circle(c + Vector2(-s * 0.22, 0), s * 0.09, Color("#1c2733"))
	draw_rect(Rect2(c.x - s * 0.02, c.y - s * 0.06, s * 0.52, s * 0.12), Color("#ffd76a"))
	draw_rect(Rect2(c.x + s * 0.3, c.y, s * 0.1, s * 0.2), Color("#ffd76a"))

func acp_press(id: String) -> void:
	match id:
		"acp_bg":
			pass
		"acp_close":
			acp_open = false
		"acp_login":
			acp_open = false
			if acct != null:
				acct.show_login("")
		"acp_out":
			acp_open = false
			if acct != null:
				acct.logout()
		"acp_save":
			if TEST:
				acp_msg = "테스트 모드라 클라우드에 올리지 않아요"
				return
			acp_msg = "저장 중…"
			await acct.push(true)
			acp_msg = "저장했어요" if acct.state == "ok" else "저장 실패 · 나중에 다시 해 주세요"
		"acp_vsend":
			acp_msg = "보내는 중…"
			var tk: String = await acct.tok()
			var j: Dictionary = await acct.idt("sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": tk})
			acp_msg = acct.err_txt(j.err) if j.has("err") else "인증 메일을 보냈어요 · 메일함을 확인해 주세요"
		"acp_admin":
			acp_open = false
			adm.open()
		"acp_srv":
			acp_msg = "서버를 바꾸는 중…"
			await acct.switch_srv()
			acp_msg = acct.srv_name() + "로 바꿨어요"
		"acp_reset":
			acp_msg = "보내는 중…"
			var j2: Dictionary = await acct.idt("sendOobCode", {"requestType": "PASSWORD_RESET", "email": str(acct.ses.get("email", ""))})
			acp_msg = acct.err_txt(j2.err) if j2.has("err") else "비밀번호 재설정 메일을 보냈어요"

func acp_show() -> void:
	acp_open = true
	acp_msg = ""
	acp_ver = null
	if acct == null or acct.ses == null:
		return
	if acct.ses.get("ev", false):
		acp_ver = true
		return
	var tk: String = await acct.tok()
	if tk == "":
		acp_ver = "x"
		return
	var j: Dictionary = await acct.idt("lookup", {"idToken": tk})
	if j.has("err"):
		acp_ver = "x"
		return
	var L: Array = j.get("users", [])
	acp_ver = L.size() > 0 and bool(L[0].get("emailVerified", false))

# ── 확률표 카드 ──
func _L_pcard(P: Dictionary, x0: float, y: float, W: float) -> float:
	var rows: Array = P.rows
	var acc: Color = P.col
	var h := 46.0 + rows.size() * 46.0 + 8.0
	var r := Rect2(x0, y, W, h)
	_E({"k": "box", "r": r, "st": Color("#10151a"), "rad": 10.0, "bc": Color(acc, 0.55)})
	_E({"k": "box", "r": Rect2(x0 + 1.0, y + 1.0, W - 2.0, 44.0), "st": [[0.0, Color(acc, 0.22)], [1.0, Color(acc, 0.04)]], "ang": 90.0, "rad": [9.0, 9.0, 0.0, 0.0]})
	var tx := x0 + 16.0
	if P.get("ic", "") != "":
		_E({"k": "t", "p": Vector2(tx, y + 29.0), "s": P.t, "fs": 16, "b": true, "c": Color("#ffe9b8"), "ic": P.ic})
	else:
		_E({"k": "t", "p": Vector2(tx, y + 29.0), "s": P.t, "fs": 16, "b": true, "c": Color("#ffe9b8")})
	if P.get("sub", "") != "":
		var sw := _tw(P.sub, 13, true) + 20.0
		_E({"k": "box", "r": Rect2(x0 + W - 14.0 - sw, y + 11.0, sw, 24.0), "st": Color("#0b1015"), "rad": 12.0, "bc": Color(acc, 0.7)})
		_E({"k": "t", "p": Vector2(x0 + W - 14.0 - sw, y + 28.0), "s": P.sub, "fs": 13, "b": true, "c": acc, "al": 1, "w": sw})
	var yy := y + 46.0
	var bx := x0 + W * 0.5
	var bw := W * 0.5 - 14.0 - 96.0
	for i in rows.size():
		var q: Array = rows[i]
		if i % 2 == 1:
			_E({"k": "box", "r": Rect2(x0 + 1.0, yy, W - 2.0, 46.0), "st": Color("#141b22")})
		var nt: String = q[2] if q.size() > 2 else ""
		_E({"k": "t", "p": Vector2(tx, yy + (19.0 if nt != "" else 28.0)), "s": q[0], "fs": 14, "b": true, "c": q[3] if q.size() > 3 else Color("#dfe6ea"), "w": bx - tx - 10.0})
		if nt != "":
			_E({"k": "t", "p": Vector2(tx, yy + 37.0), "s": nt, "fs": 12, "c": Color("#8a9bad"), "w": bx - tx - 10.0})
		if bw > 40.0:
			_E({"k": "box", "r": Rect2(bx, yy + 19.0, bw, 8.0), "st": Color("#05080b"), "rad": 4.0})
			_E({"k": "box", "r": Rect2(bx, yy + 19.0, maxf(4.0, bw * clampf(float(q[1]), 0.0, 1.0)), 8.0), "st": [[0.0, Color(acc, 0.6)], [1.0, acc]], "ang": 90.0, "rad": 4.0})
		_E({"k": "t", "p": Vector2(x0 + W - 16.0 - 90.0, yy + 30.0), "s": _pc(float(q[1])), "fs": 19, "b": true, "c": Color("#ffd76a"), "al": 2, "w": 90.0})
		yy += 46.0
	return y + h + 14.0

func _rows_prob() -> Array:
	var JN := 1.0 - 1e-4
	var cnt := func(L: Array, g: String) -> int: return L.filter(func(q): return q.get("g", "") == g and not q.has("ex")).size()
	var rj: int = cnt.call(SK, "ju")
	var rk: int = cnt.call(SK, "kro")
	var bn: int = BS.filter(func(q): return not q.has("ex") and q.get("g", "") != "star").size()
	var tj: int = cnt.call(TS, "ju")
	var tk: int = cnt.call(TS, "kro")
	var ks: int = SETS.filter(func(S): return item(S.r).g == "kro").size()
	var ms := star_all().size()
	var gold := Color("#e8c36a")
	var R: Array = []
	R.append({"jump": [["소로 상자", "box", "gift"], ["파편 개수", "frag", ""], ["★ 별 뽑기", "star", ""], ["배틀패스", "bp", "scroll"]]})
	R.append({"p": "모든 확률은 게임 안에서 실제로 쓰이는 값과 같아요 · 뽑을 때마다 따로따로 적용돼요", "mb": 12.0})
	R.append({"anchor": "box"})
	R.append({"pcard": {"t": "소로 상자", "ic": "gift", "sub": "청석 600", "col": gold, "rows": [
		["주 등급 로봇 스킨 파편", 0.4 * 0.82 * JN, "1종당 " + _pc(0.4 * 0.82 * JN / rj) + " · " + str(rj) + "종"],
		["크로 등급 로봇 스킨 파편", 0.4 * 0.18 * JN, "1종당 " + _pc(0.4 * 0.18 * JN / rk) + " · " + str(rk) + "종", Color("#ffe28a")],
		["기지 스킨 파편", 0.25 * JN, "1종당 " + _pc(0.25 * JN / bn) + " · " + str(bn) + "종"],
		["주 등급 테마 파편", 0.35 * 0.82 * JN, "1종당 " + _pc(0.35 * 0.82 * JN / tj) + " · " + str(tj) + "종"],
		["크로 등급 테마 파편", 0.35 * 0.18 * JN, "1종당 " + _pc(0.35 * 0.18 * JN / tk) + " · " + str(tk) + "종", Color("#ffe28a")],
		["크로 세트 통째로 (잭팟)", 1e-4, "1세트당 " + _pc(1e-4 / ks) + " · " + str(ks) + "세트", Color("#7affd4")]]}})
	R.append({"anchor": "frag"})
	R.append({"pcard": {"t": "한 번에 나오는 파편 개수", "sub": "로봇 6 · 기지 5 · 테마 4개면 완성", "col": Color("#7fd2ff"), "rows": [
		["파편 1개", 0.65, ""], ["파편 2개", 0.25, ""], ["파편 3개", 0.10, ""]]}})
	R.append({"p": "이미 가진 스킨의 파편은 청석으로 돌려받아요 · 주 15 · 기지 20 · 크로 60 (파편 1개당)", "mb": 12.0})
	var Q := 1.0 - 1e-5
	R.append({"anchor": "star"})
	R.append({"pcard": {"t": "★ 별 뽑기", "sub": "별석 15", "col": Color("#c08cff"), "rows": [
		["별 파편 1개", 0.54 * Q, ""], ["별 파편 2개", 0.32 * Q, ""], ["별 파편 3개", 0.11 * Q, ""], ["별 파편 4개", 0.03 * Q, ""],
		["★ 걸작 완품", 1e-5, "아직 없는 걸작 " + str(ms) + "종 중 1개 · 500번째는 확정", Color("#ffd25a")]]}})
	R.append({"p": "천장: 500번째 뽑기는 걸작 완품 확정 · 완품이 나오면 천장 초기화 · 별 파편 30개로 원하는 걸작 제작 · 걸작을 모두 가졌다면 완품 대신 별 파편 30개", "mb": 12.0})
	R.append({"anchor": "bp"})
	R.append({"h": "배틀패스", "ic": "scroll"})
	R.append({"p": "배틀패스 보상은 확률이 아닌 확정 보상이에요. 크로 파편 보상은 아직 없는 크로 로봇·테마 중 1종에 균등하게 들어가요."})
	return R

# ── 패치 노트 ──
const PNOTES := [
	["11월 26일 밤", "로비 다듬기", [
		["new", "user", "왼쪽 위 프로필 카드 · 계정 관리 창을 새로 꾸몄어요"],
		["new", "scroll", "패치 노트를 보기 쉽게 새로 꾸몄어요"],
		["up", "chart", "확률표를 한눈에 보기 쉽게 (바로 가기 버튼 · 막대 그래프)"],
		["up", "note", "테마곡 미리듣기 중이면 버튼이 빛나고 남은 시간이 보여요 · 한 번 더 누르면 멈춰요"],
		["up", "crown", "청석이 모이면 배틀패스 해금 · 단계 구매 버튼이 금색으로 빛나요"],
		["up", "", "스크롤 막대를 손가락 · 마우스로 잡고 끌 수 있어요 · PC는 좌클릭 끌기로도 스크롤"],
		["fix", "gift", "상자 결과 카드가 창 밖으로 삐져나오던 문제"],
		["fix", "", "환영 문구가 청석 칸에 붙어 보이던 문제"]]],
	["11월 26일", "상점 · 조작 웹과 똑같이", [
		["new", "gift", "상점 · 상자 열기 · 창고 · 배틀패스 · 설정을 웹과 똑같은 모양으로"],
		["new", "scroll", "뽑기 내역 · 충전 탭"],
		["up", "", "PC 마우스: 좌클릭 = 로봇 선택 · 명령 / 우클릭 = 묶기 · 빈 곳 선택 해제"],
		["up", "", "앱을 내렸다 다시 켜면 지난 시간만큼 게임이 이어져요 (최대 5분)"],
		["fix", "crown", "레이드를 막아도 배틀패스 XP가 안 들어오던 문제"],
		["new", "sparkle", "테스트 모드: 재화 무한 (진짜 계정 기록은 안 건드려요)"]]],
	["11월 26일", "꾸미기 · 계정 · 앱", [
		["new", "crown", "로봇 · 기지 · 테마 스킨 · 걸작 · 세트 · 소로 상자 · 별 뽑기 · 배틀패스"],
		["new", "note", "테마 배경음 27곡 · 레이드 · 걸작 세트 전용 편곡"],
		["new", "user", "웹과 같은 계정으로 로그인 · 클라우드 저장"],
		["new", "gem", "PC exe · 안드로이드 apk · 새 버전 알림"],
		["new", "sparkle", "SOROMA GAMES 인트로 · 테마별 승리 · 기지별 패배 연출"]]],
	["11월 26일", "게임 안 다듬기", [
		["new", "", "웹과 같은 전투 AI · 분대 돌격 · 지원 로봇 · 적 카이팅"],
		["new", "", "마우스 올리면 말풍선 · 휠 · 가장자리 이동 · 깃발 · 조작법 창"],
		["new", "sparkle", "효과 · 효과음 · 배경음 · 튜토리얼 · 자동 저장 · 이어하기"],
		["up", "", "로봇끼리 안 겹치게 밀어내기 (고도판에서 새로)"]]],
	["11월 25일", "고도판 첫 버전", [
		["new", "", "큰 맵 · 시야 · 길찾기 · 미니맵"],
		["new", "", "생산 · 채굴 · 적 기지 · 전투 · 정복 · 레이드 · 부활 · 업그레이드 · 진화"],
		["new", "", "웹 SOROK과 같은 HUD · 상점 · 일시정지"]]],
]

func _rows_notes() -> Array:
	var R: Array = [{"nhero": true}]
	for i in PNOTES.size():
		R.append({"note": PNOTES[i], "latest": i == 0})
	return R

func _L_nhero(x0: float, y: float, W: float) -> float:
	var r := Rect2(x0, y, W, 104.0)
	_E({"k": "box", "r": r, "st": [[0.0, Color("#1a2a3a")], [0.55, Color("#14202c")], [1.0, Color("#2a2040")]], "ang": 110.0, "rad": 14.0, "bc": Color("#3a5068")})
	_E({"k": "pvb", "r": Rect2(x0 + 14.0, y + 10.0, 140.0, 84.0)})
	_E({"k": "t", "p": Vector2(x0 + 172.0, y + 44.0), "s": "패치 노트", "fs": 24, "b": true, "c": Color("#ffd76a")})
	_E({"k": "t", "p": Vector2(x0 + 172.0, y + 72.0), "s": "SOROK 고도판이 어떻게 바뀌어 왔는지 모아 봤어요", "fs": 13, "c": Color("#aab8c5"), "w": W - 172.0 - 150.0})
	var vs := "버전 " + (app_ver if app_ver != "" else "개발판")
	var vw := _tw(vs, 12, true) + 22.0
	_E({"k": "box", "r": Rect2(x0 + W - 16.0 - vw, y + 16.0, vw, 26.0), "st": Color("#0b1015"), "rad": 13.0, "bc": Color("#4fd1b5")})
	_E({"k": "t", "p": Vector2(x0 + W - 16.0 - vw, y + 34.0), "s": vs, "fs": 12, "b": true, "c": Color("#7affd4"), "al": 1, "w": vw})
	return y + 104.0 + 16.0

func _L_note(row: Dictionary, x0: float, y: float, W: float) -> float:
	var N: Array = row.note
	var latest: bool = row.latest
	var TG := {"new": ["NEW", Color("#3ae07a"), Color("#123020")], "up": ["개선", Color("#5ab8f0"), Color("#0f2433")], "fix": ["수정", Color("#ffa65a"), Color("#33200f")]}
	var tx := x0 + 22.0 + 58.0
	var tw := W - (tx - x0) - 48.0
	var lines: Array = []
	for it in N[2]:
		lines.append([it, _wrap(ThemeDB.fallback_font, it[2], 14, tw)])
	var h := 58.0
	for l in lines:
		h += maxf(30.0, l[1].size() * 20.0 + 10.0)
	h += 10.0
	var r := Rect2(x0, y, W, h)
	var acc := Color("#e8c36a") if latest else Color("#4a5a6a")
	if latest:
		_E({"k": "box", "r": r, "st": _g2("#1e1a10", "#10151a"), "rad": 12.0, "bc": acc, "glow": Color(0.91, 0.76, 0.42, 0.25)})
	else:
		_E({"k": "box", "r": r, "st": Color("#10151a"), "rad": 12.0, "bc": Color("#2b3640")})
	_E({"k": "box", "r": Rect2(x0 + 1.0, y + 1.0, 6.0, h - 2.0), "st": acc, "rad": [11.0, 0.0, 0.0, 11.0]})
	var dw := _tw(N[0], 13, true) + 22.0
	_E({"k": "box", "r": Rect2(x0 + 22.0, y + 16.0, dw, 26.0), "st": _g2("#e8c36a", "#b8902f") if latest else Color("#1b232b"), "rad": 13.0, "bc": Color("#f3d98e") if latest else Color("#33414d")})
	_E({"k": "t", "p": Vector2(x0 + 22.0, y + 34.0), "s": N[0], "fs": 13, "b": true, "c": Color("#1c1406") if latest else Color("#dfe6ea"), "al": 1, "w": dw})
	_E({"k": "t", "p": Vector2(x0 + 22.0 + dw + 12.0, y + 35.0), "s": N[1], "fs": 17, "b": true, "c": Color("#ffe9b8") if latest else Color("#dfe6ea")})
	if latest:
		var nx := x0 + 22.0 + dw + 12.0 + _tw(N[1], 17, true) + 10.0
		_E({"k": "box", "r": Rect2(nx, y + 18.0, 42.0, 22.0), "st": Color("#3a0f14"), "rad": 11.0, "bc": Color("#ff6a7a")})
		_E({"k": "t", "p": Vector2(nx, y + 33.0), "s": "최신", "fs": 12, "b": true, "c": Color("#ffb0b8"), "al": 1, "w": 42.0})
	var yy := y + 58.0
	for l in lines:
		var it: Array = l[0]
		var T: Array = TG[it[0]]
		_E({"k": "box", "r": Rect2(x0 + 22.0, yy + 2.0, 46.0, 20.0), "st": T[2], "rad": 10.0, "bc": T[1]})
		_E({"k": "t", "p": Vector2(x0 + 22.0, yy + 16.0), "s": T[0], "fs": 11, "b": true, "c": T[1], "al": 1, "w": 46.0})
		var ly := yy + 17.0
		for s in l[1]:
			_E({"k": "t", "p": Vector2(tx, ly), "s": s, "fs": 14, "c": Color("#d6dee5")})
			ly += 20.0
		if it[1] != "":
			_E({"k": "icn", "kind": it[1], "c": Vector2(x0 + W - 26.0, yy + 11.0), "s": 15.0})
		yy += maxf(30.0, l[1].size() * 20.0 + 10.0)
	return y + h + 14.0


# ═════════ SOROK CLIENT (웹 런처 화면: 왼쪽 계정 · 오른쪽 그림 + 플레이) ═════════
var ln_on := false

# 글자를 실제 화면 픽셀 크기로 만들어요 (휴대폰에서 UI를 키울 때 글자가 계단처럼 깨지지 않게)
var _os_v := 0.0
func _os_tick() -> void:
	var vp := get_viewport()
	var k := maxf(us, _cl_us() if scene == "client" or scene == "intro" else us)
	var sc := vp.get_final_transform().get_scale().x * k
	sc = snappedf(clampf(sc, 1.0, 4.0), 0.25)
	if absf(sc - _os_v) < 0.01:
		return
	_os_v = sc
	if "oversampling_override" in vp:
		vp.set("oversampling_override", sc)

func ln_side_px() -> float:
	var vs := vsize()
	return clampf(vs.x * 0.3, 340.0 * (1.6 if touch_mode else 1.0), 620.0 * (1.6 if touch_mode else 1.0))

func _ln_art(r: Rect2) -> void:
	# 하늘 · 별 · 언덕 · 기지 · 로봇 · 적 기지 (웹 lnArt와 같은 그림, 900×560 기준으로 오른쪽 아래에 맞춤)
	_gbox(r, _g2("#0c1420", "#1a2230"), 180.0, 0.0)
	var s := maxf(r.size.x / 900.0, r.size.y / 560.0)
	var o := r.end - Vector2(900, 560) * s
	var tt := t_real
	for i in 70:
		var x := fmod(i * 137.5 + tt * 6.0 * (1 + i % 3), 900.0)
		var y := float((i * 71) % 300)
		var p := o + Vector2(x, y) * s
		if r.has_point(p):
			draw_rect(Rect2(p, Vector2(1.6, 1.6) * maxf(1.0, s)), Color(1, 1, 1, 0.25 + 0.5 * absf(sin(tt * 0.8 + i))))
	var H := PackedVector2Array([o + Vector2(0, 400) * s])
	var xx := 0.0
	while xx <= 900.0:
		H.append(o + Vector2(xx, 390.0 + sin(xx / 90.0) * 18.0) * s)
		xx += 30.0
	H.append(o + Vector2(900, 560) * s)
	H.append(o + Vector2(0, 560) * s)
	draw_colored_polygon(H, Color("#1b2a24"))
	var bxf := inv * Transform2D(0.0, Vector2(us, us), 0.0, Vector2.ZERO) * Transform2D(0.0, Vector2(1.25, 1.25) * s, 0.0, o + Vector2(560, 420) * s)
	draw_set_transform_matrix(bxf)
	art_base(self, Vector2.ZERO, tt, bxf, bsk)
	var cols := ["c", "r", "h", "c", "r"]
	for i in cols.size():
		var k: String = cols[i]
		_ui_tf(o + Vector2(660.0 + i * 44.0 + sin(tt * 1.4 + i) * 8.0, 455.0 + cos(tt * 1.2 + i) * 5.0) * s, 0.0, 1.5 * s)
		if skn.is_empty():
			art_bot(self, k, UT[k].col, UT[k].acc, tt)
		else:
			art_bot_s(self, k, C(skn.c), C(skn.a), tt, skn.pt)
	_ui_reset()
	draw_colored_polygon(PackedVector2Array([o + Vector2(830, 470) * s, o + Vector2(865, 385) * s, o + Vector2(900, 470) * s]), Color(150 / 255.0, 95 / 255.0, 210 / 255.0, 0.9))
	draw_circle(o + Vector2(865, 422) * s, 6.0 * s, Color(1.0, 90 / 255.0, 70 / 255.0, 0.5 + 0.5 * sin(tt * 3.0)))
	# 그림자 (왼쪽 · 아래 어둡게)
	_gbox(r, [[0.0, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.75)], [0.6, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.15)], [1.0, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.15)]], 90.0, 0.0)
	_gbox(r, [[0.0, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.85)], [0.5, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.0)], [1.0, Color(10 / 255.0, 15 / 255.0, 21 / 255.0, 0.0)]], 0.0, 0.0)

func _ln_logo(p: Vector2, fs: int) -> void:
	var w := 0.0
	for ch in "SOROK":
		w += _tw(ch, fs, true) + fs * 0.14
	# 웹 text-shadow처럼 글자 뒤에 부드럽게 퍼지는 빛 (글자를 밀어 겹치지 않고 두꺼운 테두리를 옅게 여러 겹)
	for q in [[0.62, 0.035], [0.44, 0.05], [0.28, 0.07], [0.14, 0.10]]:
		var x := p.x
		for ch in "SOROK":
			draw_string_outline(fb(), Vector2(x, p.y + fs * 0.04), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(fs * q[0]), Color(1.0, 0.75, 0.24, q[1]))
			x += _tw(ch, fs, true) + fs * 0.14
	_spaced_l(p, "SOROK", fs, 0.14, Color("#ffd76a"), 0.0)

func _spaced_l(p: Vector2, s: String, fs: int, ls: float, col: Color, grow: float) -> void:
	# 글자 크기 보정 기능이 없는 버전이면 실제 크기로 직접 그려요 (큰 로고가 깨지지 않게)
	if us != 1.0 and not ("oversampling_override" in get_viewport()):
		draw_set_transform_matrix(inv)
		var fz := int(round(fs * us))
		var x2 := p.x * us
		for ch in s:
			var q := Vector2(x2, p.y * us)
			if grow > 0.0:
				for d in [Vector2(-grow, 0), Vector2(grow, 0), Vector2(0, -grow), Vector2(0, grow)]:
					draw_string(fb(), q + d * us, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fz, col)
			else:
				draw_string(fb(), q, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fz, col)
			x2 += (_tw(ch, fs, true) + fs * ls) * us
		_ui_reset()
		return
	var x := p.x
	for ch in s:
		if grow > 0.0:
			for d in [Vector2(-grow, 0), Vector2(grow, 0), Vector2(0, -grow), Vector2(0, grow)]:
				draw_string(fb(), Vector2(x, p.y) + d, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		else:
			draw_string(fb(), Vector2(x, p.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += _tw(ch, fs, true) + fs * ls

func _client_build() -> Dictionary:
	var u := ui_size()
	var sw := ln_side_px() / us
	var art := Rect2(sw, 0, u.x - sw, u.y)
	var G := {"sw": sw, "art": art}
	if ln_on:
		return G
	var x := 30.0
	var w := sw - 60.0
	var by := u.y - 24.0
	var logged: bool = acct != null and acct.ses != null and str(acct.ses.get("nick", "")) != ""
	var B: Array = [["cl_acct", "계정 관리"], ["cl_keys", "조작법" if touch_ui() else "조작법 (Tab)"], ["cl_out", "로그아웃" if logged else "로그인 / 회원가입"]]
	for i in range(B.size() - 1, -1, -1):
		by -= 44.0
		_add(B[i][0], Rect2(x, by, w, 44.0))
		by -= 8.0
	var fs := int(clampf(art.size.x * 0.085, 48.0, 96.0))
	var hx := art.position.x + 48.0
	var hy := u.y - 56.0
	G.play = Rect2(hx, hy - 18.0 - 60.0, 230.0, 60.0)
	G.fs = fs
	_add("cl_play", G.play)
	return G

func _cl_us() -> float:
	return 1.6 if touch_mode else 1.0

func _client(f: Font) -> void:
	var us0 := us
	us = _cl_us()
	_client0(f)
	us = us0

func _client0(f: Font) -> void:
	_ui_reset()
	var u := ui_size()
	ui.clear()
	var G := _client_build()
	if acp_open:
		_build_acp()
	var hov = null if touch_ui() else ui_hit(mouse_ui * us)
	var art: Rect2 = G.art
	_ln_art(art)
	if ln_on:
		# 로그인 화면 오른쪽: 큰 SOROK + 부제 (lnHero)
		var fs2 := int(clampf(art.size.x * 0.085, 48.0, 96.0))
		_ln_logo(Vector2(art.position.x + 48.0, u.y - 56.0 - 34.0), fs2)
		draw_string(f, Vector2(art.position.x + 50.0, u.y - 56.0), "외계 기지 정복 전략", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c9d4dc"))
		return
	# 왼쪽 패널
	var sw: float = G.sw
	draw_rect(Rect2(0, 0, sw, u.y), Color("#f4f5f7"))
	var x := 30.0
	var w := sw - 60.0
	var y := 34.0
	draw_colored_polygon(PackedVector2Array([Vector2(x, y + 6), Vector2(x + 6, y), Vector2(x + 12, y + 6), Vector2(x + 6, y + 12)]), Color("#c9a255"))
	_spaced_l(Vector2(x + 18.0, y + 12.0), "SOROK CLIENT", 13, 0.12, Color("#c9a255"), 0.0)
	y += 30.0
	# 계정 카드 (.lnuser)
	var P := _prof_info()
	var logged: bool = P[0] != ""
	var cr := Rect2(x, y, w, 78.0)
	_gbox(cr, Color.WHITE, 180.0, 10.0)
	var c := cr.position + Vector2(12.0 + 16.0, 39.0)
	_gbox(Rect2(c - Vector2(16, 16), Vector2(32, 32)), _g2("#e8c36a", "#b8902f"), 135.0, 16.0)
	draw_string(fb(), Vector2(c.x - 16.0, c.y + 6.0), str(P[0]).substr(0, 1).to_upper() if logged else "?", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 16, Color("#1c1406"))
	var tx := cr.position.x + 54.0
	if logged:
		draw_string(fb(), Vector2(tx, cr.position.y + 25.0), P[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#1a1d22"))
		draw_string(fb(), Vector2(tx + _tw(P[0], 15, true) + 3.0, cr.position.y + 25.0), P[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8a929c"))
	else:
		draw_string(fb(), Vector2(tx, cr.position.y + 25.0), "로그인 안 함", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#1a1d22"))
	draw_string(f, Vector2(tx, cr.position.y + 46.0), "청석 " + _cm(SV.cs) + " · 별석 " + str(SV.ss), HORIZONTAL_ALIGNMENT_LEFT, cr.end.x - tx - 8.0, 12, Color("#6a7480"))
	var st := "로그인해 주세요"
	if logged:
		st = acct.srv_name() + " · " + ("불러오는 중…" if booting() else {"ok": "저장됨", "sync": "저장 중…", "off": "오프라인", "err": "저장 실패", "conf": "확인 중"}.get(acct.state, "연결됨"))
		if TEST:
			st += " · 테스트 모드"
	draw_string(f, Vector2(tx, cr.position.y + 66.0), st, HORIZONTAL_ALIGNMENT_LEFT, cr.end.x - tx - 8.0, 12, Color("#3a7bd5"))
	y += 78.0 + 12.0
	# 게임 카드 (.lngame)
	var gr := Rect2(x, y, w, 64.0)
	_gbox(gr, Color("#1a1d22"), 180.0, 10.0)
	_gbox(Rect2(x, y, 4.0, 64.0), Color("#e8c36a"), 180.0, [10.0, 0.0, 0.0, 10.0])
	_spaced_l(Vector2(x + 18.0, y + 28.0), "SOROK", 17, 0.1, Color("#ffd76a"), 0.0)
	draw_string(f, Vector2(x + 18.0, y + 50.0), "외계 기지 정복 전략", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#c9d4dc"))
	# 아래 메뉴 (.lnmenu)
	for it in ui:
		var lb := ""
		var ic := ""
		match it.id:
			"cl_acct":
				lb = "계정 관리"
				ic = "user"
			"cl_keys":
				lb = "조작법" if touch_ui() else "조작법 (Tab)"
			"cl_out":
				lb = "로그아웃" if logged else "로그인 / 회원가입"
			_:
				continue
		var h: bool = hov == it
		_gbox(it.r, Color("#f7f8fa") if h else Color.WHITE, 180.0, 8.0, Color("#1a1d22") if h else Color("#dde1e6"))
		var lx: float = it.r.position.x + 14.0
		if ic == "user":
			_icon_user(Vector2(lx + 8.0, it.r.position.y + 23.0), 16.0)
			lx += 24.0
		draw_string(f, Vector2(lx, it.r.position.y + 27.0), lb, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#1a1d22"))
	# 오른쪽 히어로 (.lnhero2)
	var hx := art.position.x + 48.0
	var pr: Rect2 = G.play
	var fs: int = G.fs
	draw_string(fb(), Vector2(hx, pr.position.y - 14.0 - 22.0), "외계 기지 50개를 정복하라 · 시즌 1 은하 원정", HORIZONTAL_ALIGNMENT_LEFT, art.end.x - hx - 20.0, 15, Color("#c9d4dc"))
	_ln_logo(Vector2(hx, pr.position.y - 14.0 - 22.0 - 32.0), fs)
	_spaced_l(Vector2(hx, pr.position.y - 14.0 - 22.0 - 32.0 - fs - 8.0), "GAME", 12, 0.2, Color("#8a9bad"), 0.0)
	var busy := booting()
	var hp: bool = hov != null and hov.id == "cl_play"
	_bglow(pr, Color(0.91, 0.65, 0.16, 0.4), 18.0, 10.0)
	_gbox(pr, _g2("#ffe58a", "#f0b03a") if hp else _g2("#ffdf7a", "#e8a52a"), 180.0, 10.0)
	_spaced_l(Vector2(pr.position.x + (pr.size.x - _tw("플레이", 22, true) - 3.0 * 22 * 0.1) / 2.0, pr.position.y + 39.0), "불러오는 중" if busy else "플레이", 22 if not busy else 17, 0.1, Color("#2a1a00"), 0.0)
	if busy:
		_fade(pr, 0.35, Color("#0c1420"))
	var vs := "버전 " + (app_ver if app_ver != "" else "개발판") + (" · 테스트 모드 (재화 무한)" if TEST else "")
	draw_string(f, Vector2(hx, pr.end.y + 22.0), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8a9bad"))
	if upd_url != "":
		draw_string(fb(), Vector2(hx, pr.end.y + 42.0), "새 버전이 나왔어요 · 로비에서 받을 수 있어요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffd76a"))
	if acp_open:
		_acp_draw(f, hov)
	if keys_open:
		_keys_win(f)

func client_press(id: String) -> void:
	sfx("click")
	match id:
		"cl_play":
			if booting():
				return
			# 로그인해야 플레이 (게스트 없음)
			if acct != null and not OS.get_cmdline_user_args().has("--selftest"):
				if acct.ses == null:
					acct.show_login("로그인하면 플레이할 수 있어요")
					return
				if acct.mode in ["verify", "nick", "renick", "ban"]:
					return
				# 운영자 계정은 게임 대신 운영자 화면
				if acct.is_admin():
					adm.open()
					return
			scene = "lobby"
			lsec = "main"
			intro_out = t_real
		"cl_acct":
			acp_show()
		"cl_keys":
			keys_open = true
		"cl_out":
			if acct == null:
				return
			if acct.ses != null:
				acct.logout()
			else:
				acct.show_login("")
		"acp_bg", "acp_close", "acp_login", "acp_out", "acp_save", "acp_vsend", "acp_reset", "acp_admin", "acp_srv":
			acp_press(id)

func _client_input(e: InputEvent) -> void:
	var us0 := us
	us = _cl_us()
	_client_input0(e)
	us = us0

func _client_input0(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if keys_open and (e.keycode == KEY_ESCAPE or e.keycode == KEY_TAB):
			keys_open = false
		elif e.keycode == KEY_TAB:
			keys_open = true
		elif e.keycode == KEY_ESCAPE and acp_open:
			acp_open = false
		elif (e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER) and not acp_open:
			client_press("cl_play")
		return
	if e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION:
		mouse_ui = e.position / us
		return
	var pos = null
	if e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		pos = e.position
	elif e is InputEventScreenTouch and not e.pressed:
		pos = e.position
	if pos == null:
		return
	if keys_open:
		keys_open = false
		return
	var it = ui_hit(pos)
	if it != null:
		client_press(it.id)

func cos_press(a: Dictionary) -> void:
	match a.a:
		"tab":
			shop_tab2 = a.k
			lob_scroll = 0.0
		"settab":
			set_tab = a.k
			lob_scroll = 0.0
			bgm_open = false
		"hf":
			hF = a.v
			lob_scroll = 0.0
		"cash":
			cash_sel = int(a.i)
		"jump":
			lob_scroll = clampf(float(lob_anchor.get(a.k, 0.0)) - 4.0, 0.0, lob_max)
		"tprev":
			if bgm_prev_id == a.id and t_real < bgm_prev_u:
				bgm_prev_u = 0.0
				lmsg = "미리듣기를 멈췄어요"
				return
			bgm_prev_id = a.id
			bgm_prev_u = t_real + 15.0
			lmsg = item(a.id).get("n", "") + " 테마곡 미리듣기 중 (15초)" + (" · 음소거를 풀어야 들려요" if SV.mute else "")
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
			var L: Array = stF[a.k]
			if a.v == "all":
				L.clear()
			elif L.has(a.v):
				L.erase(a.v)
			else:
				L.append(a.v)
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

# ═════════ SOROMA GAMES 인트로 → SOROK 로고 (웹과 같은 순서 · 건너뛰기 없음) ═════════
var intro_t0 := 0.0
var intro_P: Array = []
var intro_ding := false
var intro_out := -9.0
var rad_tex: Texture2D = null

func intro_start() -> void:
	scene = "intro"
	intro_t0 = t_real
	intro_ding = false
	intro_P.clear()
	intro_sd = 11
	var rn := _intro_rn
	for a in 2:
		for i in 1100:
			var tt: float = pow(rn.call(), 0.8) * 3.1
			var r := 24.0 * exp(0.704 * tt)
			if r > 330.0:
				continue
			var sa: float = rn.call() * 7.0
			var sr: float = 420.0 + rn.call() * 380.0
			intro_P.append({"r": r * (1.0 + (rn.call() - 0.5) * 0.12), "a": a * PI + tt * 2.2 + (rn.call() - 0.5) * (0.2 + 0.08 * tt), "k": r / 330.0,
				"s": (1.1 + 1.4 * rn.call()) * (1.2 - r / 660.0), "sx": cos(sa) * sr, "sy": sin(sa) * sr, "dl": rn.call() * 0.45})

var intro_sd := 11
func _intro_rn() -> float:
	intro_sd = (intro_sd * 16807) % 2147483647
	return float(intro_sd) / 2147483647.0

func _rad() -> Texture2D:
	if rad_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		rad_tex = gt
	return rad_tex

func _glow(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_texture_rect(_rad(), Rect2(c - Vector2(rx, ry), Vector2(rx, ry) * 2.0), false, col)

func _ease3(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)

func _spaced(f: Font, s: String, cx: float, y: float, fs: int, em: float, col: Color) -> void:
	var gap := fs * em
	var w := 0.0
	for ch in s:
		w += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
	w -= gap
	var x := cx - w / 2.0
	for ch in s:
		draw_string(f, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		x += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap

func _intro(f: Font) -> void:
	_ui_reset()
	var u := ui_size()
	var ti := t_real - intro_t0
	draw_rect(Rect2(Vector2.ZERO, u), Color.BLACK)
	var cw := minf(minf(u.x * 0.9, u.y * 1.1), 1000.0)
	var k := cw / 900.0
	var ch := 560.0 * k
	var top := (u.y - ch - 60.0) / 2.0
	var C0 := Vector2(u.x / 2.0, top + 290.0 * k)
	var s1 := 1.0 - clampf((ti - 2.7) / 0.6, 0.0, 1.0)
	if ti < 3.3 and s1 > 0.0:
		var ap := _ease3(ti / 1.1)
		_glow(C0, 280 * k, 280 * k, Color(60 / 255.0, 170 / 255.0, 190 / 255.0, 0.25 * ap * s1))
		var rot := ti * 0.3
		for p in intro_P:
			var q := _ease3((ti - p.dl) / 1.05)
			if q <= 0.0:
				continue
			var an: float = p.a + rot
			var fx: float = cos(an) * p.r
			var fy: float = sin(an) * p.r * 0.58
			var pos := Vector2(p.sx + (fx - p.sx) * q, p.sy * 0.7 + (fy - p.sy * 0.7) * q)
			var kk: float = p.k
			draw_circle(C0 + pos * k, maxf(0.6, p.s * k), Color((255 - 150 * kk) / 255.0, 220 / 255.0, (140 + 90 * kk) / 255.0, q * (0.92 - 0.62 * kk) * s1))
		_glow(C0, 90 * k, 70 * k, Color(1.0, 236 / 255.0, 180 / 255.0, ap * s1))
		var dk := ti - 1.5
		var sp := 0.0 if ti < 1.2 else minf(1.0, (ti - 1.2) / 0.3) * 0.55
		if dk > 0.0:
			sp = 0.55 + 0.9 * maxf(0.0, 1.0 - dk / 0.6)
		if sp > 0.0:
			var L := 90.0 * sp * k
			var w := 6.0 * k
			var sc := Color(1.0, 250 / 255.0, 230 / 255.0, minf(1.0, sp) * s1)
			draw_colored_polygon(PackedVector2Array([C0 + Vector2(0, -L), C0 + Vector2(w, 0), C0 + Vector2(0, L), C0 + Vector2(-w, 0)]), sc)
			draw_colored_polygon(PackedVector2Array([C0 + Vector2(-L * 0.75, 0), C0 + Vector2(0, -w), C0 + Vector2(L * 0.75, 0), C0 + Vector2(0, w)]), sc)
		if dk > 0.0 and dk < 0.9:
			var kq := dk / 0.9
			var rr := (40.0 + 420.0 * _ease3(kq)) * k
			ell_line(self, C0, rr, rr * 0.6, Color(1.0, 236 / 255.0, 190 / 255.0, 0.8 * (1.0 - kq) * s1), 3.0 * (1.0 - kq) + 0.5)
			_glow(C0, 260 * k, 260 * k, Color(1.0, 250 / 255.0, 235 / 255.0, 0.75 * maxf(0.0, 1.0 - dk / 0.35) * s1))
		# SOROMA · GAMES
		var ta := clampf((ti - 0.95) / 0.7, 0.0, 1.0) * s1
		if ta > 0.0:
			var ty := top + ch - u.y * 0.04 + (1.0 - ta) * 10.0
			var fs := int(clampf(u.x * 0.055, 34.0, 68.0))
			var pulse := 0.0
			if ti > 1.5 and ti < 2.4:
				pulse = sin((ti - 1.5) / 0.9 * PI)
			var tc := Color(236 / 255.0, 196 / 255.0, 110 / 255.0, ta).lerp(Color(1, 0.97, 0.85, ta), pulse * 0.6)
			_spaced(f, "SOROMA", u.x / 2.0, ty + fs * 0.4, fs, 0.2, tc)
			_spaced(f, "GAMES", u.x / 2.0, ty + fs * 0.4 + 30.0, int(clampf(u.x * 0.013, 11.0, 15.0)), 0.7, Color(150 / 255.0, 170 / 255.0, 185 / 255.0, ta))
	if ti > 1.5 and not intro_ding:
		intro_ding = true
		sfx("ding")
	# SOROK 로고
	var s2 := clampf((ti - 3.4) / 0.6, 0.0, 1.0)
	if s2 > 0.0:
		var e := _ease3((ti - 3.4) / 1.2)
		var fs := int(clampf(u.x * 0.1, 64.0, 150.0))
		var sp := lerpf(0.6, 0.14, e)
		var sc := lerpf(1.08, 1.0, e)
		var cy := u.y / 2.0
		_ui_tf(Vector2(u.x / 2.0, cy), 0.0, sc)
		_spaced(f, "SOROK", 0.0, fs * 0.36 + 4.0, fs, sp, Color(0.6, 0.38, 0.1, 0.35 * s2 * e))
		_spaced(f, "SOROK", 0.0, fs * 0.36, fs, sp, Color(1.0, 215 / 255.0, 106 / 255.0, s2 * (0.35 + 0.65 * e)))
		_ui_reset()
		var lw := minf(u.x * 0.6, 640.0) * _ease3((ti - 3.9) / 1.0)
		if lw > 1.0:
			draw_polyline_colors(PackedVector2Array([Vector2(u.x / 2.0 - lw / 2.0, cy + fs * 0.5 + 18.0), Vector2(u.x / 2.0, cy + fs * 0.5 + 18.0), Vector2(u.x / 2.0 + lw / 2.0, cy + fs * 0.5 + 18.0)]),
				PackedColorArray([Color(1, 0.84, 0.42, 0), Color(1, 0.84, 0.42, 1), Color(1, 0.84, 0.42, 0)]), 2.0)
		var sa := clampf((ti - 4.2) / 0.8, 0.0, 1.0)
		if sa > 0.0:
			_spaced(f, "외계 기지 정복 전략", u.x / 2.0, cy + fs * 0.5 + 52.0, int(clampf(u.x * 0.016, 14.0, 19.0)), 0.3, Color(201 / 255.0, 212 / 255.0, 220 / 255.0, sa))
	if ti > 5.6:
		scene = "client"
		intro_out = t_real
		_after_intro()

func _intro_fade() -> void:
	var a := 1.0 - (t_real - intro_out) / 0.5
	if a > 0.0:
		_ui_reset()
		draw_rect(Rect2(Vector2.ZERO, ui_size()), Color(0, 0, 0, a))

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

var snd_req := {}
func _snd(k: String) -> AudioStream:
	if not snd_cache.has(k) and snd_req.has(k):
		var r = ResourceLoader.load_threaded_get(snd_req[k])
		snd_req.erase(k)
		if r is AudioStream:
			snd_cache[k] = r
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
	# 효과음은 미리 불러 둬요 (처음 울릴 때 파일을 읽느라 화면이 끊기지 않게) · 띵은 바로, 나머지는 뒤에서
	_snd("ding")
	var d := DirAccess.open("res://sounds")
	if d != null:
		for fn in d.get_files():
			var nm := fn.trim_suffix(".import").trim_suffix(".remap")
			if not nm.ends_with(".wav") or nm.begins_with("bgm_"):
				continue
			var k := nm.get_basename()
			if snd_cache.has(k) or snd_req.has(k):
				continue
			if ResourceLoader.load_threaded_request("res://sounds/" + nm) == OK:
				snd_req[k] = "res://sounds/" + nm

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
		if t_real < bgm_prev_u and bgm_prev_id != "":
			want = "bgm_" + bgm_prev_id
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
const BXS := {"b1": "petal", "b2": "ice", "b3": "fire", "b4": "star", "b5": "bubble", "b7": "aurora", "b8": "bolt", "b9": "bolt", "b10": "aurora", "b11": "petal", "b12": "star", "mb1": "star", "mb2": "fire", "mb3": "aurora"}
func _base_boom(lt: float) -> void:
	var X := B
	var h := func(i: int) -> float: return fmod(i * 9301.0 + 49297.0, 233280.0) / 233280.0
	var sty: String = BXS.get(bsk.get("id", ""), "normal")
	var A := C(bsk.lt) if sty != "normal" else Color("#ffd25a")
	var Bc := C(bsk.gl) if sty != "normal" else Color("#ff6a1f")
	if lt < 0.45:
		var sh := (1.0 - lt / 0.45) * 7.0
		art_base(self, X + Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * sh, t, Transform2D.IDENTITY, bsk)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(X, 58.0, Color(1, 1, 1, lt / 0.45 * 0.85))
		return
	var tt := lt - 0.45
	draw_colored_polygon(ell(X + Vector2(0, 10), 62, 22), Color(0, 0, 0, 0.35))
	for i in 10:
		draw_rect(Rect2(X.x - 42.0 + h.call(i) * 84.0, X.y - 16.0 + h.call(i + 20) * 36.0, 6.0 + h.call(i + 40) * 11.0, 4.0 + h.call(i + 60) * 7.0), C(bsk.get("bd", "#38434d")) if i % 2 else C(bsk.get("tp", "#5a6a78")))
	if tt < 0.8:
		draw_arc(X, 20.0 + tt * 280.0, 0, TAU, 64, Color(Color(1.0, 0.95, 0.75) if sty == "normal" else A, 1.0 - tt / 0.8), 7.0 * (1.0 - tt / 0.8) + 1.0)
	if tt < 1.2:
		draw_circle(X, 32.0 + tt * 55.0, Color(Bc, (1.0 - tt / 1.2) * 0.85))
		draw_circle(X, 18.0 + tt * 26.0, Color(A, 1.0 - tt / 1.2))
	var fade := maxf(0.0, 1.0 - tt / 2.3)
	for i in 48:
		var a: float = h.call(i) * TAU
		var v: float = 60.0 + h.call(i + 7) * 230.0
		var d := v * tt * (1.0 - minf(tt, 2.0) / 4.0)
		var z: float = 2.0 + h.call(i + 11) * 4.0
		var py := sin(a) * d * (0.5 if sty == "bubble" else 1.0)
		if sty == "bubble":
			py -= tt * 70.0 * h.call(i + 3)
		elif sty == "aurora":
			py -= tt * 45.0
		elif sty == "normal" or sty == "fire":
			py += tt * tt * 30.0
		var pp := X + Vector2(cos(a) * d, py)
		var ac := A if i % 2 else Bc
		match sty:
			"normal":
				var col := Color(0.35, 0.35, 0.35, 0.85)
				if i % 3:
					col = Color("#ffb03a") if i % 2 else Color("#ff5a1a")
				draw_circle(pp, z + (0.0 if i % 3 else tt * 6.0), Color(col, col.a * fade))
			"fire":
				draw_circle(pp, z + 1.0, Color(ac, fade))
			"ice":
				var pts := PackedVector2Array()
				for q in [Vector2(z * 2.2, 0), Vector2(0, -z * 0.7), Vector2(-z * 1.4, 0), Vector2(0, z * 0.7)]:
					pts.append(pp + (q as Vector2).rotated(a))
				draw_colored_polygon(pts, Color(Color.WHITE if i % 2 else Bc, fade))
			"bolt":
				if i % 4 == 0 and sin(lt * 30.0 + i) > 0.0:
					var L := PackedVector2Array([X])
					for q in range(1, 6):
						var r := d * q / 5.0
						var jj: float = (h.call(i * q + 3) - 0.5) * 20.0
						L.append(X + Vector2(cos(a) * r - sin(a) * jj, sin(a) * r + cos(a) * jj))
					draw_polyline(L, Color(A if i % 8 else Bc, fade), 2.0)
				else:
					draw_rect(Rect2(pp, Vector2(2.5, 2.5)), Color(A, fade))
			"petal":
				draw_colored_polygon(_rot_ell(pp, z + 1.5, z * 0.55, a + tt * 6.0), Color(ac, fade))
			"bubble":
				draw_arc(pp, z + 1.5, 0, TAU, 12, Color(ac, fade), 1.5)
			"aurora":
				draw_rect(Rect2(pp.x - 1.5, pp.y - z * 3.0, 3, z * 6.0), Color(ac, fade * 0.65))
			_:
				var st := PackedVector2Array()
				for q in 10:
					var r := z * 0.45 if q % 2 else z * 1.25
					st.append(pp + Vector2.from_angle(q * PI / 5.0 + tt * 5.0 + i) * r)
				draw_colored_polygon(st, Color(ac, fade))
	if sty == "aurora" and tt < 2.5:
		var H := 260.0 * minf(1.0, tt * 1.5)
		for b in 3:
			draw_rect(Rect2(X.x - 30 + b * 22, X.y - H, 14, H), Color(Bc if b % 2 else A, 0.25 * (1.0 - tt / 2.5)))
	if sty == "bubble" and tt < 2.0:
		for r in 3:
			draw_arc(X, fmod(tt * 140.0 + r * 40.0, 180.0), 0, TAU, 40, Color(A, 0.5 * (1.0 - tt / 2.0)), 2.0)
	if sty == "ice" and tt < 1.5:
		draw_circle(X, 40.0 + tt * 120.0, Color(0.91, 0.96, 1.0, 0.35 * (1.0 - tt / 1.5)))
	if sty == "normal" or sty == "fire":
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

# ═════════ 승리 연출 (웹 drawWin · 테마별 WJU) ═════════
const WJU := {"t1": ["snow", ["#ffffff", "#cfe6ff", "#9cc8ff"]], "t2": ["sand", ["#ffd98a", "#e0b060", "#fff0c0"]], "t3": ["leaf", ["#7fd04a", "#b8e06a", "#ffffff"]], "t4": ["dust", ["#ff8a4a", "#e0c060", "#ffd0a0"]], "t5": ["star", ["#ffffff", "#a0c8ff", "#5aa0d8"]], "t6": ["bubble", ["#a0e070", "#d0ff9a", "#ffffff"]], "t7": ["bubble", ["#7fd8ff", "#ffffff", "#f09a5a"]], "t8": ["leaf", ["#e0602a", "#f0a030", "#ffd060"]], "t9": ["star", ["#4affd8", "#ffb04a", "#ffffff"]], "t10": ["ash", ["#b8b8b8", "#e06a4a", "#808080"]], "t11": ["neon", ["#3affe8", "#ff3ad0", "#ffffff"]], "t12": ["petal", ["#c89aff", "#e8c8ff", "#ffffff"]], "t13": ["dust", ["#ff6a4a", "#5a8ac8", "#ffd0a0"]],
	"tk1": ["bubble", ["#3ff0ff", "#2ad0a0", "#ffffff"], "deep"], "tk2": ["petal", ["#ff8fb8", "#ffd0e0", "#ffffff"], "bloom"], "tk3": ["snow", ["#ffffff", "#bfe6ff", "#7ab8ff"], "blizzard"], "tk4": ["rain", ["#ffe14a", "#8a8aff", "#ffffff"], "storm"], "tk5": ["ember", ["#ffd25a", "#ff6a1f", "#ff3a1a"], "lava"], "tk6": ["star", ["#7affd4", "#c08cff", "#ffffff"], "aurora"], "tk7": ["star", ["#ffe27a", "#8ab0ff", "#ffffff"], "meteor"], "tk8": ["neon", ["#3affe8", "#ff3ad0", "#ffffff"], "grid"], "tk10": ["petal", ["#ff4a6a", "#ffb0c0", "#ffffff"], "bloom"], "tk9": ["sand", ["#9ad8ff", "#ffd98a", "#ffffff"], "meteor"], "tk11": ["star", ["#c08cff", "#7a5aff", "#ffffff"], "galaxy"],
	"tm1": ["feather", ["#ffffff", "#ffd25a", "#fff3c0"], "heaven"], "tm2": ["ember", ["#ffd25a", "#ff6a1f", "#ff3a1a"], "dragon"], "tm3": ["shard", ["#7affd4", "#c08cff", "#ffffff"], "prism"]}
var ws := {}
var wbolt := {}

func win_style() -> Dictionary:
	var th := TH()
	var id: String = th.get("id", "")
	var w = WJU.get(id, null)
	var S := {"id": id, "g": th.get("g", ""), "fall": w[0] if w != null else "confetti", "cols": w[1] if w != null else ["#ffd76a", "#7fe0ff", "#ff7aa8", "#9bff8a", "#c79bff"],
		"fx": w[2] if (w != null and w.size() > 2) else "", "acc": th.get("a", "#ffd24a"), "set": ""}
	for z in MSET:
		if z.t == id and mset_done(id):
			S.set = z.n
	if id == "tm2":
		S.grad = ["#fff0a0", "#ffb02a", "#ff3a10"]
	elif id == "tm1":
		S.grad = ["#ffffff", "#fff1b0", "#e8b83a"]
	elif S.g == "kro":
		S.grad = ["#ffffff", S.acc, S.cols[1]]
	else:
		S.grad = ["#fff8d6", "#ffd24a", "#f0a020"]
	return S

func _wrc() -> Color:
	return C(ws.cols[rng.randi() % ws.cols.size()])

func _tick_win(dt: float) -> void:
	if ws.is_empty():
		ws = win_style()
	var u := ui_size()
	var VW := u.x
	var VH := u.y
	var wt := t_real - won_at
	var fx: String = ws.fx
	if fx == "storm" and rng.randf() < 0.025:
		wbolt = {"t": t_real, "x": VW * (0.15 + 0.7 * rng.randf()), "pts": []}
		var lx: float = wbolt.x
		var ly := 0.0
		var P := PackedVector2Array([Vector2(lx, ly)])
		while ly < VH * 0.7:
			lx += (rng.randf() - 0.5) * 60.0
			ly += 30.0 + rng.randf() * 30.0
			P.append(Vector2(lx, ly))
		wbolt.pts = P
	if fx == "dragon":
		var dp := (wt - 0.4) / 2.6
		if dp > 0.0 and dp < 1.2 and rng.randf() < 0.6:
			var dpos := Vector2(-200 + dp * (VW + 400), VH * 0.16 + sin(dp * 6.0) * 20.0)
			for i in 5:
				wfx.append({"p": dpos + Vector2(100, -6), "v": Vector2(120 + rng.randf() * 160, 40 + rng.randf() * 120), "l": 0.9, "c": _wrc(), "r": 3.0 + rng.randf() * 3.0, "gl": true})
	if fx == "lava" and rng.randf() < 0.05:
		var bx := VW * (0.1 + 0.8 * rng.randf())
		for i in 40:
			wfx.append({"p": Vector2(bx, VH), "v": Vector2((rng.randf() - 0.5) * 160, -(260 + rng.randf() * 320)), "l": 2.2, "c": _wrc(), "r": 2.0 + rng.randf() * 3.0, "g": 260.0, "gl": true})
	if fx == "meteor" and rng.randf() < 0.08:
		wfx.append({"p": Vector2(rng.randf() * VW * 0.8, -10), "v": Vector2(380 + rng.randf() * 200, 240 + rng.randf() * 120), "l": 1.6, "c": _wrc(), "r": 2.4, "mt": true})
	if fx == "bloom" and rng.randf() < 0.05:
		var bp0 := Vector2(VW * (0.15 + 0.7 * rng.randf()), VH * (0.15 + 0.45 * rng.randf()))
		for i in 30:
			var a := rng.randf() * 7.0
			var v := 40.0 + rng.randf() * 120.0
			wfx.append({"p": bp0, "v": Vector2(cos(a), sin(a)) * v, "l": 2.0, "c": _wrc(), "pt": true, "a": a, "g": 40.0})
	if fx != "heaven" and rng.randf() < (0.08 if wt < 4.0 else 0.035):
		var bp0 := Vector2(VW * (0.15 + 0.7 * rng.randf()), VH * (0.12 + 0.45 * rng.randf()))
		for i in 46:
			var a := rng.randf() * 7.0
			var v := 60.0 + rng.randf() * 190.0
			wfx.append({"p": bp0, "v": Vector2(cos(a), sin(a)) * v, "l": 1.0 + rng.randf() * 0.6, "c": hsl(rng.randf() * 360.0, 1.0, 0.7) if ws.id == "tm3" else _wrc(), "r": 2.0 + rng.randf() * 1.6, "g": 90.0, "fr": true})
	var fl: String = ws.fall
	var rate := 6 if fx == "blizzard" else (1 if fl == "star" else 2)
	if wfx.size() < 650 and wt > 0.3:
		for i in rate:
			if rng.randf() > 0.85 and fl != "confetti" and fx != "blizzard":
				continue
			var c := _wrc()
			match fl:
				"snow":
					var bz := fx == "blizzard"
					wfx.append({"p": Vector2(rng.randf() * VW * (1.4 if bz else 1.0) - (VW * 0.4 if bz else 0.0), -8), "v": Vector2(260 if bz else (rng.randf() - 0.5) * 30, (160 + rng.randf() * 80) if bz else (40 + rng.randf() * 40)), "l": 8.0, "c": c, "r": 1.5 + rng.randf() * 2.2, "sw": true})
				"bubble":
					wfx.append({"p": Vector2(rng.randf() * VW, VH + 8), "v": Vector2(0, -(40 + rng.randf() * 60)), "l": 9.0, "c": c, "r": 3.0 + rng.randf() * 6.0, "bb": true, "sw": true})
				"ember":
					wfx.append({"p": Vector2(rng.randf() * VW, VH + 5), "v": Vector2((rng.randf() - 0.5) * 30, -(50 + rng.randf() * 80)), "l": 7.0, "c": c, "r": 1.5 + rng.randf() * 2.0, "gl": true, "sw": true})
				"star":
					wfx.append({"p": Vector2(rng.randf() * VW, rng.randf() * VH * 0.8), "v": Vector2.ZERO, "l": 1.4, "c": c, "r": 3.0 + rng.randf() * 4.0, "st4": true, "l0": 1.4})
				"rain":
					wfx.append({"p": Vector2(rng.randf() * VW * 1.2, -10), "v": Vector2(-120, 700), "l": 2.0, "c": Color(0.7, 0.78, 1.0, 0.6), "rn": true})
				"dust", "sand":
					wfx.append({"p": Vector2(-8, rng.randf() * VH * 0.9), "v": Vector2(80 + rng.randf() * 90, (rng.randf() - 0.5) * 20), "l": 12.0, "c": c, "r": 1.0 + rng.randf() * 2.0, "sq": fl == "sand"})
				"confetti":
					wfx.append({"p": Vector2(rng.randf() * VW, -10), "v": Vector2((rng.randf() - 0.5) * 40, 60 + rng.randf() * 80), "l": 9.0, "c": c, "cf": true, "a": rng.randf() * 7.0})
				_:
					wfx.append({"p": Vector2(rng.randf() * VW, -12), "v": Vector2((rng.randf() - 0.5) * 30, 35 + rng.randf() * 45), "l": 12.0, "c": c, "lf": fl, "a": rng.randf() * 7.0, "sw": true})
	for i in wfx.size():
		var q: Dictionary = wfx[i]
		q.l -= dt
		if q.has("g"):
			q.v = (q.v as Vector2) + Vector2(0, q.g * dt)
		if q.get("fr", false):
			q.v = (q.v as Vector2) * 0.97
		if q.get("sw", false):
			q.p = (q.p as Vector2) + Vector2(sin(t_real * 1.7 + i) * 0.4, 0)
		q.p = (q.p as Vector2) + (q.v as Vector2) * dt
		if q.has("a"):
			q.a += dt * (2.0 if q.has("lf") else 6.0)
	wfx = wfx.filter(func(q): return q.l > 0.0 and q.p.y < VH + 20.0 and not (q.p.y < -30.0 and q.v.y < 0.0) and q.p.x < VW + 60.0)

func _ray_fan(c: Vector2, n: int, rot: float, L: float, w: float, col: Color) -> void:
	for i in n:
		var a := rot + i * TAU / n
		var dv := Vector2.from_angle(a - PI / 2.0)
		var pv := Vector2(-dv.y, dv.x)
		draw_polygon(PackedVector2Array([c, c + dv * L - pv * w, c + dv * L + pv * w]), PackedColorArray([col, Color(col, 0.0), Color(col, 0.0)]))

func _victory(f: Font) -> void:
	if ws.is_empty():
		ws = win_style()
	var u := ui_size()
	var VW := u.x
	var VH := u.y
	var wt := t_real - won_at
	var c := Vector2(VW / 2.0, VH * 0.36)
	var fx: String = ws.fx
	draw_rect(Rect2(Vector2.ZERO, u), Color(6 / 255.0, 8 / 255.0, 16 / 255.0, minf(0.72, wt * 0.9)))
	if wt < 0.5:
		draw_rect(Rect2(Vector2.ZERO, u), Color(1.0, 0.55, 0.24, (1.0 - wt / 0.5) * 0.7) if ws.id == "tm2" else Color(1.0, 0.96, 0.82, (1.0 - wt / 0.5) * 0.75))
	if fx == "aurora":
		for k in 3:
			var top := PackedVector2Array()
			var bot := PackedVector2Array()
			var px := 0.0
			while px <= VW:
				top.append(Vector2(px, VH * 0.12 + k * 30 + sin(px / 140.0 + wt * 1.2 + k * 2) * 40))
				bot.append(Vector2(px, VH * 0.42 + k * 30 + sin(px / 120.0 + wt * 1.5 + k) * 50))
				px += 20.0
			var cc := Color(0.75, 0.55, 1.0, 0.22) if k % 2 else Color(0.48, 1.0, 0.83, 0.25)
			for i in top.size() - 1:
				var mid := (top[i] + bot[i]) / 2.0
				var mid2 := (top[i + 1] + bot[i + 1]) / 2.0
				draw_polygon(PackedVector2Array([top[i], top[i + 1], mid2, mid]), PackedColorArray([Color(cc, 0), Color(cc, 0), cc, cc]))
				draw_polygon(PackedVector2Array([mid, mid2, bot[i + 1], bot[i]]), PackedColorArray([cc, cc, Color(cc, 0), Color(cc, 0)]))
	if fx == "deep" or fx == "heaven":
		for k in 6:
			var bx := VW * (0.1 + 0.16 * k) + sin(wt * 0.6 + k) * 30.0
			var cc := Color(1.0, 0.94, 0.75, 0.22) if fx == "heaven" else Color(0.47, 1.0, 1.0, 0.16)
			draw_polygon(PackedVector2Array([Vector2(bx - 20, 0), Vector2(bx + 20, 0), Vector2(bx + 120, VH), Vector2(bx - 40, VH)]), PackedColorArray([cc, cc, Color(cc, 0), Color(cc, 0)]))
	if fx == "heaven":
		var a := minf(1.0, wt * 1.5)
		draw_polygon(PackedVector2Array([Vector2(c.x - 90 * a, 0), Vector2(c.x + 90 * a, 0), Vector2(c.x + 90 * a, c.y + 40), Vector2(c.x - 90 * a, c.y + 40)]),
			PackedColorArray([Color(1, 0.98, 0.86, 0), Color(1, 0.98, 0.86, 0), Color(1, 0.94, 0.67, 0.55 * a), Color(1, 0.94, 0.67, 0.55 * a)]))
		var sp := clampf((wt - 0.3) * 1.4, 0.0, 1.0)
		for sd in [-1.0, 1.0]:
			for fi in 9:
				var an := (-0.25 - fi * 0.13) * sp
				var L := (90.0 + fi * 16.0) * sp
				var ctr := c + Vector2(sd * (120 + L * 0.5), 0).rotated(an * sd)
				draw_colored_polygon(_rot_ell(ctr, maxf(1.0, L * 0.55), 10 - fi * 0.5, an * sd), Color(1, 1, 1, 0.85) if fi % 2 else Color(1, 0.9, 0.59, 0.85))
		ell_line(self, c - Vector2(0, minf(90.0, VW * 0.075)), minf(120.0, VW * 0.1), 18, Color(1, 0.9, 0.55, 0.6 * a), 5.0)
	if fx == "prism":
		for i in 12:
			var a := wt * 0.35 + (i + 1) * PI / 6.0
			var dv := Vector2.from_angle(a - PI / 2.0)
			var pv := Vector2(-dv.y, dv.x)
			var L := VW * 0.8
			draw_colored_polygon(PackedVector2Array([c, c + dv * L - pv * 55, c + dv * L + pv * 55]), hsl(fmod(i * 30 + wt * 80, 360.0), 1.0, 0.65, minf(0.22, wt * 0.3)))
	elif fx != "heaven" and fx != "deep":
		var rc := C(ws.acc) if (ws.g == "kro" or ws.g == "star") else Color("#ffd76a")
		_ray_fan(c, 14, wt * 0.25, VW * 0.7, 40, Color(rc, 0.3 * minf(1.0, wt * 1.3)))
	if fx == "galaxy":
		for i in 220:
			var r := fmod(i * 7.3, maxf(VW, VH) * 0.55)
			var a := i * 0.5 + wt * (0.9 - r / 1400.0)
			var cc := Color(0.75, 0.55, 1.0, 0.75) if i % 3 else Color(1, 1, 1, 0.9)
			var z := 1.6 if i % 3 else 2.2
			draw_rect(Rect2(c + Vector2(cos(a) * r, sin(a) * r * 0.55), Vector2(z, z)), cc)
	if fx == "grid":
		var hy := VH * 0.62
		for i in range(-12, 13):
			draw_line(Vector2(c.x + i * 20, hy), Vector2(c.x + i * 140, VH), Color(0.23, 1.0, 0.91, 0.35), 1.0)
		for k in 10:
			var yy := hy + pow(fmod(k + wt * 1.5, 10.0) / 10.0, 2.0) * (VH - hy)
			draw_line(Vector2(0, yy), Vector2(VW, yy), Color(1.0, 0.23, 0.82, 0.15 + 0.3 * (yy - hy) / (VH - hy)), 1.0)
	if fx == "storm" and not wbolt.is_empty() and t_real - wbolt.t < 0.25:
		var a: float = 1.0 - (t_real - wbolt.t) / 0.25
		draw_rect(Rect2(Vector2.ZERO, u), Color(0.9, 0.9, 1.0, a * 0.35))
		draw_polyline(wbolt.pts, Color(1.0, 0.94, 0.55, a), 3.0)
	if fx == "dragon":
		draw_polygon(PackedVector2Array([Vector2(0, VH * 0.6), Vector2(VW, VH * 0.6), Vector2(VW, VH), Vector2(0, VH)]),
			PackedColorArray([Color(1, 0.31, 0.08, 0), Color(1, 0.31, 0.08, 0), Color(1, 0.35, 0.08, minf(0.45, wt * 0.5)), Color(1, 0.35, 0.08, minf(0.45, wt * 0.5))]))
		var dp := (wt - 0.4) / 2.6
		if dp > 0.0 and dp < 1.2:
			var dpos := Vector2(-200 + dp * (VW + 400), VH * 0.16 + sin(dp * 6.0) * 20.0)
			var fl := sin(t_real * 9.0) * 0.5
			var dk := Color(20 / 255.0, 6 / 255.0, 4 / 255.0, 0.92)
			draw_colored_polygon(ell(dpos, 70, 16), dk)
			draw_colored_polygon(PackedVector2Array([dpos + Vector2(60, -6), dpos + Vector2(105, -16), dpos + Vector2(98, 4)]), dk)
			draw_colored_polygon(PackedVector2Array([dpos + Vector2(-60, 0), dpos + Vector2(-120, 10), dpos + Vector2(-160, -8), dpos + Vector2(-62, 8)]), dk)
			for sd in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([dpos + Vector2(-10, 0), dpos + Vector2(-20, sd * (70 + fl * 40)), dpos + Vector2(-80, sd * (80 + fl * 50)), dpos + Vector2(-40, sd * 30), dpos + Vector2(30, 0)]), dk)
			draw_circle(dpos + Vector2(92, -10), 3, Color("#ff9a2a"))
	# 입자
	for q in wfx:
		var al: float = maxf(0.0, sin(PI * q.l / q.l0)) if q.get("st4", false) else minf(1.0, q.l * 1.4)
		var col: Color = Color(q.c, (q.c as Color).a * al)
		var p: Vector2 = q.p
		if q.get("gl", false):
			draw_circle(p, q.r * 2.2, Color(col, col.a * 0.3))
		if q.get("cf", false):
			_ui_tf(p, q.a, 1.0)
			draw_rect(Rect2(-4, -2, 8, 4), col)
			_ui_reset()
		elif q.has("lf") or q.get("pt", false):
			var lf: String = q.get("lf", "")
			if lf == "feather":
				draw_colored_polygon(_rot_ell(p, 10, 3.2, q.a), col)
				draw_line(p + Vector2(-11, 0).rotated(q.a), p + Vector2(10, 0).rotated(q.a), Color(0.63, 0.47, 0.16, 0.6 * al), 1.0)
			elif lf == "shard":
				var pts := PackedVector2Array()
				for v in [Vector2(0, -8), Vector2(5, 4), Vector2(-4, 6)]:
					pts.append(p + (v as Vector2).rotated(q.a))
				draw_colored_polygon(pts, hsl(fmod(q.a * 40.0, 360.0), 1.0, 0.75, 0.85 * al))
			elif lf == "neon":
				draw_circle(p, 7, Color(col, col.a * 0.3))
				draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), col)
			elif lf == "ash":
				draw_rect(Rect2(p - Vector2(2.5, 1.5), Vector2(5, 3)), col)
			else:
				draw_colored_polygon(_rot_ell(p, 7.0 if lf == "leaf" else 5.5, 3.5 if lf == "leaf" else 3.2, q.a), col)
		elif q.get("bb", false):
			draw_arc(p, q.r, 0, TAU, 16, col, 1.4)
			draw_circle(p - Vector2(q.r, q.r) * 0.35, q.r * 0.25, Color(1, 1, 1, 0.5 * al))
		elif q.get("st4", false):
			var pts := PackedVector2Array()
			for k in 8:
				var rr: float = q.r * 0.28 if k % 2 else q.r
				pts.append(p + Vector2.from_angle(k * PI / 4.0) * rr)
			draw_colored_polygon(pts, col)
		elif q.get("rn", false):
			draw_line(p, p + Vector2(-6, -24), col, 1.2)
		elif q.get("mt", false):
			draw_polyline_colors(PackedVector2Array([p, p - (q.v as Vector2) * 0.25]), PackedColorArray([col, Color(col, 0)]), 2.5)
		elif q.get("sq", false):
			draw_rect(Rect2(p, Vector2(q.r + 1, q.r + 1)), col)
		else:
			draw_circle(p, q.r, col)
	# 승리! 글씨
	_ui_reset()
	var sk := (1.0 - wt / 0.8) * 10.0 if (ws.id == "tm2" and wt < 0.8) else 0.0
	var sc := 0.4 + 1.0 * (wt / 0.6) + 0.15 * sin(wt / 0.6 * PI) if wt < 0.6 else 1.0 + 0.03 * sin(wt * 3.0)
	var fs := int(minf(110.0, VW * 0.09))
	_ui_tf(c + Vector2((rng.randf() - 0.5) * sk, (rng.randf() - 0.5) * sk), 0.0, sc)
	var tw := f.get_string_size("승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bp := Vector2(-tw / 2.0, fs * 0.36)
	var oc := Color("#2a1a4a") if ws.id == "tm3" else (Color("#0e1420") if ws.g == "kro" else Color("#5a3300"))
	draw_circle(Vector2.ZERO, fs * 1.1, Color(C(ws.acc), 0.12))
	draw_string_outline(f, bp, "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, oc)
	var g0 := C(ws.grad[0])
	var g1 := C(ws.grad[1])
	var g2 := C(ws.grad[2])
	if ws.id == "tm3":
		draw_string(f, bp, "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, hsl(fmod(wt * 120.0, 360.0), 1.0, 0.72))
	else:
		draw_string(f, bp, "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, g1)
		draw_string(f, bp + Vector2(0, -2), "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(g0, 0.35))
		draw_string(f, bp + Vector2(0, 2), "승리!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(g2, 0.25))
	if ws.set != "":
		var cw := fs * 0.5
		var cy := -fs * 0.78
		var crown := PackedVector2Array([Vector2(-cw, cy + cw * 0.45), Vector2(-cw, cy - cw * 0.05), Vector2(-cw * 0.5, cy + cw * 0.2), Vector2(0, cy - cw * 0.3), Vector2(cw * 0.5, cy + cw * 0.2), Vector2(cw, cy - cw * 0.05), Vector2(cw, cy + cw * 0.45)])
		draw_colored_polygon(crown, C(ws.acc))
		crown.append(crown[0])
		draw_polyline(crown, Color("#3a2400"), 3.0)
	_ui_reset()
	if wt > 0.7:
		var a := minf(1.0, (wt - 0.7) * 2.0)
		var sub: String = "외계 기지 50개를 모두 정복했어요!" + ("  ·  " + ws.set + " 완성!" if ws.set != "" else "")
		draw_string(f, Vector2(0, c.y + minf(80.0, VW * 0.065)), sub, HORIZONTAL_ALIGNMENT_CENTER, VW, int(minf(24.0, VW * 0.02)), Color(0.91, 0.93, 0.97, a))
	if wt > 1.4:
		var a := minf(1.0, (wt - 1.4) * 1.6)
		var w := minf(520.0, VW - 40.0)
		var py := c.y + minf(115.0, VW * 0.09)
		var r := Rect2(c.x - w / 2.0, py, w, 150.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(14 / 255.0, 20 / 255.0, 30 / 255.0, 0.92 * a)
		sb.border_color = Color(C(ws.acc), a)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.draw(get_canvas_item(), r)
		var items := [["플레이 시간", "%d분 %02d초" % [int(t / 60.0), int(t) % 60]], ["정복", "50 / 50"], ["잡은 적", str(int(SS.kills))], ["만든 로봇", str(int(SS.made))], ["번 광석", str(int(SS.earn))], ["받을 청석", "+" + str(cs_gain())]]
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

var _wrap_c := {}
func _wrap(f: Font, line: String, fs: int, mw: float) -> Array:
	var key := "%s|%d|%d|%d" % [line, fs, int(mw), f.get_instance_id()]
	if _wrap_c.has(key):
		return _wrap_c[key]
	if _wrap_c.size() > 4000:
		_wrap_c.clear()
	var r := _wrap0(f, line, fs, mw)
	_wrap_c[key] = r
	return r

func _wrap0(f: Font, line: String, fs: int, mw: float) -> Array:
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
						lab = "다시 누르면 판매" if warn else ("판매 " + str(sell_value(q)))
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
	if scene == "intro" or scene == "admin":
		return
	if acct != null and (acct.is_open() or acct.is_overlay()):
		return
	if bat != null and bat.is_open():
		return
	if conn_msg != "":
		return
	if scene == "client":
		_client_input(e)
		return
	if scene == "game" and slider_drag != null:
		if (e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION) or e is InputEventScreenDrag:
			_slider_set(slider_drag, e.position)
			return
		if (e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION and not e.pressed) or (e is InputEventScreenTouch and not e.pressed):
			slider_drag = null
			_apply_sv()
			sv_save()
			return
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
				finish_box(false)
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
			elif paused and pause_set:
				pause_set = false
				_apply_sv()
				sv_save()
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
			zm_t = t_real
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
var back_arm := 0.0
func booting() -> bool:
	return acct != null and acct.state == "boot"

# 안드로이드 뒤로 가기 버튼: 열린 창부터 하나씩 닫고, 로비 첫 화면에선 두 번 눌러 종료
func go_back() -> void:
	if acct != null and acct.is_overlay():
		acct.close_overlay()
		return
	if adm != null and adm.is_open():
		return
	if bat != null and bat.is_open():
		bat.close()
		return
	if acct != null and acct.is_open():
		if acct.mode == "panel":
			acct.hide_ui()
		return
	if conn_msg != "":
		return
	if keys_open:
		keys_open = false
		return
	if scene == "intro":
		return
	if scene == "client":
		if acp_open:
			acp_open = false
		elif t_real < back_arm:
			_quit_saved()
		else:
			back_arm = t_real + 2.0
		return
	if scene == "game":
		if won or lost:
			return
		if info_open:
			info_open = false
		elif shop_open:
			shop_open = false
		elif aim != "":
			aim = ""
			msg("취소했어요")
		elif paused and pause_set:
			pause_set = false
			_apply_sv()
			sv_save()
		elif paused:
			paused = false
		elif not selected().is_empty():
			clear_sel()
		else:
			paused = true
			sfx("pause")
		return
	# 로비
	if acp_open:
		acp_open = false
	elif bgm_open:
		bgm_open = false
	elif cash_sel >= 0:
		cash_sel = -1
	elif not box_res.is_empty():
		if box_busy():
			box_t0 = t_real - 100.0
			box_shown = box_res.size()
		else:
			box_res = []
			box_scroll = 0.0
	elif lsec != "main":
		lsec = "main"
		lob_scroll = 0.0
		_apply_sv()
		sv_save()
	elif t_real < back_arm:
		_quit_saved()
	else:
		back_arm = t_real + 2.0
		lmsg = "한 번 더 누르면 게임이 꺼져요"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if scene == "game":
			save_game()
		if acct != null and what != NOTIFICATION_WM_CLOSE_REQUEST:
			acct.push()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_saved()
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_in = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		mouse_in = true

# ── 새 버전 알림 (GitHub 다운로드 페이지 확인) ──
var app_ver := ""
var upd_url := ""
func _check_update() -> void:
	if FileAccess.file_exists("res://version.txt"):
		app_ver = FileAccess.get_file_as_string("res://version.txt").strip_edges()
	if app_ver == "" or OS.has_feature("editor"):
		return
	var r: Dictionary = await acct.http(HTTPClient.METHOD_GET, "https://api.github.com/repos/SOR0K/SOROK-GODOT/releases/tags/app-latest", PackedStringArray(["Accept: application/vnd.github+json", "User-Agent: SOROK"]))
	if not r.ok:
		return
	var nm: String = str(r.j.get("name", ""))
	if nm != "" and not (app_ver in nm):
		var want := "SOROK.apk" if OS.get_name() == "Android" else "SOROK.exe"
		for a in r.j.get("assets", []):
			if str(a.get("name", "")) == want:
				upd_url = str(a.get("browser_download_url", ""))
		if upd_url == "":
			upd_url = "https://github.com/SOR0K/SOROK-GODOT/releases/tag/app-latest"

func _quit_saved() -> void:
	if acct != null and acct.ses != null:
		await acct.push()
	get_tree().quit()

func _process(dt: float) -> void:
	t_real += dt
	if TEST:
		if int(SV.cs) < 999999:
			SV.cs = 999999
		if int(SV.ss) < 99999:
			SV.ss = 99999
		if scene == "game":
			ore = maxf(ore, 999999.0)
			stone = maxi(stone, 99999)
	if acct != null:
		acct.tick(dt)
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
	if scene == "lobby" and t_real - promo_t > 6.0:
		promo_t = t_real
		promo_i += 1
	_gnd_tick()
	_os_tick()
	if scene == "lobby" or scene == "intro" or scene == "client":
		_box_tick()
		queue_redraw()
		return
	var tu := Time.get_ticks_usec()
	if not won and not lost and not paused:
		# 앱이 멈췄다 돌아오면 지난 시간만큼 이어서 진행 (웹: 다른 창에 있어도 게임이 계속 진행돼요 · 최대 5분)
		if dt > 0.1:
			var el := minf(dt, 300.0)
			var n := ceili(el / (1.0 / 30.0))
			for i in n:
				if won or lost:
					break
				update_game(el / n)
		else:
			update_game(dt)
		_tut_tick()
		_pf("update_x%d" % int(Engine.time_scale), tu)
		save_acc += dt
		if save_acc > 15.0:
			save_acc = 0.0
			save_game()
	for f in fx:
		f.t -= dt
	fx = fx.filter(func(f): return f.t > 0.0)
	if mm_dirty:
		mm_tex.update(mm_img)
		fog_tex.update(fog_img)
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
			msg("기지 정복! 광석 +" + str(int(g)) + " · 진화석 +" + str(sg) + " · 채굴·기지 수입 ×" + String.num(eco(), 2))
			if captured() >= outs.size():
				won = true
				won_at = t_real
				sfx("victory")
				wfx = []
				ws = win_style()
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
		if t - rvm > 4.0:
			rvm = t
			var d0: Dictionary = rdy[0]
			msg(UT[d0.t].n + " 로봇(Lv" + str(d0.lv) + (" · 진화 " + str(d0.ev) if int(d0.ev) > 0 else "") + ")이 기지에서 부활했어요")
	if raid_alive and not ra:
		raid_wins += 1
		msg("🛡 레이드 방어 성공! (배틀패스 +50 XP)")
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

var PF := {}
func _pf(k: String, t0: int) -> void:
	var d := Time.get_ticks_usec() - t0
	if not PF.has(k):
		PF[k] = [0, 0, 0]
	var a: Array = PF[k]
	a[0] += d
	a[1] += 1
	a[2] = maxi(a[2], d)

func _pf_print() -> void:
	var ks := PF.keys()
	ks.sort()
	for k in ks:
		var a: Array = PF[k]
		print("PERF ", k, " avg=", int(a[0] / maxi(1, a[1])), "us max=", a[2], "us n=", a[1])

func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_draw0()
	_pf("draw_" + scene + ("_" + lsec if scene == "lobby" else ""), t0)

func _draw0() -> void:
	var f := ThemeDB.fallback_font
	_cos_cache()
	if scene == "intro":
		inv = get_canvas_transform().affine_inverse()
		draw_set_transform_matrix(inv)
		_intro(f)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if scene == "client":
		inv = get_canvas_transform().affine_inverse()
		draw_set_transform_matrix(inv)
		_client(f)
		_intro_fade()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if scene == "lobby":
		inv = get_canvas_transform().affine_inverse()
		draw_set_transform_matrix(inv)
		_lobby(f)
		_intro_fade()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var vr: Rect2 = view_rect().grow(CELL)
	var i0 := maxi(0, int(vr.position.x / CELL))
	var j0 := maxi(0, int(vr.position.y / CELL))
	var i1 := mini(GN - 1, int(vr.end.x / CELL))
	var j1 := mini(GN - 1, int(vr.end.y / CELL))
	var tq := Time.get_ticks_usec()
	_ground(i0, j0, i1, j1)
	_pf("g_ground", tq)
	tq = Time.get_ticks_usec()
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
	_pf("g_world", tq)
	tq = Time.get_ticks_usec()
	for u in bots:
		if vr.has_point(u.p):
			_unit(u, f)
	_pf("g_units", tq)
	tq = Time.get_ticks_usec()
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
	_pf("g_fx", tq)
	tq = Time.get_ticks_usec()
	_fog(i0, j0, i1, j1)
	_pf("g_fog", tq)
	tq = Time.get_ticks_usec()
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
	_pf("g_rest", tq)
	tq = Time.get_ticks_usec()
	_minimap()
	_pf("g_minimap", tq)
	tq = Time.get_ticks_usec()
	_hud(f)
	_pf("g_hud", tq)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _bar(x: float, y: float, w: float, r: float, c: Color, h: float = 3.0) -> void:
	draw_rect(Rect2(x - w / 2.0, y, w, h), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(x - w / 2.0, y, w * clampf(r, 0.0, 1.0), h), c)

# 땅: 매 장면 칸마다 그리지 않고, 40×40칸 무늬를 한 번만 그림으로 구워 두고 반복해서 깔아요
const GT := 40
var gnd_vp: SubViewport = null
var gnd_node: Node2D = null
var gnd_layer: Node2D = null
var gnd_key := ""

func _gnd_setup() -> void:
	gnd_vp = SubViewport.new()
	gnd_vp.world_2d = World2D.new()
	gnd_vp.size = Vector2i(GT * CELL, GT * CELL)
	gnd_vp.transparent_bg = false
	gnd_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(gnd_vp)
	gnd_node = Node2D.new()
	gnd_vp.add_child(gnd_node)
	gnd_node.draw.connect(_gnd_paint)
	gnd_layer = Node2D.new()
	gnd_layer.z_index = -1
	gnd_layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	gnd_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(gnd_layer)
	gnd_layer.draw.connect(_gnd_draw)

func _gnd_tick() -> void:
	if gnd_layer == null:
		return
	if scene == "game":
		var key := str(tn_cols)
		if key != gnd_key and not tn_cols.is_empty():
			gnd_key = key
			gnd_node.queue_redraw()
			gnd_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	gnd_layer.queue_redraw()

func _gnd_paint() -> void:
	if tn_cols.is_empty():
		return
	for j in range(-1, GT):
		for i in range(-1, GT):
			_ground_cell(gnd_node, i, j, posmod(i, GT), posmod(j, GT))

func _gnd_draw() -> void:
	if scene != "game" or gnd_key == "":
		return
	var vr: Rect2 = view_rect().grow(CELL)
	var i0 := maxi(0, int(vr.position.x / CELL))
	var j0 := maxi(0, int(vr.position.y / CELL))
	var i1 := mini(GN - 1, int(vr.end.x / CELL))
	var j1 := mini(GN - 1, int(vr.end.y / CELL))
	var r := Rect2(i0 * CELL, j0 * CELL, (i1 - i0 + 1) * CELL, (j1 - j0 + 1) * CELL)
	gnd_layer.draw_texture_rect_region(gnd_vp.get_texture(), r, r)

func _ground_cell(ci: CanvasItem, i: int, j: int, hi: int, hj: int) -> void:
	var h: int = ((hi * 73856093) ^ (hj * 19349663)) & 0xFFFFFFFF
	ci.draw_rect(Rect2(i * CELL, j * CELL, CELL + 1, CELL + 1), tn_cols[h % 4])
	var a := i * CELL + (h >> 2) % 30 + 4
	var b := j * CELL + (h >> 6) % 30 + 4
	if h % 11 == 0:
		ell_fill(ci, Vector2(a + 2, b + 3), 9, 5, Color(0, 0, 0, 0.18))
		ell_fill(ci, Vector2(a, b), 8, 5, Color("#625846"))
		ci.draw_rect(Rect2(a - 4, b - 3, 5, 2), Color("#7a6f5a"))
	elif h % 13 == 1:
		ci.draw_polyline(PackedVector2Array([Vector2(a, b), Vector2(a + 10, b + 4), Vector2(a + 16, b + 1)]), Color(0, 0, 0, 0.22), 1.0)
	elif h % 7 == 2:
		ci.draw_rect(Rect2(a, b, 2, 5), Color(0.47, 0.55, 0.31, 0.35))
		ci.draw_rect(Rect2(a + 4, b + 1, 2, 4), Color(0.47, 0.55, 0.31, 0.35))

func _ground(_i0: int, _j0: int, _i1: int, _j1: int) -> void:
	pass

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
	if u.t == "h":
		draw_arc(p, 12.0 + sin(t * 4.0) * 2.0, 0, TAU, 20, Color(0.55, 0.89, 0.55, 0.35), 1.0)
	if u.hp < u.mh and (p as Vector2).distance_to(B) <= WELL:
		draw_arc(p, z + 5.0, -PI / 2.0, -PI / 2.0 + TAU * fmod(t * 0.8, 1.0), 16, Color(0.43, 0.94, 0.63, 0.5), 1.5)
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
				draw_line(p, e.q, Color(C(skn.a) if not skn.is_empty() else Color(0.55, 0.89, 0.55), 0.7), 2.0)
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

# 안개: 칸마다 사각형을 그리지 않고 지도 크기 그림 한 장으로 (칸 하나 = 점 하나)
func _fog_upd(i: int, j: int) -> void:
	if i < 0 or j < 0 or i >= GN or j >= GN:
		return
	var c := Color(0, 0, 0, 0)
	if not exa(i, j):
		c = FOG
	elif not (exa(i - 1, j) and exa(i + 1, j) and exa(i, j - 1) and exa(i, j + 1)):
		c = Color(FOG, 0.4)
	fog_img.set_pixel(i, j, c)

func _fog(_i0: int, _j0: int, _i1: int, _j1: int) -> void:
	draw_texture_rect(fog_tex, Rect2(0, 0, GN * CELL, GN * CELL), false)

func _fog_old(i0: int, j0: int, i1: int, j1: int) -> void:
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
	intro_start()
	await _wait(1.6)
	await _shot("00x_intro_a")
	await _wait(0.4)
	await _shot("00x_intro_b")
	await _wait(2.6)
	await _shot("00x_intro_c")
	await _wait(1.4)
	scene = "client"
	await _wait(0.6)
	await _shot("00_client")
	acct.show_login("")
	await _wait(0.3)
	await _shot("00_client_login")
	acct.show_create()
	await _wait(0.3)
	await _shot("00_client_create")
	acct.show_help()
	await _wait(0.3)
	await _shot("00_client_help")
	acct.show_resend()
	await _wait(0.3)
	await _shot("00_client_resend")
	acct.show_forgot()
	await _wait(0.3)
	await _shot("00_client_forgot")
	acct.ban_info = {"why": "핵 사용 (테스트)", "until": acct.now_ms() + 3 * 86400000}
	acct.show_ban()
	await _wait(0.3)
	await _shot("00_client_ban")
	acct.show_renick()
	await _wait(0.3)
	await _shot("00_client_renick")
	acct.hide_ui()
	acct.popup("📮 운영자 우편이 도착했어요", "🎁 청석 500, 스킨 로봇 · 봄 벚꽃\n   버그 보상이에요. 불편을 드려 죄송해요")
	await _wait(0.3)
	await _shot("00_mail_pop")
	acct.close_overlay()
	acct.mails = [{"p": "x", "d": {"sum": "청석 500, 로봇 · 봄 벚꽃", "msg": "버그 보상이에요. 불편을 드려 죄송해요", "t": acct.now_ms()}}, {"p": "y", "d": {"sum": "무료 상자 3", "msg": "", "t": acct.now_ms() - 86400000}}]
	acct.notice_new = true
	scene = "lobby"
	lsec = "main"
	await _wait(0.4)
	await _shot("00_lobby_tb")
	acct.show_mailbox()
	await _wait(0.3)
	await _shot("00_mailbox")
	acct.close_overlay()
	bat.open("mode")
	await _wait(0.4)
	await _shot("00_battle_mode")
	SV.st = {"pl": 12, "w": 7, "l": 5, "best": 1834, "cap": 412}
	bat.show_tab("rec")
	await _wait(0.4)
	await _shot("00_battle_rec")
	bat.fr_in = [{"_id": "a1", "nick": "BANANA", "tag": "SR1"}]
	bat.fr_ok = [{"_id": "a2", "nick": "MUSIALA", "tag": "42"}]
	bat.fr_out = [{"_id": "a3", "nick": "NEWCASTLE", "tag": "NUFC"}]
	bat.show_tab("rank")
	for ch in bat.body.get_children():
		ch.queue_free()
	bat._draw_friends(bat.body)
	await _wait(0.4)
	await _shot("00_battle_friend")
	bat.close()
	bat.fr_in = []
	bat.fr_ok = []
	bat.fr_out = []
	SV.erase("st")
	acct.mails = []
	acct.notice_new = false
	scene = "client"
	adm.open()
	await _wait(0.3)
	await _shot("00_admin")
	adm.cur = {"uid": "TESTUID", "nick": "YASR", "tag": "1712", "email": "test@gmail.com", "t": acct.now_ms(), "S": {"pc": {"cs": 1234, "ss": 56, "fbox": 2, "bp": {"xp": 2300}, "own": ["j1", "k3"], "bown": ["b1"], "town": [], "tutDone": true, "_t": acct.now_ms(), "_game": true}}, "ban": {}, "tester": true, "mail": []}
	adm._draw_player()
	await _wait(0.4)
	await _shot("00_admin_player")
	adm.show_tab("notice")
	await _wait(0.4)
	await _shot("00_admin_notice")
	adm.close()
	adm.cur = {}
	acct.hide_ui()
	scene = "lobby"
	await _wait(0.6)
	await _shot("00_lobby")
	lsec = "set"
	set_tab = "a"
	await _shot("00b_set")
	bgm_open = true
	await _shot("00b1_set_bgm")
	bgm_open = false
	set_tab = "p"
	await _shot("00b2_prob")
	set_tab = "a"
	SV.cs = 30000
	SV.ss = 200
	lsec = "shop"
	shop_tab2 = "box"
	await _shot("00c_shop_box")
	open_box(10, false)
	await _wait(0.45)
	await _shot("00d0_box_shake")
	await _wait(1.0)
	await _shot("00d_box_open")
	await _wait(1.5)
	await _shot("00d2_box_done")
	box_res = []
	star_pull(10)
	await _wait(3.0)
	await _shot("00d3_star_done")
	box_res = []
	shop_tab2 = "r"
	await _shot("00e_shop_r")
	shop_tab2 = "t"
	await _shot("00e2_shop_t")
	shop_tab2 = "set"
	await _shot("00e3_shop_set")
	shop_tab2 = "hist"
	await _shot("00e4_shop_hist")
	shop_tab2 = "cash"
	await _shot("00e5_shop_cash")
	cash_sel = 2
	await _shot("00e6_cash_ask")
	cash_sel = -1
	shop_tab2 = "star"
	await _shot("00f_shop_star")
	buy_set(0)
	print("SET eq=", SV.eq, " beq=", SV.beq, " teq=", SV.teq, " cs=", SV.cs)
	lsec = "store"
	await _shot("00g_store")
	SV.bp.xp = 6200
	lsec = "pass"
	pass_init = true
	await _shot("00h_pass")
	lsec = "notes"
	lob_scroll = 0.0
	await _shot("00i_notes")
	lsec = "set"
	set_tab = "p"
	lob_scroll = 0.0
	await _shot("00i2_prob")
	cos_press({"a": "jump", "k": "star"})
	await _shot("00i3_prob_star")
	lsec = "shop"
	shop_tab2 = "t"
	lob_scroll = 0.0
	cos_press({"a": "tprev", "id": str(TS[0].id)})
	await _shot("00i4_tpv")
	lsec = "main"
	acp_show()
	await _shot("00i5_acct")
	acp_open = false
	shop_tab2 = "box"
	lsec = "shop"
	box_scroll = 0.0
	open_box(1, false)
	await _wait(2.0)
	await _shot("00i6_box1")
	box_res = []
	lsec = "store"
	cos_press({"a": "sf", "k": "cat", "v": "s"})
	cos_press({"a": "sf", "k": "cat", "v": "t"})
	await _shot("00i7_store_multi")
	stF = {"own": [], "cat": [], "gr": []}
	lsec = "set"
	set_tab = "a"
	await _shot("00i8_set_back")
	cos_press({"a": "bpall"})
	print("BP ", lmsg, " cs=", SV.cs, " fbox=", SV.fbox)
	lsec = "main"
	await _shot("00i_main_skin")
	var pk: String = acct.pack()
	var cs0: int = SV.cs
	SV.cs = 1
	acct.apply_cloud(pk)
	print("ACCT pack->apply cs ", cs0, "->", SV.cs, " eq=", SV.eq, " own=", SV.own.size(), " bp=", SV.bp.xp)
	# 웹 서버에서 온 것 같은 기록(빈 칸·옛 모양)을 받아도 로비가 그려지는지
	SV.mute = true
	acct.apply_cloud(JSON.stringify({"sorok_v1": JSON.stringify({"cs": 1234, "own": ["j1", "k3", "zz9"], "eq": "k3", "bown": ["b1"], "beq": null, "town": [], "teq": "nope", "frag": {"j2": 3}, "fbox": null, "bp": {"xp": 2300, "cf": [1, 3]}, "hist": [{"t": 1, "k": "box", "g": "ju", "x": "주 테스트"}, 5], "tutDone": true, "vol": {"s": null, "b": 40}, "uis": 1}), "sorok_save": "{}"}))
	print("WEBDATA cs=", SV.cs, " eq=", SV.eq, " teq=", SV.teq, " bp=", SV.bp, " vol=", SV.vol_s, "/", SV.vol_b, " uis=", SV.uis)
	lsec = "main"
	await _shot("00ia_after_web")
	SV.mute = true
	acct.show_login("")
	await _shot("00j_login")
	var jr: Dictionary = await acct.idt("signInWithPassword", {"email": "nobody-ci-test@sorok.invalid", "password": "wrongpass1", "returnSecureToken": true})
	print("ACCT net ", jr.get("err", "ok"), " -> ", acct.err_txt(str(jr.get("err", ""))))
	acct.show_create()
	await _shot("00k_signup")
	acct.hide_ui()
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
	pause_set = true
	await _shot("01d_pause_set")
	pause_set = false
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
	# 많이 몰린 상황 (로봇 80대 · 가장 멀리 본 화면)
	PF.clear()
	for i in 80:
		var bu := mk_bot(["c", "r", "h", "m", "s"][i % 5], B + Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500)))
		bots.append(bu)
	won = false
	zm = ZMIN
	cam.zoom = Vector2(zm, zm)
	cam_to(B)
	await _wait(4.0)
	print("BENCH bots=", bots.size(), " ens=", ens.size(), " fps=", Engine.get_frames_per_second())
	_pf_print()
	scene = "lobby"
	lsec = "main"
	PF.clear()
	await _wait(1.5)
	lsec = "shop"
	shop_tab2 = "box"
	await _wait(1.5)
	lsec = "store"
	await _wait(1.5)
	lsec = "pass"
	await _wait(1.5)
	scene = "client"
	await _wait(1.5)
	_pf_print()
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

# 타원: 단위 원을 한 번만 계산해 두고 늘이고 옮겨서 써요 (매번 cos·sin 28번 계산하지 않게)
var _ell_u := {}
func _ell_unit(n: int, closed: bool) -> PackedVector2Array:
	var key := n * 2 + (1 if closed else 0)
	if not _ell_u.has(key):
		var p := PackedVector2Array()
		for i in n:
			var a := TAU * i / float(n)
			p.append(Vector2(cos(a), sin(a)))
		if closed:
			p.append(p[0])
		_ell_u[key] = p
	return _ell_u[key]

func ell(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	return Transform2D(Vector2(rx, 0), Vector2(0, ry), c) * _ell_unit(n, false)

func ell_fill(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	ci.draw_colored_polygon(ell(c, rx, ry), col)

func ell_line(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, w: float = 1.5) -> void:
	ci.draw_polyline(Transform2D(Vector2(rx, 0), Vector2(0, ry), c) * _ell_unit(28, true), col, w, true)

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
