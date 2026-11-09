"""Scenes: the screens the game switches between (main menu, play, pause, game over).

The Game always has exactly one current scene. It passes each event, update
and draw to that scene, and scenes switch by calling the Game's navigation
methods (``start_run``, ``pause``, ``open_main_menu`` ...).
"""
