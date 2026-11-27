extends CanvasLayer
# SOROK 계정 · 클라우드 저장 (웹과 같은 Firebase 계정 · 같은 서버 문서)
# 웹 index.html의 FB · cPush · cBoot · cEnter · lnLogin · lnCreate · lnNick · lnVerify를 옮긴 것
const FBK := "AIzaSyASPfEvwyTI9HtXAQzXa3pydetYTBr7fjQ"
const FBDB := "https://firestore.googleapis.com/v1/projects/sorok-77548/databases/(default)/documents"
const DTAG := "SR1"
const SES_P := "user://fb.dat"
var g: Node = null
var ses = null            # {uid, it, rt, exp, email, nick, tag, ut, h, ev, an, at}
var srv := "pc"
var raw := {}             # 서버에서 받은 d (웹 키 그대로 보관)
var raw_sv := {}          # 웹 sorok_v1 원본 (모르는 칸 지키기)
var state := ""           # ok · sync · off · err · conf
var busy := false
var no_push := false
var dirty := false
var push_acc := 0.0
var remember := true
var ui_root: Control = null
var err_l: Label = null
var fields := {}
var mode := ""

# ── 세션 ──
func load_ses() -> void:
	ses = null
	if FileAccess.file_exists(SES_P):
		var f := FileAccess.open(SES_P, FileAccess.READ)
		var d = f.get_var()
		if d is Dictionary and d.has("rt"):
			ses = d

func keep() -> void:
	if ses == null:
		return
	if remember:
		var f := FileAccess.open(SES_P, FileAccess.WRITE)
		if f != null:
			f.store_var(ses)

func clear() -> void:
	ses = null
	if FileAccess.file_exists(SES_P):
		DirAccess.remove_absolute(SES_P)

func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

# ── HTTP ──
func http(method: int, url: String, headers: PackedStringArray, body: String = "") -> Dictionary:
	var rq := HTTPRequest.new()
	rq.timeout = 20.0
	rq.use_threads = true
	add_child(rq)
	var e := rq.request(url, headers, method, body)
	if e != OK:
		rq.queue_free()
		return {"ok": false, "st": 0, "j": {}, "net": true}
	var res: Array = await rq.request_completed
	rq.queue_free()
	var code: int = res[1]
	var txt: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var j = JSON.parse_string(txt) if txt != "" else {}
	if not (j is Dictionary):
		j = {}
	return {"ok": res[0] == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300, "st": code, "j": j, "net": res[0] != HTTPRequest.RESULT_SUCCESS}

func idt(path: String, body: Dictionary) -> Dictionary:
	var r := await http(HTTPClient.METHOD_POST, "https://identitytoolkit.googleapis.com/v1/accounts:" + path + "?key=" + FBK,
		PackedStringArray(["Content-Type: application/json", "X-Firebase-Locale: ko"]), JSON.stringify(body))
	if not r.ok:
		var m := "NETWORK" if r.get("net", false) else str(r.j.get("error", {}).get("message", "HTTP " + str(r.st)))
		return {"err": m}
	return r.j

func set_tok(j: Dictionary) -> void:
	if ses == null:
		ses = {}
	ses.uid = j.get("localId", j.get("user_id", ses.get("uid", "")))
	ses.it = j.get("idToken", j.get("id_token", ""))
	ses.rt = j.get("refreshToken", j.get("refresh_token", ses.get("rt", "")))
	ses.exp = now_ms() + (int(j.get("expiresIn", j.get("expires_in", "3600"))) - 120) * 1000
	if j.has("email"):
		ses.email = j.email

func tok() -> String:
	if ses == null:
		return ""
	if str(ses.get("it", "")) != "" and now_ms() < int(ses.get("exp", 0)):
		return ses.it
	var r := await http(HTTPClient.METHOD_POST, "https://securetoken.googleapis.com/v1/token?key=" + FBK,
		PackedStringArray(["Content-Type: application/x-www-form-urlencoded"]), "grant_type=refresh_token&refresh_token=" + str(ses.rt).uri_encode())
	if not r.ok:
		return ""
	set_tok(r.j)
	keep()
	return ses.it

func fs(method: int, path: String, body = null, qs: String = "") -> Dictionary:
	var t := await tok()
	if t == "":
		return {"ok": false, "st": 401, "j": {}, "tok": true}
	return await http(method, FBDB + "/" + path + ("?" + qs if qs != "" else ""),
		PackedStringArray(["Authorization: Bearer " + t, "Content-Type: application/json"]), JSON.stringify(body) if body != null else "")

