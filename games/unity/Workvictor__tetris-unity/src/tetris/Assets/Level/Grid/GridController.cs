using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GridController : MonoBehaviour {
  public int width = 10;

  public int height = 24;

  public int[,] matrix;

  Transform GetBlock(int x, int y) {
    Transform result = null;
    foreach (Transform child in transform) {
      if (child.position.x == x && child.position.y == y) {
        result = child;
      }
    }
    return result;
  }

  public void MergeMatrix(Transform parent, Color color, GameObject blockPrefab) {
    foreach (Transform child in parent) {
      Vector2Int pos = RoundPos(child.position);
      SetMatrixValue(pos, 1);
      GameObject block = Instantiate(blockPrefab, transform);
      block.transform.Translate(pos.x, pos.y, 0);
      block.GetComponent<Renderer>().material.color = color;
    }
    for (int y = height - 1; y >= 0; y--) {
      CheckFulfilledRow(y);
    }
  }

  void CheckFulfilledRow(int y) {
    int topRow = height - 1;
    bool fulfilled = true;
    for (int x = 0; x < width; x++) {
      if (matrix[x, y] == 0) {
        fulfilled = false;
        break;
      }
    }
    if (fulfilled) {
      foreach (Transform block in transform) {
        if (block.position.y == y) {
          Destroy(block.gameObject);
        } else if (block.position.y > y) {
          block.Translate(Vector2.down);
        }
      }
      for (int yy = y; yy < topRow; yy++) {
        for (int x = 0; x < width; x++) {
          matrix[x, yy] = matrix[x, yy + 1];
        }
      }
      for (int x = 0; x < width; x++) {
        matrix[x, topRow] = 0;
      }
    }
  }

  private void SetMatrixValue(Vector2 position, int value) {
    if (IsValidPosition(position)) {
      Vector2Int pos = RoundPos(position);
      matrix[pos.x, pos.y] = value;
    }
  }

  private Vector2Int RoundPos(Vector2 pos) {
    return new Vector2Int((int)Mathf.Round(pos.x), (int)Mathf.Round(pos.y));
  }

  private int GetMatrixValue(Vector2Int pos) {
    return IsValidPosition(pos) ? matrix[pos.x, pos.y] : 0;
  }

  public int GetWidth(int offset = 0) {
    return width + offset; ;
  }

  public int GetHeight(int offset = 0) {
    return height + offset;
  }

  public bool IsValidPosition(Vector2 position) {
    Vector2Int pos = RoundPos(position);
    return Mathf.Round(pos.x) >= 0 && Mathf.Round(pos.x) < width && Mathf.Round(pos.y) >= 0 && Mathf.Round(pos.y) < height;
  }

  public bool CollidesVertical(Transform matrix) {
    bool result = false;
    foreach (Transform child in matrix) {
      Vector2Int pos = RoundPos(child.position);
      if (GetMatrixValue(pos) > 0 || pos.y < 0) {
        result = true;
        break;
      }
    }
    return result;
  }

  public bool OutOfBounds(Vector2Int pos) {
    return pos.x < 0 || pos.x >= width || pos.y < 0 || pos.y >= height;
  }

  public bool Collides(Transform matrix) {
    bool result = false;
    foreach (Transform child in matrix) {
      Vector2Int pos = RoundPos(child.position);
      if (GetMatrixValue(pos) > 0 || OutOfBounds(pos)) {
        result = true;
        break;
      }
    }
    return result;
  }

  void Start() {
    matrix = new int[width, height];
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        matrix[x, y] = 0;
      }
    }
  }
}
