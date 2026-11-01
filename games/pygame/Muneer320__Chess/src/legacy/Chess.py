"""
This script was supposed to show the moves in algebraic notation in order of the move,
but due to some bug in the script it isn't working as expected, and I am too lazy to look for it.
So if anybody is interested they can do it.
"""

import pygame
import chess


pygame.init()
board = chess.Board()

# Constants for window dimensions and colors
WIDTH, HEIGHT = 600, 750
BOARD_SIZE = 512
MARGIN = (WIDTH - BOARD_SIZE) // 2
TITLE_HEIGHT = 50
MOVE_HEIGHT = 180

SQ_SIZE = BOARD_SIZE // 8
LIGHT_BLUE = (173, 216, 230)
DARK_BLUE = (70, 130, 180)
HIGHLIGHT_COLOR = (255, 255, 0)

# UI colors
BACKGROUND_COLOR = (50, 50, 70)
ALTERNATE_MOVE_COLORS = [(230, 230, 255), (210, 230, 255)]

# Colors for moves
WHITE_MOVE_COLOR = (25, 53, 73)
BLACK_MOVE_COLOR = (38, 44, 58)

# Load chess piece images
pieces = {f'{color}_{piece}': pygame.image.load(
    f'pieces/{color}_{piece}.png') for color in ['w', 'b'] for piece in ['p', 'r', 'n', 'b', 'q', 'k']}

# Create screen
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Chess Game")

# Fonts for the title and moves
title_font = pygame.font.Font(None, 48)
moves_font = pygame.font.Font(None, 28)
moves_number_font = pygame.font.Font(None, 24)
endgame_font = pygame.font.Font(None, 64)

move_list = []
scroll_offset = 0


def draw_board(selected_square=None):
    """Draw the chessboard with a possible highlighted square."""
    for row in range(8):
        for col in range(8):
            color = LIGHT_BLUE if (row + col) % 2 == 0 else DARK_BLUE
            square_rect = pygame.Rect(
                MARGIN + col * SQ_SIZE, TITLE_HEIGHT + row * SQ_SIZE, SQ_SIZE, SQ_SIZE)
            pygame.draw.rect(screen, color, square_rect)

            # Highlight the selected square
            if selected_square == chess.square(col, 7 - row):
                pygame.draw.rect(screen, HIGHLIGHT_COLOR, square_rect, 4)


def draw_pieces():
    """Draw the pieces on the board based on the current board state."""
    for square in chess.SQUARES:
        piece = board.piece_at(square)
        if piece:
            piece_color = 'w' if piece.color else 'b'
            piece_type = piece.symbol().lower()
            piece_image = pieces[f'{piece_color}_{piece_type}']
            x = MARGIN + \
                chess.square_file(square) * SQ_SIZE + \
                (SQ_SIZE - piece_image.get_width()) // 2
            y = TITLE_HEIGHT + (7 - chess.square_rank(square)) * \
                SQ_SIZE + (SQ_SIZE - piece_image.get_height()) // 2
            screen.blit(piece_image, pygame.Rect(x, y, SQ_SIZE, SQ_SIZE))


