from src.effects.tilt_effect import TiltEffect


def collect_offsets(tilt_effect, number_of_frames):
    offsets = []
    for _frame in range(number_of_frames):
        offset = tilt_effect.next_offset()
        offsets.append(None if offset is None else offset.y)
    return offsets


class TestTiltEffect:
    def test_returns_no_offset_when_not_enabled(self):
        assert TiltEffect().next_offset() is None

    def test_base_speed_repeats_offsets_by_cursor_integer_part(self):
        tilt_effect = TiltEffect()
        tilt_effect.enable()

        # Cursor moves 0 → 0.75 → 1.5 → 2.25, and the offset index is its integer part
        assert collect_offsets(tilt_effect, 4) == [-25, -25, 20, -15]

    def test_speed_one_returns_whole_sequence_then_no_offset(self):
        tilt_effect = TiltEffect()
        tilt_effect.enable(1)

        number_of_offsets = len(TiltEffect.OFFSET_VALUES)
        assert collect_offsets(tilt_effect, number_of_offsets + 2) == list(TiltEffect.OFFSET_VALUES) + [None, None]

    def test_enabling_again_after_finish_starts_from_beginning(self):
        tilt_effect = TiltEffect()
        tilt_effect.enable(1)
        collect_offsets(tilt_effect, len(TiltEffect.OFFSET_VALUES) + 1)

        tilt_effect.enable(1)

        assert collect_offsets(tilt_effect, 2) == [-25, 20]

    def test_enable_without_speed_restores_base_speed(self):
        tilt_effect = TiltEffect()
        tilt_effect.enable(1)
        tilt_effect.enable()

        assert collect_offsets(tilt_effect, 3) == [-25, -25, 20]
