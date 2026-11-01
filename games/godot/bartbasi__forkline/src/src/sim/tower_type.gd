# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TowerType
extends RefCounted
## One tower from data/stats/towers.json, in the file's units (docs/ARCHITECTURE.md 2.6).
## Read only.

var id: StringName = &""
var name: String = ""
var plural: String = ""
var info: String = ""
var kind: StringName = &"attack"                       # &"attack", &"slow", &"boost" or &"fright" (14.4)
var specs: Array[StringName] = []                      # the 2 path ids, spec 0 first

var _tiers: Array[TowerStats] = []                     # tier 1, tier 2
var _spec_stats: Array[TowerStats] = []                # spec 0, spec 1
var _spec_names: PackedStringArray = PackedStringArray()
var _spec_infos: PackedStringArray = PackedStringArray()


## Tier 1 or 2 with spec -1, or tier 3 with spec 0 or 1. Null for anything else.
func stats(tier: int, spec: int) -> TowerStats:
	if (tier == 1 or tier == 2) and spec == -1 and _tiers.size() == 2:
		return _tiers[tier - 1]
	if tier == 3 and (spec == 0 or spec == 1) and _spec_stats.size() == 2:
		return _spec_stats[spec]
	return null


func spec_name(spec: int) -> String:
	if spec < 0 or spec >= _spec_names.size():
		return ""
	return _spec_names[spec]


func spec_info(spec: int) -> String:
	if spec < 0 or spec >= _spec_infos.size():
		return ""
	return _spec_infos[spec]
