from src.bonus_record import BonusRecord


class TestBonusRecord:
    def test_initial_awarded_is_zero(self):
        record = BonusRecord()
        assert record.awarded == 0

    def test_initial_score_is_zero(self):
        record = BonusRecord()
        assert record.score == 0

    def test_record_award_counts_award_and_adds_score(self):
        record = BonusRecord()

        record.record_award(500)
        record.record_award(300)

        assert (record.awarded, record.score) == (2, 800)

    def test_reset_clears_record(self):
        record = BonusRecord()
        record.record_award(500)

        record.reset()

        assert (record.awarded, record.score) == (0, 0)

    def test_add_sums_values_of_other_record(self):
        record = BonusRecord()
        record.record_award(500)
        other_record = BonusRecord()
        other_record.record_award(300)

        record.add(other_record)

        assert (record.awarded, record.score) == (2, 800)
        assert (other_record.awarded, other_record.score) == (1, 300)
