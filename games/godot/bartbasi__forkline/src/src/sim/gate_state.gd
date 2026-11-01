# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GateState
extends RefCounted
## One placed gate. Read only outside src/sim/.

var cell: Vector2i = Vector2i(-1, -1)
var fixed: bool = false                                # cannot be moved or removed
var broken: bool = false                               # broken; mends, closed, when the next build phase begins