func err_txt(m: String) -> String:
	var M := {"EMAIL_EXISTS": "이미 가입된 이메일이에요", "INVALID_EMAIL": "이메일 형식이 올바르지 않아요", "EMAIL_NOT_FOUND": "이메일 또는 비밀번호가 틀렸어요",
		"INVALID_PASSWORD": "이메일 또는 비밀번호가 틀렸어요", "INVALID_LOGIN_CREDENTIALS": "이메일 또는 비밀번호가 틀렸어요", "USER_DISABLED": "정지된 계정이에요",
		"TOO_MANY_ATTEMPTS_TRY_LATER": "시도가 너무 많아요. 잠시 후 다시 해 주세요", "OPERATION_NOT_ALLOWED": "서버에서 이메일 로그인이 꺼져 있어요",
		"MISSING_PASSWORD": "비밀번호를 입력해 주세요", "MISSING_EMAIL": "이메일을 입력해 주세요", "WEAK_PASSWORD": "비밀번호는 6자 이상이어야 해요",
		"TOKEN_EXPIRED": "로그인이 만료됐어요. 다시 로그인해 주세요", "INVALID_REFRESH_TOKEN": "로그인이 만료됐어요. 다시 로그인해 주세요", "NETWORK": "서버에 연결할 수 없어요. 인터넷을 확인해 주세요"}
	for k in M:
		if m.begins_with(k):
			return M[k]
	return "오류: " + m

# ── 웹 데이터 ↔ 고도 데이터 ──
func _ijson(v):
	# JSON 숫자는 소수로 들어와요 → 정수면 정수로
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1e15:
		return int(v)
	if v is Array:
		return v.map(func(x): return _ijson(x))
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _ijson(v[k])
		return o
	return v

func apply_cloud(d: String) -> void:
	var D = JSON.parse_string(d) if d != "" else {}
	raw = D if D is Dictionary else {}
	var w = JSON.parse_string(str(raw.get("sorok_v1", "{}")))
	raw_sv = _ijson(w) if w is Dictionary else {}
	var SV: Dictionary = g.SV
	for k in ["cs", "own", "bown", "town", "frag", "fbox", "ss", "sfrag", "spity", "bp", "hist", "bgm"]:
		if raw_sv.has(k):
			SV[k] = raw_sv[k]
		else:
			SV.erase(k)
	for k in ["eq", "beq", "teq"]:
		SV[k] = raw_sv[k] if raw_sv.get(k) != null else ""
	SV.tut_done = raw_sv.get("tutDone", false) == true
	if raw_sv.has("mute"):
		SV.mute = raw_sv.mute == true
	if raw_sv.get("vol") is Dictionary:
		SV.vol_s = g._num(raw_sv.vol.get("s", 70), 70)
		SV.vol_b = g._num(raw_sv.vol.get("b", 35), 35)
	var ui_ = raw_sv.get("uis")
	if ui_ is float or ui_ is int:
		SV.uis = clampi(roundi(float(ui_) * 100.0), 50, 130)
	g._sv_defaults()
	g._apply_sv()
	g.sv_save(true)
	# 고도 진행 중 게임 (웹 저장은 고도가 못 읽어서 따로 보관)
	var gs: String = str(raw.get("sorok_gsave", ""))
	if gs != "":
		var b := Marshalls.base64_to_raw(gs)
		var n: int = int(raw.get("sorok_gsave_n", 0))
		var u := b.decompress(n, FileAccess.COMPRESSION_GZIP) if n > 0 else PackedByteArray()
		if u.size() > 0:
			var f := FileAccess.open(g.SAVE_P, FileAccess.WRITE)
			if f != null:
				f.store_buffer(u)
	else:
		g.del_save()

func pack() -> String:
	var SV: Dictionary = g.SV
	var w := raw_sv.duplicate(true)
	for k in ["cs", "own", "bown", "town", "frag", "fbox", "ss", "sfrag", "spity", "bp", "hist"]:
		if SV.has(k):
			w[k] = SV[k]
	for k in ["eq", "beq", "teq"]:
		w[k] = SV[k] if str(SV.get(k, "")) != "" else null
	w.tutDone = SV.get("tut_done", false)
	w.mute = SV.get("mute", false)
	w.vol = {"s": SV.get("vol_s", 70), "b": SV.get("vol_b", 35)}
	w.uis = float(SV.get("uis", 100)) / 100.0
	if SV.has("bgm"):
		w.bgm = SV.bgm
	var D := raw.duplicate(true)
	D.sorok_v1 = JSON.stringify(w)
	if FileAccess.file_exists(g.SAVE_P):
		var b := FileAccess.get_file_as_bytes(g.SAVE_P)
		D.sorok_gsave = Marshalls.raw_to_base64(b.compress(FileAccess.COMPRESSION_GZIP))
		D.sorok_gsave_n = b.size()
	else:
		D.erase("sorok_gsave")
		D.erase("sorok_gsave_n")
	return JSON.stringify(D)

func fields_of(d: String) -> Dictionary:
	var F := {"nick": {"stringValue": str(ses.get("nick", ""))}, "d": {"stringValue": d}, "t": {"integerValue": str(now_ms())}, "email": {"stringValue": str(ses.get("email", ""))}}
	if str(ses.get("tag", "")) != "":
		F.tag = {"stringValue": ses.tag}
	return {"fields": F}

