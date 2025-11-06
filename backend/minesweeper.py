from typing import List, Tuple, Dict, Set
import random

# Cell states
HIDDEN = -1
MINE = -2
FLAGGED = -3
REVEALED = 0  # 0-8 for number of adjacent mines

Coordinate = Tuple[int, int]


def _neighbors_8(row: int, col: int, rows: int, cols: int) -> List[Coordinate]:
    """Get all 8 neighbors of a cell"""
    neighbors = []
    for dr in [-1, 0, 1]:
        for dc in [-1, 0, 1]:
            if dr == 0 and dc == 0:
                continue
            nr, nc = row + dr, col + dc
            if 0 <= nr < rows and 0 <= nc < cols:
                neighbors.append((nr, nc))
    return neighbors


def generate_board(rows: int, cols: int, num_mines: int, first_click: Coordinate | None = None, seed: int | None = None) -> Tuple[List[List[int]], Set[Coordinate]]:
    """
    Generate a minesweeper board
    Returns: (board, mine_positions)
    - board: 2D list where -1=hidden, -2=mine, -3=flagged, 0-8=revealed with count
    - mine_positions: set of (row, col) tuples where mines are placed
    """
    rnd = random.Random(seed)
    board = [[HIDDEN for _ in range(cols)] for _ in range(rows)]
    mine_positions: Set[Coordinate] = set()
    
    # Place mines, avoiding first click
    safe_cells = set()
    if first_click:
        safe_cells.add(first_click)
        for nr, nc in _neighbors_8(first_click[0], first_click[1], rows, cols):
            safe_cells.add((nr, nc))
    
    all_cells = [(r, c) for r in range(rows) for c in range(cols)]
    available = [cell for cell in all_cells if cell not in safe_cells]
    rnd.shuffle(available)
    
    for i in range(min(num_mines, len(available))):
        mine_positions.add(available[i])
    
    return board, mine_positions


def calculate_numbers(board: List[List[int]], mine_positions: Set[Coordinate], rows: int, cols: int) -> List[List[int]]:
    """Calculate numbers for each cell based on adjacent mines"""
    number_board = [[0 for _ in range(cols)] for _ in range(rows)]
    
    for r in range(rows):
        for c in range(cols):
            if (r, c) in mine_positions:
                number_board[r][c] = MINE
            else:
                count = sum(1 for nr, nc in _neighbors_8(r, c, rows, cols) if (nr, nc) in mine_positions)
                number_board[r][c] = count
    
    return number_board


def reveal_cell(board: List[List[int]], number_board: List[List[int]], mine_positions: Set[Coordinate], 
                row: int, col: int, rows: int, cols: int) -> Dict[str, any]:
    """
    Reveal a cell and auto-reveal neighbors if it's a zero
    Returns: {
        'revealed': [(row, col, number), ...],
        'game_over': bool,
        'won': bool
    }
    """
    if board[row][col] != HIDDEN and board[row][col] != FLAGGED:
        return {'revealed': [], 'game_over': False, 'won': False}
    
    if (row, col) in mine_positions:
        # Game over - reveal all mines
        revealed = [(r, c, MINE) for r, c in mine_positions]
        return {'revealed': revealed, 'game_over': True, 'won': False}
    
    # Reveal this cell and neighbors if zero
    revealed: List[Tuple[int, int, int]] = []
    to_reveal = [(row, col)]
    visited = set()
    
    while to_reveal:
        r, c = to_reveal.pop(0)
        if (r, c) in visited:
            continue
        visited.add((r, c))
        
        if board[r][c] == FLAGGED:
            continue
            
        num = number_board[r][c]
        board[r][c] = num
        revealed.append((r, c, num))
        
        # If zero, reveal all neighbors
        if num == 0:
            for nr, nc in _neighbors_8(r, c, rows, cols):
                if (nr, nc) not in visited and board[nr][nc] == HIDDEN:
                    to_reveal.append((nr, nc))
    
    # Check if won
    total_cells = rows * cols
    revealed_count = sum(1 for row in board for cell in row if cell >= 0)
    won = revealed_count == (total_cells - len(mine_positions))
    
    return {'revealed': revealed, 'game_over': False, 'won': won}


def toggle_flag(board: List[List[int]], row: int, col: int) -> bool:
    """Toggle flag on a cell. Returns True if flagged, False if unflagged"""
    if board[row][col] == HIDDEN:
        board[row][col] = FLAGGED
        return True
    elif board[row][col] == FLAGGED:
        board[row][col] = HIDDEN
        return False
    return False


def get_board_state(board: List[List[int]], mine_positions: Set[Coordinate], 
                    rows: int, cols: int, game_over: bool = False) -> List[List[Dict[str, any]]]:
    """
    Convert board to frontend-friendly format
    Returns: 2D list of {state, number, isMine}
    """
    result = []
    for r in range(rows):
        row = []
        for c in range(cols):
            cell_state = board[r][c]
            is_mine = (r, c) in mine_positions
            number = cell_state if cell_state >= 0 else None
            
            if game_over and is_mine:
                state = 'mine'
            elif cell_state == FLAGGED:
                state = 'flagged'
            elif cell_state == HIDDEN:
                state = 'hidden'
            else:
                state = 'revealed'
            
            row.append({
                'state': state,
                'number': number,
                'isMine': is_mine
            })
        result.append(row)
    return result

