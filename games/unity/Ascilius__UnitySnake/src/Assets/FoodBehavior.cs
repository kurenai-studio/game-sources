using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class FoodBehavior : MonoBehaviour, Saveable {
  
  private SnakeController snakeObject;

  // saveable data
  [SerializeField] private Vector2 loc;

  // make sure new food location does not collide with snake
  public void newPos() {
    bool pass = false;
    while (!pass) {
      this.transform.position = new Vector2((int)(Random.value * 9) - 4, (int)(Random.value * 5) - 2);
      
      List<GameObject> snake = snakeObject.getSnake();
      pass = true;
      foreach (GameObject body in snake)
      {
        if (body.transform.position.Equals(this.transform.position)) {
          pass = false;
          break;
        }
      }
    }
  }

  // Start is called once before the first execution of Update after the MonoBehaviour is created
  public void Start() {
    snakeObject = GameObject.Find("Snake").GetComponent<SnakeController>();
    newPos();
  }

  // Update is called once per frame
  public void Update() {
    if (this.tag.Equals("Eaten")) {
      newPos();
      this.tag = "Not Eaten"; // marking food as not eaten
    }
  }

  // DEPRECIATED: returns save data in JSON format
  public string getSaveData() {
    return this.transform.position.ToString();
  }

  // save required data into serialized field
  public void Save() {
    loc = this.transform.position;
  }

  // load data from serialized fields
  public void Load() {
    this.transform.position = loc;
  }

}
