extends Node
# 대전 화면: 게임 모드 · 내 기록 · 랭킹 · 친구 (게임 로비 분위기의 어두운 화면)
var a = null          # account.gd
var g = null          # game.gd
var root: Control = null
var body: VBoxContainer = null
var tabs_box: HBoxContainer = null
var note_l: Label = null
var tab := "mode"
var fr_in: Array = []     # 받은 친구 신청
var fr_out: Array = []    # 보낸 친구 신청
var fr_ok: Array = []     # 친구
var confirm_k := ""
var confirm_t := 0.0

const BG := Color("#0e1419")
const CARD := Color("#16202a")
const LINE := Color("#2c3a49")
const INK := Color("#e6edf3")
const SUB := Color("#8fa3b5")
const GOLD := Color("#ffd76a")
const RED := Color("#ff7a6b")
const GREEN := Color("#6ee7a8")

func _fs(k: float) -> int:
	return a._fs(k)

func _ready() -> void:
	get_tree().node_added.connect(_on_node)

func _on_node(n: Node) -> void:
	if root != null and n is Control and not (n is ScrollContainer) and root.is_ancestor_of(n):
		var c := n as Control
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			c.mouse_filter = Control.MOUSE_FILTER_PASS

func is_open() -> bool:
	return root != null

func close() -> void:
	if root != null:
		root.queue_free()
		root = null

func open(t: String = "mode") -> void:
	close()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = _fs(14)
	root.theme = th
	a.add_child(root)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var mg := MarginContainer.new()
	mg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sp: float = g._safe_top() * g.us if g.has_method("_safe_top") else 0.0
	mg.add_theme_constant_override("margin_left", _fs(22))
	mg.add_theme_constant_override("margin_right", _fs(22))
	mg.add_theme_constant_override("margin_top", _fs(14) + int(sp))
	mg.add_theme_constant_override("margin_bottom", _fs(10))
	root.add_child(mg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _fs(10))
	mg.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", _fs(8))
	col.add_child(top)
	var brand := _lab(top, "대전", 20, GOLD, true)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	tabs_box = HBoxContainer.new()
	tabs_box.add_theme_constant_override("separation", _fs(4))
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tabs_box)
	_b(top, "← 로비로", func(): close(), "w")
	note_l = _lab(col, " ", 13, GREEN)
	note_l.custom_minimum_size = Vector2(0, _fs(18))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", _fs(12))
	sc.add_child(body)
	show_tab(t)

# ── 부품 ──
func _lab(p: Control, t: String, fs: float, c: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", _fs(fs))
	l.add_theme_color_override("font_color", c)
	if bold:
		l.add_theme_font_override("font", g.fb())
	p.add_child(l)
	return l

func _sb(bg: Color, bd: Color, rad: int = 10, bw: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bd
	s.set_border_width_all(bw)
	s.set_corner_radius_all(rad)
	return s

func _b(p: Control, t: String, cb: Callable, kind: String = "w") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, _fs(40))
	var C: Array = {"w": [Color("#1a2430"), LINE, INK], "on": [Color("#2a2410"), Color("#c9a255"), GOLD], "g": [Color("#d9b04e"), Color("#d9b04e"), Color("#2a1a02")],
		"r": [Color("#3a1a1a"), Color("#a04040"), RED], "off": [Color("#141b22"), Color("#222c36"), Color("#5a6a78")]}[kind]
	var n := _sb(C[0], C[1], 8)
	n.content_margin_left = _fs(14)
	n.content_margin_right = _fs(14)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = C[0].lightened(0.08)
	h.border_color = Color("#c9a255") if kind != "off" else C[1]
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", n)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(k, C[2])
	b.add_theme_font_size_override("font_size", _fs(13.5))
	b.add_theme_font_override("font", g.fb())
	b.pressed.connect(cb)
	p.add_child(b)
	return b

func _card(p: Control, title: String = "", bd: Color = LINE) -> VBoxContainer:
	var pc := PanelContainer.new()
	var st := _sb(CARD, bd, 12)
	st.content_margin_left = _fs(18)
	st.content_margin_right = _fs(18)
	st.content_margin_top = _fs(14)
	st.content_margin_bottom = _fs(14)
	pc.add_theme_stylebox_override("panel", st)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", _fs(8))
	pc.add_child(v)
	if title != "":
		_lab(v, title, 16, INK, true)
	return v

func _row(p: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(10))
	p.add_child(h)
	return h

func note(t: String, bad: bool = false) -> void:
	if note_l == null:
		return
	note_l.text = t if t != "" else " "
	note_l.add_theme_color_override("font_color", RED if bad else GREEN)

func show_tab(t: String) -> void:
	tab = t
	for c in tabs_box.get_children():
		c.queue_free()
	var fn := fr_in.size()
	for it in [["mode", "게임 모드"], ["rec", "내 기록"], ["rank", "랭킹"], ["friend", "친구" + (" (" + str(fn) + ")" if fn > 0 else "")]]:
		var k: String = it[0]
		_b(tabs_box, it[1], func(): show_tab(k), "on" if k == t else "w")
	a.fields = {}
	for c in body.get_children():
		c.queue_free()
	note("")
	match t:
		"mode":
			_mode_tab()
		"rec":
			_rec_tab()
		"rank":
			_rank_tab()
		"friend":
			_friend_tab()

# ═════════ 게임 모드 ═════════
func _mode_card(p: Control, title: String, sub: String, open_: bool) -> VBoxContainer:
	var v := _card(p, "", Color("#c9a255") if open_ else LINE)
	v.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", _fs(4))
	_lab(v, title, 20, GOLD if open_ else INK, true)
	var d := _lab(v, sub, 12.5, SUB)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, _fs(10))
	v.add_child(gap)
	return v

