from collections import deque
from typing import List, Tuple, Dict
import random

# Cell values
WALL = 1
PATH = 0

Coordinate = Tuple[int, int]


def _in_bounds(row: int, col: int, size: int) -> bool:
    return 0 <= row < size and 0 <= col < size


def _neighbors_4(row: int, col: int) -> List[Coordinate]:
    return [(row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)]


def _carve_maze_recursive_backtracker(size: int, rnd: random.Random) -> List[List[int]]:
    # Use odd-sized grid; outer border stays walls
    grid = [[WALL for _ in range(size)] for _ in range(size)]
    start = (1, 1)
    stack: List[Coordinate] = [start]
    grid[start[0]][start[1]] = PATH

    while stack:
        r, c = stack[-1]
        dirs = [(-2, 0), (2, 0), (0, -2), (0, 2)]
        rnd.shuffle(dirs)
        moved = False
        for dr, dc in dirs:
            nr, nc = r + dr, c + dc
            if 1 <= nr < size - 1 and 1 <= nc < size - 1 and grid[nr][nc] == WALL:
                grid[r + dr // 2][c + dc // 2] = PATH
                grid[nr][nc] = PATH
                stack.append((nr, nc))
                moved = True
                break
        if not moved:
            stack.pop()
    return grid


def _add_loops(grid: List[List[int]], ratio: float, rnd: random.Random) -> None:
    size = len(grid)
    candidates: List[Coordinate] = []
    for r in range(1, size - 1):
        for c in range(1, size - 1):
            if grid[r][c] == WALL:
                # Opening a wall that sits between two PATH cells horizontally or vertically creates a loop
                if (grid[r - 1][c] == PATH and grid[r + 1][c] == PATH) or (grid[r][c - 1] == PATH and grid[r][c + 1] == PATH):
                    candidates.append((r, c))
    rnd.shuffle(candidates)
    openings = int(len(candidates) * ratio)
    for i in range(openings):
        rr, cc = candidates[i]
        grid[rr][cc] = PATH


def _farthest_point(grid: List[List[int]], start: Coordinate) -> Tuple[Coordinate, Dict[Coordinate, Coordinate]]:
    size = len(grid)
    q = deque([start])
    visited = {start}
    parent: Dict[Coordinate, Coordinate] = {}
    last = start
    while q:
        cur = q.popleft()
        last = cur
        for nr, nc in _neighbors_4(cur[0], cur[1]):
            if _in_bounds(nr, nc, size) and grid[nr][nc] == PATH and (nr, nc) not in visited:
                visited.add((nr, nc))
                parent[(nr, nc)] = cur
                q.append((nr, nc))
    return last, parent


def generate_maze(size: int, difficulty: str = "normal", seed: int | None = None) -> Tuple[List[List[int]], Coordinate, Coordinate]:
    # Ensure odd size for better structure
    if size % 2 == 0:
        size += 1
    rnd = random.Random(seed)
    base = _carve_maze_recursive_backtracker(size, rnd)

    # Difficulty tuning: bigger, more loops, farther endpoints
    loop_ratio = {
        "easy": 0.02,
        "normal": 0.06,
        "hard": 0.12,
        "extreme": 0.2,
    }.get(difficulty, 0.06)

    _add_loops(base, loop_ratio, rnd)

    # Choose endpoints to maximize shortest path length
    start = (1, 1)
    a, _ = _farthest_point(base, start)
    b, _ = _farthest_point(base, a)
    return base, a, b


def bfs_solve(grid: List[List[int]], start: Coordinate, goal: Coordinate) -> Dict[str, List[Dict[str, int]]]:
    size = len(grid)
    q = deque([start])
    visited = {start}
    parent: Dict[Coordinate, Coordinate] = {}
    visit_order: List[Dict[str, int]] = []

    while q:
        r, c = q.popleft()
        visit_order.append({"row": r, "col": c})
        if (r, c) == goal:
            break
        for nr, nc in _neighbors_4(r, c):
            if _in_bounds(nr, nc, size) and grid[nr][nc] == PATH and (nr, nc) not in visited:
                visited.add((nr, nc))
                parent[(nr, nc)] = (r, c)
                q.append((nr, nc))

    # reconstruct
    path: List[Dict[str, int]] = []
    cur = goal
    if cur not in parent and cur != start:
        return {"visited": visit_order, "path": []}
    while cur != start:
        path.append({"row": cur[0], "col": cur[1]})
        cur = parent[cur]
    path.append({"row": start[0], "col": start[1]})
    path.reverse()
    return {"visited": visit_order, "path": path}


