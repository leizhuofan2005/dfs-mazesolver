import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Bar } from './components/Bar';
import { Controls } from './components/Controls';
import { Minesweeper } from './components/Minesweeper';
import { Sorting } from './components/Sorting';
import { Sudoku } from './components/Sudoku';
import { CellType, Grid } from './types';
import { API_URL } from './src/config';

type TabType = 'maze' | 'minesweeper' | 'sorting' | 'sudoku';

const MazeView: React.FC = () => {
  const [grid, setGrid] = useState<Grid>([]);
  const [gridSize, setGridSize] = useState<number>(25);
  const [speed, setSpeed] = useState<number>(50);
  const [difficulty, setDifficulty] = useState<'easy' | 'normal' | 'hard' | 'extreme'>('hard');
  const [isSolving, setIsSolving] = useState<boolean>(false);

  const effectiveGridSize = useMemo(() => (gridSize % 2 === 0 ? gridSize + 1 : gridSize), [gridSize]);

  const [startNode, setStartNode] = useState<{ row: number; col: number }>({ row: 1, col: 1 });
  const [endNode, setEndNode] = useState<{ row: number; col: number }>({ row: effectiveGridSize - 2, col: effectiveGridSize - 2 });

  const isSolved = useMemo(() => {
    if (!grid.length) return false;
    return grid.flat().some(cell => cell === CellType.CorrectPath);
  }, [grid]);

  const mapBackendGrid = (raw: number[][], start: {row: number; col: number}, goal: {row: number; col: number}): Grid => {
    const g: Grid = raw.map(row => row.map(cell => (cell === 1 ? CellType.Wall : CellType.Path)));
    g[start.row][start.col] = CellType.Start;
    g[goal.row][goal.col] = CellType.End;
    return g;
  };

  const generateMaze = useCallback(async () => {
    // 生成新迷宫时，清除之前的搜索痕迹
    setIsSolving(false);
    const resp = await fetch(`${API_URL}/maze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ size: effectiveGridSize, difficulty })
    });
    const data = await resp.json();
    const start = { row: data.start.row, col: data.start.col };
    const goal = { row: data.goal.row, col: data.goal.col };
    setStartNode(start);
    setEndNode(goal);
    setGrid(mapBackendGrid(data.grid, start, goal));
  }, [effectiveGridSize, difficulty]);

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

  const visualizeBfs = async () => {
    if (isSolved || isSolving || grid.length === 0) return;
    setIsSolving(true);
    
    // 将当前前端网格转换为后端格式
    const backendGrid: number[][] = grid.map(row => 
      row.map(cell => {
        if (cell === CellType.Wall) return 1;
        return 0;
      })
    );
    
    // 使用当前迷宫进行搜索，不重新生成
    const resp = await fetch(`${API_URL}/solve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        grid: backendGrid,
        start: startNode,
        goal: endNode
      })
    });
    const data = await resp.json();
    const visited: {row: number; col: number}[] = data.visited;
    const path: {row: number; col: number}[] = data.path;
    const delay = Math.floor(500 / (speed * 2));

    // 重置网格，清除之前的搜索痕迹
    const baseGrid = grid.map(row => row.map(cell => {
      if (cell === CellType.Visited || cell === CellType.CorrectPath) {
        return CellType.Path;
      }
      return cell;
    }));
    setGrid(baseGrid);

    // 显示搜索过程
    for (const v of visited) {
      await sleep(delay);
      setGrid(prev => {
        const next = prev.map(row => [...row]);
        const current = next[v.row][v.col];
        if (current !== CellType.Start && current !== CellType.End && current !== CellType.Wall) {
          next[v.row][v.col] = CellType.Visited;
        }
        return next;
      });
    }
    
    // 显示最终路径
    for (const p of path) {
      await sleep(delay);
      setGrid(prev => {
        const next = prev.map(row => [...row]);
        const current = next[p.row][p.col];
        if (current !== CellType.Start && current !== CellType.End && current !== CellType.Wall) {
          next[p.row][p.col] = CellType.CorrectPath;
        }
        return next;
      });
    }
    setIsSolving(false);
  };
  
  return (
    <>
      <Controls
        isSolving={isSolving}
        isSolved={isSolved}
        gridSize={gridSize}
        speed={speed}
        difficulty={difficulty}
        onGenerateMaze={generateMaze}
        onSolve={visualizeBfs}
        onResetPath={resetPath}
        onSizeChange={setGridSize}
        onSpeedChange={setSpeed}
        onDifficultyChange={setDifficulty}
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
        <p>起点是绿色方块，终点是红色方块。</p>
      </footer>
    </>
  );
};

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('maze');

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100 flex flex-col items-center p-4 font-sans">
      <header className="w-full max-w-7xl mb-4">
        <h1 className="text-3xl md:text-4xl font-bold text-cyan-400 text-center tracking-wider">
          算法游戏集合
        </h1>
        <p className="text-center text-gray-400 mt-2">
          广度优先搜索迷宫寻路 & 扫雷游戏
        </p>
      </header>

      {/* Tab Navigation */}
      <div className="w-full max-w-4xl mb-6 flex gap-4 justify-center flex-wrap">
        <button
          onClick={() => setActiveTab('maze')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'maze'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          迷宫寻路 (BFS)
        </button>
        <button
          onClick={() => setActiveTab('minesweeper')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'minesweeper'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          扫雷游戏
        </button>
        <button
          onClick={() => setActiveTab('sorting')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'sorting'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          排序算法
        </button>
        <button
          onClick={() => setActiveTab('sudoku')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'sudoku'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          数独游戏
        </button>
      </div>

      {/* Tab Content */}
      <div className="w-full max-w-7xl">
        {activeTab === 'maze' && (
          <div className="flex flex-col items-center">
            <h2 className="text-2xl font-bold text-cyan-400 mb-4">
              广度优先搜索 (BFS) 迷宫寻路（后端计算）
            </h2>
            <p className="text-center text-gray-400 mb-4">
              可视化算法如何通过探索（蓝色）和回溯来找到最优路径（黄色）。
            </p>
            <MazeView />
          </div>
        )}

        {activeTab === 'minesweeper' && (
          <div className="flex flex-col items-center">
            <h2 className="text-2xl font-bold text-cyan-400 mb-4">
              扫雷游戏（后端计算）
            </h2>
            <p className="text-center text-gray-400 mb-4">
              经典的扫雷游戏，使用后端 Python 计算逻辑
            </p>
            <Minesweeper rows={16} cols={16} numMines={40} />
          </div>
        )}

        {activeTab === 'sorting' && <SortingView />}

        {activeTab === 'sudoku' && (
          <div className="flex flex-col items-center">
            <h2 className="text-2xl font-bold text-cyan-400 mb-4">
              数独游戏（后端计算）
            </h2>
            <p className="text-center text-gray-400 mb-4">
              经典数独游戏，使用后端 Python 生成和验证
            </p>
            <Sudoku />
          </div>
        )}
      </div>
    </div>
  );
};

const SortingView: React.FC = () => {
  const [selectedAlgorithm, setSelectedAlgorithm] = useState<'bubble' | 'quick'>('bubble');

  return (
    <div className="flex flex-col items-center">
      <h2 className="text-2xl font-bold text-cyan-400 mb-4">
        排序算法可视化（后端计算）
      </h2>
      <p className="text-center text-gray-400 mb-4">
        可视化冒泡排序和快速排序算法
      </p>
      <div className="w-full mb-4 flex gap-4 justify-center">
        <button
          onClick={() => setSelectedAlgorithm('bubble')}
          className={`px-4 py-2 rounded-md transition-colors ${
            selectedAlgorithm === 'bubble'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          冒泡排序
        </button>
        <button
          onClick={() => setSelectedAlgorithm('quick')}
          className={`px-4 py-2 rounded-md transition-colors ${
            selectedAlgorithm === 'quick'
              ? 'bg-cyan-600 text-white'
              : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
          }`}
        >
          快速排序
        </button>
      </div>
      <Sorting algorithm={selectedAlgorithm} />
    </div>
  );
};

export default App;
