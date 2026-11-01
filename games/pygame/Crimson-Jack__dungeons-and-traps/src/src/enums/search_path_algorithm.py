from enum import StrEnum


class SearchPathAlgorithm(StrEnum):
    BREADTH_FIRST_SEARCH = 'BFS'
    GREEDY_BEST_FIRST_SEARCH = 'GBFS'