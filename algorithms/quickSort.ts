import { Grid, CellType, AnimationStep } from '../types';

export const getDfsAnimations = (
  grid: Grid,
  startNode: { row: number; col: number },
  endNode: { row: number; col: number }
): AnimationStep[] => {
  const animations: AnimationStep[] = [];
  const visited = new Set<string>();
  const path: { row: number; col: number }[] = [];
  const found = { value: false };

  dfs(startNode.row, startNode.col, grid, visited, animations, path, endNode, found);

  return animations;
};

function dfs(
  row: number,
  col: number,
  grid: Grid,
  visited: Set<string>,
  animations: AnimationStep[],
  path: { row: number; col: number }[],
  endNode: { row: number; col: number },
  found: { value: boolean }
) {
  if (
    row < 0 ||
    row >= grid.length ||
    col < 0 ||
    col >= grid[0].length ||
    visited.has(`${row}-${col}`) ||
    grid[row][col] === CellType.Wall ||
    found.value
  ) {
    return;
  }

  visited.add(`${row}-${col}`);
  path.push({ row, col });
  
  if (grid[row][col] !== CellType.Start && grid[row][col] !== CellType.End) {
      animations.push({ row, col, type: CellType.Visited });
  }


  if (row === endNode.row && col === endNode.col) {
    found.value = true;
    // Animate the correct path
    for (const p of path) {
        if (grid[p.row][p.col] !== CellType.Start && grid[p.row][p.col] !== CellType.End) {
             animations.push({ row: p.row, col: p.col, type: CellType.CorrectPath });
        }
    }
    return;
  }

  // Explore neighbors: Down, Right, Up, Left
  const directions = [[1, 0], [0, 1], [-1, 0], [0, -1]];
  for(const [dr, dc] of directions) {
      if (!found.value) {
        dfs(row + dr, col + dc, grid, visited, animations, path, endNode, found);
      }
  }

  path.pop();
}
