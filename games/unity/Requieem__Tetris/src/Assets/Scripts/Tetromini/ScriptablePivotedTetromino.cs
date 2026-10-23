using UnityEngine;

[CreateAssetMenu(fileName = "New Tetromino", menuName = "Tetromini/PivotedTetromino")]
public class ScriptablePivotedTetromino : ScriptableTetrominoBase
{
    [SerializeField] private PivotedTetromino m_tretromino;
    override public ITetromino Tetromino => m_tretromino;
}