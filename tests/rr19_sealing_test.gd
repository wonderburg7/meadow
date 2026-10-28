extends SceneTree
## RR-19 test: a comb worker caps and uncaps cells over time.
##
## Level 4 (15 cells, two comb workers) with every cell cleared and every
## bee held fed. Every bee is put on Build, so none takes the sealing row,
## then:
##   1. winter's bill draws on a sealed cell and closes it again at once,
##      and Seal on a closed cell changes nothing;
##   2. Seal on a full honey cell with no comb worker free leaves it open
##      (and usable) for 20 s;
##   3. one comb worker on Clearing caps it: the cell stays open, its stores
##      usable, until comb workers have spent cell_seal_seconds on it;
##   4. Open: it stays closed until they have spent cell_unseal_seconds;
##   5. "Fill then seal" on a honey cell filled after the order by the
##      deposit honey makers use, a jelly cell already full, and a brood
##      cell: each asks for its cap, refuses withdrawals while it waits, and
##      is capped.
## Worker-seconds are counted from the bees' own states, frame by frame,
## not read off the cell.
## Run by tests/test_rr19_sealing.py:
##   godot --headless --fixed-fps 60 --path <repo> --script res://tests/rr19_sealing_test.gd

const LEVEL := 4
const BOOT_FRAMES := 10
const NO_WORKER_SECONDS := 20.0
const TOLERANCE := 0.1          # seconds, six frames at 60 fps
const PHASE_TIMEOUT := 120.0    # game-seconds any one phase may take

var _main: Node = null
var _session: Node = null
var _config: Node = null
var _bee_states: Variant = null
var _frame := 0
var _phase := "boot"
var _failures: PackedStringArray = PackedStringArray()
var _last_now := -1.0
var _phase_start := 0.0
var _worker: Node2D = null
var _winter_cell: Node2D = null
var _seal_cell: Node2D = null
var _fill_cells: Dictionary = {}   # label -> cell
## Worker-seconds spent on `_seal_cell` in this phase, and how many bees
## were capping or uncapping it at the last check (they worked the frame
## that followed it).
var _work := 0.0
var _sealers_last := 0


func _process(_delta: float) -> bool:
	_frame += 1
	match _phase:
		"boot":
			_boot()
		"settle":
			if _frame >= BOOT_FRAMES:
				_setup()
		_:
			_step()
	if _phase == "done":
		_report()
		return true
	return false


func _boot() -> void:
	_session = root.get_node("Session")
	_config = root.get_node("GameConfig")
	_session.starting_level = LEVEL
	_session.menu_pending = false
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	current_scene = _main
	_phase = "settle"


func _setup() -> void:
	_bee_states = _main.Bee.State
	var progression: Object = _session.progression
	var roles: GDScript = load("res://scripts/roles.gd")
	var skill: String = roles.skill_for(_main.Bee.Role.BUILDER)
	if progression != null and skill != "":
		progression.grant_temporary(skill)
		progression._behaviour_cache.clear()
	_main.Availability.invalidate()
	for bee: Variant in _bees():
		bee.energy_immune = true
		bee.age_seconds = 0.0
		bee.architect_mode = "build"
	var cells: Array = _main.hive.cells.filter(func(c: Variant) -> bool: return is_instance_valid(c) and c.is_built)
	if cells.size() < 5:
		_fail("level %d has %d built cells, fewer than five" % [LEVEL, cells.size()])
		_phase = "done"
		return
	for cell: Variant in cells:
		cell.clear_cell()
		cell.set_closed(false)
		cell.pending_open = false
		cell.keep_empty = false
		cell.set_designation("", false)
	_winter_cell = cells[0]
	_seal_cell = cells[1]
	# The brood cell comes first in the comb, so it is capped first, well
	# inside its development time.
	_fill_cells = {"brood": cells[2], "honey": cells[3], "jelly": cells[4]}
	for label: String in ["honey", "jelly"]:
		_fill_cells[label].set_designation(label)
	_fill_cells["brood"].set_designation("brood")
	_stock_fill_cells()
	if paused:
		paused = false
	_check_winter_and_closed_seal()
	# 2. Seal with no comb worker free.
	_seal_cell.set_designation("honey")
	_seal_cell.add_resource("honey", _seal_cell.capacity_for("honey"))
	_order_seal(_seal_cell, true)
	_check(_seal_cell.pending_seal and not _seal_cell.is_closed, "Seal did not leave the cell open and waiting for its cap")
	_start_phase("no_worker")


