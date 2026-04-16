extends AutoworkTest

var helper: Object
var sdk: Object
var reconnect_attempted: bool = false
var reconnected: bool = false

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
    reconnect_attempted = false
    reconnected = false
    
    if not sdk.is_client_connected():
        sdk.connect_to_server("127.0.0.1", 7005)
        var connected = helper.attempt_wait_for_condition(get_tree(), func():
            sdk.poll(0.1); OS.delay_msec(100)
            return sdk.is_client_connected()
        , 2.0)
        
func _on_reconnecting(attempt: int, next_delay: float) -> void:
    reconnect_attempted = true

func _on_reconnected(resume_state) -> void:
    reconnected = true

func test_auto_reconnect_fire() -> void:
    # Need to auth so we get a session to reconnect to
    sdk.authenticate(helper.mint_jwt("reconnect_user"))
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return false
    , 0.5)
    
    sdk.reconnecting.connect(_on_reconnecting)
    sdk.reconnected.connect(_on_reconnected)
    
    sdk.set_auto_reconnect(true)
    
    # We forcefully kill the server to drop the socket
    helper.stop_server()


    
    # Pump the SDK to recognize the socket drop (Wait up to 35 seconds)
    print("Waiting for ENet to detect dropped socket (approx 15-30s)...")
    var dropped = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return not sdk.is_client_connected()
    , 35.0)
    
    # Let it attempt reconnecting
    helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return reconnect_attempted
    , 2.0)
    
    assert_true(reconnect_attempted, "Auto reconnect should fire its event when socket drops with it enabled")
    
    # Bring server back
    helper.start_server()
    OS.delay_msec(2000)
    
    # Allow 10 seconds for exponential backoff to re-catch the server
    var res = helper.attempt_wait_for_condition(get_tree(), func():
        sdk.poll(0.1); OS.delay_msec(100)
        return reconnected
    , 10.0)
    
    assert_true(res, "Client should successfully auto-reconnect once server comes back online")
    
    sdk.reconnecting.disconnect(_on_reconnecting)
    sdk.reconnected.disconnect(_on_reconnected)

func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()

