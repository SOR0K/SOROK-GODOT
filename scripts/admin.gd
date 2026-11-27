extends Node
# SOROK 운영자 화면 (운영자 계정으로 로그인했을 때만)
# 플레이어 검색·정보 · 보상/명령 우편 · 테스터 · 정지 · 공지 · 목록 · 우편 기록
var a = null          # account.gd
var g = null          # game.gd
var root: Control = null
var body: VBoxContainer = null
var tabs_box: HBoxContainer = null
var tab := "player"
var note_l: Label = null
var cur := {}
var confirm_k := ""
var confirm_t := 0.0

const BG := Color("#eef0f3")
const INK := Color("#1a1d22")
const SUB := Color("#5a6470")
const GOLD := Color("#c9a255")
const RED := Color("#d23c2c")
const GREEN := Color("#2f8a5a")

func _fs(k: float) -> int:
	return a._fs(k)

func is_open() -> bool:
	return root != null

func close() -> void:
	if root != null:
		root.queue_free()
		root = null

func open() -> void:
	close()
	a.hide_ui()
	g.scene = "admin"
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
	var sp: float = g._safe_top() if g.has_method("_safe_top") else 0.0
	mg.add_theme_constant_override("margin_left", _fs(22))
	mg.add_theme_constant_override("margin_right", _fs(22))
	mg.add_theme_constant_override("margin_top", _fs(14) + int(sp))
	mg.add_theme_constant_override("margin_bottom", _fs(10))
	root.add_child(mg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _fs(10))
	mg.add_child(col)
	# 위쪽 줄: 이름 · 탭 · 게임 테스트 · 로그아웃
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", _fs(8))
	col.add_child(top)
	var brand := _lab(top, "◆ SOROK 운영자", 16, GOLD, true)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	tabs_box = HBoxContainer.new()
	tabs_box.add_theme_constant_override("separation", _fs(4))
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tabs_box)
	_b(top, "게임 테스트하기", func(): play(), "w")
	_b(top, "로그아웃", func():
		close()
		a.logout(), "w")
	note_l = _lab(col, "", 13, GREEN)
	note_l.visible = false
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", _fs(10))
	sc.add_child(body)
	show_tab(tab)

func play() -> void:
	close()
	g.scene = "lobby"
	g.lsec = "main"

# ── 작은 부품 ──
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

func _b(p: Control, t: String, cb: Callable, kind: String = "w") -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, _fs(38))
	var C := {"w": [Color.WHITE, Color("#d5dae0"), INK], "k": [INK, INK, Color.WHITE], "r": [Color("#d6303f"), Color("#d6303f"), Color.WHITE],
		"g": [Color("#f2c14e"), Color("#e0ad3a"), Color("#2a1a00")], "on": [INK, INK, Color("#ffd76a")]}[kind]
	var n: StyleBoxFlat = a._style(C[0], C[1], 8, 1)
	n.content_margin_left = _fs(14)
	n.content_margin_right = _fs(14)
	var h: StyleBoxFlat = n.duplicate()
	h.border_color = INK
	h.bg_color = C[0].lightened(0.06) if kind != "w" else Color("#f7f8fa")
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, C[2])
	b.add_theme_font_size_override("font_size", _fs(13.5))
	b.add_theme_font_override("font", g.fb())
	b.pressed.connect(cb)
	p.add_child(b)
	return b

func _in(p: Control, key: String, ph: String, val: String = "", w: float = 0.0) -> LineEdit:
	var e: LineEdit = a._input_box(p, key, ph, false, val)
	e.custom_minimum_size = Vector2(_fs(w) if w > 0.0 else 0.0, _fs(40))
	if w <= 0.0:
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return e

func _row(p: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(8))
	p.add_child(h)
	return h

func _card(p: Control, title: String = "") -> VBoxContainer:
	var pc := PanelContainer.new()
	var st: StyleBoxFlat = a._style(Color.WHITE, Color("#e1e5ea"), 12, 1)
	st.content_margin_left = _fs(18)
	st.content_margin_right = _fs(18)
	st.content_margin_top = _fs(14)
	st.content_margin_bottom = _fs(14)
	pc.add_theme_stylebox_override("panel", st)
	p.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", _fs(8))
	pc.add_child(v)
	if title != "":
		_lab(v, title, 15, INK, true)
	return v

