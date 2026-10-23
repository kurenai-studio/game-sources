using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "ScriptableTetrisBoard", menuName = "ScriptableObjects/TetrisBoard", order = 1)]
public class ScriptableTetrisBoard : ScriptableObject
{
    [SerializeField] private Vector2Int m_size;
    [SerializeField] private Vector2Int m_spawnPosition;
    [SerializeField] private Sprite m_wallSprite;

    private HashSet<Vector2Int> m_occupiedCells = new HashSet<Vector2Int>();
    private Dictionary<Vector2Int, Color> m_cellColors = new Dictionary<Vector2Int, Color>();

    public Vector2Int Size => m_size;
    public Vector2Int SpawnPosition => m_spawnPosition;
    public Sprite WallSprite => m_wallSprite;
    public HashSet<Vector2Int> OccupiedCells => m_occupiedCells;
    public Dictionary<Vector2Int, Color> CellColors => m_cellColors;
    public Color CellColor(Vector2Int cell)
    {
        if(m_cellColors.ContainsKey(cell))
        {
            return m_cellColors[cell];
        }
        else
        {
            return Color.clear;
        }
    }
    public bool IsCellOccupied(Vector2Int cell) => m_occupiedCells.Contains(cell);
    public void OccupyCell(Vector2Int cell, Color color)
    {
        m_occupiedCells.Add(cell);
        if(!m_cellColors.ContainsKey(cell))
        {
            m_cellColors.Add(cell, color);
        }
        else
        {
            m_cellColors[cell] = color;
        }
    }
    public void ClearCell(Vector2Int cell)
    {
        m_occupiedCells.Remove(cell);
        m_cellColors.Remove(cell);
    }
    public void ClearAllCells()
    {
        m_occupiedCells.Clear();
        m_cellColors.Clear();
    }
    public bool IsCellWithinBounds(Vector2Int cell) => cell.x >= 0 && cell.x < m_size.x && cell.y >= 0 && cell.y < m_size.y;
}