class CollectableRecord:
    """
    Collectables of one kind on a level, or the sum over levels: how many were placed,
    how many were collected and how many points they gave.
    """

    def __init__(self) -> None:
        """Start with nothing placed or collected."""
        self._count = 0
        self._collected = 0
        self._score = 0

    @property
    def count(self) -> int:
        """Number of collectables placed on the map."""
        return self._count

    @property
    def collected(self) -> int:
        """Number of collectables the player collected."""
        return self._collected

    @property
    def score(self) -> int:
        """Points given by the collected collectables."""
        return self._score

    def record_placed(self) -> None:
        """Record one collectable placed on the map."""
        self._count += 1

    def record_collected(self, score: int) -> None:
        """
        Record one collected collectable.

        :param score: points of the collectable
        """
        self._collected += 1
        self._score += score

    def reset(self) -> None:
        """Clear the record."""
        self._count = 0
        self._collected = 0
        self._score = 0

    def add(self, other: 'CollectableRecord') -> None:
        """Add the values of another record to this one."""
        self._count += other.count
        self._collected += other.collected
        self._score += other.score
