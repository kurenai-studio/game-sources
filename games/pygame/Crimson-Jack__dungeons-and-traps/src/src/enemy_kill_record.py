class EnemyKillRecord:
    """
    Enemies of one type on a level, or the sum over levels: how many appeared,
    how many were killed and how many points they gave.
    """

    def __init__(self) -> None:
        """Start with no enemies."""
        self._count = 0
        self._killed = 0
        self._score = 0

    @property
    def count(self) -> int:
        """Number of enemies that appeared."""
        return self._count

    @property
    def killed(self) -> int:
        """Number of enemies the player killed."""
        return self._killed

    @property
    def score(self) -> int:
        """Points given by the killed enemies."""
        return self._score

    def record_spawn(self) -> None:
        """Record one enemy that appeared."""
        self._count += 1

    def record_kill(self, score: int) -> None:
        """
        Record one killed enemy.

        :param score: points of the enemy
        """
        self._killed += 1
        self._score += score

    def reset(self) -> None:
        """Clear the record."""
        self._count = 0
        self._killed = 0
        self._score = 0

    def add(self, other: 'EnemyKillRecord') -> None:
        """Add the values of another record to this one."""
        self._count += other.count
        self._killed += other.killed
        self._score += other.score
