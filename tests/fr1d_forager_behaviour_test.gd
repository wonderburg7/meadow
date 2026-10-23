extends SceneTree
## Exercise the shipping exit/match paths with real bees and a real hive.

var _foraging: GDScript
var _bee_script: GDScript
var _hive: Node2D
var _config: Node
var _failures: PackedStringArray = []
var _checks := 0
var _ran := false

func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_foraging = load("res://scripts/bee_foraging.gd")
	_bee_script = load("res://scripts/bee.gd")
	_config = root.get_node("GameConfig")
	root.get_node("Session").rain_intensity = 0.0
	_config.scouting_on = true
	_config.auto_recruitment_on = true
	_config.proximity_recruitment_on = false
	_config.recruit_grace_trips = 3
	var hive_script: GDScript = load("res://scripts/hive.gd")
	_hive = hive_script.new()
	_hive.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(_hive)
	_test_empty_and_mixed()
	_test_match()
	_test_boundaries()
	_test_waiting_scout()
	_test_modes()
	_profile_exit()
	if _checks < 30:
		_failures.append("test functions did not complete: %d checks" % _checks)
	if _failures.is_empty():
		print("FR1D PASS checks=", _checks)
	else:
		for failure in _failures:
			print("FR1D FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
	return true

func _bee(scouting: bool = true, resource: String = "nectar") -> Node2D:
	var bee: Node2D = _bee_script.new()
	bee.process_mode = Node.PROCESS_MODE_DISABLED
	bee.hive = _hive
	bee.role = _bee_script.Role.FORAGER
	root.add_child(bee)
	bee.is_scouting = scouting
	bee.resource_type = resource
	bee.state = _bee_script.State.IN_HIVE_TO_EXIT
	bee.position = Vector2.ZERO
	bee.preferred_species = "clover"
	return bee

func _expect(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)

func _test_empty_and_mixed() -> void:
	for resource in ["nectar", "pollen"]:
		var bee := _bee(true, resource)
		_foraging.go_to_exit(bee, 0.0)
		_expect(bee.state == _bee_script.State.MOVE_TO_POINT, resource + ": empty queue resumes scouting")
		_expect(bee.is_scouting and bee.scout_bout == 0, "no bout consumed by bypass")
		_expect(bee.preferred_species == "clover", "explicit species preserved")
		var other := _bee(false, "pollen" if resource == "nectar" else "nectar")
		other.state = _bee_script.State.AT_ENTRANCE_MENTORING
		other.timer = _config.recruit_wait_seconds
		_hive.add_entrance_mentor(other)
		bee.state = _bee_script.State.IN_HIVE_TO_EXIT
		_foraging.go_to_exit(bee, 0.0)
		_expect(bee.state == _bee_script.State.MOVE_TO_POINT, "wrong resource cannot justify wait")
		_expect(_hive.entrance_mentors.has(other), "other resource mentor stays available")
		var stale := _bee(false, resource)
		_hive.add_entrance_mentor(stale)
		stale.free()
		bee.state = _bee_script.State.IN_HIVE_TO_EXIT
		_foraging.go_to_exit(bee, 0.0)
		_expect(bee.state == _bee_script.State.MOVE_TO_POINT, "freed mentor cannot justify wait")
		_hive.entrance_mentors.clear()
		other.free()
		bee.free()

func _test_match() -> void:
	for pass_species in [false, true]:
		_config.floral_constancy_on = pass_species
		var bee := _bee()
		var other := _bee(false, "pollen")
		var mentor := _bee(false)
		mentor.state = _bee_script.State.AT_ENTRANCE_MENTORING
		mentor.timer = _config.recruit_wait_seconds
		mentor.forage_start_point = Vector2(300, 100)
		mentor.preferred_species = "lavender"
		_hive.add_entrance_mentor(other)
		_hive.add_entrance_mentor(mentor)
		_foraging.go_to_exit(bee, 0.0)
		_expect(bee.state == _bee_script.State.AT_ENTRANCE_SEEKING, "existing mentor retains useful wait")
		_expect(bee.timer == _config.recruit_wait_seconds, "wait duration unchanged")
		_foraging.wait_at_entrance(bee, 0.0)
		_expect(not bee.is_scouting and bee.state == _bee_script.State.MOVE_TO_POINT, "matching ends scouting")
		_expect(bee.recruit_partner == mentor, "same-resource mentor selected behind wrong resource")
		_expect(not _hive.entrance_mentors.has(mentor) and _hive.entrance_mentors.has(other), "mentor used once")
		_expect(bee.preferred_species == ("lavender" if pass_species else "clover"), "species toggle unchanged")
		_hive.entrance_mentors.clear()
		bee.free()
		mentor.free()
		other.free()
	_config.floral_constancy_on = false

func _test_boundaries() -> void:
	var bee := _bee(false)
	bee.trips_scored = 2
	bee.avg_collection_rate = 0.0
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state != _bee_script.State.AT_ENTRANCE_SEEKING, "established bee still gets grace")
	bee.trips_scored = 3
	bee.state = _bee_script.State.IN_HIVE_TO_EXIT
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state == _bee_script.State.AT_ENTRANCE_SEEKING, "established low rate still waits without mentor")
	_foraging.wait_at_entrance(bee, _config.recruit_wait_seconds - 0.1)
	_expect(bee.state == _bee_script.State.AT_ENTRANCE_SEEKING, "established wait not shortened")
	_foraging.wait_at_entrance(bee, 0.2)
	_expect(bee.state != _bee_script.State.AT_ENTRANCE_SEEKING and bee.preferred_species == "", "established timeout resets stale preference")
	bee.is_scouting = true
	bee.scout_bout = 2
	bee.trips_scored = 2
	bee.trip_start_time = root.get_node("Session").sim_time - 1.0
	bee.trip_load_amount = 0.1
	bee.scout_current_start_point = Vector2(200, 50)
	_foraging._score_trip(bee)
	_expect(not bee.is_scouting and bee.trips_scored == 3, "third bout settles normally")
	bee.state = _bee_script.State.IN_HIVE_TO_EXIT
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state == _bee_script.State.AT_ENTRANCE_SEEKING, "settled low rate returns to established policy")
	bee.free()

