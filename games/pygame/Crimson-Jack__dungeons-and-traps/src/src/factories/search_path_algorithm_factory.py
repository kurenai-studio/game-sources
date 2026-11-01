from src.enums.search_path_algorithm import SearchPathAlgorithm
from src.search_path_algorithms.breadth_first_search import BreadthFirstSearch
from src.search_path_algorithms.greedy_best_first_search import GreedyBestFirstSearch


class SearchPathAlgorithmFactory:
    @staticmethod
    def create(search_path_algorithm_name: SearchPathAlgorithm):
        if search_path_algorithm_name == SearchPathAlgorithm.BREADTH_FIRST_SEARCH:
            return BreadthFirstSearch()
        elif search_path_algorithm_name == SearchPathAlgorithm.GREEDY_BEST_FIRST_SEARCH:
            return GreedyBestFirstSearch()
        else:
            raise ValueError(f'Unknown algorithm name: {search_path_algorithm_name}')