func _opt(p: Control, items: Array) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(str(it))
	o.custom_minimum_size = Vector2(0, _fs(40))
	o.add_theme_font_size_override("font_size", _fs(13.5))
	p.add_child(o)
	return o

func note(t: String, bad: bool = false) -> void:
	if note_l == null:
		return
	note_l.text = t
	note_l.visible = t != ""
	note_l.add_theme_color_override("font_color", RED if bad else GREEN)

func _clear() -> void:
	a.fields = {}
	for c in body.get_children():
		c.queue_free()

func show_tab(t: String) -> void:
	tab = t
	for c in tabs_box.get_children():
		c.queue_free()
	for it in [["player", "플레이어"], ["notice", "공지"], ["list", "목록"], ["log", "우편 기록"]]:
		var k: String = it[0]
		_b(tabs_box, it[1], func(): show_tab(k), "on" if k == t else "w")
	_clear()
	note("")
	match t:
		"player":
			_player_tab()
		"notice":
			_notice_tab()
		"list":
			_list_tab()
		"log":
			_log_tab()

# ── 서버 묻기 ──
func q(coll: String, where = null, order: String = "", lim: int = 40) -> Array:
	var sq := {"from": [{"collectionId": coll}], "limit": lim}
	if where != null:
		sq.where = where
	if order != "":
		sq.orderBy = [{"field": {"fieldPath": order}, "direction": "DESCENDING"}]
	var tk: String = await a.tok()
	var r: Dictionary = await a.http(HTTPClient.METHOD_POST, a.FBDB + ":runQuery", PackedStringArray(["Authorization: Bearer " + tk, "Content-Type: application/json"]), JSON.stringify({"structuredQuery": sq}))
	if not r.ok:
		note("서버에서 못 가져왔어요 (" + str(r.st) + ") · Firestore 규칙을 확인해 주세요", true)
		return []
	var out: Array = []
	for it in r.a:
		if it is Dictionary and it.has("document"):
			var D: Dictionary = a.dfields(it.document)
			D._id = a.dpath(it.document).get_slice("/", a.dpath(it.document).get_slice_count("/") - 1)
			out.append(D)
	return out

func eqf(field: String, v: String) -> Dictionary:
	return {"fieldFilter": {"field": {"fieldPath": field}, "op": "EQUAL", "value": {"stringValue": v}}}

# ═════════ 플레이어 ═════════
var res_box: VBoxContainer = null
func _player_tab() -> void:
	var c := _card(body, "플레이어 찾기")
	_lab(c, "닉네임#태그 또는 이메일로 찾아요 (태그는 비워도 돼요)", 12.5, SUB)
	var r := _row(c)
	var n := _in(r, "pn", "닉네임 또는 이메일")
	var hs := _lab(r, "#", 16, SUB, true)
	hs.autowrap_mode = TextServer.AUTOWRAP_OFF
	var t := _in(r, "pt", "태그", "", 110)
	_b(r, "찾기", func(): _search(n.text.strip_edges(), t.text.strip_edges()), "k")
	res_box = VBoxContainer.new()
	res_box.add_theme_constant_override("separation", _fs(10))
	body.add_child(res_box)
	if not cur.is_empty():
		_open_player(cur.uid)

func _search(n: String, t: String) -> void:
	if n == "":
		note("닉네임이나 이메일을 넣어 주세요", true)
		return
	note("찾는 중…")
	var W
	if n.contains("@"):
		W = eqf("email", n.to_lower())
	elif t != "":
		W = {"compositeFilter": {"op": "AND", "filters": [eqf("nl", n.to_lower()), eqf("tl", t.to_lower())]}}
	else:
		W = eqf("nl", n.to_lower())
	var L := await q("book", W, "", 20)
	if n.contains("@") and L.is_empty():
		L = await q("book", eqf("email", n), "", 20)
	for c in res_box.get_children():
		c.queue_free()
	if L.is_empty():
		note("못 찾았어요 · 이 기능이 생긴 뒤 한 번도 로그인하지 않은 사람이면 Firebase 콘솔에서 찾아 주세요", true)
		return
	note("")
	if L.size() == 1:
		_open_player(L[0]._id)
		return
	var c := _card(res_box, str(L.size()) + "명 찾았어요")
	for D in L:
		var uid: String = D._id
		_b(c, str(D.get("nick", "?")) + "#" + str(D.get("tag", "")) + "   ·   " + str(D.get("email", "")), func(): _open_player(uid))

