from src.events import Events
from src.sprites.octopus_enemy import OctopusEnemy


def create_octopus_enemy_with_energy(game_manager, energy):
    # Full constructor requires costumes, tile details and the obstacle map, which are irrelevant for the energy
    octopus_enemy = object.__new__(OctopusEnemy)
    octopus_enemy.game_manager = game_manager
    octopus_enemy.energy = energy
    return octopus_enemy


class TestDecreaseEnergy:
    def test_updates_boss_energy_and_posts_energy_change(self, game_manager, post_event_mock):
        octopus_enemy = create_octopus_enemy_with_energy(game_manager, 100)

        octopus_enemy.decrease_energy(30)

        assert game_manager.boss_energy == 70
        assert [call.args[0].type for call in post_event_mock.call_args_list] == [Events.CHANGE_ENERGY_EVENT]
