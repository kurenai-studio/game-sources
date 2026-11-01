import os

import chess
import pygame

from engine import choose_move, game_over_message

# Initialize pygame and chess board
pygame.init()
board = chess.Board()

# Constants for window dimensions and colors
WIDTH, HEIGHT = 600, 750
BOARD_SIZE = 512
MARGIN = (WIDTH - BOARD_SIZE) // 2
TITLE_HEIGHT = 50
SQ_SIZE = BOARD_SIZE // 8
LIGHT = (235, 236, 208)
DARK = (115, 149, 82)
LIGHT_HIGHLIGHT = (245, 246, 130)
DARK_HIGHLIGHT = (185, 202, 67)
BOT_HIGHLIGHT_COLOR = (205, 92, 92)
BACKGROUND_COLOR = (48, 46, 43)
PANEL_COLOR = (50, 50, 50)
WHITE = (255, 255, 255)

# Load chess piece images relative to this file, so the game runs from any directory
PIECES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'pieces')
pieces = {f'{color}_{piece}': pygame.image.load(os.path.join(PIECES_DIR, f'{color}_{piece}.png'))
          for color in ['w', 'b'] for piece in ['p', 'r', 'n', 'b', 'q', 'k']}

# Create screen
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Chess Bot")

# Fonts for the title and endgame message
title_font = pygame.font.Font(None, 48)
endgame_font = pygame.font.Font(None, 64)
small_font = pygame.font.Font(None, 32)

PROMOTION_CHOICES = [chess.QUEEN, chess.ROOK, chess.BISHOP, chess.KNIGHT]

# Variables for game state
selected_square = None
bot_last_move = None
game_over_text = None
running = True
game_mode = None
bot_difficulty = None
show_difficulty_selection = False
confirmation_active = False
confirm_restart_rect = None
cancel_restart_rect = None
pending_promotion = None   # (from_square, to_square) while the picker is open
bot_to_move = False        # set after the player moves; the bot replies next frame


def draw_board(selected_square=None, last_move=None):
    highlighted = {last_move.from_square, last_move.to_square} if last_move else set()
    for row in range(8):
        for col in range(8):
            square = chess.square(col, 7 - row)
            light = (row + col) % 2 == 0
            color = LIGHT if light else DARK
            if square in highlighted:
                color = BOT_HIGHLIGHT_COLOR
            if selected_square == square:
                color = LIGHT_HIGHLIGHT if light else DARK_HIGHLIGHT
            square_rect = pygame.Rect(
                MARGIN + col * SQ_SIZE, TITLE_HEIGHT + row * SQ_SIZE, SQ_SIZE, SQ_SIZE)
            pygame.draw.rect(screen, color, square_rect)


def piece_image(piece):
    return pieces[f'{"w" if piece.color else "b"}_{piece.symbol().lower()}']


def draw_pieces():
    for square in chess.SQUARES:
        piece = board.piece_at(square)
        if piece:
            image = piece_image(piece)
            x = MARGIN + chess.square_file(square) * SQ_SIZE + (SQ_SIZE - image.get_width()) // 2
            y = TITLE_HEIGHT + (7 - chess.square_rank(square)) * SQ_SIZE + (SQ_SIZE - image.get_height()) // 2
            screen.blit(image, pygame.Rect(x, y, SQ_SIZE, SQ_SIZE))


