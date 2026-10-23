using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Board : MonoBehaviour {

  public GameObject blockPrefab;

  public Color color;

  public static int cols = 10;

  public static int rows = 20;

  void Start() {
    for (int col = -1; col < cols + 1; col++) {
      for (int row = -1; row < rows; row++) {
        if (col < 0 || col >= cols || row < 0) {
          GameObject wall = Instantiate(blockPrefab, new Vector2(col, row), Quaternion.identity);
          wall.transform.SetParent(transform, false);
          Renderer prefabRender = wall.GetComponent<Renderer>();
          prefabRender.material.color = color;
        }
      }
    }
  }
}
