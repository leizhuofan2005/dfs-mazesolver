"""
排序算法后端实现
提供快速排序和冒泡排序的动画步骤
"""
from typing import List, Dict, Tuple
import random


def bubble_sort_steps(arr: List[int]) -> List[Dict[str, any]]:
    """
    冒泡排序，返回每一步的动画信息
    返回: [{type: 'compare'|'swap'|'final', indices: [i, j], values: [val1, val2]}, ...]
    """
    steps: List[Dict[str, any]] = []
    n = len(arr)
    arr_copy = arr.copy()
    
    for i in range(n):
        swapped = False
        for j in range(0, n - i - 1):
            # 比较步骤
            steps.append({
                'type': 'compare',
                'indices': [j, j + 1],
                'values': [arr_copy[j], arr_copy[j + 1]]
            })
            
            if arr_copy[j] > arr_copy[j + 1]:
                # 交换步骤
                arr_copy[j], arr_copy[j + 1] = arr_copy[j + 1], arr_copy[j]
                steps.append({
                    'type': 'swap',
                    'indices': [j, j + 1],
                    'values': [arr_copy[j], arr_copy[j + 1]]
                })
                swapped = True
        
        if not swapped:
            break
    
    # 最终状态
    steps.append({
        'type': 'final',
        'array': arr_copy.copy()
    })
    
    return steps


def quick_sort_steps(arr: List[int]) -> List[Dict[str, any]]:
    """
    快速排序，返回每一步的动画信息
    """
    steps: List[Dict[str, any]] = []
    arr_copy = arr.copy()
    
    def partition(low: int, high: int) -> int:
        pivot = arr_copy[high]
        i = low - 1
        
        for j in range(low, high):
            # 比较步骤
            steps.append({
                'type': 'compare',
                'indices': [j, high],
                'values': [arr_copy[j], pivot]
            })
            
            if arr_copy[j] <= pivot:
                i += 1
                if i != j:
                    arr_copy[i], arr_copy[j] = arr_copy[j], arr_copy[i]
                    steps.append({
                        'type': 'swap',
                        'indices': [i, j],
                        'values': [arr_copy[i], arr_copy[j]]
                    })
        
        if i + 1 != high:
            arr_copy[i + 1], arr_copy[high] = arr_copy[high], arr_copy[i + 1]
            steps.append({
                'type': 'swap',
                'indices': [i + 1, high],
                'values': [arr_copy[i + 1], arr_copy[high]]
            })
        
        return i + 1
    
    def quick_sort_recursive(low: int, high: int):
        if low < high:
            pi = partition(low, high)
            quick_sort_recursive(low, pi - 1)
            quick_sort_recursive(pi + 1, high)
    
    quick_sort_recursive(0, len(arr_copy) - 1)
    
    # 最终状态
    steps.append({
        'type': 'final',
        'array': arr_copy.copy()
    })
    
    return steps


def generate_random_array(size: int, min_val: int = 1, max_val: int = 100, seed: int | None = None) -> List[int]:
    """生成随机数组"""
    rnd = random.Random(seed)
    return [rnd.randint(min_val, max_val) for _ in range(size)]

