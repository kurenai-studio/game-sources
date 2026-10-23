using JetBrains.Annotations;
using System;
using System.IO;
using Unity.Loading;
using Unity.VisualScripting;
using UnityEditor.SearchService;
using UnityEditor.ShaderGraph.Drawing.Inspector.PropertyDrawers;
using UnityEngine;
using UnityEngine.InputSystem;

public class DataMgmt : MonoBehaviour {

  private static string savePath = System.IO.Directory.GetCurrentDirectory() + "\\Saves\\save0";

  private static bool saving = false; // mitigating save spamming
  private static bool loading = false;

  // saves current game state into Saves/save, returns success through a boolean
  public static bool Save() {

    // TODO: saving snake parts
    GameObject snake = GameObject.Find("Snake");
    SnakeController snakeController = snake.GetComponent<SnakeController>();
    snakeController.Save();
    string snakeJSON = JsonUtility.ToJson(snakeController);

    Debug.Log("snakeJSON: " + snakeJSON);

    // saving food location

    GameObject food = GameObject.Find("Food");
    FoodBehavior foodBehavior = food.GetComponent<FoodBehavior>();
    foodBehavior.Save();
    string foodJSON = JsonUtility.ToJson(foodBehavior);

    Debug.Log("foodJSON: " + foodJSON);

    // writing to file
    
    Debug.Log("Saving to \"" + savePath + "\"...");
    FileStream saveFile = new FileStream(savePath, FileMode.Create);
    BinaryWriter writer = new BinaryWriter(saveFile);
    writer.Write(snakeJSON + "\n"); // NOTE: need to create "Save/" directory for this to work
    writer.Write(foodJSON);

    // cleaning up

    writer.Close();
    saveFile.Close();

    Debug.Log("Saved!");

    return true;
  }

  // loads game state at given path, returns success through a boolean
  public static bool Load() {
    // send string to script, have user define loading behavior
    // or define all loading behavior here

    // reading from file
    
    FileStream saveFile = new FileStream(savePath, FileMode.Open);
    BinaryReader reader = new BinaryReader(saveFile);
    
    Debug.Log("Reading from \"" + savePath + "\"...");
    
    string snakeJSON = reader.ReadString(); // TOFIX
    string foodJSON = reader.ReadString();

    reader.Close();
    saveFile.Close();

    print("Debug: snakeJSON: " + snakeJSON);
    print("Debug: foodJSON: " + foodJSON);

    // snake
    GameObject snake = GameObject.Find("Snake");
    SnakeController snakeController = snake.GetComponent<SnakeController>();
    JsonUtility.FromJsonOverwrite(snakeJSON, snakeController);
    snakeController.Load();

    // food
    GameObject food = GameObject.Find("Food");
    FoodBehavior foodBehavior = food.GetComponent<FoodBehavior>();
    JsonUtility.FromJsonOverwrite(foodJSON, foodBehavior);
    foodBehavior.Load();

    // success!
    Debug.Log("Save loaded!");
    return true;
  }

  void Update() {
    
    // saving

    if (Input.GetKey(KeyCode.LeftControl) && Input.GetKey(KeyCode.X) && !saving) {
      Time.timeScale = 0f;
      saving = true;
      Save();
      Time.timeScale = 1f;
    }

    else if (saving && (Input.GetKeyUp(KeyCode.LeftControl) || Input.GetKeyUp(KeyCode.X))) {
      saving = false;
    }

    // loading

    if (Input.GetKey(KeyCode.LeftControl) && Input.GetKey(KeyCode.V) && !loading) {
      Time.timeScale = 0f;
      loading = true;
      Load();
      Time.timeScale = 1f;
    }

    else if (loading && (Input.GetKeyUp(KeyCode.LeftControl) || Input.GetKeyUp(KeyCode.V))) {
      loading = false;
    }

    // revive snake; TOFIX: move to InputHandler
    if (Input.GetKey(KeyCode.R)) {
      GameObject snake = GameObject.Find("Snake");
      SnakeController snakeController = snake.GetComponent<SnakeController>();
      snakeController.ReviveSnake();
    }

  }

}