func push(force: bool = false) -> void:
	if no_push or state == "boot":
		return
	if ses == null or str(ses.get("nick", "")) == "" or busy:
		return
	var d := pack()
	var h := str(d.hash()) + "." + str(d.length())
	if not force and h == str(ses.get("h", "")):
		dirty = false
		return
	busy = true
	state = "sync"
	var q := ("currentDocument.updateTime=" + str(ses.ut).uri_encode()) if str(ses.get("ut", "")) != "" else "currentDocument.exists=false"
	var r := await fs(HTTPClient.METHOD_PATCH, "servers/" + srv + "/users/" + str(ses.uid), fields_of(d), q)
	if r.ok:
		ses.ut = r.j.get("updateTime", "")
		ses.h = h
		keep()
		state = "ok"
		dirty = false
	elif r.st in [400, 409, 404]:
		state = "conf"
		await conflict()
	elif r.get("net", false):
		state = "off"
	else:
		state = "err"
	busy = false

func conflict() -> void:
	var r := await fs(HTTPClient.METHOD_GET, "servers/" + srv + "/users/" + str(ses.uid))
	if not r.ok or not r.j.has("fields"):
		return
	apply_cloud(str(r.j.fields.get("d", {}).get("stringValue", "")))
	ses.ut = r.j.get("updateTime", "")
	ses.h = ""
	keep()
	state = "ok"
	if g.scene == "game":
		g.scene = "lobby"
		g.lsec = "main"
	g.lmsg = "다른 기기에서 플레이한 더 최신 기록을 불러왔어요"

func tick(dt: float) -> void:
	if ses == null or str(ses.get("nick", "")) == "":
		return
	push_acc += dt
	if push_acc > 30.0:
		push_acc = 0.0
		if dirty:
			push()

func mark() -> void:
	dirty = true

# ── 들어가기 ──
func boot() -> bool:
	load_ses()
	if ses == null:
		return false
	# 전에 들어왔던 계정이면 기다리지 않고 로비부터 보여 주고, 기록은 뒤에서 불러와요
	if str(ses.get("nick", "")) != "" and ses.get("ev", false):
		state = "boot"
		_boot_bg()
		return true
	show_msg("서버에 연결하는 중…")
	var vok = await verified()
	if vok == null:
		state = "off"
		hide_ui()
		g.lmsg = "오프라인이에요 · 연결되면 자동으로 저장돼요"
		return true
	if not vok:
		if ses != null:
			show_verify()
		return true
	await enter()
	return true

func verified():
	if ses.get("ev", false):
		return true
	var t := await tok()
	if t == "":
		return null
	var j := await idt("lookup", {"idToken": t})
	if j.has("err"):
		if str(j.err) == "NETWORK":
			return null
		clear()
		show_login(err_txt(j.err))
		return false
	var u = (j.get("users", []) as Array).front() if (j.get("users", []) as Array).size() > 0 else null
	if u != null and u.get("emailVerified", false):
		ses.ev = true
		ses.exp = 0
		await tok()
		keep()
		return true
	return false

func enter(nick_hint: String = "") -> void:
	var r := await fs(HTTPClient.METHOD_GET, "servers/" + srv + "/users/" + str(ses.uid))
	if r.st == 404:
		show_nick(nick_hint)
		return
	if not r.ok:
		if r.get("net", false) or r.get("tok", false):
			state = "off"
			hide_ui()
			return
		show_login("서버 오류 (" + str(r.st) + ")")
		return
	var f: Dictionary = r.j.fields
	ses.nick = f.get("nick", {}).get("stringValue", "")
	ses.tag = f.get("tag", {}).get("stringValue", DTAG)
	ses.ut = r.j.get("updateTime", "")
	_backup_local()
	apply_cloud(str(f.get("d", {}).get("stringValue", "")))
	ses.h = ""
	keep()
	state = "ok"
	hide_ui()
	g.lmsg = str(ses.nick) + "#" + str(ses.tag) + " 님 환영해요"
	ensure_acct()

func _boot_bg() -> void:
	await enter()
	if state == "boot":
		state = "off"

func ensure_acct() -> void:
	if ses == null or str(ses.get("nick", "")) == "":
		return
	var r := await fs(HTTPClient.METHOD_GET, "accounts/" + str(ses.uid))
	if r.ok and r.j.has("fields") and r.j.fields.has("nick"):
		ses.an = r.j.fields.nick.stringValue
		ses.at = r.j.fields.get("tag", {}).get("stringValue", DTAG)
		if ses.an != ses.nick or ses.at != ses.get("tag", DTAG):
			ses.nick = ses.an
			ses.tag = ses.at
			keep()
			push(true)
	elif r.st == 404:
		await claim_nick(ses.nick, str(ses.get("tag", DTAG)))

func rkey(n: String, t: String) -> String:
	return (n + "#" + t).to_lower()

func name_ok(n: String) -> bool:
	return n.length() >= 3 and n.length() <= 16 and not ("#" in n or "/" in n or "\\" in n or "?" in n or "%" in n)
func tag_ok(t: String) -> bool:
	return t.length() >= 3 and t.length() <= 5 and not (" " in t or "#" in t or "/" in t or "\\" in t or "?" in t or "%" in t)

