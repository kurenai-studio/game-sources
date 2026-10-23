using UnityEngine;

[CreateAssetMenu(fileName = "ScriptableTetrisGame", menuName = "ScriptableObjects/ScriptableTetrisGame", order = 1)]
public class ScriptableTetrisGame : ScriptableObject
{
    [SerializeField] private ScriptableTetrominiCollection m_tetrominiCollection;
    [SerializeField] private ScriptableTetrisBoard m_tetrisBoard;
    [SerializeField] private bool m_isDropping = false;

    private ITetromino m_currentTetromino;

    public ScriptableTetrominiCollection TetrominiCollection => m_tetrominiCollection;
    public ScriptableTetrisBoard TetrisBoard => m_tetrisBoard;

    public void ResetGame()
    {
        m_tetrisBoard.ClearAllCells();
    }

    public bool IsGameOver()
    {
        foreach(Vector2Int _cell in m_tetrisBoard.OccupiedCells)
        {
            if(_cell.y >= m_tetrisBoard.Size.y - 1)
            {
                return true;
            }
        }

        return false;
    }

    public void ClearLines()
    {
        for(int _y = 0; _y < m_tetrisBoard.Size.y; _y++)
        {
            if(IsLineComplete(_y))
            {
                ClearLine(_y);
                MoveLinesDown(_y);
            }
        }
    }

    private bool IsLineComplete(int y)
    {
        for(int _x = 0; _x < m_tetrisBoard.Size.x; _x++)
        {
            if(!m_tetrisBoard.IsCellOccupied(new Vector2Int(_x, y)))
            {
                return false;
            }
        }

        return true;
    }

    private void ClearLine(int y)
    {
        for(int _x = 0; _x < m_tetrisBoard.Size.x; _x++)
        {
            m_tetrisBoard.ClearCell(new Vector2Int(_x, y));
        }
    }

    private void MoveLinesDown(int y)
    {
        for(int _y = y; _y < m_tetrisBoard.Size.y - 1; _y++)
        {
            for(int _x = 0; _x < m_tetrisBoard.Size.x; _x++)
            {
                if(m_tetrisBoard.IsCellOccupied(new Vector2Int(_x, _y + 1)))
                {
                    m_tetrisBoard.OccupyCell(new Vector2Int(_x, _y), m_tetrisBoard.CellColor(new Vector2Int(_x, _y + 1)));
                    m_tetrisBoard.ClearCell(new Vector2Int(_x, _y + 1));
                }
            }
        }
    }

    private void SpawnRandomTetromino()
    {
        var _randomTetromino = m_tetrominiCollection.GetRandomTetromino();
        _randomTetromino = _randomTetromino.Move(m_tetrisBoard.SpawnPosition);

        foreach(Vector2Int _cell in _randomTetromino.Data.GridSpaceCells)
        {
            m_tetrisBoard.OccupyCell(_cell, _randomTetromino.Color);
        }

        m_currentTetromino = _randomTetromino;
        m_isDropping = true;
    }

    private void Drop()
    {
        var _oldTetromino = m_currentTetromino;
        m_currentTetromino = m_currentTetromino.Move(new Vector2Int(0, -1));

        var _collides = false;
        foreach(Vector2Int _cell in m_currentTetromino.Data.GridSpaceCells)
        {
            _collides = _collides || (m_tetrisBoard.IsCellOccupied(_cell) && !_oldTetromino.Data.GridSpaceCells.Contains(_cell));
            _collides = _collides || !m_tetrisBoard.IsCellWithinBounds(_cell);
        }

        if(!_collides)
        {
            foreach(Vector2Int _cell in _oldTetromino.Data.GridSpaceCells)
            {
                m_tetrisBoard.ClearCell(_cell);
            }
            foreach(Vector2Int _cell in m_currentTetromino.Data.GridSpaceCells)
            {
                m_tetrisBoard.OccupyCell(_cell, m_currentTetromino.Color);
            }
        }
        else
        {
            m_isDropping = false;
            foreach(Vector2Int _cell in m_currentTetromino.Data.GridSpaceCells)
            {
                if(IsLineComplete(_cell.y))
                {
                    ClearLine(_cell.y);
                    MoveLinesDown(_cell.y);
                }
            }
        }
    }

    public void Tick()
    {
        if(!m_isDropping)
        {
            SpawnRandomTetromino();
        }
        else
        {
            Drop();
        }
    }
}