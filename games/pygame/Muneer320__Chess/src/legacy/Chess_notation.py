import pygame
import chess


# Initialize pygame and chess board
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
WHITE_MOVE_COLOR = (25, 53, 73)
BLACK_MOVE_COLOR = (38, 44, 58)

# Load chess piece images
pieces = {f'{color}_{piece}': pygame.image.load(f'pieces/{color}_{piece}.png') for color in ['w', 'b'] for piece in ['p', 'r', 'n', 'b', 'q', 'k']}


# Create screen
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Chess Game")

# Fonts for the title and moves
title_font = pygame.font.Font(None, 48)
moves_font = pygame.font.Font(None, 28)
moves_number_font = pygame.font.Font(None, 24)

TEXT_COLOR = (255, 255, 255)
INPUT_BOX_COLOR = (255, 0, 0)
font = pygame.font.Font(None, 32)
input_box = pygame.Rect((WIDTH//2) - 200, 625, 400, 50)
input_text = ''


move_list = []
scroll_offset = 0

def draw_board(selected_square=None):
    """Draw the chessboard with a possible highlighted square."""
    for row in range(8):
        for col in range(8):
            color = LIGHT_BLUE if (row + col) % 2 == 0 else DARK_BLUE
            square_rect = pygame.Rect(MARGIN + col * SQ_SIZE, TITLE_HEIGHT + row * SQ_SIZE, SQ_SIZE, SQ_SIZE)
            pygame.draw.rect(screen, color, square_rect)

            # Highlight the selected square
            if selected_square == chess.square(col, 7 - row):
                pygame.draw.rect(screen, HIGHLIGHT_COLOR, square_rect, 4)  # Draw a border on the selected square

    # Draw a textbox, to enter the notation of next move
    pygame.draw.rect(screen, INPUT_BOX_COLOR, input_box, 2)
    text_surface = font.render(input_text, True, TEXT_COLOR)
    screen.blit(text_surface, (input_box.x + 5, input_box.y + 5))


def draw_pieces():
    """Draw the pieces on the board based on the current board state."""
    for square in chess.SQUARES:
        piece = board.piece_at(square)
        if piece:
            piece_color = 'w' if piece.color else 'b'
            piece_type = piece.symbol().lower()
            piece_image = pieces[f'{piece_color}_{piece_type}']
            x = MARGIN + chess.square_file(square) * SQ_SIZE + (SQ_SIZE - piece_image.get_width()) // 2
            y = TITLE_HEIGHT + (7 - chess.square_rank(square)) * SQ_SIZE + (SQ_SIZE - piece_image.get_height()) // 2
            screen.blit(piece_image, pygame.Rect(x, y, SQ_SIZE, SQ_SIZE))

def draw_title():
    """Draw the game title at the top of the screen."""
    title_surface = title_font.render("Chess Game", True, (255, 255, 255))
    title_rect = title_surface.get_rect(center=(WIDTH // 2, TITLE_HEIGHT // 2))
    screen.blit(title_surface, title_rect)

def get_square_under_mouse():
    """Get the square on the board based on mouse position."""
    mouse_pos = pygame.Vector2(pygame.mouse.get_pos())
    x, y = [int((v - MARGIN) // SQ_SIZE) for v in mouse_pos]
    if 0 <= x < 8 and TITLE_HEIGHT <= y * SQ_SIZE + TITLE_HEIGHT < TITLE_HEIGHT + BOARD_SIZE:
        return chess.square(x, 7 - int((mouse_pos[1] - TITLE_HEIGHT) // SQ_SIZE))  # Translate GUI to chess coords
    return None

def is_pawn_promotion(move):
    """Check if the move is a pawn promotion."""
    return board.piece_at(move.from_square).piece_type == chess.PAWN and (chess.square_rank(move.to_square) == 0 or chess.square_rank(move.to_square) == 7)

def pawn_promotion():
    """Handle pawn promotion by prompting the user for promotion type."""
    promotion_type = chess.QUEEN  # Default to queen for simplicity
    return promotion_type

selected_square = None
running = True

# Main loop
while running:
    screen.fill(BACKGROUND_COLOR)
    draw_title()
    draw_board(selected_square)
    draw_pieces()

    if board.is_game_over():
        game_over_message = "Game Over: " + board.result()
        font = pygame.font.SysFont(None, 55)
        text = font.render(game_over_message, True, (255, 0, 0))
        screen.blit(text, (WIDTH // 2 - text.get_width() // 2, HEIGHT // 2 - text.get_height() // 2))
    else:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RETURN:
                    try:
                        move = board.parse_san(input_text)
                        if move in board.legal_moves:
                            board.push(move)
                            input_text = ''
                    except ValueError:
                        print("Invalid move")
                elif event.key == pygame.K_BACKSPACE:
                    input_text = input_text[:-1]
                else:
                    input_text += event.unicode

    pygame.display.flip()

pygame.quit()
