import pytest

from src.search_path_algorithms.unique_priority_queue import UniquePriorityQueue


class TestUniquePriorityQueueIsEmpty:
    def test_new_queue_is_empty(self):
        queue = UniquePriorityQueue()
        assert queue.is_empty() is True

    def test_not_empty_after_add(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 1.0)
        assert queue.is_empty() is False

    def test_empty_after_add_and_pop(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 1.0)
        queue.pop()
        assert queue.is_empty() is True


class TestUniquePriorityQueueAdd:
    def test_added_item_appears_in_get_items(self):
        queue = UniquePriorityQueue()
        queue.add((1, 2), 5.0)
        assert (1, 2) in queue.get_items()

    def test_duplicate_item_with_higher_priority_is_ignored(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 1.0)
        queue.add((0, 0), 9.0)
        item, priority = queue.pop()
        assert priority == 1.0

    def test_duplicate_item_with_lower_priority_replaces_existing(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 9.0)
        queue.add((0, 0), 1.0)
        item, priority = queue.pop()
        assert priority == 1.0

    def test_multiple_items_all_appear_in_get_items(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 3.0)
        queue.add((1, 1), 1.0)
        queue.add((2, 2), 2.0)
        items = set(queue.get_items())
        assert (0, 0) in items
        assert (1, 1) in items
        assert (2, 2) in items


class TestUniquePriorityQueuePop:
    def test_pop_returns_item_and_priority(self):
        queue = UniquePriorityQueue()
        queue.add((3, 4), 5.0)
        item, priority = queue.pop()
        assert item == (3, 4)
        assert priority == 5.0

    def test_pop_returns_lowest_priority_first(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 3.0)
        queue.add((1, 1), 1.0)
        queue.add((2, 2), 2.0)
        item, priority = queue.pop()
        assert priority == 1.0
        assert item == (1, 1)

    def test_pop_removes_item_from_get_items(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 1.0)
        queue.pop()
        assert (0, 0) not in queue.get_items()

    def test_pop_from_empty_queue_raises_key_error(self):
        queue = UniquePriorityQueue()
        with pytest.raises(KeyError):
            queue.pop()

    def test_pop_order_across_all_items(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 3.0)
        queue.add((1, 1), 1.0)
        queue.add((2, 2), 2.0)
        _, first_priority = queue.pop()
        _, second_priority = queue.pop()
        _, third_priority = queue.pop()
        assert first_priority < second_priority < third_priority


class TestUniquePriorityQueueGetItems:
    def test_returns_empty_when_queue_is_new(self):
        queue = UniquePriorityQueue()
        assert len(queue.get_items()) == 0

    def test_reflects_current_state_after_pop(self):
        queue = UniquePriorityQueue()
        queue.add((0, 0), 1.0)
        queue.add((1, 1), 2.0)
        queue.pop()
        items = set(queue.get_items())
        assert len(items) == 1
        assert (1, 1) in items
