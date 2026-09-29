class_name WorldState
extends RefCounted

const BREAKABLE_CRAG := "crag_breakable"
const UNBREAKABLE_CRAG := "crag_unbreakable"
const CACTUS := "cactus"

var player_cell := Vector2i.ZERO
var occupied := {
	Vector2i(-3, -2): BREAKABLE_CRAG,
	Vector2i(0, 2): UNBREAKABLE_CRAG,
	Vector2i(3, -2): BREAKABLE_CRAG,
	Vector2i(-2, 2): UNBREAKABLE_CRAG,
	Vector2i(2, 2): BREAKABLE_CRAG,
	Vector2i(3, 0): CACTUS
}

var water_cells := [
	Vector2i(-3, 1),
	Vector2i(-2, 1),
	Vector2i(2, -1),
	Vector2i(2, 0),
	Vector2i(-1, -3),
]

func is_obstacle(cell: Vector2i) -> bool:
	return occupied.has(cell)

func is_crag(cell: Vector2i) -> bool:
	return occupied.get(cell, "").begins_with("crag")

func is_cactus(cell: Vector2i) -> bool:
	return occupied.get(cell, "") == CACTUS

func crag_count() -> int:
	var count := 0
	for cell in occupied:
		if is_crag(cell):
			count += 1
	return count

func cactus_count() -> int:
	var count := 0
	for cell in occupied:
		if is_cactus(cell):
			count += 1
	return count