func _save_of(doc: Dictionary) -> Dictionary:
	var F: Dictionary = a.dfields(doc)
	var D = JSON.parse_string(str(F.get("d", "")))
	var sv := {}
	if D is Dictionary:
		var w = JSON.parse_string(str(D.get("sorok_v1", "{}")))
		if w is Dictionary:
			sv = w
	sv._t = int(F.get("t", 0))
	sv._game = D is Dictionary and str(D.get("sorok_gsave", "")) != ""
	return sv

func _open_player(uid: String) -> void:
	if tab != "player":
		show_tab("player")
	note("불러오는 중…")
	var B: Dictionary = await a.fs(HTTPClient.METHOD_GET, "book/" + uid)
	var info: Dictionary = a.dfields(B.j) if B.ok else {}
	var S := {}
	for sv in ["pc", "m", "pcT", "mT"]:
		var r: Dictionary = await a.fs(HTTPClient.METHOD_GET, "servers/" + sv + "/users/" + uid)
		if r.ok:
			S[sv] = _save_of(r.j)
	var ban: Dictionary = await a.fs(HTTPClient.METHOD_GET, "bans/" + uid)
	var tst: Dictionary = await a.fs(HTTPClient.METHOD_GET, "testers/" + uid)
	var ml: Dictionary = await a.fs(HTTPClient.METHOD_GET, "mail/" + uid + "/items")
	cur = {"uid": uid, "nick": str(info.get("nick", "?")), "tag": str(info.get("tag", "")), "email": str(info.get("email", "")),
		"t": int(info.get("t", 0)), "S": S, "ban": a.dfields(ban.j) if ban.ok else {}, "tester": tst.ok, "mail": ml.j.get("documents", []) if ml.ok else []}
	note("")
	_draw_player()

