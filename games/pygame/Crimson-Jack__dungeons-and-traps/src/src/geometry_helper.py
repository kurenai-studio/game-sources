import pygame


class GeometryHelper:
    """Collection of static geometry helpers for segment and rectangle intersection tests."""

    @staticmethod
    def check_intersection_of_two_segments(
            a: pygame.Vector2, b: pygame.Vector2,
            c: pygame.Vector2, d: pygame.Vector2) -> bool:
        """
        Check whether segment AB intersects segment CD.

        :param a: start point of the first segment
        :param b: end point of the first segment
        :param c: start point of the second segment
        :param d: end point of the second segment
        :return: True if the segments intersect, False otherwise
        """
        # a + t*ab = c + u*cd
        # t*ab - u*cd = c-a

        # Equations:
        # t*ab.x - u*cd.x = c.x-a.x
        # t*ab.y - u*cd.y = c.y-a.y

        ab_x = b.x - a.x
        ab_y = b.y - a.y
        cd_x = -(d.x - c.x)
        cd_y = -(d.y - c.y)
        ac_x = c.x - a.x
        ac_y = c.y - a.y

        w = ab_x * cd_y - ab_y * cd_x
        if w == 0:
            return False

        w_t = ac_x * cd_y - ac_y * cd_x
        w_u = ab_x * ac_y - ab_y * ac_x

        t = w_t / w
        u = w_u / w

        if 0 <= t <= 1 and 0 <= u <= 1:
            return True
        else:
            return False

    @staticmethod
    def check_intersection_of_segment_with_rectangle(
            start_point: pygame.Vector2,
            end_point: pygame.Vector2,
            rectangle: pygame.Rect) -> bool:
        """
        Check whether a segment intersects any edge of a rectangle.

        :param start_point: start point of the segment
        :param end_point: end point of the segment
        :param rectangle: rectangle to test against
        :return: True if the segment intersects any edge, False otherwise
        """
        vertexes = [
            pygame.Vector2(rectangle.topleft),
            pygame.Vector2(rectangle.topright),
            pygame.Vector2(rectangle.bottomright),
            pygame.Vector2(rectangle.bottomleft)
        ]

        edges = [
            (vertexes[0], vertexes[1]),  # top
            (vertexes[1], vertexes[2]),  # right
            (vertexes[2], vertexes[3]),  # bottom
            (vertexes[3], vertexes[0])   # left
        ]

        # Verify each edge with segment
        for start_vertex, end_vertex in edges:
            intersection = GeometryHelper.check_intersection_of_two_segments(start_point, end_point, start_vertex, end_vertex)
            if intersection:
                return True

        return False
