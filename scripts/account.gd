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
	SV.tut_done = bool(raw_sv.get("tutDone", false))
	if raw_sv.has("mute"):
		SV.mute = bool(raw_sv.mute)
	if raw_sv.get("vol") is Dictionary:
		SV.vol_s = int(raw_sv.vol.get("s", 70))
		SV.vol_b = int(raw_sv.vol.get("b", 35))
	if raw_sv.has("uis"):
		SV.uis = clampi(roundi(float(raw_sv.uis) * 100.0), 50, 130)
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
	show_msg("서버에 연결하는 중…")
	var vok = await verified()
	if vok == null:
		state = "off"
		hide_ui()
		g.lmsg = "오프라인이에요 · 연결되면 자동으로 저장돼요"
		return true
	if not vok:
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
	g.scene = "lobby"
	g.lsec = "main"
	show_login("")

# ── 화면 (글자 입력이 필요해서 진짜 UI 노드로 만들어요) ──
func _style(c: Color, b: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = b
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(10)
	return s

func _shell(title: String) -> VBoxContainer:
	hide_ui()
	err_l = null
	fields = {}
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font_size = 26 if g.touch_mode else 16
	root.theme = th
	add_child(root)
	ui_root = root
	var bg := ColorRect.new()
	bg.color = Color("#0b1015")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _style(Color("#10161c"), Color("#c9a255")))
	pan.custom_minimum_size = Vector2(640 if g.touch_mode else 420, 0)
	cc.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	var logo := Label.new()
	logo.text = "S O R O K"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 60 if g.touch_mode else 42)
	logo.add_theme_color_override("font_color", Color("#f2c86a"))
	v.add_child(logo)
	var sub := Label.new()
	sub.text = title
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#9fb3c2"))
	v.add_child(sub)
	return v

func _input_box(v: VBoxContainer, key: String, ph: String, secret: bool = false, val: String = "") -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = ph
	e.secret = secret
	e.text = val
	e.custom_minimum_size = Vector2(0, 58 if g.touch_mode else 40)
	e.add_theme_stylebox_override("normal", _style(Color("#0b1015"), Color("#33414d")))
	e.add_theme_stylebox_override("focus", _style(Color("#0b1015"), Color("#ffd76a")))
	v.add_child(e)
	fields[key] = e
	e.text_submitted.connect(func(_t): _enter_key())
	return e

func _btn(v: Container, txt: String, cb: Callable, gold: bool = false) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 60 if g.touch_mode else 42)
	b.add_theme_stylebox_override("normal", _style(Color("#d9b04e") if gold else Color("#1c2834"), Color("#ffd76a") if gold else Color("#c9a255")))
	b.add_theme_stylebox_override("hover", _style(Color("#e8c060") if gold else Color("#243444"), Color("#ffd76a")))
	b.add_theme_stylebox_override("pressed", _style(Color("#b8902e") if gold else Color("#141c24"), Color("#ffd76a")))
	if gold:
		b.add_theme_color_override("font_color", Color("#2a1a02"))
		b.add_theme_color_override("font_hover_color", Color("#2a1a02"))
	b.pressed.connect(cb)
	v.add_child(b)
	return b

func _err(v: VBoxContainer, t: String) -> void:
	err_l = Label.new()
	err_l.text = t
	err_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	err_l.add_theme_color_override("font_color", Color("#ffb0a0"))
	v.add_child(err_l)

func say(t: String) -> void:
	if err_l != null:
		err_l.text = t

func _enter_key() -> void:
	match mode:
		"login": _do_login()
		"create": _do_create()
		"nick": _do_nick()