func _mode_tab() -> void:
	var r := _row(body)
	r.add_theme_constant_override("separation", _fs(12))
	var n := _mode_card(r, "일반전", "혼자 · 외계 기지 50개 정복", true)
	var br := _row(n)
	br.add_theme_constant_override("separation", _fs(8))
	if g.has_save():
		var cb := _b(br, "이어하기", func():
			close()
			g.start_game(true), "w")
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nb := _b(br, "새 게임", func():
		close()
		g.start_game(false), "g")
	nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c := _mode_card(r, "경쟁전", "점수 · 랭킹", false)
	_b(c, "준비 중", func(): note("경쟁전은 점수 기준을 정한 뒤에 열려요"), "off")
	var p := _mode_card(r, "사용자 설정 게임", "친구와 원하는 규칙으로", false)
	_b(p, "준비 중", func(): note("사용자 설정 게임은 멀티플레이 업데이트 때 열려요"), "off")
	# 좁은 화면이면 세로로
	var vs: Vector2 = g.get_viewport().get_visible_rect().size
	if vs.x < _fs(900):
		r.queue_free()
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", _fs(12))
		body.add_child(col)
		for ch in r.get_children():
			r.remove_child(ch)
			col.add_child(ch)

# ═════════ 내 기록 ═════════
func _stats() -> Dictionary:
	return g.SV.get("st", {}) if g.SV.get("st") is Dictionary else {}

func _tm(sec: int) -> String:
	if sec <= 0:
		return "-"
	return "%d분 %02d초" % [int(sec / 60), sec % 60] if sec < 3600 else "%d시간 %02d분" % [int(sec / 3600), int(sec / 60) % 60]

func _tile(p: Control, label: String, val: String, c: Color) -> void:
	var v := _card(p)
	v.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab(v, label, 12.5, SUB, true)
	_lab(v, val, 26, c, true)

func _rec_tab() -> void:
	var S := _stats()
	var pl := int(S.get("pl", 0))
	var w := int(S.get("w", 0))
	var l := int(S.get("l", 0))
	var hc := _card(body)
	var hr := _row(hc)
	var nick := str(a.ses.get("nick", "?")) if a.ses != null else "?"
	var nl := _lab(hr, nick, 24, INK, true)
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	var tl := _lab(hr, "#" + (str(a.ses.get("tag", "")) if a.ses != null else ""), 16, SUB)
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tl.size_flags_vertical = Control.SIZE_SHRINK_END
	_lab(hc, a.srv_name() + " 기록 · 일반전 기준 (판이 끝났을 때 쌓여요)", 12.5, SUB)
	var r1 := _row(body)
	_tile(r1, "플레이", str(pl) + "판", INK)
	_tile(r1, "승리", str(w), GREEN)
	_tile(r1, "패배", str(l), RED)
	_tile(r1, "승률", ("%d%%" % int(round(100.0 * w / pl))) if pl > 0 else "-", GOLD)
	var r2 := _row(body)
	_tile(r2, "가장 빠른 승리", _tm(int(S.get("best", 0))), GOLD)
	_tile(r2, "정복한 기지 (누적)", str(int(S.get("cap", 0))) + "개", INK)
	if pl == 0:
		_lab(body, "아직 끝낸 판이 없어요 · 일반전을 한 판 끝내면 여기에 기록이 쌓여요", 13, SUB)

