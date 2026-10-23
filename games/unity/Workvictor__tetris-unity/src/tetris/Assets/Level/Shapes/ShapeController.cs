using System;
using UnityEngine;

public class ShapeController : MonoBehaviour {
  public ShapeCommon[] shapes;
  public GameObject blockPrefab;
  public GridController grid;
  public GameController game;
  [Range(0.01f, 0.5f)]
  public float handleTimeout = 0.25f;

  protected int matrixSize = 4;
  protected float rotationStep = 90f;
  protected ShapeCommon currentShape;
  protected float updateTime = 0;
  protected float handlerDeltaTime;
  protected Vector2 horizontalDirection = new Vector2(0, 0);

  void Start() {
    handlerDeltaTime = Time.time;
    for (int i = 0; i < matrixSize; i++) {
      Instantiate(blockPrefab, transform);
    }
    SetNextShape();
  }

  private void EachChild(Action<Transform> action) {
    foreach (Transform child in transform) {
      action(child);
    }
  }

  private void InitShape() {
    if (!game.gameIsOver) {
      SetNextShape();
    }
  }

  private void Move(Vector2 vector) {
    transform.Translate(vector, Space.World);
  }

  private void SetNextShape() {
    currentShape = shapes[UnityEngine.Random.Range(0, shapes.Length)];
    transform.position = new Vector2(grid.width / 2, grid.height - matrixSize);
    transform.rotation = Quaternion.Euler(0, 0, 0);
    int i = 0;
    EachChild(child => {
      float x = currentShape.GetLocalPosition(i).x + transform.position.x;
      float y = currentShape.GetLocalPosition(i).y + transform.position.y;
      child.localPosition = currentShape.GetLocalPosition(i);
      child.rotation = Quaternion.Euler(0, 0, 0);
      child.GetComponent<Renderer>().material.color = currentShape.color;
      i++;
    });
  }

  private void FixedUpdate() {
    if (!game.gameIsOver) {
      Move(Vector2.down);
      CheckVerticalMove();
    }
  }

  private void HandlerUpdate() {
    if (Time.time - handlerDeltaTime > handleTimeout && horizontalDirection.x != 0) {
      handlerDeltaTime = Time.time;
      MoveHorizontal(horizontalDirection);
    }
  }

  void Update() {
    if (!game.gameIsOver) {

      if (Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown(KeyCode.W)) {
        RotateMatrix();
      }

      if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A)) {
        horizontalDirection = Vector2.left;
      }

      if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D)) {
        horizontalDirection = Vector2.right;
      }

      if (Input.GetKeyUp(KeyCode.RightArrow) || Input.GetKeyUp(KeyCode.D)
        || Input.GetKeyUp(KeyCode.LeftArrow) || Input.GetKeyUp(KeyCode.A)) {
        horizontalDirection = Vector2.zero;
      }

      if (Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.S)) {
        game.FastForvard();
      }

      if (Input.GetKeyUp(KeyCode.DownArrow) || Input.GetKeyUp(KeyCode.S)) {
        game.SetDefaultDropInterval();
      }

      HandlerUpdate();
    }
  }

  private void MoveVertical(Vector2 vector) {
    Vector2 savePosition = transform.position;
    Move(vector);

  }

  private void CheckVerticalMove() {
    bool collides = grid.CollidesVertical(transform);
    bool outOfbounds = false;
    if (collides) {
      Move(Vector2.up);
      grid.MergeMatrix(transform, currentShape.color, blockPrefab);
      EachChild(child => {
        if (child.position.y > grid.GetHeight(-matrixSize)) {
          outOfbounds = true;
        }
      });
      if (outOfbounds) {
        game.GameOver();
      } else {
        InitShape();
      }
    }
  }

  private void MoveHorizontal(Vector2 vector) {
    Vector2 prevPosition = transform.localPosition;
    Move(vector);

    float offset = 0;
    while (Mathf.Abs(offset) < matrixSize && grid.Collides(transform)) {
      offset = (-Mathf.Sign(offset) * (Mathf.Abs(offset) + 1));
      Move(new Vector2(offset, 0));
    }

    if (grid.Collides(transform)) {
      Move(prevPosition);
    }
  }

  private int GetBottomOffset() {
    int offset = 0;
    EachChild(child => {
      if (Mathf.Abs(transform.position.y - child.position.y) > offset) {
        offset = (int)Mathf.Abs(transform.position.y - child.position.y);
      }
    });
    return offset;
  }

  private void RotateMatrix(int direction = 1) {
    Vector2 prevPosition = transform.position;
    Quaternion prevRotation = transform.rotation;

    transform.Rotate(Vector3.forward, -direction * rotationStep);

    if (grid.Collides(transform)) {
      MoveHorizontal(Vector2.left);
    }

    if (grid.Collides(transform)) {
      transform.position = prevPosition;
      transform.rotation = prevRotation;
    } else {
      int offset = GetBottomOffset();
      EachChild(child => {
        child.Translate(Vector2.up * offset, Space.World);
        child.rotation = Quaternion.Euler(0, 0, 0);
      });
    }

  }
}
