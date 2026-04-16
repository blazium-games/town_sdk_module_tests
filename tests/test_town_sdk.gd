extends AutoworkTest

var helper: Object
var sdk: Object

func _before_all() -> void:
    var HelperClass = preload("res://tests/test_helper.gd")
    helper = HelperClass.new()
    helper.start_server()
    OS.delay_msec(2000)
    sdk = Engine.get_singleton("TownSDK")

func _after_all() -> void:
    if helper:
        helper.stop_server()
        helper.queue_free()

func test_simple_server_connection() -> void:
    assert_not_null(sdk, "TownSDK singleton should be found")
    if not sdk:
        return
        
    print("Testing connection to 127.0.0.1:7005...")
    var success = sdk.connect_to_server("127.0.0.1", 7005)
    assert_true(success, "Should initiate connection successfully to 127.0.0.1")
    
    # Non-blocking wait for connection state
    for i in range(20): # 2 seconds max
        sdk.poll(0.1); OS.delay_msec(100)
        if sdk.is_client_connected():
            break
        
    assert_true(sdk.is_client_connected(), "Client should be fully connected")
    
    # Safe disconnect
    sdk.disconnect_from_server()

func _after_each() -> void:
    if sdk and sdk.is_client_connected():
        sdk.disconnect_from_server()
