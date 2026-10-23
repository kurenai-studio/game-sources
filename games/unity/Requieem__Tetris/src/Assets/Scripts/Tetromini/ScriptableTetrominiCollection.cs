using UnityEngine;

[CreateAssetMenu(fileName = "ScriptableTetrominiCollection", menuName = "ScriptableObjects/ScriptableTetrominiCollection", order = 1)]
public class ScriptableTetrominiCollection : ScriptableObject
{
    [SerializeField] private ScriptableTetrominoBase[] m_tetromini;

    public ScriptableTetrominoBase this[int index] => m_tetromini[index];
    public int Length => m_tetromini.Length;
    public ITetromino GetRandomTetromino()
    {
        return m_tetromini[Random.Range(0, m_tetromini.Length)].Tetromino;
    }
}