func _test_waiting_scout() -> void:
	var bee := _bee()
	var mentor := _bee(false)
	mentor.state = _bee_script.State.AT_ENTRANCE_MENTORING
	mentor.timer = _config.recruit_wait_seconds
	_hive.add_entrance_mentor(mentor)
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state == _bee_script.State.AT_ENTRANCE_SEEKING, "scout starts with a matching mentor")
	mentor.free()
	_foraging.wait_at_entrance(bee, 0.0)
	_expect(bee.state == _bee_script.State.MOVE_TO_POINT and bee.is_scouting, "scout resumes when mentor dies during wait")
	_expect(_hive.entrance_mentors.is_empty(), "freed waiting mentor pruned")
	mentor = _bee(false)
	mentor.state = _bee_script.State.AT_ENTRANCE_MENTORING
	mentor.timer = _config.recruit_wait_seconds
	_hive.add_entrance_mentor(mentor)
	_foraging.wait_at_entrance(mentor, 0.1)
	_expect(mentor.state == _bee_script.State.AT_ENTRANCE_MENTORING and _hive.entrance_mentors.has(mentor), "mentor keeps her own wait")
	_foraging.wait_at_entrance(mentor, _config.recruit_wait_seconds)
	_expect(mentor.state != _bee_script.State.AT_ENTRANCE_MENTORING and _hive.entrance_mentors.is_empty(), "mentor timeout unchanged")
	bee.free()
	mentor.free()

func _test_modes() -> void:
	var bee := _bee()
	_config.auto_recruitment_on = false
	_config.proximity_recruitment_on = true
	_foraging._update_dance_eligibility(bee)
	_expect(_hive.dance_eligible_seekers.has(bee), "proximity seeker eligibility unchanged")
	var mentor := _bee(false)
	mentor.trips_scored = 3
	mentor.avg_collection_rate = 10.0
	mentor.forage_start_point = Vector2(200, 100)
	_foraging._update_dance_eligibility(mentor)
	_foraging.check_dance_proximity(mentor, 0.0)
	_expect(bee.state == _bee_script.State.DANCING and mentor.dance_partner == bee, "proximity mentor still pairs with scout")
	_foraging.dance(mentor, _config.recruit_dance_seconds + 0.1)
	_expect(not bee.is_scouting and bee.recruit_partner == mentor, "proximity match still hands over patch")
	_foraging.dance(bee, _config.recruit_dance_seconds + 0.1)
	mentor.free()
	bee.is_scouting = true
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state == _bee_script.State.MOVE_TO_POINT, "proximity mode adds no entrance wait")
	_config.proximity_recruitment_on = false
	_foraging.leave_recruitment(bee)
	_config.auto_recruitment_on = true
	bee.tipsy_time_left = 5.0
	bee.state = _bee_script.State.IN_HIVE_TO_EXIT
	_foraging.go_to_exit(bee, 0.0)
	_expect(bee.state == _bee_script.State.MOVE_TO_POINT, "tipsy bee still bypasses recruitment")
	bee.free()

func _profile_exit() -> void:
	var bee := _bee()
	var started := Time.get_ticks_usec()
	for i in 1000:
		bee.state = _bee_script.State.IN_HIVE_TO_EXIT
		_foraging.go_to_exit(bee, 0.0)
	print("FR1D PROFILE population=1 calls=1000 empty_queue total_us=", Time.get_ticks_usec() - started)
	bee.free()