func _draw_player() -> void:
	for c in res_box.get_children():
		c.queue_free()
	var P := cur
	# 프로필
	var c := _card(res_box)
	_lab(c, P.nick + "#" + P.tag, 22, INK, true)
	_lab(c, P.email + "     ·     답장용: " + a._mask(P.email), 13.5, SUB)
	_lab(c, "UID " + P.uid + "     ·     마지막 접속 " + a.when(P.t), 12, Color("#8a929c"))
	var st: Array = []
	var bu := int(P.ban.get("until", 0))
	if bu > a.now_ms():
		st.append("⛔ 정지 중 (" + ("영구" if bu >= a.PERMA else a.when(bu) + " 까지") + " · " + str(P.ban.get("why", "")) + ")")
	if P.tester:
		st.append("🧪 테스터")
	if not P.mail.is_empty():
		st.append("📮 안 받은 우편 " + str(P.mail.size()) + "개")
	if not st.is_empty():
		_lab(c, "   ".join(st), 13.5, RED if bu > a.now_ms() else INK, true)
	# 서버별 진행
	var sc := _card(res_box, "진행 상황")
	if P.S.is_empty():
		_lab(sc, "아직 저장된 진행이 없어요", 13, SUB)
	for sv in P.S:
		var W: Dictionary = P.S[sv]
		var nm: String = {"pc": "PC 서버", "m": "모바일 서버", "pcT": "PC 테스트", "mT": "모바일 테스트"}[sv]
		var bp = W.get("bp", {})
		var xp: int = int(bp.get("xp", 0)) if bp is Dictionary else 0
		var own: int = (W.get("own", []) as Array).size() if W.get("own") is Array else 0
		var bown: int = (W.get("bown", []) as Array).size() if W.get("bown") is Array else 0
		var town: int = (W.get("town", []) as Array).size() if W.get("town") is Array else 0
		_lab(sc, nm + "   ·   청석 " + str(int(W.get("cs", 0))) + "   ·   별석 " + str(int(W.get("ss", 0))) + "   ·   무료 상자 " + str(int(W.get("fbox", 0)))
			+ "   ·   배틀패스 XP " + str(xp) + "   ·   스킨 로봇 " + str(own) + " / 기지 " + str(bown) + " / 테마 " + str(town)
			+ "   ·   튜토리얼 " + ("완료" if W.get("tutDone", false) else "안 함") + ("   ·   진행 중인 판 있음" if W._game else "") + "   ·   저장 " + a.when(W._t), 13, INK)
	# 보상 보내기
	var rc := _card(res_box, "🎁 보상 보내기")
	_lab(rc, "다음에 게임을 켤 때 우편으로 받아요", 12.5, SUB)
	var r1 := _row(rc)
	var cs := _in(r1, "g_cs", "청석", "", 0)
	var ss := _in(r1, "g_ss", "별석", "", 0)
	var fb := _in(r1, "g_fb", "무료 상자", "", 0)
	var sk_ids: Array = [""]
	var sk_names: Array = ["스킨 없음"]
	for it in g.SK:
		sk_ids.append("r:" + it.id)
		sk_names.append("로봇 · " + it.n)
	for it in g.BS:
		sk_ids.append("b:" + it.id)
		sk_names.append("기지 · " + it.n)
	for it in g.TS:
		sk_ids.append("t:" + it.id)
		sk_names.append("테마 · " + it.n)
	var r2 := _row(rc)
	var so := _opt(r2, sk_names)
	so.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gm := _in(rc, "g_msg", "메시지 (예: 버그 보상이에요. 불편을 드려 죄송해요)")
	_b(rc, "보상 보내기", func():
		var d := {"ty": "grant", "cs": cs.text.to_int(), "ss": ss.text.to_int(), "fbox": fb.text.to_int(), "msg": gm.text.strip_edges()}
		var si: String = sk_ids[so.selected]
		if si != "":
			d.skin = si
			d.skn = sk_names[so.selected]
		if d.cs == 0 and d.ss == 0 and d.fbox == 0 and si == "":
			note("보낼 걸 하나 이상 넣어 주세요", true)
			return
		var sm: Array = []
		if d.cs != 0: sm.append("청석 " + str(d.cs))
		if d.ss != 0: sm.append("별석 " + str(d.ss))
		if d.fbox != 0: sm.append("상자 " + str(d.fbox))
		if si != "": sm.append(sk_names[so.selected])
		_send(d, ", ".join(sm)), "g")
	# 직접 수정
	var ec := _card(res_box, "🔧 직접 수정")
	_lab(ec, "모두 다음에 게임을 켤 때 적용돼요 · 위험한 버튼은 두 번 눌러야 해요", 12.5, SUB)
	var r3 := _row(ec)
	var vcs := _in(r3, "s_cs", "청석을 이 값으로", "", 0)
	var vss := _in(r3, "s_ss", "별석을 이 값으로", "", 0)
	_b(r3, "값 맞추기", func():
		var d := {"ty": "set", "cs": vcs.text.to_int() if vcs.text.strip_edges() != "" else -1, "ss": vss.text.to_int() if vss.text.strip_edges() != "" else -1, "msg": ""}
		if d.cs < 0 and d.ss < 0:
			note("바꿀 값을 넣어 주세요", true)
			return
		if _confirm("set", "한 번 더 누르면 값을 맞춰요"):
			_send(d, "재화 조정 (청석 " + str(d.cs) + " · 별석 " + str(d.ss) + ")"), "w")
	var r4 := _row(ec)
	var em := _in(r4, "e_msg", "사유 (플레이어에게 보여요)")
	_b(r4, "닉네임 바꾸게 하기", func():
		if _confirm("rn", "한 번 더 누르면 닉네임 변경을 요청해요"):
			_send({"ty": "renick", "msg": em.text.strip_edges()}, "닉네임 변경 요청"), "w")
	_b(r4, "진행 초기화", func():
		if _confirm("rs", "⚠ 한 번 더 누르면 이 사람의 진행을 모두 지워요 (되돌릴 수 없어요)"):
			_send({"ty": "reset", "msg": em.text.strip_edges()}, "진행 초기화"), "r")
	# 테스터 · 정지
	var tc := _card(res_box, "🧪 테스터 · ⛔ 정지")
	var r5 := _row(tc)
	var tl := _lab(r5, "테스터 서버(pcT · mT) 입장: " + ("가능" if P.tester else "불가"), 13.5, INK, true)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if P.tester:
		_b(r5, "테스터에서 빼기", func(): _tester(false), "w")
	else:
		_b(r5, "테스터로 추가", func(): _tester(true), "k")
	var r6 := _row(tc)
	var why := _in(r6, "b_why", "정지 사유 (플레이어에게 보여요)")
	var per := _opt(r6, ["1일", "3일", "7일", "30일", "영구"])
	_b(r6, "정지하기", func():
		if _confirm("ban", "한 번 더 누르면 정지해요"):
			_ban(why.text.strip_edges(), per.selected), "r")
	if bu > a.now_ms():
		_b(tc, "정지 해제", func(): _unban(), "k")
	# 안 받은 우편
	if not P.mail.is_empty():
		var mc := _card(res_box, "📮 아직 안 받은 우편")
		for doc in P.mail:
			var D: Dictionary = a.dfields(doc)
			var pth: String = a.dpath(doc)
			var rr := _row(mc)
			var ml := _lab(rr, a.when(int(D.get("t", 0))) + "   " + str(D.get("sum", D.get("ty", ""))), 13, INK)
			ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_b(rr, "보내기 취소", func():
				var x: Dictionary = await a.fs(HTTPClient.METHOD_DELETE, pth)
				note("취소했어요" if x.ok else "취소 실패 (" + str(x.st) + ")", not x.ok)
				_open_player(cur.uid), "w")