## 1. Winter's bill opens a sealed cell, draws on it and closes it again in
## the same call; Seal on a closed cell changes nothing.
func _check_winter_and_closed_seal() -> void:
	var cell: Node2D = _winter_cell
	cell.set_designation("honey")
	cell.add_resource("honey", cell.capacity_for("honey"))
	cell.add_fanning_progress(_config.honey_ripen_time)
	cell.set_closed(true)
	_check(cell.is_closed and not cell.pending_seal, "set_closed(true), winter's close, did not close the cell at once")
	var before: float = cell.amount
	_main.season._pay_from_stores(5.0 * _config.honey_energy_factor)
	_check(cell.amount < before - 0.001, "winter's bill did not draw on the sealed cell (%.2f before, %.2f after)" % [before, cell.amount])
	_check(cell.is_closed, "winter's bill left the sealed cell open")
	_check(not cell.pending_seal and not cell.pending_open, "winter's bill left a capping order on the cell")
	var epoch: int = cell.display_epoch
	_order_seal(cell, true)
	_check(cell.is_closed and not cell.pending_seal and not cell.pending_open and not cell.fill_then_close,
		"Seal on a closed cell changed its flags")
	_check(cell.display_epoch == epoch, "Seal on a closed cell changed what the popup shows")


func _step() -> void:
	var now: float = float(_session.sim_time)
	var dt: float = 0.0 if _last_now < 0.0 else now - _last_now
	_last_now = now
	_work += dt * _sealers_last
	_sealers_last = _count_sealers(_seal_cell)
	var elapsed: float = now - _phase_start
	match _phase:
		"no_worker":
			_check(not _seal_cell.is_closed, "the cell closed with no comb worker on Clearing")
			_check(_seal_cell.can_withdraw(), "a cell waiting for its cap refused withdrawals")
			if elapsed >= NO_WORKER_SECONDS:
				_check(_seal_cell.pending_seal, "the Seal order was lost while no comb worker was free")
				_check(_work == 0.0, "a bee capped the cell while every comb worker was on Build")
				_worker = _main.world_building._spawn_indoor_bee(_main.Bee.Role.BUILDER)
				_worker.energy_immune = true
				_worker.age_seconds = 0.0
				_worker.architect_mode = "maintain"
				_worker.state = _bee_states.BUILD_IDLE
				_start_phase("seal")
		"seal":
			if not _seal_cell.is_closed:
				_check(_seal_cell.can_withdraw(), "a plain Seal refused withdrawals before the cap closed")
				_check(_work <= _config.cell_seal_seconds + TOLERANCE,
					"the cell was still open after %.2f worker-seconds" % _work)
			else:
				_check(absf(_work - _config.cell_seal_seconds) <= TOLERANCE,
					"the cell closed after %.2f worker-seconds, not %.1f" % [_work, _config.cell_seal_seconds])
				_check(not _seal_cell.pending_seal, "the closed cell still asks for its cap")
				_check(not _seal_cell.can_withdraw(), "the closed cell still lets stores out")
				print("RR19 sealed after %.2f worker-seconds" % _work)
				_order_seal(_seal_cell, false)
				_check(_seal_cell.is_closed and _seal_cell.pending_open, "Open did not leave the cell closed and waiting")
				_start_phase("open")
		"open":
			if _seal_cell.is_closed:
				_check(not _seal_cell.can_withdraw(), "a closed cell let stores out before its cap came off")
				_check(_work <= _config.cell_unseal_seconds + TOLERANCE,
					"the cell was still closed after %.2f worker-seconds" % _work)
			else:
				_check(absf(_work - _config.cell_unseal_seconds) <= TOLERANCE,
					"the cell opened after %.2f worker-seconds, not %.1f" % [_work, _config.cell_unseal_seconds])
				_check(not _seal_cell.pending_open, "the open cell still asks for its cap off")
				_check(_seal_cell.can_withdraw(), "the opened cell refuses withdrawals")
				print("RR19 opened after %.2f worker-seconds" % _work)
				_start_fill_then_seal()
				_start_phase("fill")
		"fill":
			var all_closed := true
			for label: String in _fill_cells:
				var cell: Node2D = _fill_cells[label]
				if not cell.is_closed:
					all_closed = false
					_check(cell.pending_seal, "the full %s cell stopped asking for its cap (holds %s)" % [label, cell.content_type])
					if label != "brood":
						_check(not cell.can_withdraw(), "the %s cell let stores out while it was being capped" % label)
			if all_closed:
				for label: String in _fill_cells:
					var cell: Node2D = _fill_cells[label]
					_check(not cell.fill_then_close and not cell.pending_seal, "the capped %s cell kept its order" % label)
				print("RR19 fill then seal capped honey, jelly and brood after %.1f s" % elapsed)
				_phase = "done"
				return
	if _phase != "done" and elapsed > PHASE_TIMEOUT:
		_fail("phase %s timed out after %.0f game-seconds (worker state %s)" % [
			_phase, elapsed, str(_worker.state) if _worker != null and is_instance_valid(_worker) else "none"])
		_phase = "done"


