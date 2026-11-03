class GameField:
    def __init__(self):
        self.width = 29
        self.height = 40
        self.map = []
        for i in range(self.height):
            self.map.append([])
            for j in range(self.width):
                self.map[i].append(0)
