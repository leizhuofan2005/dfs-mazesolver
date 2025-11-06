import React, { useState, useEffect, useCallback, useRef } from 'react';
import { API_URL } from '../src/config';

interface SortingProps {
  algorithm: 'bubble' | 'quick';
}

interface SortStep {
  type: 'compare' | 'swap' | 'final';
  indices?: number[];
  values?: number[];
  array?: number[];
}

export const Sorting: React.FC<SortingProps> = ({ algorithm }) => {
  const [array, setArray] = useState<number[]>([]);
  const [originalArray, setOriginalArray] = useState<number[]>([]);
  const [steps, setSteps] = useState<SortStep[]>([]);
  const [currentStep, setCurrentStep] = useState(0);
  const [isSorting, setIsSorting] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [speed, setSpeed] = useState(50);
  const [arraySize, setArraySize] = useState(20);
  const [highlightedIndices, setHighlightedIndices] = useState<number[]>([]);
  const isSortingRef = useRef(false);
  const isPausedRef = useRef(false);

  const generateNewArray = useCallback(async () => {
    try {
      const resp = await fetch(`${API_URL}/sorting/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm,
          size: arraySize
        })
      });
      const data = await resp.json();
      setArray(data.array);
      setOriginalArray(data.array);
      setSteps([]);
      setCurrentStep(0);
      setHighlightedIndices([]);
    } catch (error) {
      console.error('Failed to generate array:', error);
    }
  }, [algorithm, arraySize]);

  useEffect(() => {
    generateNewArray();
  }, [generateNewArray]);

  const startSorting = async () => {
    if (isSortingRef.current) return;
    
    setIsSorting(true);
    setIsPaused(false);
    isSortingRef.current = true;
    isPausedRef.current = false;
    
    try {
      const resp = await fetch(`${API_URL}/sorting/sort`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm,
          size: arraySize
        })
      });
      const data = await resp.json();
      
      // 初始化数组状态
      let currentArray = [...data.original];
      setArray(data.original);
      setOriginalArray(data.original);
      setSteps(data.steps);
      setCurrentStep(0);
      
      // 执行动画
      for (let i = 0; i < data.steps.length; i++) {
        // 检查暂停状态
        while (isPausedRef.current) {
          await new Promise(resolve => setTimeout(resolve, 100));
          // 如果用户取消了排序
          if (!isSortingRef.current) {
            setIsSorting(false);
            return;
          }
        }
        
        // 如果用户取消了排序
        if (!isSortingRef.current) break;
        
        const step = data.steps[i];
        
        if (step.type === 'compare') {
          setHighlightedIndices(step.indices || []);
        } else if (step.type === 'swap') {
          setHighlightedIndices(step.indices || []);
          // 更新本地数组状态
          if (step.indices && step.indices.length === 2) {
            [currentArray[step.indices[0]], currentArray[step.indices[1]]] = 
              [currentArray[step.indices[1]], currentArray[step.indices[0]]];
            setArray([...currentArray]);
          }
        } else if (step.type === 'final') {
          if (step.array) {
            currentArray = [...step.array];
            setArray(currentArray);
          }
          setHighlightedIndices([]);
        }
        
        setCurrentStep(i);
        await new Promise(resolve => setTimeout(resolve, Math.floor(500 / (speed * 2))));
      }
      
      isSortingRef.current = false;
      setIsSorting(false);
      setHighlightedIndices([]);
    } catch (error) {
      console.error('Failed to sort:', error);
      isSortingRef.current = false;
      setIsSorting(false);
      setHighlightedIndices([]);
    }
  };

  const reset = () => {
    isSortingRef.current = false;
    isPausedRef.current = false;
    setIsSorting(false);
    setIsPaused(false);
    setArray(originalArray);
    setSteps([]);
    setCurrentStep(0);
    setHighlightedIndices([]);
  };

  const maxValue = array.length > 0 ? Math.max(...array) : 100;

  return (
    <div className="flex flex-col items-center w-full">
      <div className="mb-4 flex items-center gap-4 flex-wrap justify-center">
        <div className="flex items-center gap-2">
          <label className="text-gray-300">数组大小:</label>
          <input
            type="range"
            min="5"
            max="50"
            value={arraySize}
            onChange={(e) => setArraySize(Number(e.target.value))}
            disabled={isSorting}
            className="w-32"
          />
          <span className="text-cyan-400 w-8">{arraySize}</span>
        </div>
        
        <div className="flex items-center gap-2">
          <label className="text-gray-300">速度:</label>
          <input
            type="range"
            min="1"
            max="100"
            value={speed}
            onChange={(e) => setSpeed(Number(e.target.value))}
            disabled={isSorting}
            className="w-32"
          />
          <span className="text-cyan-400 w-8">{speed}</span>
        </div>
        
        <button
          onClick={generateNewArray}
          disabled={isSorting}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          生成新数组
        </button>
        
        <button
          onClick={startSorting}
          disabled={isSorting}
          className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          开始排序
        </button>
        
        <button
          onClick={() => {
            const newPaused = !isPaused;
            setIsPaused(newPaused);
            isPausedRef.current = newPaused;
          }}
          disabled={!isSorting}
          className="px-4 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          {isPaused ? '继续' : '暂停'}
        </button>
        
        <button
          onClick={() => {
            isSortingRef.current = false;
            reset();
          }}
          disabled={!isSorting}
          className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          停止
        </button>
      </div>

      <div className="w-full max-w-4xl mb-4">
        <div className="flex items-end justify-center gap-1 h-64 bg-gray-800 p-4 rounded-lg border border-gray-700">
          {array.map((value, index) => {
            const height = (value / maxValue) * 100;
            const isHighlighted = highlightedIndices.includes(index);
            
            return (
              <div
                key={index}
                className={`flex-1 flex flex-col items-center justify-end transition-all duration-150 ${
                  isHighlighted
                    ? 'bg-cyan-400 shadow-lg shadow-cyan-400/50'
                    : 'bg-cyan-600 hover:bg-cyan-500'
                }`}
                style={{
                  height: `${height}%`,
                  minWidth: `${100 / array.length}%`
                }}
              >
                <span className="text-xs text-white mb-1 font-bold">{value}</span>
              </div>
            );
          })}
        </div>
      </div>

      <div className="text-sm text-gray-400">
        <p>
          算法: {algorithm === 'bubble' ? '冒泡排序' : '快速排序'} | 
          步骤: {currentStep} / {steps.length} | 
          {isSorting && (isPaused ? '已暂停' : '排序中...')}
        </p>
      </div>
    </div>
  );
};

