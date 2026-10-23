using UnityEngine;

[CreateAssetMenu(fileName = "New Tetromino", menuName = "Tetromini/Tetromino")]
public class ScriptableTetromino : ScriptableTetrominoBase
{
    [SerializeField] private Tetromino m_tretromino;
    override public ITetromino Tetromino => m_tretromino;
}