func claim_nick(n: String, t: String) -> String:
	var nid := rkey(n, t).uri_encode()
	var gq := await fs(HTTPClient.METHOD_GET, "nicks/" + nid)
	if gq.st == 403:
		return "legacy"
	if gq.ok and gq.j.has("fields") and gq.j.fields.uid.stringValue != ses.uid:
		return "taken"
	if not gq.ok:
		var c := await fs(HTTPClient.METHOD_POST, "nicks", {"fields": {"uid": {"stringValue": ses.uid}, "n": {"stringValue": n}, "t": {"stringValue": t}}}, "documentId=" + nid)
		if not c.ok:
			return "taken" if c.st == 409 else "fail:" + str(c.st)
	var a := await fs(HTTPClient.METHOD_PATCH, "accounts/" + str(ses.uid), {"fields": {"nick": {"stringValue": n}, "tag": {"stringValue": t}}})
	if not a.ok:
		return "fail:" + str(a.st)
	ses.an = n
	ses.at = t
	return "ok"

func _backup_local() -> void:
	# 로그인 전 이 기기에서 하던 기록은 한 번만 따로 보관해요
	if FileAccess.file_exists(g.SV_P) and not FileAccess.file_exists("user://sv_local_backup.dat"):
		DirAccess.copy_absolute(g.SV_P, "user://sv_local_backup.dat")
		if FileAccess.file_exists(g.SAVE_P):
			DirAccess.copy_absolute(g.SAVE_P, "user://save_local_backup.dat")

func logout() -> void:
	if g.scene == "game":
		g.save_game()
	await push(true)
	clear()
	raw = {}
	raw_sv = {}
	g.SV = g.SV_BASE.duplicate(true)
	g._sv_defaults()
	g._apply_sv()
	g.sv_save(true)
	g.del_save()
	g.scene = "client"
	g.lsec = "main"
	show_login("")

# ── 화면 (웹 SOROK CLIENT 모양 · 글자 입력이 필요해서 진짜 UI 노드로 만들어요) ──
func _style(c: Color, b: Color, rad: int = 8, bw: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = b
	s.set_border_width_all(bw)
	s.set_corner_radius_all(rad)
	s.set_content_margin_all(12)
	return s

func _fs(k: float) -> int:
	return int(round(k * (1.6 if g.touch_mode else 1.0)))

func _label(v: Container, t: String, fs: float, col: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", _fs(fs))
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", g.fb())
	v.add_child(l)
	return l

func _shell(title: String) -> VBoxContainer:
	hide_ui()
	err_l = null
	fields = {}
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = _fs(15)
	root.theme = th
	add_child(root)
	ui_root = root
	g.ln_on = true
	var side := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color("#f4f5f7")
	ss.content_margin_left = _fs(30)
	ss.content_margin_right = _fs(30)
	ss.content_margin_top = _fs(34)
	ss.content_margin_bottom = _fs(24)
	side.add_theme_stylebox_override("panel", ss)
	side.anchor_bottom = 1.0
	side.offset_right = g.ln_side_px()
	root.add_child(side)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", _fs(12))
	sc.add_child(v)
	_label(v, "◆ SOROK CLIENT", 13, Color("#c9a255"), true)
	if title != "":
		_label(v, title, 24, Color("#1a1d22"), true)
	return v

func _input_box(v: Container, key: String, ph: String, secret: bool = false, val: String = "") -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = ph
	e.secret = secret
	e.text = val
	e.custom_minimum_size = Vector2(0, _fs(46))
	var n := _style(Color("#e8ebef"), Color("#e8ebef"), 6, 2)
	n.content_margin_left = _fs(14)
	var fo := _style(Color.WHITE, Color("#1a1d22"), 6, 2)
	fo.content_margin_left = _fs(14)
	e.add_theme_stylebox_override("normal", n)
	e.add_theme_stylebox_override("focus", fo)
	e.add_theme_color_override("font_color", Color("#1a1d22"))
	e.add_theme_color_override("font_placeholder_color", Color("#8a929c"))
	e.add_theme_color_override("caret_color", Color("#1a1d22"))
	e.add_theme_font_size_override("font_size", _fs(15))
	# 휴대폰 키보드의 추천 단어(자동완성)가 글자를 지웠다 다시 넣으면서 꼬이지 않게, 추천 없는 입력 방식으로
	e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD if secret else LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	e.context_menu_enabled = not g.touch_mode
	if _nat_ok():
		# 안드로이드: 칸을 누르면 안드로이드 기본 입력 창을 띄워요 (게임 칸에 직접 치면 키보드와 어긋나 글자가 꼬여서)
		e.virtual_keyboard_enabled = false
		e.focus_mode = Control.FOCUS_NONE
		e.gui_input.connect(func(ev):
			var up: bool = (ev is InputEventScreenTouch and not ev.pressed) or (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed)
			if up and e.focus_mode == Control.FOCUS_NONE:
				_nat_open(e, ph, secret, key == "em"))
	elif g.touch_mode:
		# 휴대폰 키보드는 커서가 항상 맨 끝이라고 알고 있어요 → 칸 중간을 눌러도 커서를 맨 끝으로 (글자가 엉뚱한 곳에 들어가지 않게)
		e.selecting_enabled = false
		e.middle_mouse_paste_enabled = false
		var to_end := func(): e.caret_column = e.text.length()
		e.focus_entered.connect(func(): to_end.call_deferred())
		e.gui_input.connect(func(ev):
			if ev is InputEventScreenTouch or ev is InputEventScreenDrag or ev is InputEventMouseButton or ev is InputEventMouseMotion:
				to_end.call_deferred())
	v.add_child(e)
	fields[key] = e
	e.text_submitted.connect(func(_t): _enter_key())
	return e

# ── 안드로이드 기본 입력 창 ──
var nat_open := false
var nat_seen := false
var nat_t := 0.0
var nat_dlg = null
var nat_et = null
var nat_le: LineEdit = null
var nat_bad := false

func _nat_ok() -> bool:
	return not nat_bad and OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime")

func _nat_open(e: LineEdit, hint: String, secret: bool, email: bool) -> void:
	if nat_open:
		return
	var rt = Engine.get_singleton("AndroidRuntime")
	var act = rt.getActivity() if rt != null else null
	if act == null:
		_nat_fail(e)
		return
	nat_open = true
	nat_seen = false
	nat_t = 0.0
	nat_dlg = null
	nat_et = null
	nat_le = e
	var txt := e.text
	var it := 129 if secret else (33 if email else 1)
	act.runOnUiThread(rt.createRunnableFromGodotCallable(func():
		var ET = JavaClassWrapper.wrap("android.widget.EditText")
		var et = ET.call("EditText", act)
		if et == null:
			return
		et.setInputType(it)
		et.setSingleLine(true)
		et.setText(txt)
		et.setSelection(txt.length())
		et.setHint(hint)
		var B = JavaClassWrapper.wrap("android.app.AlertDialog$Builder")
		var b = B.call("Builder", act)
		if b == null:
			b = B.call("AlertDialog$Builder", act)
		if b == null:
			return
		b.setTitle(hint)
		b.setView(et)
		b.setPositiveButton("확인", null)
		b.setCancelable(true)
		var d = b.create()
		if d == null:
			return
		d.setCanceledOnTouchOutside(true)
		d.show()
		var w = d.getWindow()
		if w != null:
			w.setSoftInputMode(5)
		et.requestFocus()
		nat_et = et
		nat_dlg = d))

func _nat_fail(e: LineEdit) -> void:
	# 기본 입력 창을 못 띄우면 예전처럼 게임 칸에 직접 입력
	nat_bad = true
	nat_open = false
	if is_instance_valid(e):
		e.focus_mode = Control.FOCUS_ALL
		e.virtual_keyboard_enabled = true
		e.grab_focus()

func _process(dt: float) -> void:
	if not nat_open:
		return
	nat_t += dt
	if nat_dlg == null:
		if nat_t > 3.0:
			_nat_fail(nat_le)
		return
	var showing: bool = nat_dlg.isShowing()
	if showing:
		nat_seen = true
		return
	if not nat_seen and nat_t < 3.0:
		return
	nat_open = false
	var s := ""
	if nat_et != null:
		var tx = nat_et.getText()
		if tx != null:
			s = str(tx.toString())
	if is_instance_valid(nat_le):
		nat_le.text = s
	nat_dlg = null
	nat_et = null

# 흰 메뉴 버튼 (.lnmenu)
func _btn(v: Container, txt: String, cb: Callable, gold: bool = false) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, _fs(42))
	b.add_theme_stylebox_override("normal", _style(Color.WHITE, Color("#dde1e6")))
	b.add_theme_stylebox_override("hover", _style(Color("#f7f8fa"), Color("#1a1d22")))
	b.add_theme_stylebox_override("pressed", _style(Color("#eceef1"), Color("#1a1d22")))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color("#1a1d22"))
	b.add_theme_font_size_override("font_size", _fs(13.5))
	if gold:
		b.add_theme_font_override("font", g.fb())
	b.pressed.connect(cb)
	v.add_child(b)
	return b

