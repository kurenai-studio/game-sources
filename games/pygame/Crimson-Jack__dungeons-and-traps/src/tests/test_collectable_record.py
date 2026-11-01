from src.collectable_record import CollectableRecord


class TestCollectableRecord:
    def test_initial_count_is_zero(self):
        record = CollectableRecord()
        assert record.count == 0

    def test_initial_collected_is_zero(self):
        record = CollectableRecord()
        assert record.collected == 0

    def test_initial_score_is_zero(self):
        record = CollectableRecord()
        assert record.score == 0

    def test_record_placed_counts_only_placed_collectable(self):
        record = CollectableRecord()

        record.record_placed()

        assert (record.count, record.collected, record.score) == (1, 0, 0)

    def test_record_collected_counts_collectable_and_adds_score(self):
        record = CollectableRecord()

        record.record_collected(10)
        record.record_collected(30)

        assert (record.count, record.collected, record.score) == (0, 2, 40)

    def test_reset_clears_record(self):
        record = CollectableRecord()
        record.record_placed()
        record.record_collected(10)

        record.reset()

        assert (record.count, record.collected, record.score) == (0, 0, 0)

    def test_add_sums_values_of_other_record(self):
        record = CollectableRecord()
        record.record_placed()
        record.record_placed()
        record.record_collected(10)
        other_record = CollectableRecord()
        other_record.record_placed()
        other_record.record_collected(20)

        record.add(other_record)

        assert (record.count, record.collected, record.score) == (3, 2, 30)
        assert (other_record.count, other_record.collected, other_record.score) == (1, 1, 20)
