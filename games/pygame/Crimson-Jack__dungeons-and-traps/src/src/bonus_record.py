class BonusRecord:
    """Bonus of a level, or the sum over levels: how many times it was awarded and how many points it gave."""

    def __init__(self) -> None:
        """Start with no bonus awarded."""
        self._awarded = 0
        self._score = 0

    @property
    def awarded(self) -> int:
        """Number of times the bonus was awarded."""
        return self._awarded

    @property
    def score(self) -> int:
        """Points given by the bonus."""
        return self._score

    def record_award(self, score: int) -> None:
        """
        Record one awarded bonus.

        :param score: points of the bonus
        """
        self._awarded += 1
        self._score += score

    def reset(self) -> None:
        """Clear the record."""
        self._awarded = 0
        self._score = 0

    def add(self, other: 'BonusRecord') -> None:
        """Add the values of another record to this one."""
        self._awarded += other.awarded
        self._score += other.score
