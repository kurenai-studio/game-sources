class ColorSet:
    COLORS = [
        ((0, 100), (0, 0, 0))
    ]

    def __init__(self, colors=None):
        if colors is None:
            colors = self.COLORS

        self.colors = colors

    def get_color(self, percent):
        # Find a range
        list_result = list(filter(lambda item: item[0][1] >= percent >= item[0][0], self.colors))

        # Check if it exists
        if len(list_result) == 0:
            if percent < 0:
                # Set the first range
                item_result = ColorSet.COLORS[0]
            else:
                # Set the last range
                item_result = ColorSet.COLORS[len(ColorSet.COLORS) - 1]
        else:
            # Percent range exists
            item_result = list_result[0]

        # Return rgb color from the range
        return item_result[1]
