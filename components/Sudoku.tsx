import React, { useState, useEffect, useCallback } from 'react';
import { API_URL } from '../src/config';

interface SudokuProps {}

export const Sudoku: React.FC<SudokuProps> = () => {
  const [puzzle, setPuzzle] = useState<number[][]>([]);
  const [solution, setSolution] = useState<number[][]>([]);
  const [userInput, setUserInput] = useState<number[][]>([]);
  const [selectedCell, setSelectedCell] = useState<{ row: number; col: number } | null>(null);
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard' | 'expert'>('medium');
  const [isComplete, setIsComplete] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [message, setMessage] = useState('');

  const generatePuzzle = useCallback(async () => {
    try {
      const resp = await fetch(`${API_URL}/sudoku/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ difficulty })
      });
      const data = await resp.json();
      setPuzzle(data.puzzle);
      setSolution(data.solution);
      setUserInput(data.puzzle.map((row: number[]) => [...row]));
      setSelectedCell(null);
      setIsComplete(false);
      setIsCorrect(false);
      setMessage('');
    } catch (error) {
      console.error('Failed to generate puzzle:', error);
    }
  }, [difficulty]);

  useEffect(() => {
    generatePuzzle();
  }, [generatePuzzle]);

  const handleCellClick = (row: number, col: number) => {
    if (isComplete) return;
    // 只能选择初始为空的格子
    if (puzzle[row][col] === 0) {
      setSelectedCell({ row, col });
      setMessage('');
    } else {
      setMessage('不能选择初始数字');
      setTimeout(() => setMessage(''), 1500);
    }
  };

  const handleNumberInput = async (num: number) => {
    if (!selectedCell || isComplete) return;
    
    const { row, col } = selectedCell;
    
    // 如果该位置是初始谜题的一部分，不允许修改
    if (puzzle[row][col] !== 0) {
      setMessage('不能修改初始数字');
      return;
    }
    
    // 验证移动
    try {
      const testInput = userInput.map(r => [...r]);
      testInput[row][col] = num;
      
      const resp = await fetch(`${API_URL}/sudoku/validate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          puzzle: testInput,
          row,
          col,
          num
        })
      });
      const data = await resp.json();
      
      if (data.valid) {
        const newInput = userInput.map(r => [...r]);
        newInput[row][col] = num;
        setUserInput(newInput);
        setMessage('');
        
        // 检查是否完成
        const checkResp = await fetch(`${API_URL}/sudoku/check`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            puzzle: newInput,
            solution
          })
        });
        const checkData = await checkResp.json();
        
        if (checkData.complete) {
          setIsComplete(true);
          setIsCorrect(checkData.correct);
          setMessage(checkData.message);
        }
      } else {
        setMessage(data.message);
        // 短暂显示错误后清除
        setTimeout(() => setMessage(''), 2000);
      }
    } catch (error) {
      console.error('Failed to validate move:', error);
      setMessage('验证失败，请重试');
    }
  };

  const handleClear = () => {
    if (!selectedCell || isComplete) return;
    const { row, col } = selectedCell;
    if (puzzle[row][col] === 0) {
      const newInput = userInput.map(r => [...r]);
      newInput[row][col] = 0;
      setUserInput(newInput);
      setMessage('');
      setIsComplete(false);
      setIsCorrect(false);
    }
  };

  const handleHint = async () => {
    try {
      const resp = await fetch(`${API_URL}/sudoku/hint`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          puzzle: userInput,
          solution
        })
      });
      const data = await resp.json();
      
      if (data.row !== undefined) {
        const newInput = userInput.map(r => [...r]);
        newInput[data.row][data.col] = data.value;
        setUserInput(newInput);
        setSelectedCell({ row: data.row, col: data.col });
        setMessage('提示已应用');
        
        // 检查是否完成
        const checkResp = await fetch(`${API_URL}/sudoku/check`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            puzzle: newInput,
            solution
          })
        });
        const checkData = await checkResp.json();
        
        if (checkData.complete) {
          setIsComplete(true);
          setIsCorrect(checkData.correct);
          setMessage(checkData.message);
        }
      }
    } catch (error) {
      console.error('Failed to get hint:', error);
    }
  };

  const getCellClass = (row: number, col: number): string => {
    let classes = 'w-10 h-10 text-center text-lg font-bold border transition-colors ';
    
    // 边框样式
    if (row % 3 === 0 && row > 0) classes += 'border-t-2 border-gray-400 ';
    else classes += 'border-t border-gray-300 ';
    
    if (col % 3 === 0 && col > 0) classes += 'border-l-2 border-gray-400 ';
    else classes += 'border-l border-gray-300 ';
    
    if (row === 8) classes += 'border-b-2 border-gray-400 ';
    else classes += 'border-b border-gray-300 ';
    
    if (col === 8) classes += 'border-r-2 border-gray-400 ';
    else classes += 'border-r border-gray-300 ';
    
    // 背景颜色
    if (selectedCell && selectedCell.row === row && selectedCell.col === col) {
      classes += 'bg-cyan-500 text-white ';
    } else if (puzzle[row][col] !== 0) {
      classes += 'bg-gray-200 text-gray-800 ';
    } else {
      classes += 'bg-white text-gray-900 hover:bg-gray-100 cursor-pointer ';
    }
    
    // 错误提示
    if (isComplete && !isCorrect && userInput[row][col] !== solution[row][col] && userInput[row][col] !== 0) {
      classes += 'bg-red-200 text-red-800 ';
    }
    
    return classes;
  };

  return (
    <div className="flex flex-col items-center w-full">
      <div className="mb-4 flex items-center gap-4 flex-wrap justify-center">
        <div className="flex items-center gap-2">
          <label className="text-gray-300">难度:</label>
          <select
            value={difficulty}
            onChange={(e) => setDifficulty(e.target.value as any)}
            disabled={isComplete}
            className="bg-gray-700 text-gray-100 rounded-md p-2 border border-gray-600 disabled:opacity-50"
          >
            <option value="easy">简单</option>
            <option value="medium">中等</option>
            <option value="hard">困难</option>
            <option value="expert">专家</option>
          </select>
        </div>
        
        <button
          onClick={generatePuzzle}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
        >
          生成新谜题
        </button>
        
        <button
          onClick={handleHint}
          disabled={isComplete}
          className="px-4 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          提示
        </button>
        
        <button
          onClick={handleClear}
          disabled={!selectedCell || isComplete}
          className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          清除
        </button>
      </div>

      {message && (
        <div className={`mb-4 px-4 py-2 rounded-md text-center font-semibold ${
          isCorrect ? 'bg-green-500 text-white' : 
          isComplete && !isCorrect ? 'bg-red-500 text-white' : 
          message.includes('不能') ? 'bg-orange-500 text-white' :
          'bg-yellow-500 text-white'
        }`}>
          {message}
        </div>
      )}

      <div className="bg-gray-800 p-4 rounded-lg border border-gray-700 shadow-lg">
        <div className="grid grid-cols-9 gap-0">
          {userInput.map((row, rowIndex) =>
            row.map((cell, colIndex) => (
              <div
                key={`${rowIndex}-${colIndex}`}
                className={getCellClass(rowIndex, colIndex)}
                onClick={() => handleCellClick(rowIndex, colIndex)}
              >
                {cell !== 0 ? cell : ''}
              </div>
            ))
          )}
        </div>
      </div>

      <div className="mt-4 flex gap-2 flex-wrap justify-center">
        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(num => (
          <button
            key={num}
            onClick={() => handleNumberInput(num)}
            disabled={!selectedCell || isComplete}
            className="w-10 h-10 bg-cyan-600 text-white font-bold rounded-md hover:bg-cyan-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
          >
            {num}
          </button>
        ))}
        <button
          onClick={handleClear}
          disabled={!selectedCell || isComplete}
          className="w-10 h-10 bg-gray-600 text-white font-bold rounded-md hover:bg-gray-700 disabled:bg-gray-500 disabled:cursor-not-allowed transition-colors"
        >
          ×
        </button>
      </div>

      <div className="mt-4 text-sm text-gray-400">
        <p>点击空格选择，然后点击数字填入 | 右键或点击×清除</p>
      </div>
    </div>
  );
};

