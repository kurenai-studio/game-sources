import random
from typing import Callable, Iterable


def generateUniqueNumbers(
    num: int, minValue: float, maxValue: float, predicate: Callable[[float], bool] | None = None
) -> Iterable[float]:
    numbers: set[float] = set()

    while len(numbers) < num:
        x = random.uniform(minValue, maxValue)
        if predicate is None or predicate(x):
            numbers.add(x)

    return numbers


def generateUniquePoints(
    num: int,
    xRange: tuple[float, float],
    yRange: tuple[float, float],
    predicate: Callable[[float, float], bool] | None = None,
) -> Iterable[tuple[float, float]]:
    points: set[tuple[float, float]] = set()

    while len(points) < num:
        x = random.uniform(xRange[0], xRange[1])
        y = random.uniform(yRange[0], yRange[1])
        if predicate is None or predicate(x, y):
            points.add((x, y))

    return points
