import os
from utils.helpers import clamp

def load_high_score():
    try:
        with open("highscore.txt") as f:
            value = f.read().strip()
        score = int(value)
        return score if score > 0 else 0
    except (FileNotFoundError, ValueError, OSError):
        return 0

def save_high_score(score):
    try:
        with open("highscore.txt", "w") as f:
            f.write(str(score))
    except OSError:
        pass

def load_progress():
    wallet, speed_level, life_level = 0, 0, 0
    try:
        with open("progress.txt") as f:
            parts = f.read().strip().split(",")
        if len(parts) >= 3:
            wallet = max(0, int(parts[0]))
            speed_level = clamp(int(parts[1]), 0, 5)
            life_level = clamp(int(parts[2]), 0, 2)
    except (FileNotFoundError, ValueError, OSError):
        pass
    return wallet, {"speed": speed_level, "life": life_level}

def save_progress(wallet, upgrades):
    try:
        with open("progress.txt", "w") as f:
            f.write(f"{wallet},{upgrades['speed']},{upgrades['life']}")
    except OSError:
        pass

def load_stats():
    stats = {}
    try:
        with open("stats.txt") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    try:
                        stats[k] = int(v)
                    except ValueError:
                        pass
    except (FileNotFoundError, OSError):
        pass
    return stats

def save_stats(stats):
    try:
        with open("stats.txt", "w") as f:
            for k, v in stats.items():
                f.write(f"{k}={v}\n")
    except OSError:
        pass

def load_achievements():
    try:
        with open("achievements.txt") as f:
            content = f.read().strip()
        return set(x for x in content.split(",") if x)
    except (FileNotFoundError, OSError):
        return set()

def save_achievements(unlocked):
    try:
        with open("achievements.txt", "w") as f:
            f.write(",".join(sorted(unlocked)))
    except OSError:
        pass
