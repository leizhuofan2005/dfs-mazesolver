import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Bar } from './components/Bar';
import { Controls } from './components/Controls';
import { CellType, Grid } from './types';
import { getDfsAnimations } from './algorithms/quickSort'; // Re-using file for DFS

const App: React.FC = () => {
  const [grid, setGrid] = useState<Grid>([]);
  const [gridSize, setGridSize] = useState<number>(25);
  const [speed, setSpeed] = useState<number>(50);
  const [isSolving, setIsSolving] = useState<boolean>(false);

  // 使用奇数大小的网格以获得更好的迷宫结构
  const effectiveGridSize = useMemo(() => (gridSize % 2 === 0 ? gridSize + 1 : gridSize), [gridSize]);

  const START_NODE = useMemo(() => ({ row: 1, col: 1 }), []);
  const END_NODE = useMemo(() => ({ row: effectiveGridSize - 2, col: effectiveGridSize - 2 }), [effectiveGridSize]);

  const isSolved = useMemo(() => {
    if (!grid.length) return false;
    return grid.flat().some(cell => cell === CellType.CorrectPath);
  }, [grid]);

  const generateMaze = useCallback(() => {
    // 1. 初始化一个填满墙壁的网格
    const newGrid: Grid = Array.from({ length: effectiveGridSize }, () =>
      Array(effectiveGridSize).fill(CellType.Wall)
    );

    // 2. 使用随机深度优先搜索（递归回溯）算法来“雕刻”出一个完美的迷宫
    const stack: { row: number; col: number }[] = [];
    const startCell = { row: 1, col: 1 }; // 从一个角落开始雕刻

    newGrid[startCell.row][startCell.col] = CellType.Path;
    stack.push(startCell);

    while (stack.length > 0) {
      const current = stack[stack.length - 1]; // 查看栈顶元素

      const neighbors = [];
      // 检查距离为2的潜在邻居
      const directions = [[-2, 0], [2, 0], [0, -2], [0, 2]];
      directions.sort(() => Math.random() - 0.5); // 随机打乱方向

      let foundNeighbor = false;
      for (const [dr, dc] of directions) {
        const neighborRow = current.row + dr;
        const neighborCol = current.col + dc;

        if (
          neighborRow > 0 &&
          neighborRow < effectiveGridSize - 1 &&
          neighborCol > 0 &&
          neighborCol < effectiveGridSize - 1 &&
          newGrid[neighborRow][neighborCol] === CellType.Wall
        ) {
          // 移除中间的墙
          newGrid[current.row + dr / 2][current.col + dc / 2] = CellType.Path;
          // 将邻居设为路径
          newGrid[neighborRow][neighborCol] = CellType.Path;
          
          stack.push({ row: neighborRow, col: neighborCol });
          foundNeighbor = true;
          break; // 移动到新的单元格
        }
      }

      if (!foundNeighbor) {
        stack.pop(); // 没有未访问的邻居，回溯
      }
    }

    // 设置起点和终点
    newGrid[START_NODE.row][START_NODE.col] = CellType.Start;
    newGrid[END_NODE.row][END_NODE.col] = CellType.End;

    setGrid(newGrid);
  }, [effectiveGridSize, START_NODE, END_NODE]);

  useEffect(() => {
    generateMaze();
  }, [generateMaze]);

  const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
  
  const resetPath = useCallback(() => {
    if (isSolving) return;
    const newGrid = grid.map(row => row.map(cell => {
      if (cell === CellType.Visited || cell === CellType.CorrectPath) {
        return CellType.Path;
      }
      return cell;
    }));
    setGrid(newGrid);
  }, [grid, isSolving]);

  const visualizeDfs = async () => {
    if (isSolved || isSolving) return;

    setIsSolving(true);
    
    const animations = getDfsAnimations(grid, START_NODE, END_NODE);
    const delay = Math.floor(500 / (speed * 2));

    for (const step of animations) {
      await sleep(delay);
      setGrid(prevGrid => {
        const newGrid = prevGrid.map(row => [...row]);
        newGrid[step.row][step.col] = step.type;
        return newGrid;
      });
    }

    setIsSolving(false);
  };
  
  return (
    <div className="min-h-screen bg-gray-900 text-gray-100 flex flex-col items-center p-4 font-sans">
      <header className="w-full max-w-7xl mb-4">
        <h1 className="text-3xl md:text-4xl font-bold text-cyan-400 text-center tracking-wider">
          深度优先搜索 (DFS) 迷宫寻路
        </h1>
        <p className="text-center text-gray-400 mt-2">
            可视化算法如何通过探索（蓝色）和回溯来找到最优路径（黄色）。
        </p>
      </header>
      
      <Controls
        isSolving={isSolving}
        isSolved={isSolved}
        gridSize={gridSize}
        speed={speed}
        onGenerateMaze={generateMaze}
        onSolve={visualizeDfs}
        onResetPath={resetPath}
        onSizeChange={setGridSize}
        onSpeedChange={setSpeed}
      />

      <div 
        className="w-full max-w-3xl aspect-square grid gap-px bg-gray-700 p-1 rounded-lg border border-gray-600 shadow-lg mt-4"
        style={{ gridTemplateColumns: `repeat(${effectiveGridSize}, 1fr)`}}
      >
        {grid.map((row, rowIndex) => 
            row.map((cellType, colIndex) => (
                <Bar key={`${rowIndex}-${colIndex}`} type={cellType} />
            ))
        )}
      </div>

      <footer className="mt-8 text-center text-gray-500 text-sm">
        <p>
            起点是绿色方块，终点是红色方块。
        </p>
      </footer>
    </div>
  );
};

export default App;