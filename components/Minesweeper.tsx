import React, { useState, useEffect, useCallback } from 'react';
import { API_URL } from '../src/config';

interface CellData {
  state: 'hidden' | 'revealed' | 'flagged' | 'mine';
  number: number | null;
  isMine: boolean;
}

interface MinesweeperProps {
  rows: number;
  cols: number;
  numMines: number;
}

export const Minesweeper: React.FC<MinesweeperProps> = ({ rows, cols, numMines }) => {
  const [board, setBoard] = useState<CellData[][]>([]);
  const [gameOver, setGameOver] = useState(false);
  const [won, setWon] = useState(false);
  const [minesRemaining, setMinesRemaining] = useState(numMines);
  const [firstClick, setFirstClick] = useState<{ row: number; col: number } | null>(null);
  const [backendBoard, setBackendBoard] = useState<number[][]>([]);
  const [minePositions, setMinePositions] = useState<number[][]>([]);
  const [numberBoard, setNumberBoard] = useState<number[][]>([]);

  const initGame = useCallback(async (firstClickPos: { row: number; col: number } | null = null) => {
    try {
      const resp = await fetch(`${API_URL}/minesweeper/init`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          rows,
          cols,
          num_mines: numMines,
          first_click: firstClickPos,
        })
      });
      const data = await resp.json();
      
      setBackendBoard(data.board);
      setMinePositions(data.mine_positions);
      setNumberBoard(data.number_board);
      
      // Convert to frontend format
      const frontendBoard: CellData[][] = [];
      for (let r = 0; r < rows; r++) {
        const row: CellData[] = [];
        for (let c = 0; c < cols; c++) {
          const cell = data.board[r][c];
          row.push({
            state: cell === -3 ? 'flagged' : 'hidden',
            number: null,
            isMine: false
          });
        }
        frontendBoard.push(row);
      }
      setBoard(frontendBoard);
      setGameOver(false);
      setWon(false);
      setMinesRemaining(numMines);
      setFirstClick(null);
    } catch (error) {
      console.error('Failed to initialize game:', error);
    }
  }, [rows, cols, numMines]);

  // 初始化时只创建空棋盘，不生成雷区
  useEffect(() => {
    const emptyBoard: CellData[][] = [];
    for (let r = 0; r < rows; r++) {
      const row: CellData[] = [];
      for (let c = 0; c < cols; c++) {
        row.push({
          state: 'hidden',
          number: null,
          isMine: false
        });
      }
      emptyBoard.push(row);
    }
    setBoard(emptyBoard);
    setGameOver(false);
    setWon(false);
    setMinesRemaining(numMines);
    setFirstClick(null);
    setBackendBoard([]);
    setMinePositions([]);
    setNumberBoard([]);
  }, [rows, cols, numMines]);

  const handleCellClick = async (row: number, col: number, isRightClick: boolean = false) => {
    if (gameOver || won || board.length === 0) return;
    
    if (isRightClick) {
      // Right click to toggle flag
      if (board[row][col].state === 'revealed') return;
      
      // 如果棋盘未初始化，只在前端标记，不调用后端
      if (backendBoard.length === 0) {
        const newBoard = board.map(r => [...r]);
        const wasFlagged = newBoard[row][col].state === 'flagged';
        newBoard[row][col].state = wasFlagged ? 'hidden' : 'flagged';
        setBoard(newBoard);
        setMinesRemaining(prev => wasFlagged ? prev + 1 : prev - 1);
        return;
      }
      
      try {
        const resp = await fetch(`${API_URL}/minesweeper/flag`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            board: backendBoard,
            row,
            col
          })
        });
        const data = await resp.json();
        setBackendBoard(data.board);
        
        const newBoard = board.map(r => [...r]);
        const wasFlagged = newBoard[row][col].state === 'flagged';
        newBoard[row][col].state = wasFlagged ? 'hidden' : 'flagged';
        setBoard(newBoard);
        setMinesRemaining(prev => wasFlagged ? prev + 1 : prev - 1);
      } catch (error) {
        console.error('Failed to flag cell:', error);
      }
      return;
    }

    // Left click
    if (board[row][col].state === 'flagged' || board[row][col].state === 'revealed') return;

    // First click - initialize game with safe first click
    if (firstClick === null || backendBoard.length === 0) {
      setFirstClick({ row, col });
      // Initialize game with safe first click, then reveal it
      try {
        const resp = await fetch(`${API_URL}/minesweeper/init`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            rows,
            cols,
            num_mines: numMines,
            first_click: { row, col },
          })
        });
        const data = await resp.json();
        
        setBackendBoard(data.board);
        setMinePositions(data.mine_positions);
        setNumberBoard(data.number_board);
        
        // Convert to frontend format
        const frontendBoard: CellData[][] = [];
        for (let r = 0; r < rows; r++) {
          const row: CellData[] = [];
          for (let c = 0; c < cols; c++) {
            const cell = data.board[r][c];
            row.push({
              state: cell === -3 ? 'flagged' : 'hidden',
              number: null,
              isMine: false
            });
          }
          frontendBoard.push(row);
        }
        setBoard(frontendBoard);
        
        // Now click the first cell
        const clickResp = await fetch(`${API_URL}/minesweeper/click`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            board: data.board,
            mine_positions: data.mine_positions,
            number_board: data.number_board,
            row,
            col,
            rows,
            cols
          })
        });
        const clickData = await clickResp.json();
        setBackendBoard(clickData.board);
        
        if (clickData.game_over) {
          setGameOver(true);
          const newBoard = frontendBoard.map(r => [...r]);
          for (const [r, c, num] of clickData.revealed) {
            newBoard[r][c] = {
              state: 'mine',
              number: null,
              isMine: true
            };
          }
          setBoard(newBoard);
        } else {
          const newBoard = frontendBoard.map(r => [...r]);
          for (const [r, c, num] of clickData.revealed) {
            newBoard[r][c] = {
              state: 'revealed',
              number: num,
              isMine: false
            };
          }
          setBoard(newBoard);
          
          if (clickData.won) {
            setWon(true);
          }
        }
      } catch (error) {
        console.error('Failed to initialize game:', error);
      }
      return;
    }

    try {
      const resp = await fetch(`${API_URL}/minesweeper/click`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          board: backendBoard,
          mine_positions: minePositions,
          number_board: numberBoard,
          row,
          col,
          rows,
          cols
        })
      });
      const data = await resp.json();
      
      setBackendBoard(data.board);
      
      if (data.game_over) {
        setGameOver(true);
        const newBoard = board.map(r => [...r]);
        for (const [r, c, num] of data.revealed) {
          newBoard[r][c] = {
            state: 'mine',
            number: null,
            isMine: true
          };
        }
        setBoard(newBoard);
      } else {
        const newBoard = board.map(r => [...r]);
        for (const [r, c, num] of data.revealed) {
          newBoard[r][c] = {
            state: 'revealed',
            number: num,
            isMine: false
          };
        }
        setBoard(newBoard);
        
        if (data.won) {
          setWon(true);
        }
      }
    } catch (error) {
      console.error('Failed to click cell:', error);
    }
  };

  const getCellColor = (cell: CellData): string => {
    if (cell.state === 'mine') return 'bg-red-600';
    if (cell.state === 'flagged') return 'bg-yellow-500';
    if (cell.state === 'hidden') return 'bg-gray-600 hover:bg-gray-500';
    
    // Revealed
    if (cell.number === 0) return 'bg-gray-200';
    if (cell.number === 1) return 'bg-blue-100 text-blue-800';
    if (cell.number === 2) return 'bg-green-100 text-green-800';
    if (cell.number === 3) return 'bg-red-100 text-red-800';
    if (cell.number === 4) return 'bg-purple-100 text-purple-800';
    if (cell.number === 5) return 'bg-yellow-100 text-yellow-800';
    if (cell.number === 6) return 'bg-pink-100 text-pink-800';
    if (cell.number === 7) return 'bg-gray-100 text-gray-800';
    if (cell.number === 8) return 'bg-black text-white';
    return 'bg-gray-200';
  };

  const getCellContent = (cell: CellData): string => {
    if (cell.state === 'mine') return '💣';
    if (cell.state === 'flagged') return '🚩';
    if (cell.state === 'hidden') return '';
    return cell.number === 0 ? '' : String(cell.number);
  };

  return (
    <div className="flex flex-col items-center">
      <div className="mb-4 flex items-center gap-4">
        <div className="text-lg font-semibold text-cyan-400">
          剩余雷数: {minesRemaining}
        </div>
        {gameOver && (
          <div className="text-xl font-bold text-red-500">游戏结束！</div>
        )}
        {won && (
          <div className="text-xl font-bold text-green-500">恭喜胜利！</div>
        )}
        <button
          onClick={() => {
            // 重置所有状态
            const emptyBoard: CellData[][] = [];
            for (let r = 0; r < rows; r++) {
              const row: CellData[] = [];
              for (let c = 0; c < cols; c++) {
                row.push({
                  state: 'hidden',
                  number: null,
                  isMine: false
                });
              }
              emptyBoard.push(row);
            }
            setBoard(emptyBoard);
            setGameOver(false);
            setWon(false);
            setMinesRemaining(numMines);
            setFirstClick(null);
            setBackendBoard([]);
            setMinePositions([]);
            setNumberBoard([]);
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
        >
          重新开始
        </button>
      </div>

      <div
        className="grid gap-px bg-gray-700 p-1 rounded-lg border border-gray-600 shadow-lg"
        style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}
      >
        {board.map((row, rowIndex) =>
          row.map((cell, colIndex) => (
            <div
              key={`${rowIndex}-${colIndex}`}
              className={`w-8 h-8 flex items-center justify-center text-sm font-bold cursor-pointer transition-colors ${getCellColor(cell)}`}
              onClick={() => handleCellClick(rowIndex, colIndex, false)}
              onContextMenu={(e) => {
                e.preventDefault();
                handleCellClick(rowIndex, colIndex, true);
              }}
            >
              {getCellContent(cell)}
            </div>
          ))
        )}
      </div>

      <div className="mt-4 text-sm text-gray-400">
        <p>左键点击：翻开格子 | 右键点击：标记/取消标记</p>
      </div>
    </div>
  );
};