# ═════════ 랭킹 ═════════
func _rank_tab() -> void:
	var c := _card(body, "🏆 랭킹", Color("#c9a255"))
	_lab(c, "점수 기준을 정하는 중이에요", 18, GOLD, true)
	_lab(c, "경쟁전 점수 기준이 정해지면 전체 순위 TOP 100과 친구 순위가 여기에 나와요", 13, SUB)
	var S := _stats()
	var m := _card(body, "지금 내 기록")
	_lab(m, "승리 " + str(int(S.get("w", 0))) + "   ·   가장 빠른 승리 " + _tm(int(S.get("best", 0))) + "   ·   정복한 기지 " + str(int(S.get("cap", 0))) + "개", 14, INK)

# ═════════ 친구 ═════════
func _fpath(me: String, other: String) -> String:
	return "friends/" + me + "/list/" + other

func load_friends() -> void:
	if a.ses == null:
		return
	var r: Dictionary = await a.fs(HTTPClient.METHOD_GET, "friends/" + str(a.ses.uid) + "/list", null, "pageSize=300")
	fr_in = []
	fr_out = []
	fr_ok = []
	if not r.ok:
		return
	for doc in r.j.get("documents", []):
		var D: Dictionary = a.dfields(doc)
		var p: String = a.dpath(doc)
		D._id = p.get_slice("/", p.get_slice_count("/") - 1)
		match str(D.get("st", "")):
			"in":
				fr_in.append(D)
			"out":
				fr_out.append(D)
			"ok":
				fr_ok.append(D)

func _friend_tab() -> void:
	var c := _card(body, "친구 추가")
	_lab(c, "친구의 닉네임#태그를 넣어 신청해요 · 상대가 수락하면 친구가 돼요", 12.5, SUB)
	var r := _row(c)
	var n: LineEdit = a._input_box(r, "fn", "닉네임")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hs := _lab(r, "#", 18, SUB, true)
	hs.autowrap_mode = TextServer.AUTOWRAP_OFF
	var t: LineEdit = a._input_box(r, "ft", "태그")
	t.custom_minimum_size = Vector2(_fs(120), 0)
	_b(r, "신청", func(): _send(n.text.strip_edges(), t.text.strip_edges()), "g")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _fs(12))
	body.add_child(box)
	_lab(box, "불러오는 중…", 13, SUB)
	await load_friends()
	if not is_instance_valid(box):
		return
	for ch in box.get_children():
		ch.queue_free()
	_draw_friends(box)

func _draw_friends(box: Control) -> void:
	if not fr_in.is_empty():
		var c := _card(box, "📨 받은 친구 신청 (" + str(fr_in.size()) + ")", Color("#c9a255"))
		for D in fr_in:
			var fid: String = D._id
			var h := _row(c)
			var l := _lab(h, str(D.get("nick", "?")) + "#" + str(D.get("tag", "")), 15, INK, true)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_b(h, "수락", func(): _accept(D), "g")
			_b(h, "거절", func(): _remove(fid, "거절했어요"), "w")
	var fc := _card(box, "👥 친구 (" + str(fr_ok.size()) + ")")
	if fr_ok.is_empty():
		_lab(fc, "아직 친구가 없어요 · 위에서 닉네임#태그로 신청해 보세요", 13, SUB)
	for D in fr_ok:
		var fid: String = D._id
		var h := _row(fc)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(tv)
		_lab(tv, str(D.get("nick", "?")) + "#" + str(D.get("tag", "")), 15, INK, true)
		var st_l := _lab(tv, "기록 불러오는 중…", 12, SUB)
		_b(h, "삭제", func():
			if _confirm("del" + fid, "한 번 더 누르면 친구에서 삭제해요"):
				_remove(fid, "친구에서 삭제했어요"), "r")
		_pub_line(fid, st_l)
	if not fr_out.is_empty():
		var oc := _card(box, "📤 보낸 신청 (" + str(fr_out.size()) + ") · 상대가 수락하면 친구가 돼요")
		for D in fr_out:
			var fid: String = D._id
			var h := _row(oc)
			var l := _lab(h, str(D.get("nick", "?")) + "#" + str(D.get("tag", "")) + "   · 기다리는 중", 14, SUB)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_b(h, "취소", func(): _remove(fid, "신청을 취소했어요"), "w")

