using UnityEngine;

public class MoveBehaviour : IMoveBehaviour
{
    private static MoveBehaviour m_instance;
    public static MoveBehaviour Instance
    {
        get
        {
            if(m_instance == null)
            {
                m_instance = new MoveBehaviour();
            }
            return m_instance;
        }
    }

    public TetrominoData Move(TetrominoData obj, Vector2Int direction)
    {
        return new TetrominoData(obj.Cells, obj.Rotation, obj.Position + direction);
    }
}