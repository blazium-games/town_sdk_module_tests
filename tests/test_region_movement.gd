extends AutoworkTest

var helper: Object
var sdk: Object
var got_snapshot: bool = false
var got_move: bool = false
var current_snapshot: Dictionary = {}

func _before_all() -> void:
    var HelperClass = preload("res://tests/test_helper.gd")
    helper = HelperClass.new()
    helper.start_server()
    OS.delay_msec(2000)
    sdk = Engine.get_singleton("TownSDK")

func _after_all() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()
    if helper:
        helper.stop_server()
        helper.queue_free()

func _before_each() -> void:
    got_snapshot = false
    got_move = false
    
    if not sdk.is_client_connected():
        sdk.connect_to_server("127.0.0.1", 7005)
        for i in range(30):
            sdk.poll(0.1); OS.delay_msec(100)
            if sdk.is_client_connected():
                break
            
    # Needs to authenticate before joining region!
    sdk.authenticate(helper.mint_jwt("user_region_test"))
    for i in range(10):
        sdk.poll(0.1); OS.delay_msec(100)
        
func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()

func _on_snapshot(snapshot: Dictionary) -> void:
    got_snapshot = true
    current_snapshot = snapshot
    
func _on_move_state(state: Dictionary) -> void:
    got_move = true

func test_region_snapshot() -> void:
    sdk.snapshot_received.connect(_on_snapshot)
    
    sdk.enter_region("spawn")
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return got_snapshot
    , 2.0)
    
    assert_true(res, "Should receive a snapshot after entering a region")
    assert_true(current_snapshot.has("players"), "Snapshot must contain players")
    
    sdk.leave_region()
    # Pumping events
    for i in range(5):
        sdk.poll(0.1); OS.delay_msec(100)
        
    sdk.snapshot_received.disconnect(_on_snapshot)

func test_movement_broadcast() -> void:
    sdk.snapshot_received.connect(_on_snapshot)
    sdk.move_state.connect(_on_move_state)
    
    sdk.enter_region("spawn")
    
    # Wait for snapshot first
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return got_snapshot
    , 2.0)
    
    # Send movement (e.g. holding UP)
    # 0 = NONE, 1 = UP, 2 = DOWN, etc.
    sdk.send_move(1, 0.1)
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return got_move
    , 2.0)
    
    assert_true(res, "Should receive move_state packet broadcast after moving")
    sdk.move_state.disconnect(_on_move_state)
    sdk.snapshot_received.disconnect(_on_snapshot)
