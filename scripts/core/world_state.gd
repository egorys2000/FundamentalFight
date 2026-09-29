class_name WorldState
extends RefCounted

const BREAKABLE_CRAG := "crag_breakable"
const UNBREAKABLE_CRAG := "crag_unbreakable"
const BREAKABLE_SPIRE := "crag_breakable_spire"
const UNBREAKABLE_SPIRE := "crag_unbreakable_spire"
const CACTUS := "cactus"
const CACTUS_TWIN := "cactus_twin"
const CACTUS_LOW := "cactus_low"

var player_cell := Vector2i.ZERO
var occupied := {
	Vector2i(-6, -3): BREAKABLE_CRAG,
	Vector2i(-2, 3): UNBREAKABLE_SPIRE,
	Vector2i(3, -3): BREAKABLE_SPIRE,
	Vector2i(6, 2): UNBREAKABLE_CRAG,
	Vector2i(1, 2): BREAKABLE_CRAG,
	Vector2i(-4, 0): CACTUS_TWIN,
	Vector2i(5, -1): CACTUS_LOW,
	Vector2i(-1, -2): CACTUS
}

var water_cells := [
	Vector2i(-6, 1),
	Vector2i(-5, 1),
	Vector2i(-4, 1),
	Vector2i(2, -1),
	Vector2i(3, -1),
	Vector2i(4, -1),
	Vector2i(-1, 3),
]

func is_obstacle(cell: Vector2i) -> bool:
	return occupied.has(cell)

func is_crag(cell: Vector2i) -> bool:
	return occupied.get(cell, "").begins_with("crag")

func is_cactus(cell: Vector2i) -> bool:
	return occupied.get(cell, "").begins_with("cactus")

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