## 5, first half: the stores are stocked now, so the queen cannot lay in
## them while the earlier phases run. The honey cell takes its order empty
## and is half filled; the jelly cell is filled. The brood cell gets its
## larva when the phase starts, so it cannot emerge before it is capped.
func _stock_fill_cells() -> void:
	var honey: Node2D = _fill_cells["honey"]
	_order_fill_then_seal(honey)
	_check(honey.fill_then_close and not honey.pending_seal, "an empty Fill then seal cell asked for its cap")
	honey.add_resource("honey", honey.capacity_for("honey") * 0.5)
	_check(not honey.pending_seal, "a half-full Fill then seal cell asked for its cap")
	var jelly: Node2D = _fill_cells["jelly"]
	jelly.add_resource("jelly", jelly.capacity_for("jelly"))


## 5. Three ways a cell becomes full under "Fill then seal": topped up by the
## deposit honey makers use after the order, already full of jelly when the
## order comes, and holding brood.
func _start_fill_then_seal() -> void:
	var honey: Node2D = _fill_cells["honey"]
	_check(honey.content_type == "honey" and not honey.pending_seal, "the half-full honey cell changed before the fill phase")
	honey.add_resource("honey", honey.capacity_for("honey"))   # what bee_honey.gd::honey_deposit calls
	_check(honey.pending_seal, "a Fill then seal cell filled with converted honey did not ask for its cap")
	var jelly: Node2D = _fill_cells["jelly"]
	_order_fill_then_seal(jelly)
	_check(jelly.pending_seal, "Fill then seal on a jelly cell already full did not ask for its cap")
	var brood: Node2D = _fill_cells["brood"]
	brood.start_brood()
	brood.feed_brood(1000.0, false)   # so it cannot starve while it waits
	_order_fill_then_seal(brood)
	_check(brood.pending_seal, "Fill then seal on a brood cell did not ask for its cap")


func _order_seal(cell: Node2D, closed: bool) -> void:
	_main.selected_cells.clear()
	_main.hud.cell_close_requested.emit(cell, closed)


func _order_fill_then_seal(cell: Node2D) -> void:
	_main.selected_cells.clear()
	_main.hud.cell_fill_close_requested.emit(cell)


func _start_phase(name: String) -> void:
	_phase = name
	_phase_start = float(_session.sim_time)
	_work = 0.0
	_sealers_last = _count_sealers(_seal_cell)


func _count_sealers(cell: Node2D) -> int:
	var count := 0
	for bee: Variant in _bees():
		if bee.state == _bee_states.SEALING and bee.target_cell == cell:
			count += 1
	return count


func _bees() -> Array:
	return get_nodes_in_group("bees").filter(func(b: Node) -> bool: return is_instance_valid(b) and not b.is_queued_for_deletion())


func _check(condition: bool, failure: String) -> void:
	if not condition:
		_fail(failure)


func _fail(failure: String) -> void:
	if not _failures.has(failure):
		_failures.append(failure)


func _report() -> void:
	if _failures.is_empty():
		print("RR19 PASS")
		quit(0)
		return
	for line: String in _failures:
		print("RR19 FAIL: ", line)
	quit(1)
