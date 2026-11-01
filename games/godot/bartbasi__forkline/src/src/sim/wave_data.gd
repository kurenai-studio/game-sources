# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name WaveData
extends RefCounted
## One wave of a level: its strength and its groups in spawn order. Read only.

var strength: int = 100                                # the level's, unless the wave sets its own
var groups: Array[WaveGroup] = []