# 빨간 ➜ 버튼 (.lngo)
func _go(v: Container, cb: Callable) -> void:
	var b := Button.new()
	b.text = "➜"
	var w := _fs(66)
	b.custom_minimum_size = Vector2(w, w)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var n := _style(Color("#d6303f"), Color("#d6303f"), _fs(20), 0)
	n.shadow_color = Color(0.84, 0.19, 0.25, 0.35)
	n.shadow_size = _fs(10)
	n.shadow_offset = Vector2(0, _fs(6))
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate()
	h.bg_color = Color("#e23a49")
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_font_size_override("font_size", _fs(28))
	b.add_theme_font_override("font", g.fb())
	b.pressed.connect(cb)
	v.add_child(b)

func _link(v: Container, txt: String, cb: Callable) -> void:
	var b := LinkButton.new()
	b.text = txt
	b.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color("#5a6470") if k == "font_color" else Color("#1a1d22"))
	b.add_theme_font_size_override("font_size", _fs(12.5))
	b.pressed.connect(cb)
	v.add_child(b)

func _err(v: Container, t: String) -> void:
	err_l = Label.new()
	err_l.text = t
	err_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	err_l.add_theme_color_override("font_color", Color("#d23c2c"))
	err_l.add_theme_font_size_override("font_size", _fs(13))
	err_l.visible = t != ""
	v.add_child(err_l)

func say(t: String) -> void:
	if err_l != null:
		err_l.text = t
		err_l.visible = t != ""

func _enter_key() -> void:
	match mode:
		"login": _do_login()
		"create": _do_create()
		"nick": _do_nick()

