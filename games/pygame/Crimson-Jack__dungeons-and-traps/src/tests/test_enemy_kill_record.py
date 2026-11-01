from src.enemy_kill_record import EnemyKillRecord


class TestEnemyKillRecord:
    def test_initial_count_is_zero(self):
        record = EnemyKillRecord()
        assert record.count == 0

    def test_initial_killed_is_zero(self):
        record = EnemyKillRecord()
        assert record.killed == 0

    def test_initial_score_is_zero(self):
        record = EnemyKillRecord()
        assert record.score == 0

    def test_record_spawn_counts_only_appeared_enemy(self):
        record = EnemyKillRecord()

        record.record_spawn()

        assert (record.count, record.killed, record.score) == (1, 0, 0)

    def test_record_kill_counts_killed_enemy_and_adds_score(self):
        record = EnemyKillRecord()

        record.record_kill(20)
        record.record_kill(40)

        assert (record.count, record.killed, record.score) == (0, 2, 60)

    def test_reset_clears_record(self):
        record = EnemyKillRecord()
        record.record_spawn()
        record.record_kill(20)

        record.reset()

        assert (record.count, record.killed, record.score) == (0, 0, 0)

    def test_add_sums_values_of_other_record(self):
        record = EnemyKillRecord()
        record.record_spawn()
        record.record_spawn()
        record.record_kill(20)
        other_record = EnemyKillRecord()
        other_record.record_spawn()
        other_record.record_kill(30)

        record.add(other_record)

        assert (record.count, record.killed, record.score) == (3, 2, 50)
        assert (other_record.count, other_record.killed, other_record.score) == (1, 1, 30)
