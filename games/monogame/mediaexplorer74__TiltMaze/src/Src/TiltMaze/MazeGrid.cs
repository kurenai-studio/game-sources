using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System;
using System.Runtime.CompilerServices;

namespace TiltMaze
{
    // Implements the maze-generation algorithm known as "recursive division"
    public class MazeGrid
    {
        Random rand = new Random();

        public MazeGrid(int width, int height)
        {
            Width = width;
            Height = height;
            Cells = new MazeCell[Width, Height];

            for (int y = 0; y < Height; y++)
                for (int x = 0; x < Width; x++)
                {
                    Cells[x, y].HasLeft = x == 0;
                    Cells[x, y].HasTop = y == 0;
                    Cells[x, y].HasRight = x == Width - 1;
                    Cells[x, y].HasBottom = y == Height - 1;
                }

            MazeChamber rootChamber = new MazeChamber(0, 0, Width, Height);
            DivideChamber(rootChamber);
        }

        public int Width { protected set; get; }

        public int Height { protected set; get; }

        public MazeCell[,] Cells { protected set; get; }

        public void GenerateMaze()
        {
            MazeChamber rootChamber = new MazeChamber(0, 0, Width, Height);
            DivideChamber(rootChamber);
        }

        void DivideChamber(MazeChamber chamber)
        {
            if (chamber.Width == 1 && chamber.Height == 1)
            {
                return;
            }

            bool divideWidth = chamber.Width > chamber.Height;

            if (chamber.Width == 1 || chamber.Height >= 2 * chamber.Width)
            {
                divideWidth = false;
            }
            else if (chamber.Height == 1 || chamber.Width >= 2 * chamber.Height)
            {
                divideWidth = true;
            }
            else
            {
                divideWidth = Convert.ToBoolean(rand.Next(2));
            }

            int rowCol = chamber.Divide(divideWidth);

            if (divideWidth)
            {
                int col = rowCol;
                int gap = rand.Next(chamber.Y, chamber.Y + chamber.Height);

                for (int y = chamber.Y; y < chamber.Y + chamber.Height; y++)
                {
                    Cells[col - 1, y].HasRight = y != gap;
                    Cells[col, y].HasLeft = y != gap;
                }
            }
            else
            {
                int row = rowCol;
                int gap = rand.Next(chamber.X, chamber.X + chamber.Width);

                for (int x = chamber.X; x < chamber.X + chamber.Width; x++){
                    Cells[x, row - 1].HasBottom = x != gap;
                    Cells[x, row].HasTop = x != gap;
                }
            }

            DivideChamber(chamber.Chamber1);
            DivideChamber(chamber.Chamber2);
        }

        public Vector2 GetStartCellPosition()
        {
            // Assuming start is top-left corner of the maze
            return new Vector2(10, 10);
        }

        public Vector2 GetEndCellPosition()
        {
            // Assuming end is bottom-right corner of the maze
            return new Vector2(Width - 1, Height - 1);
        }

        public Vector2 GetRandomCellPosition()
        {
            return new Vector2(rand.Next(Width), rand.Next(Height));
        }

      
        public void Draw(SpriteBatch spriteBatch, GraphicsDevice graphicsDevice, Texture2D wallTexture, float cellSize)
        {
            // For simplicity, let's draw walls as lines
            // You might want to use textures for a better look

            for (int y = 0; y < Height; y++)
            {
                for (int x = 0; x < Width; x++)
                {
                    Vector2 cellTopLeft = new Vector2(x * cellSize, y * cellSize);

                    if (Cells[x, y].HasTop)
                    {
                        spriteBatch.Draw(wallTexture, new Rectangle((int)cellTopLeft.X, (int)cellTopLeft.Y, (int)cellSize, 2), Color.White);
                    }
                    if (Cells[x, y].HasBottom)
                    {
                        spriteBatch.Draw(wallTexture, new Rectangle((int)cellTopLeft.X, (int)(cellTopLeft.Y + cellSize - 2), (int)cellSize, 2),
                            Color.White);
                    }
                    if (Cells[x, y].HasLeft)
                    {
                        spriteBatch.Draw(wallTexture, new Rectangle((int)cellTopLeft.X, (int)cellTopLeft.Y, 2, (int)cellSize), Color.White);
                    }
                    if (Cells[x, y].HasRight)
                    {
                        spriteBatch.Draw(wallTexture, new Rectangle((int)(cellTopLeft.X + cellSize - 2), (int)cellTopLeft.Y, 2, (int)cellSize),
                            Color.White);
                    }
                }
            }
        }
    }
}
