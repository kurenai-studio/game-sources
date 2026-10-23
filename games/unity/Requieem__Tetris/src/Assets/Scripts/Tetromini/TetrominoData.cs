using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public struct TetrominoData
{
    [SerializeField] private Vector2Int[] m_cells;
    [SerializeField] private RotationState m_rotation;
    [SerializeField] private Vector2 m_position;

    public Vector2 Position { get => m_position; set => m_position = value; }
    public Vector2Int[] Cells { get => m_cells; set => m_cells = value; }
    public HashSet<Vector2Int> GridSpaceCells
    {
        get
        {
            HashSet<Vector2Int> _gridSpaceCells = new();
            for(int _i = 0; _i < m_cells.Length; _i++)
            {
                _gridSpaceCells.Add(new Vector2Int(m_cells[_i].x + (int)m_position.x, m_cells[_i].y + (int)m_position.y));
            }
            return _gridSpaceCells;
        }
    }
    public RotationState Rotation { get => m_rotation; set => m_rotation = value; }
    public TetrominoData(Vector2Int[] cells, RotationState rotation, Vector2 position)
    {
        m_cells = cells;
        m_rotation = rotation;
        m_position = position;
    }
}