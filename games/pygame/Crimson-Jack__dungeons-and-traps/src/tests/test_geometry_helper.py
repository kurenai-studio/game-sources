import pygame
import pytest

from src.geometry_helper import GeometryHelper


# Initialise and shut down Pygame around every test so that Vector2 and Rect behave correctly.
@pytest.fixture(autouse=True)
def pygame_init():
    pygame.init()
    yield
    pygame.quit()


class TestCheckIntersectionOfTwoSegments:
    def test_perpendicular_crossing_segments_return_true(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 1), pygame.Vector2(2, 1),
            pygame.Vector2(1, 0), pygame.Vector2(1, 2)
        )
        assert result is True

    def test_parallel_horizontal_segments_return_false(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 0), pygame.Vector2(4, 0),
            pygame.Vector2(0, 2), pygame.Vector2(4, 2)
        )
        assert result is False

    def test_collinear_overlapping_segments_return_false(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 0), pygame.Vector2(2, 0),
            pygame.Vector2(1, 0), pygame.Vector2(3, 0)
        )
        assert result is False

    def test_segments_too_short_to_reach_each_other_return_false(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 1), pygame.Vector2(0.5, 1),
            pygame.Vector2(1, 0), pygame.Vector2(1, 2)
        )
        assert result is False

    def test_endpoint_touching_other_segment_returns_true(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 1), pygame.Vector2(2, 1),
            pygame.Vector2(1, 0), pygame.Vector2(1, 1)
        )
        assert result is True

    def test_diagonal_crossing_segments_return_true(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 0), pygame.Vector2(2, 2),
            pygame.Vector2(2, 0), pygame.Vector2(0, 2)
        )
        assert result is True

    def test_segments_pointing_away_from_each_other_return_false(self):
        result = GeometryHelper.check_intersection_of_two_segments(
            pygame.Vector2(0, 0), pygame.Vector2(1, 0),
            pygame.Vector2(3, 0), pygame.Vector2(4, 0)
        )
        assert result is False


class TestCheckIntersectionOfSegmentWithRectangle:
    RECT = pygame.Rect(10, 10, 20, 20)  # corners: (10,10), (30,10), (30,30), (10,30)

    def test_segment_crossing_rectangle_horizontally_returns_true(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(0, 20), pygame.Vector2(40, 20),
            self.RECT
        )
        assert result is True

    def test_segment_crossing_rectangle_vertically_returns_true(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(20, 0), pygame.Vector2(20, 40),
            self.RECT
        )
        assert result is True

    def test_segment_entirely_outside_rectangle_returns_false(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(0, 0), pygame.Vector2(5, 5),
            self.RECT
        )
        assert result is False

    def test_segment_entirely_inside_rectangle_returns_false(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(15, 15), pygame.Vector2(25, 25),
            self.RECT
        )
        assert result is False

    def test_segment_touching_edge_from_outside_returns_true(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(0, 20), pygame.Vector2(10, 20),
            self.RECT
        )
        assert result is True

    def test_segment_parallel_to_edge_outside_rectangle_returns_false(self):
        result = GeometryHelper.check_intersection_of_segment_with_rectangle(
            pygame.Vector2(0, 5), pygame.Vector2(40, 5),
            self.RECT
        )
        assert result is False
