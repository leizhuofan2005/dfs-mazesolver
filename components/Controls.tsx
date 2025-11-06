import React from 'react';

interface ControlsProps {
  isSolving: boolean;
  isSolved: boolean;
  gridSize: number;
  speed: number;
  difficulty: 'easy' | 'normal' | 'hard' | 'extreme';
  onGenerateMaze: () => void;
  onSolve: () => void;
  onResetPath: () => void;
  onSizeChange: (size: number) => void;
  onSpeedChange: (speed: number) => void;
  onDifficultyChange: (difficulty: 'easy' | 'normal' | 'hard' | 'extreme') => void;
}

const Slider: React.FC<{
  label: string;
  value: number;
  min: number;
  max: number;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  disabled: boolean;
}> = ({ label, value, min, max, onChange, disabled }) => (
  <div className="flex flex-col sm:flex-row items-center gap-2 sm:gap-4 text-sm">
    <label htmlFor={`${label}-slider`} className="w-24 text-center sm:text-right text-gray-300">
      {label}
    </label>
    <input
      id={`${label}-slider`}
      type="range"
      min={min}
      max={max}
      value={value}
      onChange={onChange}
      disabled={disabled}
      className="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-cyan-500 disabled:opacity-50 disabled:cursor-not-allowed"
    />
  </div>
);


export const Controls: React.FC<ControlsProps> = ({
  isSolving,
  isSolved,
  gridSize,
  speed,
  difficulty,
  onGenerateMaze,
  onSolve,
  onResetPath,
  onSizeChange,
  onSpeedChange,
  onDifficultyChange,
}) => {
  return (
    <div className="w-full max-w-4xl p-4 bg-gray-800/50 rounded-lg border border-gray-700 flex flex-col md:flex-row items-center justify-between gap-4">
      <div className="flex flex-wrap items-center gap-4">
        <button
          onClick={onGenerateMaze}
          disabled={isSolving}
          className="px-4 py-2 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors duration-200"
        >
          生成新迷宫
        </button>
        <button
          onClick={onSolve}
          disabled={isSolving || isSolved}
          className="px-4 py-2 bg-green-600 text-white font-semibold rounded-md hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors duration-200"
        >
          开始寻路
        </button>
        <button
          onClick={onResetPath}
          disabled={isSolving || !isSolved}
          className="px-4 py-2 bg-yellow-600 text-white font-semibold rounded-md hover:bg-yellow-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors duration-200"
        >
          重置路径
        </button>
      </div>

      <div className="w-full md:w-1/2 flex flex-col gap-3">
        <Slider
          label="迷宫大小"
          value={gridSize}
          min={10}
          max={40}
          onChange={(e) => onSizeChange(Number(e.target.value))}
          disabled={isSolving}
        />
        <Slider
          label="速度"
          value={speed}
          min={1}
          max={100}
          onChange={(e) => onSpeedChange(Number(e.target.value))}
          disabled={isSolving}
        />
        <div className="flex items-center gap-3 text-sm">
          <label className="w-24 text-right text-gray-300">难度</label>
          <select
            value={difficulty}
            onChange={(e) => onDifficultyChange(e.target.value as any)}
            disabled={isSolving}
            className="flex-1 bg-gray-700 text-gray-100 rounded-md p-2 border border-gray-600 disabled:opacity-50"
          >
            <option value="easy">简单</option>
            <option value="normal">普通</option>
            <option value="hard">困难</option>
            <option value="extreme">地狱</option>
          </select>
        </div>
      </div>
    </div>
  );
};