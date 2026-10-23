using UnityEngine;

public interface ITetromino
{
    public TetrominoData Data { get; set; }
    public ITetromino Rotate(bool direction);
    public ITetromino Move(Vector2Int direction);
    public Color Color { get; set; }
}
