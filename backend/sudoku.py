"""
数独游戏后端实现
提供数独生成、验证、求解功能
"""
from typing import List, Tuple, Dict, Optional
import random


def is_valid(board: List[List[int]], row: int, col: int, num: int) -> bool:
    """检查在指定位置放置数字是否有效"""
    # 检查行
    for c in range(9):
        if board[row][c] == num:
            return False
    
    # 检查列
    for r in range(9):
        if board[r][col] == num:
            return False
    
    # 检查3x3宫格
    start_row = (row // 3) * 3
    start_col = (col // 3) * 3
    for r in range(start_row, start_row + 3):
        for c in range(start_col, start_col + 3):
            if board[r][c] == num:
                return False
    
    return True


def solve_sudoku(board: List[List[int]]) -> bool:
    """使用回溯算法求解数独"""
    for row in range(9):
        for col in range(9):
            if board[row][col] == 0:
                for num in range(1, 10):
                    if is_valid(board, row, col, num):
                        board[row][col] = num
                        if solve_sudoku(board):
                            return True
                        board[row][col] = 0
                return False
    return True


def generate_sudoku(difficulty: str = "medium", seed: Optional[int] = None) -> Tuple[List[List[int]], List[List[int]]]:
    """
    生成数独谜题
    Returns: (puzzle, solution)
    - puzzle: 带空格的数独（0表示空格）
    - solution: 完整解答
    """
    rnd = random.Random(seed)
    
    # 先创建一个有效的完整数独
    board = [[0 for _ in range(9)] for _ in range(9)]
    
    # 填充对角线上的3个3x3宫格（它们互不干扰）
    for box in range(3):
        nums = list(range(1, 10))
        rnd.shuffle(nums)
        idx = 0
        for i in range(3):
            for j in range(3):
                row = box * 3 + i
                col = box * 3 + j
                board[row][col] = nums[idx]
                idx += 1
    
    # 求解剩余部分
    solve_sudoku(board)
    solution = [row[:] for row in board]
    
    # 根据难度移除数字
    difficulty_removals = {
        "easy": 35,      # 移除35个数字，留下46个
        "medium": 45,    # 移除45个数字，留下36个
        "hard": 50,      # 移除50个数字，留下31个
        "expert": 55     # 移除55个数字，留下26个
    }
    removals = difficulty_removals.get(difficulty, 45)
    
    # 创建谜题副本
    puzzle = [row[:] for row in board]
    
    # 随机移除数字
    cells = [(r, c) for r in range(9) for c in range(9)]
    rnd.shuffle(cells)
    
    removed = 0
    for row, col in cells:
        if removed >= removals:
            break
        puzzle[row][col] = 0
        removed += 1
    
    return puzzle, solution


def validate_move(puzzle: List[List[int]], row: int, col: int, num: int) -> Dict[str, any]:
    """
    验证移动是否有效
    Returns: {valid: bool, message: str}
    """
    if num < 0 or num > 9:
        return {"valid": False, "message": "数字必须在0-9之间"}
    
    if num == 0:
        return {"valid": True, "message": "清除成功"}
    
    if not is_valid(puzzle, row, col, num):
        return {"valid": False, "message": "该位置不能放置此数字"}
    
    return {"valid": True, "message": "移动有效"}


def check_complete(puzzle: List[List[int]], solution: List[List[int]]) -> Dict[str, any]:
    """
    检查数独是否完成
    Returns: {complete: bool, correct: bool, message: str}
    """
    # 检查是否所有格子都已填充
    for row in range(9):
        for col in range(9):
            if puzzle[row][col] == 0:
                return {
                    "complete": False,
                    "correct": False,
                    "message": "还有空格未填充"
                }
    
    # 检查是否正确
    for row in range(9):
        for col in range(9):
            if puzzle[row][col] != solution[row][col]:
                return {
                    "complete": True,
                    "correct": False,
                    "message": "解答不正确，请检查"
                }
    
    return {
        "complete": True,
        "correct": True,
        "message": "恭喜！解答正确！"
    }


def get_hint(puzzle: List[List[int]], solution: List[List[int]]) -> Optional[Dict[str, int]]:
    """
    获取提示（返回一个空格及其正确答案）
    Returns: {row: int, col: int, value: int} or None
    """
    empty_cells = []
    for row in range(9):
        for col in range(9):
            if puzzle[row][col] == 0:
                empty_cells.append((row, col))
    
    if not empty_cells:
        return None
    
    # 随机选择一个空格
    import random
    row, col = random.choice(empty_cells)
    return {
        "row": row,
        "col": col,
        "value": solution[row][col]
    }

