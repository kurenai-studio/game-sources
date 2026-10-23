using UnityEngine;

public class StandardRotationBehaviour : IRotateBehaviour
{
    private static StandardRotationBehaviour m_instance;
    public static StandardRotationBehaviour Instance
    {
        get
        {
            if(m_instance == null)
            {
                m_instance = new StandardRotationBehaviour();
            }
            return m_instance;
        }
    }

    public TetrominoData Rotate(TetrominoData obj, bool clockwise)
    {
        // Rotate the tetromino 90 degrees in the specified direction
        var _rotation = (RotationState)(((int)obj.Rotation + (clockwise ? 1 : 3)) % 4);

        // Using matrix rotation to rotate the cells
        Vector2Int[] _newCells = new Vector2Int[obj.Cells.Length];
        for(int _i = 0; _i < obj.Cells.Length; _i++)
        {
            if(clockwise)
            {
                _newCells[_i] = new Vector2Int(obj.Cells[_i].y, -obj.Cells[_i].x);
            }
            else
            {
                _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, obj.Cells[_i].x);
            }
        }

        return new TetrominoData(_newCells, _rotation, obj.Position);
    }
}