# 밑줄 탭 (.lntabs)
func _tabs(v: Container, cur: String) -> void:
	var wrap := PanelContainer.new()
	var ws := StyleBoxFlat.new()
	ws.bg_color = Color(0, 0, 0, 0)
	ws.border_color = Color("#dde1e6")
	ws.border_width_bottom = 2
	wrap.add_theme_stylebox_override("panel", ws)
	v.add_child(wrap)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(6))
	wrap.add_child(h)
	for q in [["login", "로그인"], ["create", "회원가입"], ["info", "!"]]:
		var b := Button.new()
		b.text = q[1]
		b.custom_minimum_size = Vector2(_fs(40), _fs(42))
		if q[0] != "info":
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.border_color = Color("#d6303f") if q[0] == cur else Color(0, 0, 0, 0)
		st.border_width_bottom = 3
		for k in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(k, st)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var col := Color("#1a1d22") if q[0] == cur else Color("#8a929c")
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, col if k == "font_color" else Color("#1a1d22"))
		b.add_theme_font_size_override("font_size", _fs(15))
		b.add_theme_font_override("font", g.fb())
		var id: String = q[0]
		b.pressed.connect(func():
			if id == "login":
				show_login("")
			elif id == "create":
				show_create()
			else:
				show_info())
		h.add_child(b)

func _srv_label(v: Container) -> void:
	_label(v, ("모바일" if srv == "m" else "PC") + " 서버 · 웹 SOROK과 같은 계정", 12, Color("#3a7bd5"), true)

func _remember(v: Container) -> void:
	var c := CheckBox.new()
	c.text = "로그인 상태 유지"
	c.button_pressed = remember
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		c.add_theme_color_override(k, Color("#3a424c"))
	c.add_theme_font_size_override("font_size", _fs(13.5))
	c.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var sz := _fs(18)
	c.add_theme_icon_override("checked", _chk_icon(sz, true))
	c.add_theme_icon_override("unchecked", _chk_icon(sz, false))
	c.add_theme_icon_override("checked_disabled", _chk_icon(sz, true))
	c.add_theme_icon_override("unchecked_disabled", _chk_icon(sz, false))
	c.add_theme_constant_override("h_separation", _fs(8))
	for k in ["normal", "hover", "pressed", "hover_pressed"]:
		c.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	c.toggled.connect(func(on): remember = on)
	v.add_child(c)

# 웹 체크박스처럼 네모 칸 + 체크 표시 (휴대폰에서도 크게)
func _chk_icon(sz: int, on: bool) -> ImageTexture:
	var im := Image.create_empty(sz, sz, false, Image.FORMAT_RGBA8)
	var bg := Color("#1a1d22") if on else Color.WHITE
	var bd := Color("#1a1d22") if on else Color("#9aa3ad")
	var rr := sz * 0.2
	var bw := maxf(1.5, sz * 0.09)
	for y in sz:
		for x in sz:
			var px := Vector2(x + 0.5, y + 0.5)
			var q := (px - Vector2(sz, sz) / 2.0).abs() - Vector2(sz, sz) / 2.0 + Vector2(rr, rr)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rr
			var a := clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var c := bd if d > -bw else bg
			im.set_pixel(x, y, Color(c, a))
	if on:
		var A := Vector2(sz * 0.24, sz * 0.52)
		var B := Vector2(sz * 0.43, sz * 0.71)
		var C := Vector2(sz * 0.77, sz * 0.31)
		var lw := sz * 0.1
		for y in sz:
			for x in sz:
				var px := Vector2(x + 0.5, y + 0.5)
				var d := minf(_seg_d(px, A, B), _seg_d(px, B, C)) - lw
				var a := clampf(0.5 - d, 0.0, 1.0)
				if a > 0.0:
					im.set_pixel(x, y, im.get_pixel(x, y).lerp(Color.WHITE, a))
	return ImageTexture.create_from_image(im)

func _seg_d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	return p.distance_to(a + (b - a) * t)

# 흰 정보 카드 목록 (.lninfo)
func _info(v: Container, items: Array) -> void:
	for it in items:
		var p := PanelContainer.new()
		var s := _style(Color.WHITE, Color("#e3e6ea"))
		s.content_margin_top = _fs(10)
		s.content_margin_bottom = _fs(10)
		p.add_theme_stylebox_override("panel", s)
		var b := VBoxContainer.new()
		b.add_theme_constant_override("separation", 2)
		p.add_child(b)
		_label(b, it[0], 13.5, Color("#1a1d22"), true)
		_label(b, it[1], 13, Color("#3a424c"))
		v.add_child(p)

func _nick_row(v: Container, n: String, t: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _fs(6))
	v.add_child(h)
	var a := _input_box(h, "n", "이름 (3~16자)", false, n)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hs := _label(h, "#", 18, Color("#6a7480"), true)
	hs.autowrap_mode = TextServer.AUTOWRAP_OFF
	hs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var b := _input_box(h, "t", DTAG, false, t)
	b.custom_minimum_size = Vector2(_fs(84), _fs(46))

func show_msg(t: String) -> void:
	hide_ui()
	mode = "msg"
	g.conn_msg = t
	g.conn_t = g.t_real