func _confirm(k: String, msg: String) -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	if confirm_k == k and now - confirm_t < 4.0:
		confirm_k = ""
		return true
	confirm_k = k
	confirm_t = now
	note(msg, true)
	return false

func _send(d: Dictionary, summary: String) -> void:
	var P := cur
	note("보내는 중…")
	var lid := str(a.now_ms()) + "_" + str(randi() % 100000)
	d.t = a.now_ms()
	d.lid = lid
	d.sum = summary
	var lg: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, "maillog/" + lid, a.mk({"uid": P.uid, "nick": P.nick, "tag": P.tag, "ty": d.ty, "sum": summary, "msg": str(d.get("msg", "")), "t": d.t, "got": false}))
	var r: Dictionary = await a.fs(HTTPClient.METHOD_POST, "mail/" + P.uid + "/items", a.mk(d))
	if not r.ok:
		note("보내기 실패 (" + str(r.st) + ") · Firestore 규칙을 확인해 주세요", true)
		if lg.ok:
			a.fs(HTTPClient.METHOD_DELETE, "maillog/" + lid)
		return
	await _open_player(P.uid)
	note(P.nick + "#" + P.tag + " 님에게 보냈어요: " + summary)

func _tester(on: bool) -> void:
	var P := cur
	var r: Dictionary
	if on:
		r = await a.fs(HTTPClient.METHOD_PATCH, "testers/" + P.uid, a.mk({"nick": P.nick, "tag": P.tag, "t": a.now_ms()}))
	else:
		r = await a.fs(HTTPClient.METHOD_DELETE, "testers/" + P.uid)
	await _open_player(P.uid)
	note(("테스터로 추가했어요" if on else "테스터에서 뺐어요") if r.ok else "실패 (" + str(r.st) + ")", not r.ok)

func _ban(why: String, per: int) -> void:
	var P := cur
	var days: Array = [1, 3, 7, 30, 0]
	var until: int = a.PERMA if days[per] == 0 else a.now_ms() + int(days[per]) * 86400000
	var r: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, "bans/" + P.uid, a.mk({"why": why if why != "" else "운영 정책 위반", "until": until, "t": a.now_ms(), "nick": P.nick, "tag": P.tag}))
	await _open_player(P.uid)
	note(("정지했어요 · " + ("영구" if days[per] == 0 else str(days[per]) + "일")) if r.ok else "정지 실패 (" + str(r.st) + ")", not r.ok)

func _unban() -> void:
	var P := cur
	var r: Dictionary = await a.fs(HTTPClient.METHOD_DELETE, "bans/" + P.uid)
	await _open_player(P.uid)
	note("정지를 풀었어요" if r.ok else "해제 실패 (" + str(r.st) + ")", not r.ok)

