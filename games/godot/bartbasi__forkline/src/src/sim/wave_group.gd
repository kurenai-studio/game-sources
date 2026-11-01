# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name WaveGroup
extends RefCounted
## One group of a wave: one creature type, a count, an entrance and timing. Read only.

var enemy: StringName = &""
var count: int = 1
var entrance: int = 0                                  # 0 based
var at_tick: int = 0
var every_ticks: int = 1
