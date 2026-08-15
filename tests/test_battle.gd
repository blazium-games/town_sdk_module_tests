extends AutoworkTest

var helper: Object
var sdk: Object
var battle_started: bool = false
var battle_payload: Dictionary = {}

func _before_all() -> void:
    if not FileAccess.file_exists("d:/ai_platforms/engine_modules/town_server/build/windows/bin/turnbattle.exe"):
        return
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
    if sdk == null:
        return
    battle_started = false
    
    if not sdk.is_client_connected():
        sdk.connect_to_server("127.0.0.1", 7005)
        var connected = helper.attempt_wait_for_condition(get_tree(), func():

            sdk.poll(0.1); OS.delay_msec(100)
            return sdk.is_client_connected()
        , 2.0)

func _on_battle_start(battle: Dictionary) -> void:
    battle_started = true
    battle_payload = battle

func test_battle_action_invalid() -> void:
    if OS.get_environment("TOWN_LIVE_TESTS") != "1":
        pending("Requires local turnbattle.exe (set TOWN_LIVE_TESTS=1)")
        return
    sdk.authenticate(helper.mint_jwt("battle_user"))
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 0.5)
    
    # Send a battle action when not in a valid battle. 
    # Should not crash the client, engine should swallow or server ignores.
    # TownSdkClient::Action = { ACTION_ATTACK = 0, ACTION_BLOCK = 1, ACTION_DEFEND = 2 }
    sdk.battle_action("invalid_battle_id", 0, "enemyX")
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 1.0)
    
    assert_false(res, "Sanity wait completed without crashing or locking")

func test_leave_battle_graceful() -> void:
    if OS.get_environment("TOWN_LIVE_TESTS") != "1":
        pending("Requires local turnbattle.exe (set TOWN_LIVE_TESTS=1)")
        return
    sdk.leave_battle("some_random_id")
    
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 1.0)
    
    assert_false(res, "Leaving fake battle shouldn't crash client")

func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()

