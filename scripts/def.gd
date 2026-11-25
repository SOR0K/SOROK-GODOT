class_name Def
extends RefCounted
# 게임 전체에서 쓰는 고정값 (웹 SOROK과 같은 숫자)

const W := 5000          # 맵 크기 (px)
const G := 40            # 칸 크기
const GN := 125          # 한 줄 칸 수 (W / G)
const ZMIN := 0.6        # 최소 확대
const ZMAX := 1.8        # 최대 확대
const SCOUT_VIEW := 220.0
const BASE_VIEW := 280.0

const T := {
	"s": {"n": "정찰", "c": 15, "hp": 20, "sp": 150.0, "col": Color("#f2d14e"), "acc": Color("#ffffff"), "z": 7.0},
	"m": {"n": "채굴", "c": 35, "hp": 30, "sp": 100.0, "col": Color("#f2a64e"), "acc": Color("#ffd9a8"), "z": 11.0},
	"c": {"n": "근접", "c": 40, "hp": 70, "sp": 90.0, "col": Color("#5aa0ff"), "acc": Color("#bcdcff"), "z": 12.0},
	"r": {"n": "원거리", "c": 55, "hp": 40, "sp": 85.0, "col": Color("#5fe0e6"), "acc": Color("#bff7fb"), "z": 9.0},
	"h": {"n": "지원", "c": 60, "hp": 45, "sp": 85.0, "col": Color("#8be28b"), "acc": Color("#10301c"), "z": 9.0},
}
const ORDER := ["s", "m", "c", "r", "h"]

const TN := [Color("#4a4234"), Color("#4e4537"), Color("#463f32"), Color("#524939")]
const FOG := Color("#070b0e")
const GOLD := Color("#ffd76a")
