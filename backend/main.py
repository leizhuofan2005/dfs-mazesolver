from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from typing import Literal, List, Dict
import os

from .maze import generate_maze, bfs_solve, WALL, PATH
from .minesweeper import (
    generate_board, calculate_numbers, reveal_cell, toggle_flag, 
    get_board_state, HIDDEN, MINE, FLAGGED
)
from .sorting import bubble_sort_steps, quick_sort_steps, generate_random_array
from .sudoku import generate_sudoku, validate_move, check_complete, get_hint


class MazeRequest(BaseModel):
    size: int = Field(25, ge=5, le=501)
    difficulty: Literal["easy", "normal", "hard", "extreme"] = "hard"
    seed: int | None = None


class SolveRequest(BaseModel):
    grid: List[List[int]]
    start: Dict[str, int]
    goal: Dict[str, int]


class MinesweeperInitRequest(BaseModel):
    rows: int = Field(16, ge=8, le=30)
    cols: int = Field(16, ge=8, le=30)
    num_mines: int = Field(40, ge=10, le=200)
    first_click: Dict[str, int] | None = None
    seed: int | None = None


class MinesweeperClickRequest(BaseModel):
    board: List[List[int]]
    mine_positions: List[List[int]]  # List of [row, col] pairs
    number_board: List[List[int]]
    row: int
    col: int
    rows: int
    cols: int


class MinesweeperFlagRequest(BaseModel):
    board: List[List[int]]
    row: int
    col: int


class SortingRequest(BaseModel):
    algorithm: Literal["bubble", "quick"]
    size: int = Field(20, ge=5, le=100)
    seed: int | None = None


class SudokuGenerateRequest(BaseModel):
    difficulty: Literal["easy", "medium", "hard", "expert"] = "medium"
    seed: int | None = None


class SudokuValidateRequest(BaseModel):
    puzzle: List[List[int]]
    row: int = Field(ge=0, le=8)
    col: int = Field(ge=0, le=8)
    num: int = Field(ge=0, le=9)


class SudokuCheckRequest(BaseModel):
    puzzle: List[List[int]]
    solution: List[List[int]]


class SudokuHintRequest(BaseModel):
    puzzle: List[List[int]]
    solution: List[List[int]]


app = FastAPI(title="Maze BFS API", version="1.0.0")

# CORS配置 - 生产环境应该限制为前端域名
import os
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/maze")
def make_maze(req: MazeRequest):
    grid, start, goal = generate_maze(req.size, req.difficulty, req.seed)
    return {
        "grid": grid,
        "start": {"row": start[0], "col": start[1]},
        "goal": {"row": goal[0], "col": goal[1]},
        "legend": {"WALL": WALL, "PATH": PATH},
    }


@app.post("/bfs")
def make_maze_and_solve(req: MazeRequest):
    grid, start, goal = generate_maze(req.size, req.difficulty, req.seed)
    solved = bfs_solve(grid, start, goal)
    return {
        "grid": grid,
        "start": {"row": start[0], "col": start[1]},
        "goal": {"row": goal[0], "col": goal[1]},
        "visited": solved["visited"],
        "path": solved["path"],
    }


@app.post("/solve")
def solve(req: SolveRequest):
    start = (req.start["row"], req.start["col"])
    goal = (req.goal["row"], req.goal["col"])
    return bfs_solve(req.grid, start, goal)


# Minesweeper endpoints
@app.post("/minesweeper/init")
def init_minesweeper(req: MinesweeperInitRequest):
    """Initialize a new minesweeper game"""
    first_click = None
    if req.first_click:
        first_click = (req.first_click["row"], req.first_click["col"])
    
    board, mine_positions = generate_board(req.rows, req.cols, req.num_mines, first_click, req.seed)
    number_board = calculate_numbers(board, mine_positions, req.rows, req.cols)
    
    # Convert mine_positions set to list for JSON
    mine_list = [[r, c] for r, c in mine_positions]
    
    return {
        "board": board,
        "mine_positions": mine_list,
        "number_board": number_board,
        "rows": req.rows,
        "cols": req.cols
    }


@app.post("/minesweeper/click")
def click_cell(req: MinesweeperClickRequest):
    """Click a cell in minesweeper"""
    mine_positions_set = {(r, c) for r, c in req.mine_positions}
    result = reveal_cell(
        req.board, req.number_board, mine_positions_set,
        req.row, req.col, req.rows, req.cols
    )
    
    # Convert revealed tuples to list format
    revealed_list = [[r, c, num] for r, c, num in result["revealed"]]
    
    return {
        "revealed": revealed_list,
        "game_over": result["game_over"],
        "won": result["won"],
        "board": req.board
    }


@app.post("/minesweeper/flag")
def flag_cell(req: MinesweeperFlagRequest):
    """Toggle flag on a cell"""
    was_flagged = toggle_flag(req.board, req.row, req.col)
    return {
        "board": req.board,
        "flagged": was_flagged
    }


# Sorting endpoints
@app.post("/sorting/generate")
def generate_array(req: SortingRequest):
    """Generate a random array for sorting"""
    arr = generate_random_array(req.size, seed=req.seed)
    return {"array": arr}


@app.post("/sorting/sort")
def sort_array(req: SortingRequest):
    """Sort an array and return animation steps"""
    arr = generate_random_array(req.size, seed=req.seed)
    
    if req.algorithm == "bubble":
        steps = bubble_sort_steps(arr)
    elif req.algorithm == "quick":
        steps = quick_sort_steps(arr)
    else:
        return {"error": "Unknown algorithm"}
    
    return {
        "original": arr,
        "steps": steps,
        "algorithm": req.algorithm
    }


# Sudoku endpoints
@app.post("/sudoku/generate")
def generate_sudoku_puzzle(req: SudokuGenerateRequest):
    """Generate a new sudoku puzzle"""
    puzzle, solution = generate_sudoku(req.difficulty, req.seed)
    return {
        "puzzle": puzzle,
        "solution": solution,
        "difficulty": req.difficulty
    }


@app.post("/sudoku/validate")
def validate_sudoku_move(req: SudokuValidateRequest):
    """Validate a move in sudoku"""
    result = validate_move(req.puzzle, req.row, req.col, req.num)
    return result


@app.post("/sudoku/check")
def check_sudoku_complete(req: SudokuCheckRequest):
    """Check if sudoku is complete and correct"""
    result = check_complete(req.puzzle, req.solution)
    return result


@app.post("/sudoku/hint")
def get_sudoku_hint(req: SudokuHintRequest):
    """Get a hint for the sudoku puzzle"""
    hint = get_hint(req.puzzle, req.solution)
    if hint:
        return hint
    return {"error": "No empty cells"}


# 静态文件服务（用于单服务部署，如 Docker）
# 如果存在 static 目录，则挂载静态文件
static_dir = os.path.join(os.path.dirname(__file__), "..", "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")