func _tabs(v: VBoxContainer, cur: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	v.add_child(h)
	for q in [["login", "로그인"], ["create", "회원가입"]]:
		var b := _btn(h, q[1], (func(): show_login("")) if q[0] == "login" else (func(): show_create()), q[0] == cur)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _srv_label(v: VBoxContainer) -> void:
	var l := Label.new()
	l.text = ("모바일" if srv == "m" else "PC") + " 서버 · 웹 SOROK과 같은 계정이에요"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18 if g.touch_mode else 12)
	l.add_theme_color_override("font_color", Color("#7d8b96"))
	v.add_child(l)

func _remember(v: VBoxContainer) -> void:
	var c := CheckBox.new()
	c.text = "로그인 상태 유지"
	c.button_pressed = remember
	c.toggled.connect(func(on): remember = on)
	v.add_child(c)

func show_msg(t: String) -> void:
	var v := _shell(t)
	mode = "msg"

func show_login(e: String) -> void:
	mode = "login"
	var v := _shell("외계 기지 정복 전략")
	_tabs(v, "login")
	_srv_label(v)
	_input_box(v, "em", "이메일")
	_input_box(v, "pw", "비밀번호", true)
	_remember(v)
	_err(v, e)
	_btn(v, "로그인  ➜", _do_login, true)
	_btn(v, "비밀번호 재설정 메일 받기", _do_reset)
	_btn(v, "로그인 없이 하기 (이 기기에만 저장)", _offline)

func show_create() -> void:
	mode = "create"
	var v := _shell("새 계정 만들기")
	_tabs(v, "create")
	_srv_label(v)
	_input_box(v, "em", "이메일")
	_input_box(v, "pw", "비밀번호 (6~32자)", true)
	_input_box(v, "pw2", "비밀번호 확인", true)
	var h := HBoxContainer.new()
	v.add_child(h)
	var n := _input_box(v, "n", "이름 (3~16자)")
	n.reparent(h)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tg := _input_box(v, "t", "태그 (" + DTAG + ")")
	tg.reparent(h)
	tg.custom_minimum_size = Vector2(110, 40)
	_remember(v)
	_err(v, "")
	_btn(v, "가입하기  ➜", _do_create, true)

func show_verify() -> void:
	mode = "verify"
	var v := _shell("이메일 인증이 필요해요")
	var l := Label.new()
	l.text = "인증 메일 보낸 곳: " + str(ses.get("email", "")) + "\n메일함(스팸함 포함)의 인증 링크를 누른 뒤 아래 버튼을 눌러 주세요.\n인증한 계정만 플레이할 수 있어요."
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	_err(v, "")
	_btn(v, "인증했어요, 다시 확인", _do_vchk, true)
	_btn(v, "인증 메일 다시 보내기", _do_vsend)
	_btn(v, "로그아웃", func(): clear(); show_login(""))

func show_nick(hint: String) -> void:
	mode = "nick"
	var v := _shell("닉네임 정하기 · " + ("모바일" if srv == "m" else "PC") + " 서버 첫 입장")
	var r := await fs(HTTPClient.METHOD_GET, "accounts/" + str(ses.uid))
	if r.ok and r.j.has("fields") and r.j.fields.has("nick"):
		ses.an = r.j.fields.nick.stringValue
		ses.at = r.j.fields.get("tag", {}).get("stringValue", DTAG)
		var l := Label.new()
		l.text = "닉네임 (모든 서버 공통): " + ses.an + "#" + ses.at
		v.add_child(l)
	else:
		var hp := hint.split("#")
		var h := HBoxContainer.new()
		v.add_child(h)
		var n := _input_box(v, "n", "이름 (3~16자)", false, hp[0] if hp.size() > 0 else "")
		n.reparent(h)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tg := _input_box(v, "t", "태그 (" + DTAG + ")", false, hp[1] if hp.size() > 1 else "")
		tg.reparent(h)
		tg.custom_minimum_size = Vector2(110, 40)
	_err(v, "")
	_btn(v, "입장  ➜", _do_nick, true)
	_btn(v, "로그아웃", func(): clear(); show_login(""))

func hide_ui() -> void:
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