def draw_title():
    """Draw the game title at the top of the screen."""
    title_surface = title_font.render("Chess Game", True, (255, 255, 255))
    title_rect = title_surface.get_rect(center=(WIDTH // 2, TITLE_HEIGHT // 2))
    screen.blit(title_surface, title_rect)


def draw_move_list():
    """Draw the list of moves at the bottom of the screen."""
    visible_moves = (MOVE_HEIGHT - 30) // 30

    for i in range(len(move_list)):
        if i >= scroll_offset and i < scroll_offset + visible_moves:
            move_text = move_list[i]
            bg_color = ALTERNATE_MOVE_COLORS[i % 2]
            y_offset = HEIGHT - MOVE_HEIGHT + 30 + (i - scroll_offset) * 30

            pygame.draw.rect(screen, bg_color, pygame.Rect(
                MARGIN, y_offset, BOARD_SIZE, 30))

            if i % 2 == 0:  # White move
                move_number_surface = moves_number_font.render(
                    f"{(i // 2) + 1}.", True, WHITE_MOVE_COLOR)
                move_surface = moves_font.render(
                    move_text, True, WHITE_MOVE_COLOR)
            else:  # Black move
                move_number_surface = moves_number_font.render(
                    "", True, BLACK_MOVE_COLOR)
                move_surface = moves_font.render(
                    move_text, True, BLACK_MOVE_COLOR)

            screen.blit(move_number_surface, (MARGIN + 10, y_offset + 5))
            screen.blit(move_surface, (MARGIN + 50, y_offset + 5))


def get_square_under_mouse():
    """Get the square on the board based on mouse position."""
    mouse_pos = pygame.Vector2(pygame.mouse.get_pos())
    x, y = [int((v - MARGIN) // SQ_SIZE) for v in mouse_pos]
    if 0 <= x < 8 and TITLE_HEIGHT <= y * SQ_SIZE + TITLE_HEIGHT < TITLE_HEIGHT + BOARD_SIZE:
        # Translate GUI to chess coords
        return chess.square(x, 7 - int((mouse_pos[1] - TITLE_HEIGHT) // SQ_SIZE))
    return None


def is_pawn_promotion(move):
    """Check if the move is a pawn promotion."""
    return board.piece_at(move.from_square).piece_type == chess.PAWN and (chess.square_rank(move.to_square) == 0 or chess.square_rank(move.to_square) == 7)


def pawn_promotion():
    """Handle pawn promotion by prompting the user for promotion type."""
    promotion_type = chess.QUEEN
    return promotion_type


def check_game_over():
    """Check if the game is over and return the result message."""
    if board.is_checkmate():
        if board.turn:
            return "Checkmate! Black Wins!"
        else:
            return "Checkmate! White Win!"
    elif board.is_stalemate():
        return "Stalemate! It's a Draw!"
    elif board.is_insufficient_material():
        return "Draw due to Insufficient Material!"
    elif board.is_seventyfive_moves():
        return "Draw by 75-move Rule!"
    elif board.is_fivefold_repetition():
        return "Draw by Repetition!"
    elif board.is_variant_draw():
        return "Draw by Variant!"
    return None


def draw_endgame_message(message):
    """Draw the endgame message when the game ends."""
    message_surface = endgame_font.render(message, True, (255, 255, 255))
    message_rect = message_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
    screen.blit(message_surface, message_rect)


selected_square = None
running = True
game_over_message = None

# Main loop
while running:
    screen.fill(BACKGROUND_COLOR)
    draw_title()
    draw_board(selected_square)
    draw_pieces()
    draw_move_list()

    if game_over_message:
        draw_endgame_message(game_over_message)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if not game_over_message:
            if event.type == pygame.MOUSEBUTTONDOWN:
                square = get_square_under_mouse()

                if square is not None:
                    if selected_square is None:
                        # First click: select piece
                        # Only select if there's a piece on the square
                        if board.piece_at(square):
                            selected_square = square
                    else:
                        # Second click: make move
                        move = chess.Move(selected_square, square)
                        if is_pawn_promotion(move):
                            promotion = pawn_promotion()
                            move = chess.Move(
                                selected_square, square, promotion=promotion)

                        if move in board.legal_moves:
                            san_move = board.san(move)
                            board.push(move)
                            move_list.insert(0, san_move)

                        selected_square = None
                        game_over_message = check_game_over()

        if event.type == pygame.MOUSEBUTTONUP:
            if event.button == 4:  # Scroll up
                if scroll_offset > 0:
                    scroll_offset -= 1
            elif event.button == 5:  # Scroll down
                if scroll_offset < len(move_list) - ((MOVE_HEIGHT - 30) // 30):
                    scroll_offset += 1

    pygame.display.flip()

pygame.quit()