# ═════════ 공지 ═════════
func _notice_tab() -> void:
	var c := _card(body, "📢 로비 공지")
	_lab(c, "올리면 플레이어가 다음에 게임을 켤 때 한 번 떠요 · 줄을 바꾸려면 // 를 쓰세요", 12.5, SUB)
	var now_l := _lab(c, "불러오는 중…", 13, SUB)
	var ti := _in(c, "n_ti", "제목 (예: 12월 1일 점검 안내)")
	var bo := _in(c, "n_bo", "내용")
	var r := _row(c)
	_b(r, "공지 올리기", func():
		if ti.text.strip_edges() == "":
			note("제목을 넣어 주세요", true)
			return
		var x: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, "notice/main", a.mk({"title": ti.text.strip_edges(), "body": bo.text.replace("//", "\n").strip_edges(), "on": true, "id": str(a.now_ms()), "t": a.now_ms()}))
		note("공지를 올렸어요" if x.ok else "실패 (" + str(x.st) + ") · Firestore 규칙을 확인해 주세요", not x.ok)
		if x.ok:
			show_tab("notice"), "g")
	_b(r, "공지 내리기", func():
		var x: Dictionary = await a.fs(HTTPClient.METHOD_PATCH, "notice/main", a.mk({"on": false}), "updateMask.fieldPaths=on")
		note("공지를 내렸어요" if x.ok else "실패 (" + str(x.st) + ")", not x.ok)
		if x.ok:
			show_tab("notice"), "w")
	var r0: Dictionary = await a.fs(HTTPClient.METHOD_GET, "notice/main")
	if not is_instance_valid(now_l):
		return
	if r0.ok:
		var D: Dictionary = a.dfields(r0.j)
		now_l.text = ("지금 올라가 있어요: " if D.get("on", false) else "내려가 있어요: ") + str(D.get("title", "")) + "  (" + a.when(int(D.get("t", 0))) + ")\n" + str(D.get("body", ""))
		now_l.add_theme_color_override("font_color", GREEN if D.get("on", false) else SUB)
		ti.text = str(D.get("title", ""))
		bo.text = str(D.get("body", "")).replace("\n", "//")
	else:
		now_l.text = "아직 올린 공지가 없어요"

# ═════════ 목록 ═════════
var list_box: VBoxContainer = null
func _list_tab() -> void:
	var r := _row(body)
	_b(r, "최근 접속", func(): _list("recent"), "k")
	_b(r, "테스터", func(): _list("testers"), "w")
	_b(r, "정지 중", func(): _list("bans"), "w")
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", _fs(6))
	body.add_child(list_box)
	_list("recent")

func _list(k: String) -> void:
	for c in list_box.get_children():
		c.queue_free()
	note("불러오는 중…")
	var L: Array
	match k:
		"recent":
			L = await q("book", null, "t", 50)
		"testers":
			L = await q("testers", null, "", 100)
		"bans":
			L = await q("bans", null, "", 100)
	note("")
	if not is_instance_valid(list_box):
		return
	var c := _card(list_box, {"recent": "최근 접속한 플레이어", "testers": "테스터", "bans": "정지된 플레이어"}[k] + " (" + str(L.size()) + ")")
	if L.is_empty():
		_lab(c, "없어요", 13, SUB)
	for D in L:
		var uid: String = D._id
		var t := str(D.get("nick", "(이름 모름)")) + "#" + str(D.get("tag", "")) + "   ·   "
		match k:
			"recent":
				t += str(D.get("email", "")) + "   ·   " + a.when(int(D.get("t", 0)))
			"testers":
				t += "추가 " + a.when(int(D.get("t", 0)))
			"bans":
				var u := int(D.get("until", 0))
				t += ("영구" if u >= a.PERMA else a.when(u) + " 까지") + "   ·   " + str(D.get("why", "")) + ("" if u > a.now_ms() else "   (끝남)")
		var lb := _b(c, t, func():
			show_tab("player")
			_open_player(uid), "w")
		lb.alignment = HORIZONTAL_ALIGNMENT_LEFT

# ═════════ 우편 기록 ═════════
func _log_tab() -> void:
	var c := _card(body, "📮 보낸 우편 (최근 60개)")
	note("불러오는 중…")
	var L := await q("maillog", null, "t", 60)
	note("")
	if not is_instance_valid(c):
		return
	if L.is_empty():
		_lab(c, "아직 보낸 우편이 없어요", 13, SUB)
	for D in L:
		var uid := str(D.get("uid", ""))
		var got: bool = D.get("got", false)
		var t := a.when(int(D.get("t", 0))) + "   " + str(D.get("nick", "")) + "#" + str(D.get("tag", "")) + "   ·   " + str(D.get("sum", "")) + "   ·   " + ("✓ 받음 " + a.when(int(D.get("gt", 0))) if got else "대기 중")
		var lb := _b(c, t, func():
			show_tab("player")
			_open_player(uid), "w")
		lb.alignment = HORIZONTAL_ALIGNMENT_LEFT
