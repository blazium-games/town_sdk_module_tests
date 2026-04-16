extends Node
class_name TestHelper

var server_pid: int = -1
var privkey_path: String = "d:/ai_platforms/engine_modules/town_server/config/privkey.pem"
var turnbattle_exe: String = "d:/ai_platforms/engine_modules/town_server/build/windows/bin/turnbattle.exe"
var crypto_key: CryptoKey = null

func start_server() -> bool:
    if server_pid != -1:
        return true
    
    print("[TestHelper] Starting turnbattle.exe on port 7005...")
    # Launch in background natively with correct WorkingDirectory
    var ps_cmd = "Start-Process -FilePath '" + turnbattle_exe + "' -WorkingDirectory 'd:/ai_platforms/engine_modules/town_server' -WindowStyle Hidden -PassThru | Select-Object -ExpandProperty Id"
    var output = []
    OS.execute("powershell.exe", ["-Command", ps_cmd], output)
    if output.size() > 0:
        server_pid = int(output[0])
        print("[TestHelper] Spawned with PID ", server_pid)
    
    if server_pid <= 0:
        printerr("[TestHelper] Failed to start server!")
        return false
        
    return true

func stop_server() -> void:
    if server_pid != -1:
        print("[TestHelper] Stopping turnbattle.exe (PID ", server_pid, ")...")
        OS.kill(server_pid)
        server_pid = -1

func setup_crypto() -> void:
    if crypto_key == null:
        crypto_key = CryptoKey.new()
        var err = crypto_key.load(privkey_path)
        if err != OK:
            printerr("[TestHelper] Failed to load private key from ", privkey_path, ", err code: ", err)

func mint_jwt(user_id: String, is_admin: bool = false) -> String:
    setup_crypto()
    if crypto_key == null:
        return ""
        
    var roles = []
    if is_admin:
        roles = ["admin"]
        
    var builder = JWTBuilder.new() \
        .set_algorithm("RS256") \
        .set_subject(user_id) \
        .set_issuer("local-dev") \
        .add_claim("user_id", user_id) \
        .add_claim("roles", JSON.stringify(roles)) \
        .set_expiration(3600) \
        .set_audience("turnbattle")
    
    var token = builder.sign(crypto_key)
    return token

func mint_invalid_jwt(user_id: String) -> String:
    var crypto = Crypto.new()
    var random_key = crypto.generate_rsa(2048)
    
    var builder = JWTBuilder.new() \
        .set_algorithm("RS256") \
        .set_subject(user_id) \
        .add_claim("user_id", user_id) \
        .add_claim("is_admin", "false") \
        .set_expiration(3600) \
        .set_audience("turnbattle")
        
    return builder.sign(random_key)

func attempt_wait_for_condition(tree_ref: SceneTree, test_func: Callable, max_seconds: float = 2.0) -> bool:
    var iters = int((max_seconds * 10.0))
    for i in range(iters):
        if test_func.call():
            return true
        OS.delay_msec(100)
    return false
