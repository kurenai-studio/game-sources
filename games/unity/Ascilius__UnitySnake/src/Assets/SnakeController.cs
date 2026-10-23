using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEditor.Experimental.GraphView;
using UnityEngine;

[System.Serializable]
public class SnakeController : MonoBehaviour, Saveable {

  // snake
  private GameObject head;
  private List<GameObject> snake; // stores references to each snake part
  [SerializeField] private List<Vector2> partLocs;
  [SerializeField] private uint saveLength; // length cache that JsonUtility saves/loads into/from
  private uint currentLength;
  [SerializeField] public Sprite snakeBodySprite;
  [SerializeField] public bool alive;

  // movement
  [SerializeField] public float movementSpeed = 1f;
  private Vector2 nullDirection = new Vector2(0f, 0f); 
  [SerializeField] private Vector2 movementDirection;

  // timing
  private float startTime;
  [SerializeField] public float intervalTime = 0.5f;

  // food
  private GameObject food;

  // Start is called once before the first execution of Update after the MonoBehaviour is created
  public void Start() {
    snake = new List<GameObject>();
    currentLength = 0;

    head = newPart("Head", new Vector2(0f, 0f));
    alive = true;

    // tracking food game object
    food = GameObject.Find("Food");
    FoodBehavior foodBehavior = food.GetComponent<FoodBehavior>();
    foodBehavior.newPos();

    partLocs = new List<Vector2>(); // initializing part location array (for saving/loading)

    startTime = Time.time;
  }

  // revives the snake (if the snake is dead)
  public void ReviveSnake() {
    if (!alive) {
      alive = true;
      head = newPart("Head", new Vector2(0f, 0f));
      movementDirection = new Vector2(0f, 0f);
      Debug.Log("Snake has been revived!");

      FoodBehavior foodBehavior = food.GetComponent<FoodBehavior>();
      foodBehavior.newPos();
    }
  }

  GameObject newPart(string name, Vector2 pos) {
    // print("Debug: New part at " + pos.ToString());

    GameObject newPart = new GameObject(name);
    newPart.AddComponent<SpriteRenderer>();
    newPart.transform.parent = this.transform; // setting newPart as part of the snake

    // adding sprite
    SpriteRenderer sr = newPart.GetComponent<SpriteRenderer>();
    sr.sprite = snakeBodySprite;

    // setting position
    newPart.transform.position = pos;

    // tracking new snake part
    snake.Add(newPart);
    currentLength++;

    return newPart;
  }

  public void destroyTail() {
    GameObject.Destroy(snake[0]); // destorying fifo
    snake.Remove(snake[0]); // removing tracking from internal list
    currentLength--;
  }

  // completely destroys all parts of the snake
  public void obliterateSnake() {
    for (int i = 0; i < currentLength; i++)
      Destroy(snake[i]);
    snake.Clear();
    head = null;
    currentLength = 0;
  }

  // checks whether newLoc is equal to any part locations -> collision
  public bool CollisionCheck(Vector3 newLoc) {
    foreach (GameObject part in snake) {
      if (part.transform.position.Equals(newLoc))
        return true;
    }
    return false;
  }

  // Update is called once per frame
  public void Update() {
    // determining input direction
    float hor = Input.GetAxis("Horizontal");
    float ver = Input.GetAxis("Vertical");

    Vector2 updatedDirection;
    if (Mathf.Abs(hor) > Mathf.Abs(ver))
      updatedDirection = new Vector2(hor, 0f);
    else
      updatedDirection = new Vector2(0f, ver);
    
    updatedDirection.Normalize();

    // rejecting no direction change and reverse direction
    Vector2 reverseDirection = new Vector2(movementDirection.x * -1, movementDirection.y * -1);
    // print("Debug: movementDirection: " + movementDirection);
    // print("Debug: reverseDirection: " + reverseDirection);
    if (!(updatedDirection.Equals(nullDirection) || updatedDirection.Equals(reverseDirection))) {
      movementDirection = updatedDirection;
      // print("Debug: Direction updated: " + movementDirection.ToString());
    }
  }

  private void FixedUpdate() {
    float totalTime = Time.time - startTime;
    // Debug.Log("startTime: " + startTime);
    // Debug.Log("totalTime: " + totalTime);

    bool timeToMove = totalTime > intervalTime;
    /*
    if (timeToMove)
      Debug.Log("Time to move!");
    */

    bool hasDirection = !movementDirection.Equals(nullDirection);

    // alive behavior; movement

    if (alive && (timeToMove && hasDirection)) {
      Vector3 loc = head.transform.position + (Vector3)(movementDirection * movementSpeed);
      if (CollisionCheck(loc)) {
        alive = false;
        Debug.Log("Snake has died!");
      }
      // Debug.Log("Snake still alive!");

      // move snake
      head.name = "Body";
      head = newPart("Head", loc);

      // eating
      Vector2 foodLoc = food.transform.position;
      if (head.transform.position.Equals(foodLoc))
        food.tag = "Eaten"; // marking food as eaten
      else
        destroyTail();

      startTime = Time.time; // reset timer
    }

    // dead behavior; death animation
    else if (!alive) {
      if (currentLength > 0)
        destroyTail();

      startTime = Time.time;
    }

  }

  // returns snake parts list
  public List<GameObject> getSnake()
  {
    return snake;
  }

  public void Save() {
    saveLength = currentLength;
    partLocs.Clear();
    foreach (GameObject part in snake) // tail first, head last
      partLocs.Add(part.transform.position);
  }

  public void Load() {
    // clearing current snake
    obliterateSnake();

    // loading snake
    for (int i = 0; i < saveLength; i++) {
      if (i != saveLength - 1) // body parts
        newPart("Body", partLocs[i]);
      else // head
        head = newPart("Head", partLocs[i]);
    }

  }

}
