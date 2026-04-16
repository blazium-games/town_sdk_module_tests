extends AutoworkTest

var helper: Object
var sdk: Object
var got_admin_stats: bool = false
var admin_stats_payload: Dictionary = {}

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
    got_admin_stats = false
    
    if not sdk.is_client_connected():
        sdk.connect_to_server("127.0.0.1", 7005)
        var connected = helper.attempt_wait_for_condition(get_tree(), func():

            sdk.poll(0.1); OS.delay_msec(100)
            return sdk.is_client_connected()
        , 2.0)
        
func _on_admin_stats(payload: Dictionary) -> void:
    got_admin_stats = true
    admin_stats_payload = payload

func test_admin_permissions_pass() -> void:
    # Authing as True Admin
    sdk.authenticate(helper.mint_jwt("admin_test_user", true))
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 0.5)
    
    sdk.admin_stats_received.connect(_on_admin_stats)
    sdk.admin_stats_request()
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return got_admin_stats
    , 2.0)
    
    assert_true(res, "Admin should receive stats payload")
    assert_true(admin_stats_payload.has("stats") and admin_stats_payload["stats"].has("active_connections"), "Stats payload should contain client count")
    sdk.admin_stats_received.disconnect(_on_admin_stats)
    
func test_admin_permissions_fail() -> void:
    # Reconnecting to reset context
    sdk.disconnect_from_server()
    sdk.connect_to_server("127.0.0.1", 7005)
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return sdk.is_client_connected()
    , 2.0)
    
    # Authing as False Admin
    sdk.authenticate(helper.mint_jwt("normal_test_user", false))
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 0.5)
    
    sdk.admin_stats_received.connect(_on_admin_stats)
    sdk.admin_stats_request()
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return got_admin_stats
    , 2.0)
    
    assert_false(res, "Non-admin should NOT receive stats payload")
    sdk.admin_stats_received.disconnect(_on_admin_stats)

func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()

