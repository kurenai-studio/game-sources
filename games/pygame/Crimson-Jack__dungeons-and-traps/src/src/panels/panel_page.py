import pygame


class PanelPage:
    @property
    def title(self) -> str:
        pass

    def get_content_height(self) -> int:
        pass

    def draw_content(self, screen: pygame.Surface, content_rect: pygame.Rect) -> None:
        pass
