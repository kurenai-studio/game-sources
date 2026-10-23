using UnityEngine;

public class PivotedRotationBehaviour : IRotateBehaviour
{
    private static PivotedRotationBehaviour m_instance;
    public static PivotedRotationBehaviour Instance
    {
        get
        {
            if(m_instance == null)
            {
                m_instance = new PivotedRotationBehaviour();
            }
            return m_instance;
        }
    }

    // My Version
    /*    public TetrominoData Rotate(TetrominoData obj, bool clockwise)
        {
            // Rotate the tetromino 90 degrees in the specified direction
            var _rotation = (RotationState)(((int)obj.Rotation + (clockwise ? 1 : 3)) % 4);

            // Using matrix rotation to rotate the cells
            Vector2Int[] _newCells = new Vector2Int[obj.Cells.Length];
            for(int _i = 0; _i < obj.Cells.Length; _i++)
            {
                if(clockwise)
                {
                    switch(obj.Rotation)
                    {
                        case RotationState.Up:
                            _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, -obj.Cells[_i].x);
                            break;
                        case RotationState.Right:
                            _newCells[_i] = new Vector2Int(obj.Cells[_i].y + 1, -obj.Cells[_i].x);
                            break;
                        case RotationState.Down:
                            _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, -obj.Cells[_i].x);
                            break;
                        case RotationState.Left:
                            _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, obj.Cells[_i].x + 1);
                            break;
                    }
                }
                else
                {
                    switch(obj.Rotation)
                    {
                        case RotationState.Up:
                            _newCells[_i] = new Vector2Int(obj.Cells[_i].y + 1, -obj.Cells[_i].x);
                            break;
                        case RotationState.Left:
                            _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, -obj.Cells[_i].x);
                            break;
                        case RotationState.Down:
                            _newCells[_i] = new Vector2Int(obj.Cells[_i].y - 1, -obj.Cells[_i].x);
                            break;
                        case RotationState.Right:
                            _newCells[_i] = new Vector2Int(-obj.Cells[_i].y, -obj.Cells[_i].x);
                            break;
                    }
                }
            }

            return new TetrominoData(_newCells, _rotation, obj.Position);
        }*/

    public TetrominoData Rotate(TetrominoData obj, bool clockwise)
    {
        // Rotate the tetromino 90 degrees in the specified direction
        var _rotation = (RotationState)(((int)obj.Rotation + (clockwise ? 1 : 3)) % 4);

        // Using matrix rotation to rotate the cells around the pivot (-0.5, 0.5)
        Vector2Int[] _newCells = new Vector2Int[obj.Cells.Length];
        for(int _i = 0; _i < obj.Cells.Length; _i++)
        {
            // Translate cell so that pivot is at the origin
            int _x = obj.Cells[_i].x;
            int _y = obj.Cells[_i].y;
            float _translatedX = _x + 0.5f;
            float _translatedY = _y - 0.5f;

            // Apply rotation
            float _rotatedX, _rotatedY;
            if(clockwise)
            {
                _rotatedX = -_translatedY;
                _rotatedY = _translatedX;
            }
            else
            {
                _rotatedX = _translatedY;
                _rotatedY = -_translatedX;
            }

            // Translate back
            _newCells[_i] = new Vector2Int(Mathf.RoundToInt(_rotatedX - 0.5f), Mathf.RoundToInt(_rotatedY + 0.5f));
        }

        return new TetrominoData(_newCells, _rotation, obj.Position);
    }

}