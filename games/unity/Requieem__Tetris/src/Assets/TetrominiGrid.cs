using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TetrominiGrid : MonoBehaviour
{
    [SerializeField] private SpriteRenderer m_block;
    [SerializeField] private ScriptableTetrisBoard m_tetrisBoard;
    [SerializeField] private ScriptableTetrisGame m_tetrisGame;
    [SerializeField] private float m_dropInterval = .5f;

    private Vector2 m_gridSize = new Vector2(0.5f, 0.5f);
    private List<SpriteRenderer> m_sprites = new();

    public void DrawTetromini()
    {
        foreach(var _sprite in m_sprites)
        {
            Destroy(_sprite.gameObject);
        }

        m_sprites.Clear();

        foreach(var _cell in m_tetrisBoard.OccupiedCells)
        {
            var _position = new Vector3(_cell.x * m_gridSize.x, _cell.y * m_gridSize.y, 0);
            var _block = Instantiate(m_block, _position, Quaternion.identity);
            _block.color = m_tetrisBoard.CellColors[_cell];
            m_sprites.Add(_block);
        }
    }

    private void Start()
    {
        for(int _i = 0; _i < m_tetrisBoard.Size.x; _i++)
        {
            var _position = new Vector3(_i * m_gridSize.x, -1 * m_gridSize.y, 0);
            var _block = Instantiate(m_block, _position, Quaternion.identity);
            _block.sprite = m_tetrisBoard.WallSprite;
        }

        for(int _i = 0; _i < m_tetrisBoard.Size.y; _i++)
        {
            var _position = new Vector3(m_tetrisBoard.Size.x * m_gridSize.x, (_i * m_gridSize.y) - (1 * m_gridSize.y), 0);
            var _positionLeft = new Vector3(0, (_i * m_gridSize.y) - (1 * m_gridSize.y), 0);
            var _block = Instantiate(m_block, _position, Quaternion.identity);
            var _blockLeft = Instantiate(m_block, _positionLeft, Quaternion.identity);
        }

        StartCoroutine(Tick());
    }

    private IEnumerator Tick()
    {
        while(true)
        {
            yield return new WaitForSeconds(m_dropInterval);
            m_tetrisGame.Tick();
            DrawTetromini();
        }
    }
}
