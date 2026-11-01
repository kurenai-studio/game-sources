import heapq
from collections.abc import KeysView


class UniquePriorityQueue:
    """Priority queue that stores each item once and always pops the lowest-priority entry first."""

    def __init__(self) -> None:
        self.heap = []
        self.entry_finder = {}

    def add(self, item: tuple[int, int], priority: float) -> None:
        """
        Add item at the given priority.
        If the item is already present, update its priority only when the new value is lower.

        :param item: tile coordinates
        :param priority: priority value — lower means higher urgency
        """
        if item not in self.entry_finder:
            heapq.heappush(self.heap, (priority, item))
            self.entry_finder[item] = priority
        elif priority < self.entry_finder[item]:
            heapq.heappush(self.heap, (priority, item))
            self.entry_finder[item] = priority

    def pop(self) -> tuple[tuple[int, int], float]:
        """
        Remove and return the item with the lowest priority.

        :return: tuple of (item, priority)
        :raises KeyError: if the queue is empty
        """
        while self.heap:
            priority, item = heapq.heappop(self.heap)
            if self.entry_finder.get(item) == priority:
                del self.entry_finder[item]
                return item, priority
        raise KeyError("Pop from an empty priority queue")

    def is_empty(self) -> bool:
        """
        Return True when no items are queued.

        :return: True if the queue is empty, False otherwise
        """
        return len(self.entry_finder) == 0

    def get_items(self) -> KeysView[tuple[int, int]]:
        """
        Return a view of all currently queued items.

        :return: view of item keys
        """
        return self.entry_finder.keys()
