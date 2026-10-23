class Card:
    def __init__(self, colour: str, number: int) -> None:
        self.colour = colour
        self.number = number

    def __str__(self) -> str:
        return self.colour + "," + str(self.number)
