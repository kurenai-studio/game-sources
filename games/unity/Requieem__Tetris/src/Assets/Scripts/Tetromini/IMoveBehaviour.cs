using UnityEngine;

public interface IMoveBehaviour
{
    public TetrominoData Move(TetrominoData obj, Vector2Int direction);
}