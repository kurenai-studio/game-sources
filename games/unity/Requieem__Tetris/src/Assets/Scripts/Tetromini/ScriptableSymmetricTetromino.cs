using UnityEngine;

[CreateAssetMenu(fileName = "New Tetromino", menuName = "Tetromini/SymmetricTetromino")]
public class ScriptableSymmetricTetromino : ScriptableTetrominoBase
{
    [SerializeField] private SymmetricTetromino m_tretromino;
    override public ITetromino Tetromino => m_tretromino;
}