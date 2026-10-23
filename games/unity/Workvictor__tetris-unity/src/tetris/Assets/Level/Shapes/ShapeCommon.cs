using UnityEngine;

[CreateAssetMenu(fileName = "Shape_Type", menuName = "Tetro Shape")]
public class ShapeCommon : ScriptableObject {
  public Color color;
  public Vector2[] matrix;

  public Vector2 GetLocalPosition(int index) {
    return new Vector2(matrix[index].x, matrix[index].y);
  }
}
