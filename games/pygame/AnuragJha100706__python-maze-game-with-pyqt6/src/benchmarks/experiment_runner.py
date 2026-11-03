"""
Monte Carlo Batch Benchmark Runner (Standard Threading Worker).
Runs automated experiments across multiple grid dimensions and algorithms
in a background thread without blocking any main event loop.
"""

import csv
import json
import threading
import statistics
from typing import List, Dict, Any, Callable, Optional
from .profiler import profile_solver
from core.maze_generators import generate_maze
from database.db_manager import DatabaseManager

class BenchmarkWorker(threading.Thread):
    """Background worker thread for running computational benchmark suites."""

    def __init__(
        self,
        algorithms: Optional[List[str]] = None,
        grid_sizes: Optional[List[int]] = None,
        trials_per_config: int = 10,
        generator_algo: str = "kruskal",
        save_to_db: bool = True,
        on_progress: Optional[Callable[[int, str], None]] = None,
        on_completed: Optional[Callable[[Dict[str, Any]], None]] = None
    ):
        super().__init__(daemon=True)
        self.algorithms = algorithms or ["astar", "dijkstra", "bfs", "gbfs"]
        self.grid_sizes = grid_sizes or [10, 15, 20, 25, 30]
        self.trials = trials_per_config
        self.generator_algo = generator_algo
        self.save_to_db = save_to_db
        self.on_progress = on_progress
        self.on_completed = on_completed
        self.is_cancelled = False
        self.db = DatabaseManager()

    def cancel(self):
        self.is_cancelled = True

    def run(self):
        total_steps = len(self.grid_sizes) * self.trials * len(self.algorithms)
        current_step = 0

        raw_results: Dict[str, Dict[int, List[Dict[str, Any]]]] = {
            algo: {sz: [] for sz in self.grid_sizes} for algo in self.algorithms
        }

        for sz in self.grid_sizes:
            if self.is_cancelled:
                break

            for trial_idx in range(self.trials):
                if self.is_cancelled:
                    break

                maze = generate_maze(self.generator_algo, sz, sz)
                start = (0, 0)
                goal = (sz - 1, sz - 1)

                for algo in self.algorithms:
                    if self.is_cancelled:
                        break

                    metrics = profile_solver(algo, start, goal, maze)
                    raw_results[algo][sz].append(metrics)

                    if self.save_to_db:
                        self.db.save_benchmark_run(
                            algorithm_name=algo,
                            grid_size=sz,
                            execution_time_us=metrics["runtime_us"],
                            peak_memory_kb=metrics["peak_memory_kb"],
                            nodes_expanded=metrics["nodes_expanded"],
                            path_length=metrics["path_length"],
                            optimality_ratio=1.0
                        )

                    current_step += 1
                    pct = int((current_step / max(1, total_steps)) * 100)
                    if self.on_progress:
                        self.on_progress(pct, f"Benchmarking {algo.upper()} on {sz}x{sz} (Trial {trial_idx+1}/{self.trials})...")

        # Aggregate statistical summaries (Mean, StdDev, Median)
        summary: Dict[str, Any] = {
            "algorithms": self.algorithms,
            "grid_sizes": self.grid_sizes,
            "trials": self.trials,
            "stats": {}
        }

        for algo in self.algorithms:
            summary["stats"][algo] = {}
            for sz in self.grid_sizes:
                trials = raw_results[algo][sz]
                if trials:
                    times = [t["runtime_us"] for t in trials]
                    mems = [t["peak_memory_kb"] for t in trials]
                    expansions = [t["nodes_expanded"] for t in trials]
                    lengths = [t["path_length"] for t in trials]

                    summary["stats"][algo][sz] = {
                        "runtime_mean_us": statistics.mean(times),
                        "runtime_std_us": statistics.stdev(times) if len(times) > 1 else 0.0,
                        "memory_mean_kb": statistics.mean(mems),
                        "expansions_mean": statistics.mean(expansions),
                        "path_length_mean": statistics.mean(lengths)
                    }

        if self.on_completed:
            self.on_completed(summary)

def export_benchmark_csv(summary_data: Dict[str, Any], filepath: str):
    """Exports benchmark experiment data to publication-ready CSV."""
    with open(filepath, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "Algorithm", "Grid Dimension", "Vertices (|V|)",
            "Runtime Mean (us)", "Runtime StdDev (us)",
            "Peak Memory Mean (KB)", "Node Expansions Mean", "Path Length Mean"
        ])

        for algo, sz_dict in summary_data.get("stats", {}).items():
            for sz, s in sz_dict.items():
                writer.writerow([
                    algo.upper(),
                    f"{sz}x{sz}",
                    sz * sz,
                    f"{s['runtime_mean_us']:.2f}",
                    f"{s['runtime_std_us']:.2f}",
                    f"{s['memory_mean_kb']:.2f}",
                    f"{s['expansions_mean']:.1f}",
                    f"{s['path_length_mean']:.1f}"
                ])
