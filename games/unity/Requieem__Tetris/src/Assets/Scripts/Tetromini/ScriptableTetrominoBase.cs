using UnityEngine;

public class ScriptableTetrominoBase : ScriptableObject
{
    virtual public ITetromino Tetromino { get; }
}