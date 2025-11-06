import React from 'react';
import { CellType } from '../types';

interface CellProps {
  type: CellType;
}

export const Bar: React.FC<CellProps> = React.memo(({ type }) => {
  const getBackgroundColor = (): string => {
    switch (type) {
      case CellType.Start:
        return 'bg-green-500';
      case CellType.End:
        return 'bg-red-500';
      case CellType.Wall:
        return 'bg-gray-800';
      case CellType.Visited:
        return 'bg-blue-500';
      case CellType.CorrectPath:
        return 'bg-yellow-400';
      case CellType.Path:
      default:
        return 'bg-white';
    }
  };

  return (
    <div
      className={`w-full h-full transition-colors duration-300 ${getBackgroundColor()}`}
    ></div>
  );
});
