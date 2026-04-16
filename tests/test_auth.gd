extends AutoworkTest

var helper: Object
var sdk: Object
var is_connected: bool = false
var auth_failed: bool = false

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
    auth_failed = false
    if not sdk.is_client_connected():
        sdk.connect_to_server("127.0.0.1", 7005)
        for i in range(20):

            sdk.poll(0.1); OS.delay_msec(100)
            if sdk.is_client_connected():
                break
            

func _on_disconnect(reason: String) -> void:
    # A DISCONNECT payload typically returns a json with "reason"
    auth_failed = true

func test_valid_auth() -> void:
    assert_true(sdk.is_client_connected(), "Should be connected before auth test")
    
    var local_auth_ok = false
    var wait_conn = func():
        local_auth_ok = true
    
    # We don't have a direct "auth_success" signal natively exposed.
    # We observe if we get a snapshot or DO NOT get disconnected in ~1s.
    sdk.disconnected.connect(_on_disconnect)
    
    var valid_jwt = helper.mint_jwt("user_auth_valid")
    # AutoworkTest doesn't assert if empty string unless explicitly checked, but ensuring mint worked:
    assert_ne(valid_jwt, "", "Helper should successfully generate RSA JWT")
    
    sdk.authenticate(valid_jwt)
    
    # Allow 1 second for auth to settle
    for i in range(10):
        sdk.poll(0.1); OS.delay_msec(100)
        
        
    assert_false(auth_failed, "Valid JWT should not cause disconnection")
    sdk.disconnected.disconnect(_on_disconnect)
    sdk.disconnect_from_server()
    
func test_invalid_auth() -> void:
    # Attempting to auth with an unsinged/badly signed dummy token
    sdk.disconnected.connect(_on_disconnect)
    var invalid_jwt = helper.mint_invalid_jwt("user_attacker")
    
    sdk.authenticate(invalid_jwt)
    
    for i in range(15):
        sdk.poll(0.1); OS.delay_msec(100)
        if auth_failed:
            break
        
        
    assert_true(auth_failed, "Should be disconnected due to invalid auth JWT")
    sdk.disconnected.disconnect(_on_disconnect)

func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()

