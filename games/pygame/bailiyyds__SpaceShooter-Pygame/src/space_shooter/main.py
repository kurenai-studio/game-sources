"""太空射击 - 入口
用法：
  python main.py            正常游戏
  python main.py --demo     AI 自动演示
  python main.py --test     无窗口自动测试（跑 3000 帧并检查状态）
"""
import argparse
import os
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="store_true", help="AI 自动游玩")
    ap.add_argument("--test", action="store_true", help="无窗口冒烟测试")
    ap.add_argument("--shots", help="把指定帧截图保存到该目录")
    ap.add_argument("--frames", type=int, default=0)
    args = ap.parse_args()

    if args.test or args.shots:
        os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
        os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

    import random
    import pygame
    from game import Game

    if args.test or args.shots:
        random.seed(7)
    game = Game(autopilot=args.demo or args.test or bool(args.shots),
                fixed_dt=1 / 60 if (args.test or args.shots) else None)
    if game.autopilot:
        game.state = "playing"

    shot_frames = {700, 1700, 2900, 3900}
    stats = {"max_enemies": 0, "max_bullets": 0}

    def on_frame(g, frame):
        stats["max_enemies"] = max(stats["max_enemies"], len(g.enemies))
        stats["max_bullets"] = max(stats["max_bullets"], len(g.bullets))
        if args.shots and frame in shot_frames:
            os.makedirs(args.shots, exist_ok=True)
            pygame.image.save(g.screen, os.path.join(args.shots, f"frame_{frame}.png"))
        if g.state == "over" and g.autopilot and not args.test:
            g.reset(); g.state = "playing"

    frames = args.frames or (3000 if args.test else (4000 if args.shots else None))
    game.run(max_frames=frames, on_frame=on_frame)

    if args.test:
        print(f"[test] 波次 {game.waves.wave}  分数 {game.score}  峰值敌人 {stats['max_enemies']}  峰值子弹 {stats['max_bullets']}")
        assert game.waves.wave >= 3, "应至少推进到第 3 波"
        assert game.score > 0, "应有得分"
        print("[test] 通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
