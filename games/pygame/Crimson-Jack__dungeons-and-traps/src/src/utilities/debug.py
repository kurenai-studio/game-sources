import threading

import pygame


class Debug:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                # Another thread could have created the instance
                # before we acquired the lock. So check that the
                # instance is still nonexistent.
                if not cls._instance:
                    cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, x=10, y=10):
        self.enabled = False
        self.text_color = 0, 0, 0
        self.main_grid_color = 0, 0, 0
        self.alternative_grid_color = 0, 255, 0
        self.path_color = 0, 255, 255
        self.info_list = []
        self.x = x
        self.y = y
        pygame.init()
        self.font = pygame.font.Font(None, 26)

    def add_info(self, info):
        self.info_list.append(info)

    def show(self, area_position):
        # Text is drawn relative to area_position - the top left corner of an area redrawn every frame
        if self.enabled:
            display_surface = pygame.display.get_surface()
            y_position = 0
            for info in self.info_list:
                debug_surface = self.font.render(str(info), True, self.text_color)
                debug_surface.set_alpha(150)
                debug_rect = debug_surface.get_rect(topleft=(area_position[0] + self.x,
                                                             area_position[1] + self.y + y_position))
                display_surface.blit(debug_surface, debug_rect)
                y_position += 20

        # Clear list
        self.info_list.clear()

    def input(self):
        keys = pygame.key.get_pressed()

        if keys[pygame.K_F1]:
            self.enabled = True
            self.text_color = 255, 255, 255
            self.main_grid_color = 0, 0, 0
            self.alternative_grid_color = 0, 255, 0
            self.path_color = 0, 255, 255
        elif keys[pygame.K_F2]:
            self.enabled = True
            self.text_color = 0, 0, 0
            self.main_grid_color = 255, 255, 255
            self.alternative_grid_color = 255, 0, 0
            self.path_color = 255, 0, 255
        elif keys[pygame.K_F3]:
            self.enabled = False
