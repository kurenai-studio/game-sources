"""Local web bridge for the real FlyBrain-backed Catch the Fly duel.

Run from the repository root:
    python webcatch_server.py
Then open http://127.0.0.1:8080.
"""

import json
import math
import os
import random
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from catch_game import BrainEscapeController, WEAPONS


ROOT = Path(__file__).resolve().parent
WEB_ROOT = ROOT / "webcatch"
WIDTH, HEIGHT = 1000, 700
os.environ.setdefault("FLY_DEVICE", "cuda")


class Duel:
    def __init__(self):
        self.lock = threading.Lock()
        self.brain = BrainEscapeController()
        self.player = {"x": 300.0, "y": 380.0, "hp": 100}
        self.fly = {"x": 700.0, "y": 300.0, "hp": 100}
        self.fly_vel = [0.0, 0.0]
        self.bullets = []
        self.keys = set()
        self.mouse = {"x": 300.0, "y": 380.0, "fire": False}
        self.player_weapon = 0
        self.fly_weapon = 1
        self.player_cool = 0.0
        self.fly_cool = 0.0
        self.phase = 0.0
        self.kills = [0, 0]
        self.respawns = [0, 0]
        self.banner = ""
        self.banner_time = 0.0
        self.running = False
        self.last_spikes = 0
        self.last_brain_step = 0.0
        self.brain_interval = 0.10
        self.device = self.brain.brain.device

    def spawn(self, who):
        if who == "fly":
            self.fly = {
                "x": random.uniform(540, 900),
                "y": random.uniform(130, 600),
                "hp": 100,
            }
            self.fly_vel = [0.0, 0.0]
            self.respawns[1] += 1
        else:
            self.player = {"x": WIDTH * 0.3, "y": HEIGHT * 0.55, "hp": 100}
            self.respawns[0] += 1
        self.bullets = [b for b in self.bullets if b["owner"] != who]

    def fire(self, owner):
        source = self.player if owner == "player" else self.fly
        target = self.fly if owner == "player" else self.player
        weapon_index = self.player_weapon if owner == "player" else self.fly_weapon
        name, damage, speed, cooldown, count, color, kind = WEAPONS[weapon_index]
        angle = math.atan2(target["y"] - source["y"], target["x"] - source["x"])
        if name == "NOVA":
            count = 9
        elif name == "SHOTGUN":
            count = 5
        elif name == "BURST":
            count = 3
        for i in range(count):
            spread = (i - (count - 1) / 2) * 0.14 if count > 1 else 0
            self.bullets.append({
                "x": source["x"], "y": source["y"],
                "vx": math.cos(angle + spread) * speed,
                "vy": math.sin(angle + spread) * speed,
                "owner": owner, "damage": damage, "life": 1.8,
                "kind": kind, "color": color,
            })

    def step(self, dt):
        if not self.running:
            return
        self.phase += dt
        p, f = self.player, self.fly
        mx = int("d" in self.keys or "arrowright" in self.keys) - int(
            "a" in self.keys or "arrowleft" in self.keys)
        my = int("s" in self.keys or "arrowdown" in self.keys) - int(
            "w" in self.keys or "arrowup" in self.keys)
        if self.mouse["x"] is not None:
            p["x"] += mx * 430 * dt
            p["y"] += my * 430 * dt
        p["x"] = max(18, min(WIDTH - 18, p["x"]))
        p["y"] = max(80, min(HEIGHT - 20, p["y"]))
        f["x"] += self.fly_vel[0] * dt
        f["y"] += self.fly_vel[1] * dt
        self.fly_vel[0] += (math.cos(self.phase * 1.7) * 35 - self.fly_vel[0]) * dt * 2
        self.fly_vel[1] += (math.sin(self.phase * 1.3) * 35 - self.fly_vel[1]) * dt * 2
        f["x"] = max(20, min(WIDTH - 20, f["x"]))
        f["y"] = max(90, min(HEIGHT - 24, f["y"]))
        p["x"], p["y"] = self.mouse["x"], self.mouse["y"]

        dx, dy = p["x"] - f["x"], p["y"] - f["y"]
        distance = max(1.0, math.hypot(dx, dy))
        brain_state = {
            "approach_speed_norm": 0.2 if distance < 260 else -0.1,
        }
        escaped = False
        if self.phase - self.last_brain_step >= self.brain_interval:
            escaped = self.brain.step((p["x"], p["y"]), (f["x"], f["y"]), brain_state)
            self.last_brain_step = self.phase
            self.last_spikes = self.brain.last_fired
        else:
            escaped = self.brain.last_state == "ESCAPE"
        if escaped:
            length = math.hypot(dx, dy) or 1.0
            self.fly_vel[0] -= dx / length * 560
            self.fly_vel[1] -= dy / length * 560
        self.fly_vel[0] += math.cos(self.phase * 1.7) * 2.5
        self.fly_vel[1] += math.sin(self.phase * 1.3) * 2.5
        self.player_cool -= dt
        self.fly_cool -= dt
        if self.mouse["fire"] and self.player_cool <= 0:
            self.fire("player")
            self.player_cool = WEAPONS[self.player_weapon][3]
        if self.fly_cool <= 0:
            self.fire("fly")
            self.fly_cool = WEAPONS[self.fly_weapon][3] * 1.8
            self.fly_weapon = (self.fly_weapon + 1 + self.brain.dopamine_hits) % len(WEAPONS)

        for bullet in self.bullets:
            bullet["x"] += bullet["vx"] * dt
            bullet["y"] += bullet["vy"] * dt
            bullet["life"] -= dt
            target = f if bullet["owner"] == "player" else p
            if math.hypot(bullet["x"] - target["x"], bullet["y"] - target["y"]) < 24:
                target["hp"] = max(0, target["hp"] - bullet["damage"])
                if bullet["kind"] != "pierce":
                    bullet["life"] = 0
        self.bullets = [b for b in self.bullets if b["life"] > 0]
        if f["hp"] <= 0:
            self.kills[0] += 1
            self.banner, self.banner_time = "FLY DESTROYED | RESPAWN", 1.5
            self.spawn("fly")
        if p["hp"] <= 0:
            self.kills[1] += 1
            self.brain.dopamine_hit()
            self.banner, self.banner_time = "PLAYER DESTROYED | RESPAWN", 1.5
            self.spawn("player")
        self.banner_time = max(0.0, self.banner_time - dt)

    def state(self):
        return {
            "running": self.running,
            "player": self.player,
            "fly": self.fly,
            "bullets": self.bullets,
            "kills": self.kills,
            "respawns": self.respawns,
            "banner": self.banner if self.banner_time else "",
            "dopamine": self.brain.dopamine_hits,
            "learning": self.brain.learning_level,
            "spikes": self.last_spikes,
            "total_spikes": self.brain.total_spikes,
            "phase": self.phase,
            "brain_state": self.brain.last_state,
            "loom": max(self.brain.last_drive.get("loomL", 0), self.brain.last_drive.get("loomR", 0)),
            "threat": max(self.brain.last_drive.get("threatL", 0), self.brain.last_drive.get("threatR", 0)),
            "fly_weapon": WEAPONS[self.fly_weapon][0],
            "device": self.device,
            "brain_hz": round(1 / self.brain_interval, 1),
        }


game = Duel()


def loop():
    previous = time.perf_counter()
    while True:
        now = time.perf_counter()
        dt = min(0.04, now - previous)
        previous = now
        with game.lock:
            game.step(dt)
        time.sleep(1 / 60)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_ROOT), **kwargs)

    def do_GET(self):
        if self.path == "/api/state":
            self.send_json(game.state())
            return
        super().do_GET()

    def do_POST(self):
        if self.path != "/api/command":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", "0"))
        command = json.loads(self.rfile.read(length) or b"{}")
        with game.lock:
            if command.get("action") == "start":
                game.running = True
            if "keys" in command:
                game.keys = set(command["keys"])
            if "mouse" in command:
                game.mouse.update(command["mouse"])
            if "weapon" in command:
                game.player_weapon = max(0, min(len(WEAPONS) - 1, int(command["weapon"])))
        self.send_json({"ok": True})

    def send_json(self, value):
        body = json.dumps(value).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    threading.Thread(target=loop, daemon=True).start()
    print("Web duel with real FlyBrain: http://127.0.0.1:8080")
    ThreadingHTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