func show_login(e: String) -> void:
	mode = "login"
	g.scene = "client"
	var v := _shell("")
	_tabs(v, "login")
	_input_box(v, "em", "이메일")
	_input_box(v, "pw", "비밀번호", true)
	_remember(v)
	_err(v, e)
	_go(v, _do_login)
	_link(v, "비밀번호 재설정 메일 받기", _do_reset)

func show_create() -> void:
	mode = "create"
	g.scene = "client"
	var v := _shell("")
	_tabs(v, "create")
	_input_box(v, "em", "이메일")
	_input_box(v, "pw", "비밀번호 (6~32자)", true)
	_input_box(v, "pw2", "비밀번호 확인", true)
	_nick_row(v, "", "")
	_remember(v)
	_err(v, "")
	_go(v, _do_create)

func show_info() -> void:
	mode = "info"
	var v := _shell("")
	_tabs(v, "info")
	_label(v, "정보", 22, Color("#1a1d22"), true)
	_info(v, [["계정", "이메일 + 비밀번호. 하나의 계정으로 PC·모바일 모두 로그인"],
		["서버", "PC 서버와 모바일 서버는 청석·스킨·저장·닉네임이 완전히 따로. 지금 접속: " + ("모바일" if srv == "m" else "PC") + " 서버"],
		["저장", "진행 데이터는 서버에 자동 저장 (약 30초마다 + 게임 저장 시). 다른 기기에서도 이어 하기 가능"],
		["비밀번호 분실", "로그인 탭의 [비밀번호 재설정 메일 받기]"],
		["닉네임", "이름#태그 (예: YASR#SR1). 모든 서버 공통 · 이름 3~16자, 태그 3~5자"],
		["이메일 인증", "가입 후 받은 메일의 링크로 인증해야 플레이 가능"],
		["버전", g.app_ver if g.app_ver != "" else "개발판"]])

func show_verify() -> void:
	mode = "verify"
	g.scene = "client"
	var v := _shell("이메일 인증이 필요해요")
	_info(v, [["인증 메일 보낸 곳", str(ses.get("email", ""))], ["방법", "메일함(스팸함 포함)의 인증 링크 누르기 → 아래 [인증했어요, 다시 확인]"], ["이유", "인증한 계정만 플레이 가능"]])
	_err(v, "")
	_btn(v, "인증했어요, 다시 확인", _do_vchk, true)
	_btn(v, "인증 메일 다시 보내기", _do_vsend)
	_btn(v, "로그아웃", func(): clear(); show_login(""))

func show_nick(hint: String) -> void:
	mode = "nick"
	g.scene = "client"
	var v := _shell("불러오는 중…")
	var r := await fs(HTTPClient.METHOD_GET, "accounts/" + str(ses.uid))
	var has: bool = r.ok and r.j.has("fields") and r.j.fields.has("nick")
	v = _shell("새 서버 첫 입장" if has else "닉네임 정하기")
	if has:
		ses.an = r.j.fields.nick.stringValue
		ses.at = r.j.fields.get("tag", {}).get("stringValue", DTAG)
		_info(v, [["닉네임 (모든 서버 공통)", str(ses.an) + "#" + str(ses.at)]])
	else:
		var hp := hint.split("#")
		_nick_row(v, hp[0] if hp.size() > 0 else "", hp[1] if hp.size() > 1 else "")
	_err(v, "")
	_go(v, _do_nick)
	_link(v, "로그아웃", func(): clear(); show_login(""))

func hide_ui() -> void:
	g.conn_msg = ""
	g.ln_on = false
	if ui_root != null:
		ui_root.queue_free()
		ui_root = null
	err_l = null
	mode = ""

func is_open() -> bool:
	return ui_root != null

func _v(k: String) -> String:
	return (fields[k] as LineEdit).text.strip_edges() if fields.has(k) else ""

func _has_han(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if (c >= 0xAC00 and c <= 0xD7A3) or (c >= 0x3131 and c <= 0x318E):
			return true
	return false

func _do_login() -> void:
	var em := _v("em")
	var pw: String = (fields.pw as LineEdit).text
	if em == "":
		say("이메일을 입력해 주세요")
		return
	if pw == "":
		say("비밀번호를 입력해 주세요")
		return
	if _has_han(pw):
		(fields.pw as LineEdit).text = ""
		say("비밀번호에 한글이 들어갔어요. 키보드를 영어로 바꿔서 다시 입력해 주세요")
		return
	say("로그인 중…")
	var j := await idt("signInWithPassword", {"email": em, "password": pw, "returnSecureToken": true})
	if j.has("err"):
		say(err_txt(j.err))
		return
	ses = {}
	set_tok(j)
	keep()
	var vok = await verified()
	if vok == null:
		say("서버에 연결할 수 없어요")
		return
	if not vok:
		show_verify()
		return
	await enter()

func _do_create() -> void:
	var em := _v("em")
	var pw: String = (fields.pw as LineEdit).text
	var pw2: String = (fields.pw2 as LineEdit).text
	var n := _v("n")
	var tg := _v("t") if _v("t") != "" else DTAG
	if em == "":
		say("이메일을 입력해 주세요")
		return
	if _has_han(pw):
		say("비밀번호에는 한글을 쓸 수 없어요. 키보드를 영어로 바꿔 주세요")
		return
	if pw.length() < 6 or pw.length() > 32:
		say("비밀번호는 6~32자로 해 주세요")
		return
	if pw != pw2:
		say("비밀번호 확인이 달라요")
		return
	if not name_ok(n):
		say("이름은 3~16자예요 (#, /, ?, % 는 쓸 수 없어요)")
		return
	if not tag_ok(tg):
		say("태그는 3~5자예요 (띄어쓰기 없이)")
		return
	say("가입 중…")
	var j := await idt("signUp", {"email": em, "password": pw, "returnSecureToken": true})
	if j.has("err"):
		say(err_txt(j.err))
		return
	ses = {}
	set_tok(j)
	ses.pn = n + "#" + tg
	keep()
	await idt("sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": ses.it})
	show_verify()

