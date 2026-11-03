"""Top-level application state machine."""

from __future__ import annotations

from pathlib import Path

import pygame

from game.audio import ProceduralAudio
from game.config import HEIGHT, TITLE, WIDTH
from game.scenes import GameOverScene, GameScene, MenuScene, RankingScene
from game.storage import SaveSystem


class GameApp:
    def __init__(
        self,
        *,
        save_directory: Path | None = None,
        audio_enabled: bool = True,
    ):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption(TITLE)
        self.audio = ProceduralAudio(enabled=audio_enabled)
        self.saves = SaveSystem(save_directory) if save_directory is not None else SaveSystem()

    def run(self) -> None:
        running = True
        try:
            while running:
                action = MenuScene(self.screen, self.audio, self.saves).run()
                if action == "quit":
                    break
                if action == "ranking":
                    running = RankingScene(self.screen, self.saves).run() != "quit"
                    continue

                if action == "new_game":
                    self.saves.clear_progress()
                    progress = None
                elif action == "continue_game":
                    progress = self.saves.load_progress()
                    if progress is None:
                        continue
                else:
                    continue

                result = GameScene(self.screen, self.audio, progress).run()
                status = str(result["status"])
                if status in {"menu", "quit"}:
                    self.saves.save_progress(
                        int(result["score"]),
                        int(result["lives"]),
                        int(float(result["elapsed_seconds"])),
                    )
                    running = status != "quit"
                    continue

                self.saves.clear_progress()
                outcome = GameOverScene(
                    self.screen,
                    self.saves,
                    score=int(result["score"]),
                    elapsed_seconds=float(result["elapsed_seconds"]),
                    won=status == "victory",
                ).run()
                running = outcome != "quit"
        finally:
            self.audio.stop()
            pygame.quit()

    def capture_screenshots(self, output_directory: Path) -> list[Path]:
        output_directory.mkdir(parents=True, exist_ok=True)
        paths: list[Path] = []

        menu = MenuScene(self.screen, self.audio, self.saves)
        menu.draw()
        menu_path = output_directory / "menu.png"
        pygame.image.save(self.screen, menu_path)
        paths.append(menu_path)

        gameplay = GameScene(self.screen, self.audio, seed=29)
        gameplay.prepare_preview(boss=False)
        gameplay.draw()
        gameplay_path = output_directory / "gameplay.png"
        pygame.image.save(self.screen, gameplay_path)
        paths.append(gameplay_path)

        boss_fight = GameScene(self.screen, self.audio, seed=29)
        boss_fight.prepare_preview(boss=True)
        boss_fight.draw()
        boss_path = output_directory / "boss-fight.png"
        pygame.image.save(self.screen, boss_path)
        paths.append(boss_path)

        return paths
