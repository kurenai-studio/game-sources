extends RefCounted
## The OS owns the socket and releases it even if the game crashes.
## Bind only on loopback. No connections or remote commands are accepted.
const PORT := 57348
var listener := TCPServer.new()

func acquire(port: int = PORT) -> bool:
	return listener.is_listening() or listener.listen(port,"127.0.0.1") == OK

func allow_launch(tree: SceneTree) -> bool:
	if acquire(): return true
	var message := "Horse Racing is already open, or its launch lock is in use.\nClose the existing game or race preview before opening another copy."
	if DisplayServer.get_name() != "headless":
		OS.alert(message,"Horse Racing is already running")
	printerr(message)
	tree.quit(2)
	return false

func release() -> void:
	listener.stop()
