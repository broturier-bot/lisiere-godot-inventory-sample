extends RefCounted
## Inventory data, independent of scenes, autoloads and game rules.
## Public getters return copies. Use the methods below to change quantities.
signal changed
var revision: int = 0
var _catalog: Dictionary = {}
var _slots: Array = []

func _init(catalog: Dictionary = {}, size: int = 12) -> void:
	_catalog = catalog.duplicate(true)
	_slots.resize(clampi(size, 1, 1000))
	_slots.fill({})

func capacity() -> int:
	return _slots.size()

func slot(index: int) -> Dictionary:
	return _slots[index].duplicate(true) if _valid(index) else {}

func definition(id: String) -> Dictionary:
	return _catalog.get(id, {}).duplicate(true)

func occupied() -> int:
	var result: int = 0
	for entry in _slots:
		if not entry.is_empty(): result += 1
	return result

func count(id: String) -> int:
	var result: int = 0
	for entry in _slots:
		if entry.get("id", "") == id: result += int(entry.quantity)
	return result

func _valid(index: int) -> bool:
	return index >= 0 and index < capacity()

func _limit(id: String) -> int:
	var entry: Variant = _catalog.get(id)
	if not entry is Dictionary: return 0
	var limit: Variant = entry.get("max_stack", 0)
	if not (limit is int or limit is float): return 0
	if not is_finite(float(limit)) or float(limit) != floor(float(limit)) or float(limit) < 1 or float(limit) > 9999: return 0
	return int(limit)

func _touch() -> void:
	revision += 1
	changed.emit()

func add_item(id: String, quantity: int) -> int:
	## Returns how many were actually added. The caller retains the remainder.
	var limit: int = _limit(id)
	if quantity <= 0 or limit == 0: return 0
	var remaining: int = quantity
	for i in range(capacity()):
		if _slots[i].get("id", "") == id:
			var moved: int = mini(remaining, limit - int(_slots[i].quantity))
			_slots[i].quantity += moved
			remaining -= moved
	for i in range(capacity()):
		if remaining == 0: break
		if _slots[i].is_empty():
			var moved: int = mini(remaining, limit)
			_slots[i] = {"id": id, "quantity": moved}
			remaining -= moved
	var added: int = quantity - remaining
	if added > 0: _touch()
	return added

func remove_item(id: String, quantity: int) -> int:
	## Returns how many were removed. Quantities never become negative.
	if quantity <= 0: return 0
	var remaining: int = quantity
	for i in range(capacity()):
		if _slots[i].get("id", "") == id:
			var removed: int = mini(remaining, int(_slots[i].quantity))
			_slots[i].quantity -= removed
			remaining -= removed
			if _slots[i].quantity == 0: _slots[i] = {}
		if remaining == 0: break
	if remaining < quantity: _touch()
	return quantity - remaining

func transfer_to(target, from_index: int, to_index: int, quantity: int = 0) -> Dictionary:
	## quantity=0 means the whole stack. A partial stack cannot swap a different item.
	## Both containers are changed before signals fire. A rejected move changes nothing.
	if not target is RefCounted or target.get_script() != get_script(): return _result(0, "Invalid destination")
	if not _valid(from_index) or not target._valid(to_index): return _result(0, "Invalid slot")
	if target == self and from_index == to_index: return _result(0, "Same slot")
	var source: Dictionary = _slots[from_index]
	var dest: Dictionary = target._slots[to_index]
	if source.is_empty() or quantity < 0: return _result(0, "Nothing to move")
	var wanted: int = int(source.quantity) if quantity == 0 else mini(quantity, int(source.quantity))
	var limit: int = target._limit(source.id)
	if limit == 0: return _result(0, "Item not accepted")
	var moved: int = 0
	var reason: String = "Moved"
	if dest.is_empty() or dest.id == source.id:
		var current: int = int(dest.get("quantity", 0))
		moved = mini(wanted, limit - current)
		if moved <= 0: return _result(0, "This stack is full")
		target._slots[to_index] = {"id": source.id, "quantity": current + moved}
		_slots[from_index] = {"id": source.id, "quantity": int(source.quantity) - moved} if int(source.quantity) > moved else {}
		if moved < wanted: reason = "Part moved; the remainder stays in place"
	else:
		if wanted != int(source.quantity): return _result(0, "Choose an empty or matching slot")
		if int(source.quantity) > limit or int(dest.quantity) > _limit(dest.id): return _result(0, "Stacks cannot be exchanged")
		moved = int(source.quantity)
		_slots[from_index] = dest.duplicate(true)
		target._slots[to_index] = source.duplicate(true)
		reason = "Stacks exchanged"
	revision += 1
	if target != self: target.revision += 1
	changed.emit()
	if target != self: target.changed.emit()
	return _result(moved, reason)

func transfer_auto(target, from_index: int, quantity: int = 0) -> Dictionary:
	## Merge, then fill empty slots. Never replaces unrelated items.
	if not target is RefCounted or target.get_script() != get_script(): return _result(0, "Invalid destination")
	if target == self or not _valid(from_index) or quantity < 0: return _result(0, "Invalid destination")
	var source: Dictionary = slot(from_index)
	if source.is_empty(): return _result(0, "Select an item first")
	var wanted: int = int(source.quantity) if quantity == 0 else mini(quantity, int(source.quantity))
	var moved: int = 0
	for pass_index in range(2):
		for i in range(target.capacity()):
			if moved == wanted: break
			var dest: Dictionary = target.slot(i)
			if (pass_index == 0 and dest.get("id", "") == source.id) or (pass_index == 1 and dest.is_empty()):
				moved += int(transfer_to(target, from_index, i, wanted - moved).moved)
	return _result(moved, "Moved" if moved == wanted else "Container full; remaining items stay in place")

func _result(moved: int, reason: String) -> Dictionary:
	return {"moved": moved, "reason": reason}

func snapshot() -> Dictionary:
	return {"schema": 1, "capacity": capacity(), "slots": _slots.duplicate(true)}

func validate_snapshot(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != 1 or data.get("capacity") != capacity(): return false
	var entries: Variant = data.get("slots")
	if not entries is Array or entries.size() != capacity(): return false
	for entry in entries:
		if not entry is Dictionary: return false
		if entry.is_empty(): continue
		if entry.size() != 2 or not entry.get("id") is String: return false
		var amount: Variant = entry.get("quantity")
		if not (amount is int or amount is float): return false
		if not is_finite(float(amount)) or float(amount) != floor(float(amount)) or float(amount) < 1 or float(amount) > _limit(entry.id): return false
	return true

func restore(data: Variant, notify: bool = true) -> bool:
	## Full validation before any mutation. Invalid saves leave all slots intact.
	if not validate_snapshot(data): return false
	_slots = data.slots.duplicate(true)
	for entry in _slots:
		if not entry.is_empty(): entry.quantity = int(entry.quantity)
	revision += 1
	if notify: changed.emit()
	return true
