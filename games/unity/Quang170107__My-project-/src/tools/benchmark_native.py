"""
Geometric Dungeon - Native Plugin Performance Benchmark (Python + CTypes)
Compares C++ Native Spatial Hash Grid against Managed O(N^2) search.
"""

import ctypes
import os
import random
import time

DLL_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Assets", "Plugins", "x86_64", "NativeRoguelikeCore.dll"))

def run_benchmark():
    print("=" * 65)
    print("Benchmarking C++ NativeRoguelikeCore.dll vs Brute-force O(N^2)")
    print(f"Loading DLL: {DLL_PATH}")
    print("=" * 65)

    if not os.path.exists(DLL_PATH):
        print(f"Error: DLL not found at {DLL_PATH}")
        return

    lib = ctypes.CDLL(DLL_PATH)
    ver = lib.Native_GetVersion()
    print(f"Native Library Version: {ver}")

    # Set up argument types
    lib.Native_SpatialGrid_Init.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.Native_SpatialGrid_Clear.argtypes = []
    lib.Native_SpatialGrid_Insert.argtypes = [ctypes.c_int, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_int]
    lib.Native_SpatialGrid_QueryRadius.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_float), ctypes.c_int]
    lib.Native_SpatialGrid_QueryRadius.restype = ctypes.c_int

    # Test parameters: 500 entities, 1000 queries
    entity_count = 500
    query_count = 1000
    radius = 3.5

    random.seed(42)
    entities = [(i, random.uniform(-20, 20), random.uniform(-15, 15), 0.5) for i in range(entity_count)]
    queries = [(random.uniform(-15, 15), random.uniform(-10, 10)) for _ in range(query_count)]

    # 1. Native Spatial Grid
    lib.Native_SpatialGrid_Init(-25.0, -20.0, 25.0, 20.0, 2.5)
    lib.Native_SpatialGrid_Clear()

    t0 = time.perf_counter()
    for eid, x, y, r in entities:
        lib.Native_SpatialGrid_Insert(eid, x, y, r, 0)

    out_ids = (ctypes.c_int * 64)()
    out_dist = (ctypes.c_float * 64)()

    native_total_found = 0
    for qx, qy in queries:
        found = lib.Native_SpatialGrid_QueryRadius(qx, qy, radius, out_ids, out_dist, 64)
        native_total_found += found
    t1 = time.perf_counter()
    native_time_ms = (t1 - t0) * 1000.0

    # 2. Brute-force O(N^2)
    t2 = time.perf_counter()
    brute_total_found = 0
    rad_sq = radius * radius
    for qx, qy in queries:
        for eid, ex, ey, er in entities:
            dx = ex - qx
            dy = ey - qy
            tot_r = radius + er
            if (dx * dx + dy * dy) <= (tot_r * tot_r):
                brute_total_found += 1
    t3 = time.perf_counter()
    brute_time_ms = (t3 - t2) * 1000.0

    print(f"Entities: {entity_count} | Queries: {query_count} (radius={radius}m)")
    print(f"C++ Native Spatial Hash Grid: {native_time_ms:.2f} ms (results: {native_total_found})")
    print(f"Brute Force O(N*Q):           {brute_time_ms:.2f} ms (results: {brute_total_found})")
    speedup = brute_time_ms / max(0.001, native_time_ms)
    print(f"Speedup Factor:               {speedup:.1f}x FASTER!")
    print("=" * 65)

if __name__ == "__main__":
    run_benchmark()