def draw_title():
    text = "Chess Bot"
    if bot_to_move:
        text = "Bot is thinking..."
    title_surface = title_font.render(text, True, WHITE)
    title_rect = title_surface.get_rect(center=(WIDTH // 2, TITLE_HEIGHT // 2))
    screen.blit(title_surface, title_rect)


def draw_endgame_message(message):
    message_surface = endgame_font.render(message, True, WHITE)
    message_rect = message_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
    backdrop = message_rect.inflate(30, 20)
    pygame.draw.rect(screen, PANEL_COLOR, backdrop)
    screen.blit(message_surface, message_rect)


def square_at(pos):
    mx, my = pos
    col = (mx - MARGIN) // SQ_SIZE
    row = (my - TITLE_HEIGHT) // SQ_SIZE
    if 0 <= col < 8 and 0 <= row < 8 and mx >= MARGIN and my >= TITLE_HEIGHT:
        return chess.square(int(col), 7 - int(row))
    return None


def is_pawn_promotion(from_square, to_square):
    piece = board.piece_at(from_square)
    return (piece is not None and piece.piece_type == chess.PAWN
            and chess.square_rank(to_square) in (0, 7))


def draw_promotion_picker():
    """Draw the four promotion options and return their click rects."""
    color = board.turn
    box = pygame.Rect(WIDTH // 2 - 2 * SQ_SIZE - 10, HEIGHT // 2 - SQ_SIZE // 2 - 40,
                      4 * SQ_SIZE + 20, SQ_SIZE + 60)
    pygame.draw.rect(screen, PANEL_COLOR, box)
    pygame.draw.rect(screen, WHITE, box, 3)
    label = small_font.render("Promote to:", True, WHITE)
    screen.blit(label, (box.x + 12, box.y + 8))
    rects = []
    for i, piece_type in enumerate(PROMOTION_CHOICES):
        rect = pygame.Rect(box.x + 10 + i * SQ_SIZE, box.y + 45, SQ_SIZE, SQ_SIZE)
        pygame.draw.rect(screen, LIGHT if i % 2 == 0 else DARK, rect)
        image = piece_image(chess.Piece(piece_type, color))
        screen.blit(image, image.get_rect(center=rect.center))
        rects.append((rect, piece_type))
    return rects


def draw_mode_selection():
    screen.fill(BACKGROUND_COLOR)
    title_surface = title_font.render("Choose Game Mode", True, WHITE)
    screen.blit(title_surface, title_surface.get_rect(center=(WIDTH // 2, HEIGHT // 4)))
    pvp_surface = endgame_font.render("Player vs Player", True, WHITE)
    pvp_rect = pvp_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
    screen.blit(pvp_surface, pvp_rect)
    pvb_surface = endgame_font.render("Player vs Bot", True, WHITE)
    pvb_rect = pvb_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 100))
    screen.blit(pvb_surface, pvb_rect)
    return pvp_rect, pvb_rect


def draw_difficulty_selection():
    screen.fill(BACKGROUND_COLOR)
    title_surface = title_font.render("Select Bot Difficulty", True, WHITE)
    screen.blit(title_surface, title_surface.get_rect(center=(WIDTH // 2, HEIGHT // 4)))
    rects = []
    for i, label in enumerate(["Easy", "Medium", "Hard"]):
        surface = endgame_font.render(label, True, WHITE)
        rect = surface.get_rect(center=(WIDTH // 2, HEIGHT // 2 - 50 + i * 100))
        screen.blit(surface, rect)
        rects.append(rect)
    return rects


def draw_restart_button():
    restart_surface = endgame_font.render("Restart", True, WHITE)
    restart_rect = restart_surface.get_rect(center=(WIDTH // 2, HEIGHT - 50))
    screen.blit(restart_surface, restart_rect)
    return restart_rect


def reset_game():
    global game_mode, bot_difficulty, show_difficulty_selection, game_over_text
    global selected_square, confirmation_active, bot_last_move, pending_promotion, bot_to_move
    board.reset()
    game_mode = None
    bot_difficulty = None
    show_difficulty_selection = False
    game_over_text = None
    selected_square = None
    confirmation_active = False
    bot_last_move = None
    pending_promotion = None
    bot_to_move = False


def draw_confirmation_box():
    box_width, box_height = 400, 150
    box = pygame.Rect(WIDTH // 2 - box_width // 2, HEIGHT // 2 - box_height // 2, box_width, box_height)
    pygame.draw.rect(screen, PANEL_COLOR, box)
    pygame.draw.rect(screen, WHITE, box, 3)
    confirm_text = endgame_font.render("Restart game?", True, WHITE)
    screen.blit(confirm_text, (box.x + 60, box.y + 20))
    yes_surface = endgame_font.render("Yes", True, WHITE)
    no_surface = endgame_font.render("No", True, WHITE)
    yes_rect = yes_surface.get_rect(center=(box.x + 100, box.y + 100))
    no_rect = no_surface.get_rect(center=(box.x + 300, box.y + 100))
    screen.blit(yes_surface, yes_rect)
    screen.blit(no_surface, no_rect)
    return yes_rect, no_rect


def play(move):
    """Push a human move and hand the turn to the bot if needed."""
    global selected_square, game_over_text, bot_to_move
    board.push(move)
    selected_square = None
    game_over_text = game_over_message(board, vs_bot=game_mode == 'pvb')
    bot_to_move = game_over_text is None and game_mode == 'pvb'


def handle_board_click(square):
    global selected_square, pending_promotion
    if square is None:
        return
    piece = board.piece_at(square)
    if selected_square is None:
        if piece and piece.color == board.turn:
            selected_square = square
        return
    if piece and piece.color == board.turn and square != selected_square:
        selected_square = square  # switch to another of your own pieces
        return
    if is_pawn_promotion(selected_square, square):
        if any(m.from_square == selected_square and m.to_square == square for m in board.legal_moves):
            pending_promotion = (selected_square, square)
        else:
            selected_square = None
        return
    move = chess.Move(selected_square, square)
    if move in board.legal_moves:
        play(move)
    else:
        selected_square = None


while running:
    screen.fill(BACKGROUND_COLOR)
    promotion_rects = []

    if game_mode is None:
        pvp_rect, pvb_rect = draw_mode_selection()
    elif show_difficulty_selection:
        easy_rect, medium_rect, hard_rect = draw_difficulty_selection()
    else:
        draw_title()
        draw_board(selected_square, bot_last_move)
        draw_pieces()
        if game_over_text:
            draw_endgame_message(game_over_text)
        restart_rect = draw_restart_button()
        if pending_promotion:
            promotion_rects = draw_promotion_picker()
        if confirmation_active:
            confirm_restart_rect, cancel_restart_rect = draw_confirmation_box()

    pygame.display.flip()

    # The bot replies after the player's move has been drawn.
    if bot_to_move:
        bot_last_move = choose_move(board, bot_difficulty)
        if bot_last_move:
            board.push(bot_last_move)
        game_over_text = game_over_message(board, vs_bot=True)
        bot_to_move = False
        continue

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type != pygame.MOUSEBUTTONDOWN:
            continue
        mouse_pos = event.pos
        if game_mode is None:
            if pvp_rect.collidepoint(mouse_pos):
                game_mode = 'pvp'
            elif pvb_rect.collidepoint(mouse_pos):
                game_mode = 'pvb'
                show_difficulty_selection = True
        elif show_difficulty_selection:
            for rect, level in ((easy_rect, 'easy'), (medium_rect, 'medium'), (hard_rect, 'hard')):
                if rect.collidepoint(mouse_pos):
                    bot_difficulty = level
                    show_difficulty_selection = False
        elif confirmation_active:
            if confirm_restart_rect.collidepoint(mouse_pos):
                reset_game()
            elif cancel_restart_rect.collidepoint(mouse_pos):
                confirmation_active = False
        elif restart_rect.collidepoint(mouse_pos):
            confirmation_active = True
        elif pending_promotion:
            for rect, piece_type in promotion_rects:
                if rect.collidepoint(mouse_pos):
                    from_sq, to_sq = pending_promotion
                    pending_promotion = None
                    play(chess.Move(from_sq, to_sq, promotion=piece_type))
                    break
            else:
                pending_promotion = None
                selected_square = None
        elif not game_over_text:
            handle_board_click(square_at(mouse_pos))

pygame.quit()
