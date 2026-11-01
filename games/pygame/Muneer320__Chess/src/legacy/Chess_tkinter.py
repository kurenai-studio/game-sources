import tkinter as tk
import chess
from PIL import Image, ImageTk

class ChessApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Chess App")

        self.board = chess.Board()
        self.canvas = tk.Canvas(root, width=400, height=400)
        self.canvas.pack()

        self.image_cache = {}  # Store images to prevent garbage collection
        self.selected_square = None

        self.draw_board()
        self.draw_pieces()

        self.canvas.bind("<Button-1>", self.on_click)

        # Add this line in __init__ to create a label
        self.algebraic_label = tk.Label(root, text="Algebraic Notation: ")
        self.algebraic_label.pack()

    def draw_board(self):
        for row in range(8):
            for col in range(8):
                color = "light grey" if (row + col) % 2 == 0 else "dark grey"
                self.canvas.create_rectangle(
                    col * 50, row * 50, (col + 1) * 50, (row + 1) * 50, fill=color
                )

    def draw_pieces(self):
        for square in chess.SQUARES:
            piece = self.board.piece_at(square)
            if piece:
                piece_name = piece.symbol().lower()
                file_path = f"pieces/{'w' if piece.color == chess.WHITE else 'b'}_{piece_name}.png"

                if file_path not in self.image_cache:
                    image = self.load_image(file_path)
                    self.image_cache[file_path] = image
                else:
                    image = self.image_cache[file_path]

                col, row = chess.square_file(square), 7 - chess.square_rank(square)
                piece_tag = f"piece_{square}"
                self.canvas.create_image(
                    col * 50 + 25,
                    row * 50 + 25,
                    image=image,
                    tags=("pieces", piece_tag),
                    anchor=tk.CENTER  # Center the image at the specified position
                )

    def load_image(self, file_path):
        image = Image.open(file_path)
        image = ImageTk.PhotoImage(image)
        return image

    def on_click(self, event):
        col = event.x // 50
        row = 7 - (event.y // 50)
        square = chess.square(col, row)

        if self.selected_square is None:
            self.selected_square = square
            self.highlight_legal_moves()
        else:
            moves = [move.to_square for move in self.board.legal_moves if move.from_square == self.selected_square]
            if square in moves:
                move = chess.Move(self.selected_square, square)
                if move in self.board.legal_moves:
                    print(f"Making move: {move}")
                    self.remove_piece_from_square(self.selected_square)
                    self.board.push(move)
                    self.draw_pieces()
                    self.display_algebraic_notation(move)
                else:
                    print(f"Invalid move: {move}")
            else:
                print(f"Square {square} is not a legal move from {self.selected_square}")

            self.selected_square = None
            self.canvas.delete("highlight")  # Clear previous highlights

            if self.board.is_checkmate() or self.board.is_stalemate():
                print("Game Over!")
                # Reset the board if the game is over
                self.board.reset()
                self.draw_pieces()

    def remove_piece_from_square(self, square):
        # Remove the piece image from the canvas by deleting its tag
        piece_tag = f"piece_{square}"
        self.canvas.delete(piece_tag)

    def highlight_legal_moves(self):
        moves = [move.to_square for move in self.board.legal_moves if move.from_square == self.selected_square]
        for square in moves:
            col, row = chess.square_file(square), 7 - chess.square_rank(square)
            self.canvas.create_rectangle(
                col * 50, row * 50, (col + 1) * 50, (row + 1) * 50,
                fill="light green", outline="black", tags=("highlight",)
            )

    def display_algebraic_notation(self, move):
        notation = self.board.san(move)
        print("Algebraic Notation:", notation)
        self.algebraic_label.config(text=f"Algebraic Notation: {notation}")


if __name__ == "__main__":
    root = tk.Tk()
    app = ChessApp(root)
    root.mainloop()