func _pub_line(fid: String, l: Label) -> void:
	var r: Dictionary = await a.fs(HTTPClient.METHOD_GET, "pub/" + fid)
	if not is_instance_valid(l):
		return
	if not r.ok:
		l.text = "아직 기록이 없어요"
		return
	var P: Dictionary = a.dfields(r.j)
	l.text = "승리 " + str(int(P.get("w", 0))) + " · 플레이 " + str(int(P.get("pl", 0))) + " · 가장 빠른 승리 " + _tm(int(P.get("best", 0))) + " · 최근 접속 " + a.when(int(P.get("t", 0)))

func _confirm(k: String, msg: String) -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	if confirm_k == k and now - confirm_t < 4.0:
		confirm_k = ""
		return true
	confirm_k = k
	confirm_t = now
	note(msg, true)
	return false

func _send(n: String, t: String) -> void:
	if a.ses == null:
		return
	if n == "":
		note("친구 닉네임을 넣어 주세요", true)
		return
	if t == "":
		t = a.DTAG
	note("찾는 중…")
	var key: String = a.rkey(n, t)
	var r: Dictionary = await a.fs(HTTPClient.METHOD_GET, "nicks/" + key.uri_encode())
	if not r.ok:
		note("그런 닉네임#태그가 없어요", true)
		return
	var f: Dictionary = a.dfields(r.j)
	var fid := str(f.get("uid", ""))
	var me := str(a.ses.uid)
	if fid == "" or fid == me:
		note("나 자신은 친구로 추가할 수 없어요", true)
		return
	for D in fr_ok:
		if D._id == fid:
			note("이미 친구예요", true)
			return
	for D in fr_in:
		if D._id == fid:
			await _accept(D)
			return
	var mine := {"nick": str(f.get("n", n)), "tag": str(f.get("t", t)), "st": "out", "t": a.now_ms()}
	var theirs := {"nick": str(a.ses.get("nick", "")), "tag": str(a.ses.get("tag", a.DTAG)), "st": "in", "t": a.now_ms()}
	var w1: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, _fpath(fid, me), a.mk(theirs))
	if not w1.ok:
		note("신청 실패 (" + str(w1.st) + ") · Firestore 규칙을 확인해 주세요", true)
		return
	await a.fs(HTTPClient.METHOD_PATCH, _fpath(me, fid), a.mk(mine))
	show_tab("friend")
	note(mine.nick + "#" + mine.tag + " 님에게 친구 신청을 보냈어요")

func _accept(D: Dictionary) -> void:
	var fid: String = D._id
	var me := str(a.ses.uid)
	var w1: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, _fpath(me, fid), a.mk({"st": "ok"}), "updateMask.fieldPaths=st")
	var w2: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, _fpath(fid, me), a.mk({"st": "ok"}), "updateMask.fieldPaths=st")
	show_tab("friend")
	note((str(D.get("nick", "")) + " 님과 친구가 됐어요") if w1.ok and w2.ok else "수락 실패 · 잠시 후 다시 해 주세요", not (w1.ok and w2.ok))

func _remove(fid: String, msg: String) -> void:
	var me := str(a.ses.uid)
	await a.fs(HTTPClient.METHOD_DELETE, _fpath(me, fid))
	await a.fs(HTTPClient.METHOD_DELETE, _fpath(fid, me))
	show_tab("friend")
	note(msg)
