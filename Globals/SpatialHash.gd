extends Node

@export var cell_size: float = 128.0

var cells := {}            # key -> Array of objects
var obj_cells := {}        # object -> Array of keys
var obj_aabbs := {}        # object -> Rect2

func _cell_key(x: int, y: int) -> String:
	return str(x) + "_" + str(y)

func _cells_for_rect(rect: Rect2) -> Array:
	var minx = int(floor(rect.position.x / cell_size))
	var miny = int(floor(rect.position.y / cell_size))
	var maxx = int(floor((rect.position.x + rect.size.x) / cell_size))
	var maxy = int(floor((rect.position.y + rect.size.y) / cell_size))
	var keys := []
	for x in range(minx, maxx + 1):
		for y in range(miny, maxy + 1):
			keys.append(_cell_key(x, y))
	return keys

func insert(obj: Object, rect: Rect2) -> void:
	remove(obj)
	obj_aabbs[obj] = rect
	var keys = _cells_for_rect(rect)
	obj_cells[obj] = keys
	for key in keys:
		if not cells.has(key):
			cells[key] = []
		cells[key].append(obj)

func remove(obj: Object) -> void:
	if not obj_cells.has(obj):
		return
	for key in obj_cells[obj]:
		if cells.has(key):
			cells[key].erase(obj)
			if cells[key].size() == 0:
				cells.erase(key)
	obj_cells.erase(obj)
	obj_aabbs.erase(obj)

func update(obj: Object, rect: Rect2) -> void:
	insert(obj, rect)

# Query returns unique objects whose cells overlap rect (caller should do final AABB intersect/narrow-phase)
func query(rect: Rect2) -> Array:
	var results := {}
	for key in _cells_for_rect(rect):
		if cells.has(key):
			for obj in cells[key]:
				results[obj] = true
	return results.keys()
	
# Optional convenience
func get_aabb(obj: Object) -> Rect2:
	return obj_aabbs.get(obj, Rect2())

func clear() -> void:
	cells.clear()
	obj_cells.clear()
	obj_aabbs.clear()