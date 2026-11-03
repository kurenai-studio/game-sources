---@return table<string, audio.sound>
return {
	["fx_turret"] = { url = { "/sound/root#fx_turret" } },
	["fx_damage"] = { url = { "/sound/root#fx_damage" } },
	["fx_spikes"] = { url = { "/sound/root#fx_spikes" } },
	["fx_movement"] = { url = { "/sound/root#fx_movement" } },
	["fx_laser_movement"] = { url = { "/sound/root#fx_laser_movement" } },
	["fx_laser_attack"] = { url = { "/sound/root#fx_laser_attack" } },
	["fx_attack"] = { url = { "/sound/root#fx_attack" } },
	["fx_enemy_attack"] = { url = { "/sound/root#fx_enemy_attack" } },
	["fx_teleport"] = { url = { "/sound/root#fx_teleport" } },
	["fx_teleport_blocked"] = { url = { "/sound/root#fx_teleport_blocked" } },
	["fx_game_play"] = { url = { "/sound/root#fx_game_play" } },
	["fx_game_pause"] = { url = { "/sound/root#fx_game_pause" } },
	["fx_saw_attack"] = { url = { "/sound/root#fx_saw_attack" } },

	["fx_action_select"] = { url = { "/sound/root#fx_action_select" }, random_pitch = 0.03 },
	["fx_action_selected"] = { url = { "/sound/root#fx_action_selected" }, random_pitch = 0.03 },
	["fx_action_cancel"] = { url = { "/sound/root#fx_action_cancel" }, random_pitch = 0.03 },

	["music_bass"] = { url = { "/music/root#music_bass" }, max_instances = 1 },
	["music_idle"] = { url = { "/music/root#music_idle" }, max_instances = 1 },
	["music_battle"] = { url = { "/music/root#music_battle" }, max_instances = 1 },
}
