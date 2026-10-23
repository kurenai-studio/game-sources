using System;
using UnityEngine;

[Serializable]
public struct SymmetricTetromino : ITetromino
{
    [SerializeField] private TetrominoData m_data;
    [SerializeField] private Color m_color;

    public Color Color { get => m_color; set => m_color = value; }
    public TetrominoData Data { get => m_data; set => m_data = value; }
    private Vector2Int[] WallticksTests => new Vector2Int[0];
    public ITetromino Move(Vector2Int direction)
    {
        return new SymmetricTetromino(MoveBehaviour.Instance.Move(Data, direction), m_color);
    }
    public ITetromino Rotate(bool clockwise)
    {
        return new SymmetricTetromino(StandardRotationBehaviour.Instance.Rotate(Data, clockwise), m_color);
    }
    public SymmetricTetromino(TetrominoData data, Color color)
    {
        m_data = data;
        m_color = color;
    }
}