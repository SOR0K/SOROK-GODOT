extends Node2D
# 월드 그리기: 땅 → 기지 → 광산 → 로봇 → 효과 → 암흑 (화면에 보이는 칸만)

var g

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var G := Def.G
	var vr: Rect2 = g.view_rect().grow(G)
	var i0 := maxi(0, int(vr.position.x / G))
	var j0 := maxi(0, int(vr.position.y / G))
	var i1 := mini(Def.GN - 1, int(vr.end.x / G))
	var j1 := mini(Def.GN - 1, int(vr.end.y / G))
	_ground(i0, j0, i1, j1)
	var B: Vector2 = g.B
	draw_arc(B, Def.BASE_VIEW, 0.0, TAU, 128, Color(0.37, 0.88, 0.77, 0.2), 2.0)
	Art.base(self, B, g.t)
	for m in g.mines:
		if vr.has_point(m.p) and g.seen(m.p):
			Art.mine(self, m, g.t)
	for u in g.bots:
		if vr.has_point(u.p):
			_unit(u)
	for u in g.bots:
		if u.sel and not u.path.is_empty():
			draw_circle(u.path.back(), 2.5, Color(0.47, 1.0, 0.67, 0.35))
	if g.box_active:
		var r: Rect2 = g.box_rect()
		draw_rect(r, Color(0.55, 0.89, 0.55, 0.12))
		draw_rect(r, Color("#8be28b"), false, 1.0 / g.zm)
	_fx()
	_fog(i0, j0, i1, j1)

func _ground(i0: int, j0: int, i1: int, j1: int) -> void:
	var G := Def.G
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var h: int = ((i * 73856093) ^ (j * 19349663)) & 0xFFFFFFFF
			draw_rect(Rect2(i * G, j * G, G + 1, G + 1), Def.TN[h % 4])
			var a := i * G + (h >> 2) % 30 + 4
			var b := j * G + (h >> 6) % 30 + 4
			if h % 11 == 0:
				Art.ell_fill(self, Vector2(a + 2, b + 3), 9, 5, Color(0, 0, 0, 0.18))
				Art.ell_fill(self, Vector2(a, b), 8, 5, Color("#625846"))
				draw_rect(Rect2(a - 4, b - 3, 5, 2), Color("#7a6f5a"))
			elif h % 13 == 1:
				draw_polyline(PackedVector2Array([Vector2(a, b), Vector2(a + 10, b + 4), Vector2(a + 16, b + 1)]), Color(0, 0, 0, 0.22), 1.0)
			elif h % 7 == 2:
				draw_rect(Rect2(a, b, 2, 5), Color(0.47, 0.55, 0.31, 0.35))
				draw_rect(Rect2(a + 4, b + 1, 2, 4), Color(0.47, 0.55, 0.31, 0.35))

func _unit(u: Dictionary) -> void:
	var d: Dictionary = Def.T[u.t]
	var z: float = d.z
	var p: Vector2 = u.p
	Art.ell_fill(self, p + Vector2(0, z + 2), z + 3, 4, Color(0, 0, 0, 0.3))
	if u.sel:
		Art.ell_line(self, p + Vector2(0, z + 1), z + 6, z / 2.0 + 4.0, Color("#d9ffd0"), 1.5)
	draw_set_transform(p, u.fa, Vector2(1.35, 1.35))
	Art.bot(self, u.t, d.col, d.acc, g.t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _fx() -> void:
	for f in g.fx:
		var k: float = f.t / 0.75
		var al := maxf(0.0, 1.0 - k)
		var X: Vector2 = f.p
		var ins := minf(1.0, k * 2.6)
		var r1 := 46.0 - 32.0 * ins
		for i in 4:
			var a := PI / 4.0 + i * PI / 2.0
			draw_set_transform(X + Vector2(cos(a), sin(a)) * r1, a + PI, Vector2.ONE)
			Art.poly(self, [Vector2(11, 0), Vector2(-6, -9), Vector2(-2, 0), Vector2(-6, 9)], Color(0.43, 1.0, 0.63, al))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Art.ell_line(self, X, 8 + 34 * k, (8 + 34 * k) * 0.55, Color(0.43, 1.0, 0.63, al * 0.9), 2.2)
		Art.ell_line(self, X, 6 + 14 * k, (6 + 14 * k) * 0.55, Color(0.43, 1.0, 0.63, al * 0.9), 2.2)
		if k < 0.35:
			draw_circle(X, 5, Color(1, 1, 1, (1.0 - k / 0.35) * 0.85))

func _fog(i0: int, j0: int, i1: int, j1: int) -> void:
	var G := Def.G
	var edge := Color(Def.FOG, 0.4)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			if not g.exa(i, j):
				draw_rect(Rect2(i * G, j * G, G + 1, G + 1), Def.FOG)
			elif not (g.exa(i - 1, j) and g.exa(i + 1, j) and g.exa(i, j - 1) and g.exa(i, j + 1)):
				draw_rect(Rect2(i * G, j * G, G + 1, G + 1), edge)
