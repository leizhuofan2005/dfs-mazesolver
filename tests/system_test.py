"""
系统深度测试模块
全面测试所有后端功能：迷宫生成、BFS求解、扫雷游戏
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import unittest
import requests
import time
from typing import List, Dict, Any

BASE_URL = "http://127.0.0.1:8000"


class TestBackendHealth(unittest.TestCase):
    """测试后端健康状态"""
    
    def test_health_endpoint(self):
        """测试健康检查端点"""
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=5)
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "ok")
            print("[OK] 健康检查通过")
        except requests.exceptions.ConnectionError:
            self.fail("后端服务未运行，请先启动后端服务")
        except Exception as e:
            self.fail(f"健康检查失败: {e}")


class TestMazeGeneration(unittest.TestCase):
    """测试迷宫生成功能"""
    
    def test_maze_generation_easy(self):
        """测试简单难度迷宫生成"""
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 15, "difficulty": "easy"},
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("grid", data)
        self.assertIn("start", data)
        self.assertIn("goal", data)
        self.assertEqual(len(data["grid"]), 15)
        print("[OK] 简单难度迷宫生成测试通过")
    
    def test_maze_generation_hard(self):
        """测试困难难度迷宫生成"""
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 25, "difficulty": "hard"},
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data["grid"]), 25)
        print("[OK] 困难难度迷宫生成测试通过")
    
    def test_maze_generation_extreme(self):
        """测试地狱难度迷宫生成"""
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 35, "difficulty": "extreme"},
            timeout=15
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data["grid"]), 35)
        print("[OK] 地狱难度迷宫生成测试通过")
    
    def test_maze_bfs_solve(self):
        """测试BFS求解功能"""
        response = requests.post(
            f"{BASE_URL}/bfs",
            json={"size": 21, "difficulty": "normal"},
            timeout=15
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("grid", data)
        self.assertIn("visited", data)
        self.assertIn("path", data)
        self.assertGreater(len(data["visited"]), 0)
        self.assertGreater(len(data["path"]), 0)
        print("[OK] BFS求解测试通过")


class TestMinesweeper(unittest.TestCase):
    """测试扫雷游戏功能"""
    
    def test_minesweeper_init(self):
        """测试扫雷初始化"""
        response = requests.post(
            f"{BASE_URL}/minesweeper/init",
            json={
                "rows": 16,
                "cols": 16,
                "num_mines": 40,
                "first_click": {"row": 0, "col": 0}
            },
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("board", data)
        self.assertIn("mine_positions", data)
        self.assertIn("number_board", data)
        self.assertEqual(len(data["board"]), 16)
        self.assertEqual(len(data["board"][0]), 16)
        self.assertEqual(len(data["mine_positions"]), 40)
        print("[OK] 扫雷初始化测试通过")
    
    def test_minesweeper_click(self):
        """测试扫雷点击功能"""
        # 先初始化
        init_response = requests.post(
            f"{BASE_URL}/minesweeper/init",
            json={
                "rows": 10,
                "cols": 10,
                "num_mines": 15,
                "first_click": {"row": 5, "col": 5}
            },
            timeout=10
        )
        self.assertEqual(init_response.status_code, 200)
        init_data = init_response.json()
        
        # 点击一个格子
        click_response = requests.post(
            f"{BASE_URL}/minesweeper/click",
            json={
                "board": init_data["board"],
                "mine_positions": init_data["mine_positions"],
                "number_board": init_data["number_board"],
                "row": 5,
                "col": 5,
                "rows": 10,
                "cols": 10
            },
            timeout=10
        )
        self.assertEqual(click_response.status_code, 200)
        click_data = click_response.json()
        self.assertIn("revealed", click_data)
        self.assertIn("game_over", click_data)
        self.assertIn("won", click_data)
        print("[OK] 扫雷点击测试通过")
    
    def test_minesweeper_flag(self):
        """测试扫雷标记功能"""
        # 先初始化
        init_response = requests.post(
            f"{BASE_URL}/minesweeper/init",
            json={
                "rows": 10,
                "cols": 10,
                "num_mines": 15
            },
            timeout=10
        )
        self.assertEqual(init_response.status_code, 200)
        init_data = init_response.json()
        
        # 标记一个格子
        flag_response = requests.post(
            f"{BASE_URL}/minesweeper/flag",
            json={
                "board": init_data["board"],
                "row": 0,
                "col": 0
            },
            timeout=10
        )
        self.assertEqual(flag_response.status_code, 200)
        flag_data = flag_response.json()
        self.assertIn("board", flag_data)
        self.assertIn("flagged", flag_data)
        # 检查标记是否生效
        self.assertEqual(flag_data["board"][0][0], -3)  # FLAGGED = -3
        print("[OK] 扫雷标记测试通过")


class TestEdgeCases(unittest.TestCase):
    """测试边界情况"""
    
    def test_maze_small_size(self):
        """测试最小尺寸迷宫"""
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 5, "difficulty": "easy"},
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        print("[OK] 最小尺寸迷宫测试通过")
    
    def test_maze_large_size(self):
        """测试大尺寸迷宫"""
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 51, "difficulty": "normal"},
            timeout=20
        )
        self.assertEqual(response.status_code, 200)
        print("[OK] 大尺寸迷宫测试通过")
    
    def test_minesweeper_small_board(self):
        """测试小尺寸扫雷"""
        response = requests.post(
            f"{BASE_URL}/minesweeper/init",
            json={
                "rows": 8,
                "cols": 8,
                "num_mines": 10
            },
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        print("[OK] 小尺寸扫雷测试通过")
    
    def test_minesweeper_many_mines(self):
        """测试大量雷的扫雷"""
        response = requests.post(
            f"{BASE_URL}/minesweeper/init",
            json={
                "rows": 20,
                "cols": 20,
                "num_mines": 80
            },
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        print("[OK] 大量雷扫雷测试通过")


class TestSudoku(unittest.TestCase):
    """测试数独游戏功能"""
    
    def test_sudoku_generate(self):
        """测试数独生成"""
        response = requests.post(
            f"{BASE_URL}/sudoku/generate",
            json={"difficulty": "medium"},
            timeout=10
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("puzzle", data)
        self.assertIn("solution", data)
        self.assertEqual(len(data["puzzle"]), 9)
        self.assertEqual(len(data["puzzle"][0]), 9)
        print("[OK] 数独生成测试通过")
    
    def test_sudoku_validate(self):
        """测试数独验证"""
        # 先生成一个数独
        gen_resp = requests.post(
            f"{BASE_URL}/sudoku/generate",
            json={"difficulty": "easy"},
            timeout=10
        )
        self.assertEqual(gen_resp.status_code, 200)
        gen_data = gen_resp.json()
        puzzle = gen_data["puzzle"]
        
        # 测试有效移动
        valid_resp = requests.post(
            f"{BASE_URL}/sudoku/validate",
            json={
                "puzzle": puzzle,
                "row": 0,
                "col": 0,
                "num": 1
            },
            timeout=10
        )
        self.assertEqual(valid_resp.status_code, 200)
        valid_data = valid_resp.json()
        self.assertIn("valid", valid_data)
        print("[OK] 数独验证测试通过")
    
    def test_sudoku_check(self):
        """测试数独检查"""
        # 生成数独
        gen_resp = requests.post(
            f"{BASE_URL}/sudoku/generate",
            json={"difficulty": "easy"},
            timeout=10
        )
        self.assertEqual(gen_resp.status_code, 200)
        gen_data = gen_resp.json()
        
        # 检查完成状态
        check_resp = requests.post(
            f"{BASE_URL}/sudoku/check",
            json={
                "puzzle": gen_data["puzzle"],
                "solution": gen_data["solution"]
            },
            timeout=10
        )
        self.assertEqual(check_resp.status_code, 200)
        check_data = check_resp.json()
        self.assertIn("complete", check_data)
        self.assertIn("correct", check_data)
        print("[OK] 数独检查测试通过")
    
    def test_sudoku_hint(self):
        """测试数独提示"""
        gen_resp = requests.post(
            f"{BASE_URL}/sudoku/generate",
            json={"difficulty": "medium"},
            timeout=10
        )
        self.assertEqual(gen_resp.status_code, 200)
        gen_data = gen_resp.json()
        
        hint_resp = requests.post(
            f"{BASE_URL}/sudoku/hint",
            json={
                "puzzle": gen_data["puzzle"],
                "solution": gen_data["solution"]
            },
            timeout=10
        )
        self.assertEqual(hint_resp.status_code, 200)
        hint_data = hint_resp.json()
        if "error" not in hint_data:
            self.assertIn("row", hint_data)
            self.assertIn("col", hint_data)
            self.assertIn("value", hint_data)
        print("[OK] 数独提示测试通过")


class TestPerformance(unittest.TestCase):
    """测试性能"""
    
    def test_maze_generation_performance(self):
        """测试迷宫生成性能"""
        start_time = time.time()
        response = requests.post(
            f"{BASE_URL}/maze",
            json={"size": 25, "difficulty": "hard"},
            timeout=30
        )
        elapsed = time.time() - start_time
        self.assertEqual(response.status_code, 200)
        self.assertLess(elapsed, 5.0, "迷宫生成应该少于5秒")
        print(f"[OK] 迷宫生成性能测试通过 (耗时: {elapsed:.2f}秒)")
    
    def test_bfs_performance(self):
        """测试BFS性能"""
        start_time = time.time()
        response = requests.post(
            f"{BASE_URL}/bfs",
            json={"size": 25, "difficulty": "normal"},
            timeout=30
        )
        elapsed = time.time() - start_time
        self.assertEqual(response.status_code, 200)
        self.assertLess(elapsed, 10.0, "BFS求解应该少于10秒")
        print(f"[OK] BFS性能测试通过 (耗时: {elapsed:.2f}秒)")


def run_all_tests():
    """运行所有测试"""
    print("=" * 60)
    print("开始系统深度测试")
    print("=" * 60)
    
    # 检查后端是否运行
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code != 200:
            print("[FAIL] 后端服务未正常运行")
            return
    except:
        print("[FAIL] 无法连接到后端服务，请先启动后端服务")
        print("   启动命令: python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000")
        return
    
    print("[OK] 后端服务连接正常\n")
    
    # 创建测试套件
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # 添加所有测试类
    suite.addTests(loader.loadTestsFromTestCase(TestBackendHealth))
    suite.addTests(loader.loadTestsFromTestCase(TestMazeGeneration))
    suite.addTests(loader.loadTestsFromTestCase(TestMinesweeper))
    suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))
    suite.addTests(loader.loadTestsFromTestCase(TestSudoku))
    suite.addTests(loader.loadTestsFromTestCase(TestPerformance))
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # 输出总结
    print("\n" + "=" * 60)
    print("测试总结")
    print("=" * 60)
    print(f"总测试数: {result.testsRun}")
    print(f"成功: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"失败: {len(result.failures)}")
    print(f"错误: {len(result.errors)}")
    
    if result.failures:
        print("\n失败的测试:")
        for test, traceback in result.failures:
            print(f"  - {test}: {traceback}")
    
    if result.errors:
        print("\n错误的测试:")
        for test, traceback in result.errors:
            print(f"  - {test}: {traceback}")
    
    if result.wasSuccessful():
        print("\n[OK] 所有测试通过！")
    else:
        print("\n[FAIL] 部分测试失败，请检查上述错误信息")
    
    return result.wasSuccessful()


if __name__ == "__main__":
    run_all_tests()

