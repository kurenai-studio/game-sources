"""
Gamepad & Universal Input Manager (Pure Pygame).
Handles controller auto-detection, hotplugging, deadzone filtering,
D-pad/analog stick navigation, and unified action mappings for keyboard and gamepads.
"""

import sys
import pygame
from typing import Dict, List, Optional, Tuple, Set

class InputManager:
    """Universal Input Subsystem supporting Keyboard, Mouse, and multiple Gamepads."""

    # Default analog deadzone (threshold to ignore drift)
    DEADZONE = 0.35

    # Unified Action Identifiers
    ACTION_CONFIRM = "CONFIRM"
    ACTION_BACK = "BACK"
    ACTION_PAUSE = "PAUSE"
    ACTION_RESTART = "RESTART"
    ACTION_BOMB = "BOMB"
    ACTION_UP = "UP"
    ACTION_DOWN = "DOWN"
    ACTION_LEFT = "LEFT"
    ACTION_RIGHT = "RIGHT"

    def __init__(self):
        self.controllers: Dict[int, pygame.joystick.Joystick] = {}
        self._init_joysticks()

        # Input state tracking for edge detection (just pressed)
        self.prev_keys = set()
        self.curr_keys = set()
        self.prev_buttons: Dict[int, Set[int]] = {}
        self.curr_buttons: Dict[int, Set[int]] = {}

        # UI Navigation repeat timers
        self._last_nav_dir: Optional[str] = None
        self._nav_timer: float = 0.0
        self._repeat_delay: float = 0.32
        self._repeat_rate: float = 0.12

    def _init_joysticks(self):
        """Initializes Pygame joystick subsystem and detects connected devices."""
        try:
            if not pygame.joystick.get_init():
                pygame.joystick.init()
            
            count = pygame.joystick.get_count()
            for i in range(count):
                try:
                    joy = pygame.joystick.Joystick(i)
                    joy.init()
                    self.controllers[i] = joy
                except Exception:
                    pass
        except Exception:
            pass

    def handle_event(self, event: pygame.event.Event):
        """Processes joystick hotplug events."""
        if event.type == pygame.JOYDEVICEADDED:
            try:
                joy = pygame.joystick.Joystick(event.device_index)
                joy.init()
                self.controllers[event.device_index] = joy
            except Exception:
                pass

        elif event.type == pygame.JOYDEVICEREMOVED:
            instance_id = event.instance_id
            target_key = None
            for key, joy in self.controllers.items():
                if joy.get_instance_id() == instance_id:
                    target_key = key
                    break
            if target_key is not None:
                try:
                    self.controllers[target_key].quit()
                except Exception:
                    pass
                self.controllers.pop(target_key, None)

    def update(self, dt: float):
        """Ticks repeat timers and updates button edge tracking."""
        if self._last_nav_dir is not None:
            self._nav_timer += dt

        # Update controller button edge sets
        self.prev_buttons = {k: set(v) for k, v in self.curr_buttons.items()}
        for idx, joy in self.controllers.items():
            active_btns = set()
            try:
                for b in range(joy.get_numbuttons()):
                    if joy.get_button(b):
                        active_btns.add(b)
            except Exception:
                pass
            self.curr_buttons[idx] = active_btns

    def get_connected_controllers(self) -> List[str]:
        """Returns the list of names for all connected controllers."""
        names = []
        for idx, joy in self.controllers.items():
            try:
                names.append(joy.get_name() or f"Gamepad {idx + 1}")
            except Exception:
                names.append(f"Controller {idx + 1}")
        return names

    def is_controller_connected(self) -> bool:
        """Returns True if at least one gamepad is connected."""
        return len(self.controllers) > 0

    def get_movement(self, player: int = 0) -> Tuple[int, int]:
        """
        Returns unified movement vector (dx, dy) with values in {-1, 0, 1}.
        Aggregates Gamepad (D-pad & Analog) and Keyboard for the given player.
        """
        dx, dy = 0, 0

        # 1. Controller Input
        if player in self.controllers:
            joy = self.controllers[player]
            try:
                # Check D-pad (Hat)
                if joy.get_numhats() > 0:
                    hat_x, hat_y = joy.get_hat(0)
                    if hat_x != 0:
                        dx = 1 if hat_x > 0 else -1
                    if hat_y != 0:
                        dy = -1 if hat_y > 0 else 1  # Pygame hat Y is inverted (+1 is UP)

                # Check Left Analog Stick if D-pad is idle
                if dx == 0 and dy == 0 and joy.get_numaxes() >= 2:
                    axis_x = joy.get_axis(0)
                    axis_y = joy.get_axis(1)

                    if abs(axis_x) > self.DEADZONE:
                        dx = 1 if axis_x > 0 else -1
                    if abs(axis_y) > self.DEADZONE:
                        dy = 1 if axis_y > 0 else -1
            except Exception:
                pass

        if dx != 0 or dy != 0:
            return dx, dy

        # 2. Keyboard Input Fallback
        keys = pygame.key.get_pressed()
        if player == 0:
            # Player 1: Arrow keys or WASD
            if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
                dx = 1
            elif keys[pygame.K_LEFT] or keys[pygame.K_a]:
                dx = -1
            elif keys[pygame.K_UP] or keys[pygame.K_w]:
                dy = -1
            elif keys[pygame.K_DOWN] or keys[pygame.K_s]:
                dy = 1
        elif player == 1:
            # Player 2: Arrow keys or Numpad
            if keys[pygame.K_RIGHT] or keys[pygame.K_KP6]:
                dx = 1
            elif keys[pygame.K_LEFT] or keys[pygame.K_KP4]:
                dx = -1
            elif keys[pygame.K_UP] or keys[pygame.K_KP8]:
                dy = -1
            elif keys[pygame.K_DOWN] or keys[pygame.K_KP2]:
                dy = 1

        return dx, dy

    def is_action_pressed(self, action: str, player: int = 0) -> bool:
        """Checks if an action is currently held down on controller or keyboard."""
        # 1. Controller check
        if player in self.controllers:
            joy = self.controllers[player]
            try:
                num_btns = joy.get_numbuttons()
                if action in (self.ACTION_CONFIRM, self.ACTION_BOMB):
                    # Button A (0) or X (2)
                    if (num_btns > 0 and joy.get_button(0)) or (num_btns > 2 and joy.get_button(2)):
                        return True
                elif action == self.ACTION_BACK:
                    # Button B (1)
                    if num_btns > 1 and joy.get_button(1):
                        return True
                elif action == self.ACTION_PAUSE:
                    # Start / Menu button (typically 7 or 9)
                    for b in (7, 6, 9):
                        if num_btns > b and joy.get_button(b):
                            return True
                elif action == self.ACTION_RESTART:
                    # Button Y (3) or Select (6)
                    for b in (3, 6):
                        if num_btns > b and joy.get_button(b):
                            return True
            except Exception:
                pass

        # 2. Keyboard check
        keys = pygame.key.get_pressed()
        if action == self.ACTION_BOMB:
            return keys[pygame.K_SPACE]
        elif action == self.ACTION_CONFIRM:
            return keys[pygame.K_RETURN] or keys[pygame.K_SPACE]
        elif action == self.ACTION_BACK:
            return keys[pygame.K_ESCAPE] or keys[pygame.K_BACKSPACE]
        elif action == self.ACTION_PAUSE:
            return keys[pygame.K_ESCAPE]
        elif action == self.ACTION_RESTART:
            return keys[pygame.K_r]

        return False

    def is_action_just_pressed(self, action: str, player: int = 0) -> bool:
        """Edge detection: True only on the frame the action is initially triggered."""
        curr = self.is_action_pressed(action, player)
        # Controller button edge check
        if player in self.controllers:
            curr_set = self.curr_buttons.get(player, set())
            prev_set = self.prev_buttons.get(player, set())
            diff = curr_set - prev_set

            if action in (self.ACTION_CONFIRM, self.ACTION_BOMB):
                if 0 in diff or 2 in diff:
                    return True
            elif action == self.ACTION_BACK:
                if 1 in diff:
                    return True
            elif action == self.ACTION_PAUSE:
                if any(b in diff for b in (7, 6, 9)):
                    return True
            elif action == self.ACTION_RESTART:
                if any(b in diff for b in (3, 6)):
                    return True

        return curr

    def get_ui_nav(self) -> Optional[str]:
        """
        Returns a discrete UI navigation direction ('UP', 'DOWN', 'LEFT', 'RIGHT', 'CONFIRM', 'BACK')
        with standard repeat acceleration for menu browsing.
        """
        dx, dy = self.get_movement(player=0)
        active_dir = None
        if dy < 0:
            active_dir = "UP"
        elif dy > 0:
            active_dir = "DOWN"
        elif dx < 0:
            active_dir = "LEFT"
        elif dx > 0:
            active_dir = "RIGHT"

        # Check confirm / back actions
        if self.is_action_just_pressed(self.ACTION_CONFIRM):
            return "CONFIRM"
        if self.is_action_just_pressed(self.ACTION_BACK):
            return "BACK"

        if active_dir is None:
            self._last_nav_dir = None
            self._nav_timer = 0.0
            return None

        if active_dir != self._last_nav_dir:
            self._last_nav_dir = active_dir
            self._nav_timer = 0.0
            return active_dir

        # Auto-repeat logic
        if self._nav_timer > self._repeat_delay:
            self._nav_timer -= self._repeat_rate
            return active_dir

        return None