func _do_reset() -> void:
	var em := _v("em")
	if em == "":
		say("위 칸에 이메일을 먼저 입력해 주세요")
		return
	var j := await idt("sendOobCode", {"requestType": "PASSWORD_RESET", "email": em})
	say(err_txt(j.err) if j.has("err") else "재설정 메일을 보냈어요. 메일함(스팸함 포함)을 확인해 주세요")

func _do_vchk() -> void:
	say("확인 중…")
	var vok = await verified()
	if vok:
		say("인증 확인! 입장 중…")
		await enter(str(ses.get("pn", "")))
	elif vok == null:
		say("서버에 연결할 수 없어요")
	else:
		say("아직 인증이 안 됐어요. 메일의 링크를 누른 뒤 다시 눌러 주세요")

func _do_vsend() -> void:
	var j := await idt("sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": await tok()})
	say(err_txt(j.err) if j.has("err") else "인증 메일을 다시 보냈어요. 스팸함도 확인해 주세요")

func _do_nick() -> void:
	var n: String
	var tg: String
	if ses.has("an") and str(ses.get("an", "")) != "":
		n = ses.an
		tg = str(ses.get("at", DTAG))
	else:
		n = _v("n")
		tg = _v("t") if _v("t") != "" else DTAG
		if not name_ok(n):
			say("이름은 3~16자예요 (#, /, ?, % 는 쓸 수 없어요)")
			return
		if not tag_ok(tg):
			say("태그는 3~5자예요 (띄어쓰기 없이)")
			return
		say("확인 중…")
		var cr := await claim_nick(n, tg)
		if cr == "taken":
			say("이미 있는 이름#태그예요. 태그를 바꿔 보세요")
			return
		if cr.begins_with("fail"):
			say("닉네임 등록 실패 (" + cr.substr(5) + ")")
			return
	ses.nick = n
	ses.tag = tg
	raw = {}
	raw_sv = {}
	var w := await fs(HTTPClient.METHOD_PATCH, "servers/" + srv + "/users/" + str(ses.uid), fields_of("{}"), "currentDocument.exists=false")
	if not w.ok:
		say("계정 만들기 실패 (" + str(w.st) + ")")
		return
	ses.ut = w.j.get("updateTime", "")
	ses.h = ""
	keep()
	state = "ok"
	# 웹과 같이 서버 계정은 처음부터 시작 (이 기기 기록은 따로 백업)
	_backup_local()
	apply_cloud("{}")
	ses.h = ""
	hide_ui()
	g.lmsg = n + "#" + tg + " 님 환영해요"

func _offline() -> void:
	clear()
	hide_ui()
	g.lmsg = "로그인 없이 하는 중 · 기록은 이 기기에만 저장돼요"

# ── 계정 관리 창 ──
func show_panel() -> void:
	mode = "panel"
	var v := _shell("계정 관리")
	var l := Label.new()
	if ses == null:
		l.text = "로그인하지 않았어요 · 기록은 이 기기에만 저장돼요"
		v.add_child(l)
		_btn(v, "로그인 / 회원가입", func(): show_login(""), true)
		_btn(v, "닫기", hide_ui)
		return
	l.text = str(ses.get("nick", "?")) + "#" + str(ses.get("tag", DTAG)) + "\n" + str(ses.get("email", "")) + ("  ✓ 인증됨" if ses.get("ev", false) else "") + "\n서버: " + ("모바일" if srv == "m" else "PC") + " 서버 · 저장: " + {"ok": "저장됨", "sync": "저장 중…", "off": "오프라인", "err": "저장 실패", "conf": "확인 중"}.get(state, "연결됨")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	_err(v, "")
	_btn(v, "지금 저장", _p_save, true)
	_btn(v, "비밀번호 재설정 메일 받기", _p_reset)
	_btn(v, "로그아웃", logout)
	_btn(v, "닫기", hide_ui)

func _p_save() -> void:
	say("저장 중…")
	await push(true)
	say("저장했어요" if state == "ok" else "저장 실패 · 나중에 다시 해요")

func _p_reset() -> void:
	var j := await idt("sendOobCode", {"requestType": "PASSWORD_RESET", "email": str(ses.get("email", ""))})
	say(err_txt(j.err) if j.has("err") else "재설정 메일을 보냈어요")
