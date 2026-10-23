from random import randint, choice
from enum import Enum
import random
from typing import overload

from pygame import Surface, draw, gfxdraw
import pygame
from pymunk import Body, Segment, Shape, Space, Poly

from game.defines import BACKGROUND, WALL_FILTER
from game.gameObject import GameObject, GameObjectData


MAP_MAX_WIDTH = 23
MAP_MAX_HEIGHT = 17

MAP_MIN_WIDTH = 7
MAP_MIN_HEIGHT = 5

# 地图边距
MARGIN_X = 40
MARGIN_Y = 40

# 地图格子尺寸
PLOT_WIDTH = 50
PLOT_HEIGHT = 50

# 墙的宽度
WALL_WIDTH = 10


class MAP_PLOT_TYPE(Enum):
    MAP_EMPTY = (0,)  # 可移动单元值为0
    MAP_BLOCK = (1,)  # 墙值为1


class WALL_DIRECTION(Enum):
    # 0，1，2，3分别表示左上右下
    WALL_LEFT = (0,)
    WALL_UP = (1,)
    WALL_RIGHT = (2,)
    WALL_DOWN = (3,)


class GameMapData(GameObjectData):
    """
    地图数据类
    """

    __width: int
    __height: int
    __mapData: list[list[MAP_PLOT_TYPE]]

    @property
    def width(self):
        return self.__width

    @property
    def height(self):
        return self.__height

    def __init__(self, width: int, height: int):
        self.__width = width
        self.__height = height
        self.__mapData = [
            [MAP_PLOT_TYPE.MAP_EMPTY for x in range(self.__width)] for y in range(self.__height)
        ]
        self.__doRandomPrim()
        self.__randomDeleteWall()

    def __getitem__(self, index: tuple[int, int]):
        return self.__mapData[index[1]][index[0]]

    def __setitem__(self, index: tuple[int, int], plotType: MAP_PLOT_TYPE):
        self.__mapData[index[1]][index[0]] = plotType

    def resetMap(self, plotType: MAP_PLOT_TYPE):
        for y in range(self.__height):
            for x in range(self.__width):
                self[x, y] = plotType

    def __checkAdjacentPos(
        self, x: int, y: int, width: int, height: int, checklist: list[tuple[int, int]]
    ):
        # 建立方向列表
        directions: list[WALL_DIRECTION] = []
        # 这里的坐标(x,y)以单元格为参考系，从0开始,将对应操作数字存入方向列表
        if x > 0:
            if self[2 * (x - 1) + 1, 2 * y + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                directions.append(WALL_DIRECTION.WALL_LEFT)
        if y > 0:
            if self[2 * x + 1, 2 * (y - 1) + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                directions.append(WALL_DIRECTION.WALL_UP)
        if x < width - 1:
            if self[2 * (x + 1) + 1, 2 * y + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                directions.append(WALL_DIRECTION.WALL_RIGHT)
        if y < height - 1:
            if self[2 * x + 1, 2 * (y + 1) + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                directions.append(WALL_DIRECTION.WALL_DOWN)
        if len(directions):
            # 随机选择方向
            direction = choice(directions)
            if direction == WALL_DIRECTION.WALL_LEFT:
                self[2 * (x - 1) + 1, 2 * y + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                self[2 * x, 2 * y + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                checklist.append((x - 1, y))
            elif direction == WALL_DIRECTION.WALL_UP:
                self[2 * x + 1, 2 * (y - 1) + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                self[2 * x + 1, 2 * y] = MAP_PLOT_TYPE.MAP_EMPTY
                checklist.append((x, y - 1))
            elif direction == WALL_DIRECTION.WALL_RIGHT:
                self[2 * (x + 1) + 1, 2 * y + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                self[2 * x + 2, 2 * y + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                checklist.append((x + 1, y))
            elif direction == WALL_DIRECTION.WALL_DOWN:
                self[2 * x + 1, 2 * (y + 1) + 1] = MAP_PLOT_TYPE.MAP_EMPTY
                self[2 * x + 1, 2 * y + 2] = MAP_PLOT_TYPE.MAP_EMPTY
                checklist.append((x, y + 1))
            return False
        else:
            # 没有找到任何未被访问的元素
            return True

    # Prim算法主函数
    def __randomPrim(self, width: int, height: int):
        # 随机生成起始坐标（以单元格为参考）
        startX, startY = (randint(0, width - 1), randint(0, height - 1))
        # 显示开始的坐标
        # print("start(%d, %d)" % (startX, startY))
        # 初始化起点
        self[2 * startX + 1, 2 * startY + 1] = MAP_PLOT_TYPE.MAP_EMPTY
        # 建立检查清单存放有未被访问过的相邻元素的元素坐标
        checklist = []
        checklist.append((startX, startY))  # 将起点作为一个元素放入清单
        while len(checklist):
            # 随机从列表中选取一个元素
            entry = choice(checklist)
            if self.__checkAdjacentPos(entry[0], entry[1], width, height, checklist):
                # 该元素对应的单元格四周已经没有未被访问的相邻单元格，将该元素从检查清单列表中删除
                checklist.remove(entry)

    def __doRandomPrim(self):
        # 将所有map元素先设置为墙壁
        self.resetMap(MAP_PLOT_TYPE.MAP_BLOCK)
        self.__randomPrim((self.__width - 1) // 2, (self.__height - 1) // 2)

    def __randomDeleteWall(self):
        delNum = randint(1, min(self.__width, self.__height) // 2)
        for _ in range(delNum):
            x = randint(1, self.__width - 2)
            y = randint(1, self.__height - 2)
            while self[x, y] == MAP_PLOT_TYPE.MAP_EMPTY:
                x = randint(1, self.__width - 2)
                y = randint(1, self.__height - 2)
            self[x, y] = MAP_PLOT_TYPE.MAP_EMPTY


class GameMap(GameObject):

    __map: GameMapData

    @property
    def width(self):
        return self.__map.width

    @property
    def height(self):
        return self.__map.height

    @property
    def map(self):
        return self.__map
    
    @map.setter
    def map(self, data: GameMapData):
        self.__map = data
        self.__reGenMapObject()

    def __init__(self, key: str, data: GameMapData):
        super().__init__(key, data)
        self.map = data

        

    def __reGenMapObject(self):
        """
        重新生成地图数据
        """
        self.surface = pygame.Surface(
            (MARGIN_X * 2 + PLOT_WIDTH * self.__map.width, MARGIN_Y * 2 + PLOT_HEIGHT * self.__map.height)
        )
        self.surface.fill(BACKGROUND)

        def __getUpRectPoints(basePoint: tuple[float, float]) -> list[tuple[float, float]]:
            return [
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] - PLOT_HEIGHT / 2),
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] - PLOT_HEIGHT / 2),
            ]

        def __getDownRectPoints(basePoint: tuple[float, float]) -> list[tuple[float, float]]:
            return [
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] + PLOT_HEIGHT / 2),
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] + PLOT_HEIGHT / 2),
            ]

        def __getLeftRectPoints(basePoint: tuple[float, float]) -> list[tuple[float, float]]:
            return [
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
                (basePoint[0] + WALL_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] - PLOT_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] - PLOT_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
            ]

        def __getRightRectPoints(basePoint: tuple[float, float]) -> list[tuple[float, float]]:
            return [
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
                (basePoint[0] - WALL_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] + PLOT_WIDTH / 2, basePoint[1] + WALL_WIDTH / 2),
                (basePoint[0] + PLOT_WIDTH / 2, basePoint[1] - WALL_WIDTH / 2),
            ]

        for x in range(self.width):
            for y in range(self.height):
                if self.__map[x, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                    basePoint = (
                        MARGIN_X + x * PLOT_WIDTH + PLOT_WIDTH / 2,
                        MARGIN_Y + y * PLOT_HEIGHT + PLOT_HEIGHT / 2,
                    )
                    # pygame.draw.circle(self.surface,(255,0,0),basePoint,int(WALL_WIDTH))
                    # 向上
                    if y != 0 and self.__map[x, y - 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                        gfxdraw.filled_polygon(
                            self.surface,
                            __getUpRectPoints(basePoint),
                            (0, 0, 0),
                        )
                    if y != self.height - 1 and self.__map[x, y + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                        gfxdraw.filled_polygon(
                            self.surface,
                            __getDownRectPoints(basePoint),
                            (0, 0, 0),
                        )
                    # 向左
                    if x != 0 and self.__map[x - 1, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                        gfxdraw.filled_polygon(
                            self.surface,
                            __getLeftRectPoints(basePoint),
                            (0, 0, 0),
                        )
                    if x != self.width - 1 and self.__map[x + 1, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                        gfxdraw.filled_polygon(
                            self.surface,
                            __getRightRectPoints(basePoint),
                            (0, 0, 0),
                        )
        self.body = Body(body_type=Body.STATIC)
        self.shapes = []
        for x in range(self.width):
            for y in range(self.height):
                if self.__map[x, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                    basePoint = (
                        MARGIN_X + x * PLOT_WIDTH + PLOT_WIDTH / 2,
                        MARGIN_Y + y * PLOT_HEIGHT + PLOT_HEIGHT / 2,
                    )

                    # 向上
                    if y != 0 and self.__map[x, y - 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                        self.shapes.append(
                            Poly(
                                self.body,
                                [
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] - PLOT_HEIGHT - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] - PLOT_HEIGHT - WALL_WIDTH / 2,
                                    ),
                                ],
                            )
                        )
                    if y != self.height - 1 and self.__map[x, y + 1] == MAP_PLOT_TYPE.MAP_BLOCK:
                        self.shapes.append(
                            Poly(
                                self.body,
                                [
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] + PLOT_HEIGHT + WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] + PLOT_HEIGHT + WALL_WIDTH / 2,
                                    ),
                                ],
                            )
                        )
                    # 向左
                    if x != 0 and self.__map[x - 1, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                        self.shapes.append(
                            Poly(
                                self.body,
                                [
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] - PLOT_WIDTH - WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] - PLOT_WIDTH - WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                ],
                            )
                        )
                    if x != self.width - 1 and self.__map[x + 1, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                        self.shapes.append(
                            Poly(
                                self.body,
                                [
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] - WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + PLOT_WIDTH + WALL_WIDTH / 2,
                                        basePoint[1] - WALL_WIDTH / 2,
                                    ),
                                    (
                                        basePoint[0] + PLOT_WIDTH + WALL_WIDTH / 2,
                                        basePoint[1] + WALL_WIDTH / 2,
                                    ),
                                ],
                            )
                        )
        for shape in self.shapes:
            shape.filter = WALL_FILTER
            shape.elasticity = 1
            shape.friction = 0

    def getPlotPos(self, x: int, y: int):
        return (
            MARGIN_X + x * PLOT_WIDTH + PLOT_WIDTH / 2,
            MARGIN_Y + y * PLOT_HEIGHT + PLOT_HEIGHT / 2,
        )

    def getRandomEmptyMapPos(self):
        while True:
            x = random.randint(1, self.width - 2)
            y = random.randint(1, self.height - 2)
            if self.__map[x, y] == MAP_PLOT_TYPE.MAP_BLOCK:
                continue
            return x,y

    # 绘制迷宫函数
    def render(self, screen: Surface):
        screen.blit(self.surface, (0, 0))

    def getData(self) -> GameObjectData:
        return self.map

    def setData(self, data: GameObjectData):
        assert isinstance(data, GameMapData)
        self.map = data